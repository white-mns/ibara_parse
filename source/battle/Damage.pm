#===================================================================
#        ダメージ解析パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";

use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Damage;

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
    $self->{Datas}{Damage} = StoreData->new();
    $self->{Datas}{Target} = StoreData->new();
    $self->{Datas}{Buffer} = StoreData->new();

    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "damage_type",
                "element_id",
                "value",
    ];
    $self->{Datas}{Damage}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "target_type",
                "e_no",
                "enemy_id",
                "suffix_id",
    ];
    $self->{Datas}{Target}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "buffer_type",
                "value",
    ];
    $self->{Datas}{Buffer}->Init($header_list);
  
    #出力ファイル設定
    $self->{Datas}{Damage}->SetOutputName( "./output/battle/damage_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Target}->SetOutputName( "./output/battle/target_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Buffer}->SetOutputName( "./output/battle/buffer_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    ダメージを解析
#    ダメージ種別
#      1:ダメージ
#      2:SPダメージ
#      3:HP回復
#      4:SP回復
#------------------------------------
#    引数｜ダメージノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseDamageNode{
    my $self          = shift;
    my $b_node        = shift;
    $self->{ActId}    = shift;
    $self->{ActSubId} = shift;

    my ($target_type, $e_no, $enemy_id) = (-1, 0, 0);
    my $damage_type = -1;
    my $element_id  = 0;

    if (!$b_node || !$b_node->left || !$b_node->right) {return;}

    if ($b_node->left !~ /(.+)[にが]/) { return;}
    my $nickname = $1;
    $nickname =~ s/^\s//g;
    $nickname =~ s/のSP//g;
    $nickname =~ s/のHP//g;

    if ($b_node->right =~ /ダメージ！/) {$damage_type = 1;}
    elsif ($b_node->right =~ /ダメージ！/ && $b_node->left =~ /SPに/) {$damage_type = 1;}
    elsif ($b_node->right =~ /回復！/ && $b_node->left =~ /HPが/) {$damage_type = 3;}
    elsif ($b_node->right =~ /回復！/ && $b_node->left =~ /SPが/) {$damage_type = 4;}
    else                                {return;}

    $self->GetENoOrEnemyIdFromNickname($nickname, \$target_type, \$e_no, \$enemy_id);

    my $damage = $b_node->as_text;
 
    $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $damage_type, $element_id, $damage) ));
    $self->{Datas}{Target}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $target_type, $e_no, $enemy_id, 0) ));

    return;
}

#-----------------------------------#
#    回避行動を解析
#    ダメージ種別
#      0:回避
#------------------------------------
#    引数｜ダメージノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseDodgeNode{
    my $self          = shift;
    my $node          = shift;
    $self->{ActId}    = shift;
    $self->{ActSubId} = shift;

    my ($target_type, $e_no, $enemy_id) = (-1, 0, 0);
    my $damage_type = 0;

    if (!$node) {return;}

    my $nickname = "";

    if ($node =~ /(.+)は攻撃を回避！$/)             { $nickname = $1}
    elsif ($node->as_text =~ /(.+)は攻撃を回避！$/) { $nickname = $1}
    else                                            { return;}

    $nickname =~ s/^\s//g;

    $self->GetENoOrEnemyIdFromNickname($nickname, \$target_type, \$e_no, \$enemy_id);

    my $damage = -1;

    $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $damage_type, 0, $damage) ));
    $self->{Datas}{Target}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $target_type, $e_no, $enemy_id, 0) ));

    return;
}

#-----------------------------------#
#    クリティカルを解析
#    ダメージ種別
#      0:回避
#------------------------------------
#    引数｜ダメージノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseCriticalNode{
    my $self          = shift;
    my $i_node        = shift;
    $self->{ActId}    = shift;
    $self->{ActSubId} = shift;

    my $buffer_type = $self->{CommonDatas}{ProperName}->GetOrAddId("Critical Hit");

    if (!$i_node) {return;}

    my $value = (() = $i_node->as_text =~ /Critical Hit!!/g);

    if ($value == 0) {return;}

    $self->{Datas}{Buffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $buffer_type, $value) ));

    return;
}

#-----------------------------------#
#    対象のENoおよび敵番号を取得
#------------------------------------
#    引数｜愛称
#          対象種別
#            0:PC
#            1:NPC
#          ENo
#          敵ID
#-----------------------------------#
sub GetENoOrEnemyIdFromNickname{
    my $self = shift;
    my $nickname = shift;
    my $type = shift;
    my $e_no = shift;
    my $enemy_id = shift;

    if (exists($self->{NicknameToEno}{$nickname})) {
        $$e_no = $self->{NicknameToEno}{$nickname};
        $$type = 0;

    } elsif (exists($self->{NicknameToEnemyId}{$nickname})) {
        $$enemy_id = $self->{NicknameToEnemyId}{$nickname};
        $$type = 1;
    }
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
sub GetDamage{
    my $self = shift;
    my $acter_type = shift;
    my $e_no = shift;
    my $enemy_id = shift;
    my $dl_node = shift;

    my @nodes = $dl_node->content_list;

    foreach my $node (@nodes) {
        my ($act_type, $skill_id, $fuka_id) = (-1, 0, 0);

        if ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /F\di/) {
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

            $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, -1) ));
            $self->{Datas}{Target}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $acter_type, $e_no, $enemy_id, 0) ));

            $self->{ActId} += 1;
            $self->{ActSubId} += 1;
            
        } elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /HK\d/) {
            my $node_text = $node->as_text;
            if ($node_text =~ /(.+)の(.+?)！/) {
                my ($fuka_acter_type, $fuka_e_no, $fuka_enemy_id, $lv) = (-1, 0, 0, -1);
                $act_type = 2;

                my $nickname  = $1;
                my $fuka_name = $2;
                $nickname =~ s/\s//g;

                if (exists($self->{NicknameToEno}{$nickname})) {
                    $fuka_e_no = $self->{NicknameToEno}{$nickname};
                    $fuka_acter_type = 0;

                } elsif (exists($self->{NicknameToEnemyId}{$nickname})) {
                    $fuka_enemy_id = $self->{NicknameToEnemyId}{$nickname};
                    $fuka_acter_type = 1;
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

                $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, $lv) ));
                $self->{Datas}{Target}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $fuka_acter_type, $fuka_e_no, $fuka_enemy_id, 0) ));

                $self->{ActId} += 1;
                $self->{ActSubId} += 1;

            } elsif ($node_text =~ /通常攻撃！/) {
                $act_type = 0;

                $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, ["通常攻撃", 0, 0, 0, 0, 0, " "]);

                $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{Turn}, $self->{ActId}, $act_type, $skill_id, $fuka_id, -1) ));
                $self->{Datas}{Target}->AddData (join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $acter_type, $e_no, $enemy_id, 0) ));

                $self->{ActId} += 1;
                $self->{ActSubId} += 1;
            }

        }
    }

    return;
}

#-----------------------------------#
#    戦闘参加者の愛称を設定
#------------------------------------
#    引数｜
#-----------------------------------#
sub SetActerNickname{
    my $self = shift;
    $self->{NicknameToEno}     = shift;
    $self->{NicknameToEnemyId} = shift;
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
    $self->{NicknameToEno}  = {};
    $self->{NicknameToEnemyId} = {};
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
