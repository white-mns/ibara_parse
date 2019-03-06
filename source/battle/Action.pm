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
use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Action;

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
    $self->{Datas}{Data}   = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "party_no",
                "battle_type",
                "turn",
                "act_id",
                "act_sub_id",
                "acter_type",
                "e_no",
                "enemy_id",
                "act_type",
                "skill_id",
                "fuka_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
   
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName ( "./output/battle/action_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self          = shift;
    $self->{PNo}      = shift;
    $self->{BattleNo} = shift;
    $self->{Turn}     = shift;
    my $node          = shift;

    $self->ParseActionNodes($node);
    
    return;
}

#-----------------------------------#
#    戦闘開始時・Action表記に使われるdivノードを解析
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub ParseActionNodes{
    my $self = shift;
    my $turn_node = shift;

    my ($acter_type, $e_no, $enemy_id) = (-1, -1, -1);

    if (!$turn_node) {return;}

    my @nodes = $turn_node->right;

    foreach my $node (@nodes) {

        if ($node =~ /HASH/ && $node->tag eq "div" && $node->attr("class") eq "R870") {last;}
        if ($node =~ /HASH/ && $node->tag eq "b" &&  $node->right =~ /HASH/ && $node->right->tag eq "dl") {
            if ($node->as_text =~ /(.+)の行動/) {
                my $nickname = $1;
                $nickname =~ s/^▼//;
                $e_no = $nickname;
                $acter_type = 0;
            }

        } elsif ($node =~ /HASH/ && $node->tag eq "dl") {
            my $dl_nodes = &GetNode::GetNode_Tag("dl", \$node);
            foreach my $dl_node (@$dl_nodes) {  
                $self->GetAction($acter_type, $e_no, $enemy_id, $dl_node);
            }

            my ($acter_type, $e_no, $enemy_id) = (-1, -1, -1);
            $self->{ActNo} += 1;
            $self->{ActSubNo} += 1;
        }

    }

    return;
}

#-----------------------------------#
#    戦闘開始時・Action表記に使われるdivノードを解析
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub GetAction{
    my $self = shift;
    my $acter_type = shift;
    my $e_no = shift;
    my $enemy_id = shift;
    my $dl_node = shift;

    my @nodes = $dl_node->content_list;

    foreach my $node (@nodes) {
        my ($act_type, $skill_id, $fuka_id) = (-1, -1, -1);

        if ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /F7i/) {
            $act_type = 0;

            my $skill_name = $node->as_text;
            $skill_name =~ s/\s//g;
            $skill_name =~ s/！！//g;
            $skill_id = $skill_name;

            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $self->{BattleNo}, $self->{Turn}, $self->{ActNo}, $self->{ActSubNo}, $acter_type, $e_no, $enemy_id, $act_type, $skill_id, $fuka_id) ));

            $self->{ActNo} += 1;
            $self->{ActSubNo} += 1;
            
        } elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->attr("class") && $node->attr("class") =~ /HK\d/) {
            my $node_text = $node->as_text;
            if ($node_text =~ /(.+)の(.+?)！/) {
                $act_type = 2;
                $e_no     = $1;
                $fuka_id  = $2;

                $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $self->{BattleNo}, $self->{Turn}, $self->{ActNo}, $self->{ActSubNo}, $acter_type, $e_no, $enemy_id, $act_type, $skill_id, $fuka_id) ));

                $self->{ActNo} += 1;
                $self->{ActSubNo} += 1;

            } elsif ($node_text =~ /通常攻撃！/) {
                $act_type = 1;
                my $skill_name = $node_text;
                $skill_name =~ s/\s//g;
                $skill_name =~ s/！！//g;
                $skill_name  = "通常攻撃";

                $skill_id  = "通常攻撃";

                $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $self->{BattleNo}, $self->{Turn}, $self->{ActNo}, $self->{ActSubNo}, $acter_type, $e_no, $enemy_id, $act_type, $skill_id, $fuka_id) ));

                $self->{ActNo} += 1;
                $self->{ActSubNo} += 1;
            }

        }
    }

    return;
}

#-----------------------------------#
#    戦闘開始時・行動番号をリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    $self->{ActNo} = 0;
    $self->{ActSubNo} = 0;
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
