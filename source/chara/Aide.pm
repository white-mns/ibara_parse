#===================================================================
#        エイド情報取得パッケージ
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
package Aide;

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
    $self->{Datas}{Data}        = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "aide_no",
                "name",
                "enemy_id",
                "cost_sp",
                "bonds",
                "mhp",
                "msp",
                "mep",
                "range",
                "fuka_texts",
                "skill_texts",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/aide_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    my $div_aide_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_aide");

    if (!$div_aide_node) {return;}

    $self->GetAideData($div_aide_node);
    
    return;
}

#-----------------------------------#
#    エイドデータ取得
#------------------------------------
#    引数｜エイドデータノード
#-----------------------------------#
sub GetAideData{
    my $self  = shift;
    my $div_node = shift;

    my $span_L5_nodes = &GetNode::GetNode_Tag_Attr("span", "class", "L5",\$div_node);
 
    foreach my $node (@$span_L5_nodes){
        my ($aide_no, $name, $enemy_id, $cost_sp, $bonds, $mhp, $msp, $mep, $range, $fuka_texts, $skill_texts) = (-1, "", 0, -1, -1, -1, -1, -1, -1, "", "");
        
        my @right_nodes = $node->right;
        my $tribe_node = $right_nodes[1];
        my $status_node = $right_nodes[3];
        my $skill_node = $right_nodes[4];
        my $ep_node = $right_nodes[5];

        if ($node->as_text =~ /No\.(\d+) (.+)/) {
            $aide_no = $1;
            $name = $2;
        }

        if ($tribe_node && $tribe_node->as_text =~ /（種族：(.+)）/) {
            $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        }

        {
            my $td_nodes = &GetNode::GetNode_Tag("td",\$status_node);
            
            foreach my $td_node (@$td_nodes) {
                my $text = $td_node->as_text;
                if ($text eq "要求SP") { $cost_sp = $td_node->right->as_text; } 
                elsif ($text eq "絆")  { $bonds = $td_node->right->as_text; }
                elsif ($text eq "MHP") { $mhp = $td_node->right->as_text; }
                elsif ($text eq "MSP") { $msp = $td_node->right->as_text; }
                elsif ($text eq "射程"){ $range = $td_node->right->as_text; }

                if ($td_node->attr("colspan") && $td_node->attr("colspan") == 4) {
                    $fuka_texts = $td_node->as_text;
                }

            }
        }

        {
            my $tr_nodes = &GetNode::GetNode_Tag("tr",\$skill_node);
            shift(@$tr_nodes);
            foreach my $tr_node (@$tr_nodes) {
                my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
                $skill_texts .= $$td_nodes[1]->as_text." ";

            }

        }

        if ($ep_node && $ep_node->as_text =~ /最大EP\[(\d+)\]/) {
            $mep = $1;
        }

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $aide_no, $name, $enemy_id, $cost_sp, $bonds, $mhp, $msp, $mep, $range, $fuka_texts, $skill_texts)));
    
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
