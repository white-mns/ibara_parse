#===================================================================
#        戦闘行動解析パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";

require "./source/battle/Damage.pm";
require "./source/new/NewAction.pm";

use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package BattleAction;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
        Datas => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Action} = StoreData->new();
    $self->{Datas}{Acter}  = StoreData->new();
    $self->{Datas}{New}    = NewAction->new();
    $self->{Datas}{Damage} = Damage->new();

    $self->{Datas}{New}->Init   ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    $self->{Datas}{Damage}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});

    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "turn",
                "act_id",
                "act_type",
                "skill_id",
                "fuka_id",
                "lv",
    ];
    $self->{Datas}{Action}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "acter_type",
                "e_no",
                "enemy_id",
                "suffix_id",
    ];
    $self->{Datas}{Acter}->Init($header_list);
  
    #出力ファイル設定
    $self->{Datas}{Action}->SetOutputName( "./output/battle/action_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Acter}->SetOutputName ( "./output/battle/acter_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜ターン数,戦闘開始時・Turn表記divノード
#-----------------------------------#
sub GetData{
    my $self          = shift;
    $self->{Turn}     = shift;
    my $node          = shift;

    $self->ParseBattleActionNodes($node);
    
    return;
}

#-----------------------------------#
#    戦闘開始時・Turn表記に使われるdivノードを元に、次のターン開始までの行動を解析
#------------------------------------
#    引数｜Turn表記ノード
#-----------------------------------#
sub ParseBattleActionNodes{
    my $self = shift;
    my $turn_node = shift;

    my ($acter_type, $e_no, $enemy_id) = (-1, 0, 0);

    if (!$turn_node) {return;}

    my @nodes = $turn_node->right;

    foreach my $node (@nodes) {

        if ($node =~ /HASH/ && $node->tag eq "div" && $node->attr("class") && $node->attr("class") eq "R870") {last;}
        if ($node =~ /HASH/ && $node->tag eq "b" &&  $node->right =~ /HASH/ && $node->right->tag eq "dl") {
            if ($node->as_text =~ /(.+)の行動/) {
                ($acter_type, $e_no, $enemy_id) = (-1, 0, 0);

                my $nickname = $1;
                $nickname =~ s/^▼//;
                $nickname =~ s/\s//g;

                if (exists($self->{NicknameToEno}{$nickname})) {
                    $e_no = $self->{NicknameToEno}{$nickname};
                    $acter_type = 0;

                } elsif (exists($self->{NicknameToEnemyId}{$nickname})) {
                    $enemy_id = $self->{NicknameToEnemyId}{$nickname};
                    $acter_type = 1;
                }

            }

        } elsif ($node =~ /HASH/ && $node->tag eq "dl") {
            my $dl_nodes = &GetNode::GetNode_Tag("dl", \$node);
            foreach my $dl_node (@$dl_nodes) {  
                if (!$dl_node->attr("class")) {next;} # class属性のないdlノードは、直下のdlノードに情報が全て入っているため解析・カウントを除外する

                $self->GetBattleAction($acter_type, $e_no, $enemy_id, $dl_node);

                $self->{ActId} += 1;
                $self->{ActSubId} += 1;
                $self->{Critical} = 0;
            }

            my ($acter_type, $e_no, $enemy_id) = (-1, 0, 0);
        }

    }

    return;
}

#-----------------------------------#
#    戦闘行動dlノードを解析
#------------------------------------
#    引数｜行動種別
#            0:通常攻撃
#            1:アクティブスキル
#            2:パッシブスキル・付加
#          ENo
#          敵ID
#          戦闘行動ノード
#-----------------------------------#
sub GetBattleAction{
    my $self = shift;
    my $acter_type = shift;
    my $e_no = shift;
    my $enemy_id = shift;
    my $dl_node = shift;

    my @nodes = $dl_node->content_list;

    foreach my $node (@nodes) {
        my ($act_type, $skill_id, $fuka_id) = (-1, 0, 0);

        if ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /F[87]i/) {
            $act_type = 1;

            my $skill_name = $node->as_text;

            if ($skill_name =~ /このターン、|領域効果|この列の全領域値が減少|前ターンのクリティカル数/) {
                next;
            }

            my $sk_nodes = &GetNode::GetNode_Tag_Attr_RegExp("b", "class", 'SK\d', \$node);

            if (scalar(@$sk_nodes)) {
                $skill_name = $$sk_nodes[0]->as_text;
                $skill_name =~ s/^\>\>//g;
            }

            $skill_name =~ s/\s//g;
            $skill_name =~ s/！！//g;
            $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$skill_name, 0, 0, 0, 0, 0, " "]);

            $self->{Datas}{Action}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, -1) ));
            $self->{Datas}{Acter}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $acter_type, $e_no, $enemy_id, 0) ));

            $self->{Datas}{New}->RecordNewActionData($skill_id, $fuka_id);

            
        } elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /HK\d/) {
            my $node_text = $node->as_text;
            if ($node_text =~ /(.+)の(.+?)！/) {
                $act_type = 2;
                ($acter_type, $e_no, $enemy_id) = (-1, 0, 0);
                my $lv = -1;

                my $nickname  = $1;
                my $fuka_name = $2;
                $nickname =~ s/\s//g;

                if (exists($self->{NicknameToEno}{$nickname})) {
                    $e_no = $self->{NicknameToEno}{$nickname};
                    $acter_type = 0;

                } elsif (exists($self->{NicknameToEnemyId}{$nickname})) {
                    $enemy_id = $self->{NicknameToEnemyId}{$nickname};
                    $acter_type = 1;
                }

                my @right = $node->right;

                if ($right[1] =~ /HASH/ && $right[1]->attr("class") && $right[1]->attr("class") =~ /SK\d/) {
                    $fuka_name = $right[1]->as_text;
                    $fuka_name =~ s/^\>\>//g;
                }

                if ($fuka_name =~ s/LV(\d+)//) {
                    $lv = $1;
                }

                $fuka_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($fuka_name);

                $self->{Datas}{Action}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, $lv) ));
                $self->{Datas}{Acter}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $acter_type, $e_no, $enemy_id, 0) ));

                $self->{Datas}{New}->RecordNewActionData($skill_id, $fuka_id);

            } elsif ($node_text =~ /通常攻撃！/) {
                $act_type = 0;

                $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, ["通常攻撃", 0, 0, 0, 0, 0, " "]);

                $self->{Datas}{Action}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, -1) ));
                $self->{Datas}{Acter}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $acter_type, $e_no, $enemy_id, 0) ));

                $self->{Datas}{New}->RecordNewActionData($skill_id, $fuka_id);
            }

        } elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && ($node->attr("class") =~ /BS\d/ || $node->attr("class") =~ /Z\d/)) {
            $self->GetBattleAction($acter_type, $e_no, $enemy_id, $node);

        } elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->as_text =~ /^[0-9]+$/) { # ダメージの解析
            $self->{Datas}{Damage}->ParseDamageNode($node, $self->{Critical}, $self->{ActId}, $self->{ActSubId});
            $self->{ActSubId} += 1;
            $self->{Critical} = 0;

        } elsif ($node =~ /HASH/ && $node->tag eq "i" && $node->attr("class") && $node->attr("class") =~ /Y4/) { # クリティカル数の取得
            $self->{Critical} = $self->{Datas}{Damage}->ParseCriticalNode($node, $self->{ActId}, $self->{ActSubId});

        } elsif (($node =~ /攻撃を回避！$/) || ($node =~ /HASH/ && $node->tag eq "b" && $node->as_text =~ /攻撃を回避！$/)) {
            $self->{Datas}{Damage}->ParseDodgeNode($node, $self->{Critical}, $self->{ActId}, $self->{ActSubId});
            $self->{ActSubId} += 1;
            $self->{Critical} = 0;
        }
    }

    return;
}

