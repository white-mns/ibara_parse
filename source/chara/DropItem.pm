#===================================================================
#        取得アイテム取得パッケージ
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
package DropItem;

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
    ($self->{LastResultNo}, $self->{LastGenerateNo}) = ($self->{ResultNo} - 1, 0);
    $self->{LastResultNo} = sprintf ("%02d", $self->{LastResultNo});
    
    #初期化
    $self->{Datas}{DropItem} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "name",
                "plus",
    ];

    $self->{Datas}{DropItem}->Init($header_list);

    
    #出力ファイル設定
    $self->{Datas}{DropItem}->SetOutputName( "./output/chara/drop_item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,ブロックdivノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $div_r870_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $get_div_node = &GetIbaraNode::SearchDivNodeFromTitleImg($div_r870_nodes, "get");
    
    if (!$get_div_node) { return;}

    $self->GetDropItemData($get_div_node);
    
    return;
}

#-----------------------------------#
#    取得アイテム結果データ取得
#------------------------------------
#    引数｜GETdivノード
#-----------------------------------#
sub GetDropItemData{
    my $self = shift;
    my $get_div_node = shift;
 
    my $link_nodes = &GetNode::GetNode_Tag("a",\$get_div_node);


    for my $link_node (@$link_nodes) {
        my ($name, $plus) = ("", 0);
        my @link_right_node = $link_node->right;

        if ($self->{ENo} != &GetIbaraNode::GetENoFromLink($link_node) ) { next;}
        if ($link_right_node[2] ne " を入手！") {next;}

        $name = $link_right_node[1]->as_text;
        if ($name =~ /\+(\d+)$/) {$plus = $1;}

        $self->{Datas}{DropItem}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $plus)));
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
