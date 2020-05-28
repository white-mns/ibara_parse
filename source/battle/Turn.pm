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

require "./source/battle/BattleAction.pm";

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
    $self->{Datas}{BattleAction} = BattleAction->new();
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";

    $header_list = [
    ];

    $self->{Datas}{Data}->Init($header_list);
    $self->{Datas}{BattleAction}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
   
    #出力ファイル設定
    #$self->{Datas}{Data}->SetOutputName ( "./output/battle/turn_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜戦闘管理番号,PT番号,戦闘番号,戦闘開始時・Turn表記divノード
#-----------------------------------#
sub GetData{
    my $self          = shift;
    $self->{BattleId} = shift;
    $self->{PNo}      = shift;
    $self->{BattleNo} = shift;
    my $nodes         = shift;
    
    $self->{Datas}{BattleAction}->BattleStart($self->{BattleId});

    $self->ParseTurnNodes($nodes);
    
    return;
}

#-----------------------------------#
#    戦闘開始時・Turn表記に使われるdivノードを解析
#------------------------------------
#    引数｜Turn表記ノード
#-----------------------------------#
sub ParseTurnNodes{
    my $self = shift;
    my $nodes = shift;

    if (!$nodes) {return;}

    $self->{Datas}{BattleAction}->SetActerNicknameIndex($$nodes[0]);

    { # 戦闘開始時発動付加の解析
        my $img_nodes = &GetNode::GetNode_Tag("img", \$$nodes[0]);
        if (scalar(@$img_nodes)) {
            $self->{Datas}{BattleAction}->GetData(0, $$img_nodes[0]);
        }
    }

    foreach my $node (@$nodes) {

        my $turn = $self->GetTurn($node);

        $self->{Datas}{BattleAction}->GetData($turn, $node);
    }

    return;
}

#-----------------------------------#
#    戦闘開始時・Turn表記に使われるdivノードを解析
#------------------------------------
#    引数｜Turn表記ノード
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