#-----------------------------------#
#    戦闘参加者の愛称を取得
#------------------------------------
#    引数｜
#-----------------------------------#
sub GetActerNickname{
    my $self = shift;
    my $node = shift;

    $self->{NicknameToEno}     = {};
    $self->{NicknameToEnemyId} = {};

    my $div_INIJN_nodes = &GetNode::GetNode_Tag_Attr("div", "class", 'INIJN', \$node);

    foreach my $div_INIJN_node (@$div_INIJN_nodes) {
        my $link_nodes = &GetNode::GetNode_Tag("a", \$div_INIJN_node);
        if (scalar(@$link_nodes)) {
            my $nickname = $$link_nodes[0]->as_text;
            my $src = $$link_nodes[0]->attr("href");

            $nickname =~ s/\s//g;

            if ($src =~ /r(\d+)\.html/) {
                $self->{NicknameToEno}{$nickname} = $1;
            }

        } else {
            if ($self->{ResultNo} > 1) {
                $self->GetEnemyNickname($div_INIJN_node);

            } else {
                $self->GetEnemyNickname_0_1($div_INIJN_node);
            }

        }
    }

    $self->{Datas}{Damage}->SetActerNickname($self->{NicknameToEno}, $self->{NicknameToEnemyId});
}

#-----------------------------------#
#    敵の愛称を取得
#------------------------------------
#    引数｜
#-----------------------------------#
sub GetEnemyNickname{
    my $self = shift;
    my $node = shift;

    my @child_nodes = $node->content_list;
    my @b_child_nodes = $child_nodes[0]->content_list;
    my $enemy_name = $b_child_nodes[2];
    $enemy_name =~ s/\s//g;
    my $nickname = $enemy_name;

    if ($enemy_name =~ /[A-Z]$/) {
        chop($enemy_name);
    }

    my $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($enemy_name);

    $self->{NicknameToEnemyId}{$nickname} = $enemy_id;
}

#-----------------------------------#
#    敵の愛称を取得
#------------------------------------
#    引数｜
#-----------------------------------#
sub GetEnemyNickname_0_1{
    my $self = shift;
    my $node = shift;

    my @child_nodes = $node->content_list;
    my $enemy_name = $child_nodes[2];
    $enemy_name =~ s/\s//g;
    my $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($enemy_name);

    $self->{NicknameToEnemyId}{$enemy_name} = $enemy_id;
}

#-----------------------------------#
#    戦闘開始時・行動番号をリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    $self->{BattleId} = shift;

    $self->{ActId} = 0;
    $self->{ActSubId} = 0;
    $self->{Critical} = 0;
    $self->{NicknameToEno}  = {};
    $self->{NicknameToEnemyId} = {};

    $self->{Datas}{Damage}->BattleStart($self->{BattleId});
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
