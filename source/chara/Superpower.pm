#===================================================================
#        所持異能情報取得パッケージ
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


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Superpower;

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
                "e_no",
                "superpower_id",
                "lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/superpower_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,divY870ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $div_y870_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $div_skill_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_skill");

    if (!$div_skill_node) {return;}

    $self->GetSuperpowerData($div_skill_node);
    
    return;
}

#-----------------------------------#
#    所持異能データ取得
#------------------------------------
#    引数｜所持異能データノード
#-----------------------------------#
sub GetSuperpowerData{
    my $self  = shift;
    my $div_node = shift;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$div_node);
 
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$$table_nodes[0]);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($superpower_id, $lv) = (0, 0);

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        $superpower_id = $self->{CommonDatas}{SuperpowerData}->GetOrAddId(1, [$$td_nodes[0]->as_text, $$td_nodes[2]->as_text]);
        $lv = $$td_nodes[1]->as_text;

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $superpower_id, $lv)));
    }

    return;
}

#-----------------------------------#
#    タイトル画像からノードを探索
#------------------------------------
#    引数｜divY870ノード
#-----------------------------------#
sub SearchNodeFromTitleImg{
    my $self  = shift;
    my $div_nodes = shift;
    my $title = shift;

    foreach my $div_node (@$div_nodes){
        # imgの抽出
        my $img_nodes = &GetNode::GetNode_Tag("img",\$div_node);
        if (scalar(@$img_nodes) > 0 && $$img_nodes[0]->attr("src") =~ /$title/) {
            return $div_node;
        }
    }

    return;
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
