#===================================================================
#        スキル習得画面スキル情報取得パッケージ
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
package ActSkill;

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

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,divY870ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_node = shift;
    
    $self->ParseTrData($table_node);
    
    return;
}

#-----------------------------------#
#    tableノード解析・取得
#------------------------------------
#    引数｜スキルテーブルノード
#-----------------------------------#
sub ParseTrData{
    my $self  = shift;
    my $table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_node);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($skill_id, $skill_name, $type_id, $element_id, $timing_id, $text) = (0, "", 0, 0, 0, "");

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);

        $skill_name = $$td_nodes[1]->as_text;

        my $td1_class = $$td_nodes[1]->attr("class");
        if ($td1_class && $td1_class =~ /Z(\d)/) {
            $element_id = $1;
        }

        $text = $$td_nodes[4]->as_text;
        if ($text =~ s/(【.+】)//) {
            $type_id   = 1;
            $timing_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(1, [$skill_name, $type_id, $element_id, $$td_nodes[2]->as_text, $$td_nodes[3]->as_text, $timing_id, $text]);
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
