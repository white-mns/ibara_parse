#===================================================================
#        スキル研究情報取得パッケージ
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
package Study;

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
                "skill_id",
                "depth",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/study_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    my $div_study_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_study");

    if (!$div_study_node) {return;}

    $self->GetStudyData($div_study_node);
    
    return;
}

#-----------------------------------#
#    スキル研究データ取得
#------------------------------------
#    引数｜スキル研究データノード
#-----------------------------------#
sub GetStudyData{
    my $self  = shift;
    my $div_node = shift;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$div_node);
 
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$$table_nodes[0]);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        
        foreach my $td_node (@$td_nodes) {
            my ($study_id, $depth) = (0, 0);

            my $td_text  = $td_node->as_text;

            if ($td_text =~ /［ (\d+) ］(.+)/) {
                $depth = $1;
                my $study_name = $2;

                $study_name =~ s/\s//;
                $study_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$study_name, -1, -1, -1, -1, 0, ""]);

                $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $study_id, $depth)));
            }
        }
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
