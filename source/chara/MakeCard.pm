#===================================================================
#        作成カード結果取得パッケージ
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
package MakeCard;

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
    $self->{Datas}{MakeCard}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "receiver_e_no",
                "name",
                "skill_id",
                "card_no",
    ];

    $self->{Datas}{MakeCard}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{MakeCard}->SetOutputName   ("./output/chara/make_card_"         . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );


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
    my $div_y870_nodes = shift;
    my $div_r870_nodes = shift;

    $self->{ENo} = $e_no;

    my $div_action_node = &GetIbaraNode::SearchDivNodeFromTitleImg($div_r870_nodes, "action");
    my $div_card_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_card");

    if (!$div_action_node) { return;}

    $self->GetMakeCardData($div_action_node, $div_card_node);
    
    return;
}

#-----------------------------------#
#    作成カード結果データ取得
#------------------------------------
#    引数｜アクションdivノード
#    　　　カードdivノード
#-----------------------------------#
sub GetMakeCardData{
    my $self = shift;
    my $node = shift;
    my $card_node = shift;
 
    my @child_nodes = $node->content_list;

    my $make_card_id = 0;
    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->tag && $child_node->tag eq "b" && $child_node->attr("class") && $child_node->attr("class") eq "O3") {
            my ($name, $skill_id, $card_no) = ("", 0, 0);

            my @left_nodes = $child_node->left;
            my @right_nodes = $child_node->right;
            @left_nodes = reverse(@left_nodes);

            my $make_e_no = ($left_nodes[3] =~ /HASH/ && $left_nodes[3]->tag eq "a") ? $left_nodes[3]->attr("href") : ($left_nodes[2] =~ /誰とも交換されず/) ? $self->{ENo} : 0;
            $make_e_no =~ s/\D//g;

            $name = $child_node->as_text;

            my $skill_name = ($right_nodes[1] =~ /HASH/) ? $right_nodes[1]->as_text : "";
            $skill_name =~ s/^（//;
            $skill_name =~ s/）$//;
            $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$skill_name, -1, -1, -1, -1, 0, ""]);

            $card_no = $self->GetCardNo($card_node, $name);

            $self->{Datas}{MakeCard}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $make_e_no, $self->{ENo}, $name, $skill_id, $card_no) ));
        }
    }

    return;
}

#-----------------------------------#
#    作成カード格納番号取得
#------------------------------------
#    引数｜カードdivノード
#    　　　カード名
#-----------------------------------#
sub GetCardNo{
    my $self = shift;
    my $card_div_node = shift;
    my $name = shift;

    my $card_no = 0;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$card_div_node);
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$$table_nodes[0]);
    my $tr_max = scalar(@$tr_nodes) - 1;
    my $td_nodes = &GetNode::GetNode_Tag("td",\$$tr_nodes[$tr_max]);
    my $link_nodes = &GetNode::GetNode_Tag("a",\$$td_nodes[1]);
    my @td0_child = $$td_nodes[1]->content_list;

    my $card_name = $td0_child[1];
    $card_name =~ s/\n//;
    $card_name =~ s/^ //;

    if (scalar(@td0_child) > 2 && $name eq $card_name && $$link_nodes[0] =~ /HASH/) {
        $$link_nodes[0]->attr("href") =~ /&no=(\d+)/;
        $card_no = $1;
    }
    
    return $card_no;
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
