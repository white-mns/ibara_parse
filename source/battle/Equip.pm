#===================================================================
#        装備取得パッケージ
#-------------------------------------------------------------------
#            (C) 2021 @white_mns
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
package Equip;

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
    $self->{Datas}{Equip} = StoreData->new();
    $self->{BattleId} = -1;
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "battle_id",
                "equip_no",
                "name",
                "kind_id",
                "strength",
                "range",
                "effect_1_id",
                "effect_1_value",
                "effect_2_id",
                "effect_2_value",
                "effect_3_id",
                "effect_3_value",
    ];
    $self->{Datas}{Equip}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Equip}->SetOutputName ( "./output/battle/equip_"      . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜戦闘開始時ノード 
#-----------------------------------#
sub GetData{
    my $self = shift;
    $self->{BattleId}  = shift;
    $self->{PNo}       = shift;
    $self->{BattleNo}  = shift;
    my $div_r870_node = shift;

    if (!$div_r870_node) {return;}

    $self->GetEquipData($div_r870_node);

    return;
}

#-----------------------------------#
#    装備データ取得
#------------------------------------
#    引数｜戦闘開始時ノード 
#-----------------------------------#
sub GetEquipData{
    my $self = shift;
    my $div_r870_node = shift;
    my ($e_no, $equip_no) = (0, 0);

    # equip_no  => 0:武器、1:防具、2:装飾、3:自由
    my %equip_kinds = ("武器" => 0, "大砲" => 0, "呪器" => 0, "魔弾" => 0, "戦盾" => 0, "暗器" => 0,
                       "防具" => 1, "法衣" => 1, "重鎧" => 1, "衣装" => 1, "隔壁" => 1, "聖衣" => 1,
                       "装飾" => 2, "魔晶" => 2, "護符" => 2, "御守" => 2, "薬箱" => 2, "楽器" => 2);

    if (!$div_r870_node) {return;}

    $self->SetActerNicknameToIndex($div_r870_node);

    my @nodes = $div_r870_node->content_list;

    foreach my $node (@nodes) {
        if ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /BAA\d/) {
                if ($node->as_text =~ /^▼(.+?)は行動順/) {
                my $nickname = $1;
                $e_no = $self->GetENoFromNickname($nickname);
                $equip_no = 0;
            }
        }

        if ($node =~ /HASH/ && $node->tag eq "span" && $node->attr("class") && $node->attr("class") eq "Y3") {
            my ($name, $kind_id, $strength, $range) = ("", 0, 0, 0);
            my $effects = [{"id"=> 0, "value"=> 0},{"id"=> 0, "value"=> 0},{"id"=> 0, "value"=> 0}];
            my @right_nodes = $node->right;
            $name = $node->as_text;

            my $equip_text = $right_nodes[2];
            if ($equip_text !~ /／/ && $right_nodes[3] =~ /HASH/) { # アイテム名着色時の処理
                $equip_text = $right_nodes[3]->as_text;
            }

            if ($equip_text =~ /／(.+?)：強さ(\d+?)／/){
                $kind_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                $strength = $2;
                if (exists($equip_kinds{$1})) {
                    my $equip_kind_no = $equip_kinds{$1};
                    if ($equip_no < $equip_kind_no) { # 武器・防具・装飾の未装備時の処理
                        $equip_no = $equip_kind_no;

                    } elsif ($equip_no > 0 && $equip_kind_no == 0) { # 防具・装飾の未装備時の処理
                        $equip_no = 3;
                    }
                }
            }

            if ($equip_text =~ /／［効果1］(.+?) ［効果2］(.+?) ［効果3］(.+?)$/){
                my @effect_texts = ($1, $2, $3);
                my $i = 0;

                foreach my $text (@effect_texts) {
                    $text =~ s/【射程(\d)】//;
                    $text =~ s/／//;

                    if ($text =~ /(\D+)(\d+)/) {
                        $$effects[$i]{"id"}    = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                        $$effects[$i]{"value"} = $2;
                    } else {
                        # 効果に数値がないとき
                        $$effects[$i]{"id"} = $self->{CommonDatas}{ProperName}->GetOrAddId($text);
                    }

                    $i += 1;
                }
            }

            if ($equip_text =~ /【射程(\d)】/){
                $range = $1;
            }


            $self->{Datas}{Equip}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $self->{BattleId}, $equip_no, $name, $kind_id, $strength, $range,
                                                                  $$effects[0]{"id"}, $$effects[0]{"value"},
                                                                  $$effects[1]{"id"}, $$effects[1]{"value"},
                                                                  $$effects[2]{"id"}, $$effects[2]{"value"})));
            $equip_no += 1;
        }
    }

    return;
}


#-----------------------------------#
#    戦闘参加者の愛称を索引に追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub SetActerNicknameToIndex{
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

        }
    }
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
sub GetENoFromNickname{
    my $self = shift;
    my $nickname = shift;

    if (exists($self->{NicknameToEno}{$nickname})) {
        return $self->{NicknameToEno}{$nickname};

    }

    return 0;
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
