#===================================================================
#        所持カード情報取得パッケージ
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
package Card;

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
                "name",
                "skill_id",
                "made_e_no",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/card_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    my $div_card_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_card");

    if (!$div_card_node) {return;}

    $self->GetCardData($div_card_node);
    
    return;
}

#-----------------------------------#
#    所持カードデータ取得
#------------------------------------
#    引数｜所持カードデータノード
#-----------------------------------#
sub GetCardData{
    my $self  = shift;
    my $div_node = shift;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$div_node);
 
    if ($self->{ResultNo} <= 1) {
        $self->ParseTrData = $self->ParseTrData_0_1;
    }

    $self->ParseTrData($$table_nodes[0]);

    return;
}

#-----------------------------------#
#    tableノード解析・取得
#------------------------------------
#    引数｜カードテーブルノード
#-----------------------------------#
sub ParseTrData{
    my $self  = shift;
    my $table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_node);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($name, $skill_id) = ("", 0);
        my $skill_name = "";

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);

        my $td0_text = $$td_nodes[1]->as_text;
        my @td0_child = $$td_nodes[1]->content_list;

        if (scalar(@td0_child) > 2) {
            $name       = $td0_child[1];
            $skill_name = $td0_child[3]->as_text;
            $skill_name =~ s/（//g;
            $skill_name =~ s/）//g;

        } else {
            $name       = $$td_nodes[1]->as_text;
            $skill_name = $$td_nodes[1]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$skill_name, -1, -1, -1, -1, 0, ""]);

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $skill_id)));
    }

    return;
}

#-----------------------------------#
#    tableノード解析・取得(第1新規登録、第1回更新結果レイアウト)
#------------------------------------
#    引数｜カードテーブルノード
#-----------------------------------#
sub ParseTrData_0_1{
    my $self  = shift;
    my $table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_node);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($name, $skill_id) = ("", 0);
        my $skill_name = "";

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);

        my $td0_text = $$td_nodes[0]->as_text;
        my @td0_child = $$td_nodes[0]->content_list;

        if (scalar(@td0_child) > 2) {
            $name       = $td0_child[1];
            $skill_name = $td0_child[3]->as_text;
            $skill_name =~ s/（//g;
            $skill_name =~ s/）//g;

        } else {
            $name       = $$td_nodes[0]->as_text;
            $skill_name = $$td_nodes[0]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$skill_name, -1, -1, -1, -1, 0, ""]);

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $skill_id)));
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
