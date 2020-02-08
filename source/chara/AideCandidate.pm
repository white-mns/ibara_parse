#===================================================================
#        エイド化候補取得パッケージ
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
package AideCandidate;

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
    $self->{Datas}{AideCandidate} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "last_result_no",
                "last_generate_no",
                "enemy_id",
    ];

    $self->{Datas}{AideCandidate}->Init($header_list);

    
    #出力ファイル設定
    $self->{Datas}{AideCandidate}->SetOutputName          ( "./output/chara/aide_candidate_"             . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->{LastGenerateNo} = $self->ReadLastGenerateNo();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastGenerateNo(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/chara/aide_candidate_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }
   
    return 0;
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

    $self->GetAideCandidateData($get_div_node);
    
    return;
}

#-----------------------------------#
#    エイド化候補結果ノード取得
#------------------------------------
#    引数｜GETdivノード
#-----------------------------------#
sub GetAideCandidateData{
    my $self = shift;
    my $get_div_node = shift;
 
    my ($enemy_id) = (0);
    my $span_O3_nodes = &GetNode::GetNode_Tag_Attr("span", "class", "O3", \$get_div_node);

    foreach my $node (@$span_O3_nodes) {
        my @left_nodes = $node->left;
        @left_nodes = reverse(@left_nodes);
        if ($left_nodes[1] =~ /HASH/ && $left_nodes[1]->attr("href") =~ /r(\d+)\.html/){
            if($1 == $self->{ENo}) {
                my $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($node->as_text);

                $self->{Datas}{AideCandidate}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $enemy_id)));

            }
        }
        @left_nodes = reverse(@left_nodes);
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
