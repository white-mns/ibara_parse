#===================================================================
#        ステータス取得パッケージ
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
package Status;

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
                "style_id",
                "effect",
                "mhp",
                "msp",
                "landform_id",
                "condition",
                "max_condition",
                "ps",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/status_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,キャラクターイメージデータノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $cimgjn1 = shift;
    my $cimgnms = shift;
    
    $self->{ENo} = $e_no;
    $self->{Style}        = -1;
    $self->{Effect}       = -1;
    $self->{MHP}          = -1;
    $self->{MSP}          = -1;
    $self->{Landform}     = -1;
    $self->{Condition}    = -1;
    $self->{MaxCondition} = -1;
    $self->{PS}           = -1;

    $self->GetCIMGJNData($cimgjn1);
    $self->GetCIMGNMData($cimgnms);

    print $$cimgnms[0];

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{Style}, $self->{Effect}, $self->{MHP}, $self->{MSP}, $self->{Landform}, $self->{Condition}, $self->{MaxCondition}, $self->{PS}) ));
    return;
}

#-----------------------------------#
#    ステータスデータ取得
#------------------------------------
#    引数｜キャラクターステータス画像下部データノード
#-----------------------------------#
sub GetCIMGJNData{
    my $self = shift;
    my $node = shift;
 
    my $img_nodes = &GetNode::GetNode_Tag("img", \$node);
    my $div_nodes = &GetNode::GetNode_Tag("div", \$node);

    if ($$img_nodes[1]->attr("src") =~ /p\/j(\d).png/) {
        $self->{Style} = $1;
    }

    $self->{Effect} = "";
    foreach my $img_node (@$img_nodes) {
        if ($img_node->attr("src") =~ /p\/[mn](\d).png/) {
            $self->{Effect} .= $1;
        }
    }

    $self->{MHP}   = $$div_nodes[1]->as_text;
    $self->{MSP}   = $$div_nodes[2]->as_text;

    return;
}

#-----------------------------------#
#    ステータスデータ取得
#------------------------------------
#    引数｜キャラクターステータス上部データノード
#-----------------------------------#
sub GetCIMGNMData{
    my $self = shift;
    my $nodes = shift;

    my $node1_img_nodes = &GetNode::GetNode_Tag("img", \$$nodes[1]);
    my @node3_nodes = $$nodes[3]->content_list;

    if ($$node1_img_nodes[0]->attr("src") =~ /p\/a(\d).png/) {
        $self->{Landform} = $1;
    }

    if ($$nodes[2]->as_text =~ /(\d+) \/ (\d+)/) {
        $self->{Condition}    = $1;
        $self->{MaxCondition} = $2;
    }
    $self->{PS}   = $node3_nodes[0];

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
