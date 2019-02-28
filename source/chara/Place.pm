#===================================================================
#        現在地取得パッケージ
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
package Place;

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
                "field_id",
                "area",
                "area_column",
                "area_row",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,現在地データノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetPlaceData($node);
    
    return;
}

#-----------------------------------#
#    現在地データ取得
#------------------------------------
#    引数｜現在地データノード
#-----------------------------------#
sub GetPlaceData{
    my $self = shift;
    my $node = shift;
    my ($field_id, $area, $area_column, $area_row) = (0, "",  "", 0);
 
    my $b_nodes = &GetNode::GetNode_Tag("b", \$node);

    $field_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($$b_nodes[0]->as_text);

    $area = $$b_nodes[0]->right->right;
    my @area = split("-", $area);
    $area_column = $area[0];
    $area_row    = $area[1];

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $field_id, $area, $area_column, $area_row);
    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

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
