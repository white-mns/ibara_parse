#===================================================================
#        戦闘ターン別解析パッケージ
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
package Turn;

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
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "battle_type",
                "enemy_party_name_id",
                "member_num",
    ];

    $self->{Datas}{Data}->Init($header_list);
   
    #出力ファイル設定
    #$self->{Datas}{Data}->SetOutputName ( "./output/battle/turn_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $p_no      = shift;
    my $battle_no = shift;
    my $nodes     = shift;
    
    $self->{PNo} = $p_no;
    $self->{BattleNo} = $battle_no;

    $self->ParseTurnNodes($nodes);
    
    return;
}

#-----------------------------------#
#    戦闘開始時・Turn表記に使われるdivノードを解析
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub ParseTurnNodes{
    my $self = shift;
    my $nodes = shift;

    if (!$nodes) {return;}

    foreach my $node (@$nodes) {

        my $turn = $self->GetTurn($node);

        print "turn : " . $turn . "\n";
    }


    #$self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $battle_type, $name_id, $member_num) ));

    return;
}

#-----------------------------------#
#    戦闘開始時・Turn表記に使われるdivノードを解析
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub GetTurn{
    my $self = shift;
    my $node = shift;

    my $turn = -1;

    if (!$node) {return;}

    my $img_nodes = &GetNode::GetNode_Tag("img", \$node);

    foreach my $img_node (@$img_nodes) {
        my $src = $img_node->attr("src");

        if ($src =~ /turn\.png/) {
            $turn = "";

        } elsif ($src =~ /tu(\d+)\.png/) {
            $turn .= $1;
        } elsif ($src =~ /icheck\.png/) {
            $turn = "0";
        }
    }

    return $turn;
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
