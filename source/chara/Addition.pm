#===================================================================
#        付加結果取得パッケージ
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
package Addition;

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
    $self->{Datas}{Addition}  = StoreData->new();
    $self->{Datas}{Passive}  = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "requester_e_no",
                "addition_id",
                "last_result_no",
                "last_generate_no",
                "target_i_no",
                "target_name",
                "addition_i_no",
                "addition_name",
    ];

    $self->{Datas}{Addition}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "requester_e_no",
                "addition_id",
                "skill_id",
                "result",
                "increase",
                "dice_total",
                "dice_1",
                "dice_2",
                "dice_3",
                "dice_4",
                "dice_5",
                "dice_6",
    ];

    $self->{Datas}{Passive}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Addition}->SetOutputName( "./output/chara/addition_"         . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Passive}->SetOutputName ( "./output/chara/addition_passive_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
        $file_name = "./output/chara/addition_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

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
    my $nodes = shift;
    
    $self->{ENo} = $e_no;

    my $action_div_node = &GetIbaraNode::SearchDivNodeFromTitleImg($nodes, "action");

    if (!$action_div_node) { return;}

    $self->CrawlAdditionData($action_div_node);
    
    return;
}

#-----------------------------------#
#    付加結果データ取得
#------------------------------------
#    引数｜アクションdivノード
#-----------------------------------#
sub CrawlAdditionData{
    my $self = shift;
    my $node = shift;
 
    my @child_nodes = $node->content_list;

    my $addition_id = 0;
    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /付加し/) {
            $self->GetAddition($child_node, 1, $addition_id);
            $addition_id += 1;

        }
    }

    return;
}

#-----------------------------------#
#    付加結果データ取得
#------------------------------------
#    引数｜付加アイテム名ノード
#-----------------------------------#
sub GetAddition{
    my $self = shift;
    my $node = shift;
    my $is_success = shift;
    my $addition_id = shift;
    my ($e_no, $target_i_no, $target_name, $addition_i_no, $addition_name) = ($self->{ENo}, -1, "", -1, "");

    my @node_lefts = $node->left;
    @node_lefts = reverse(@node_lefts);
    my @node_rights = $node->right;

    if ($node_lefts[3] =~ /HASH/ && $node_lefts[3]->tag eq "a") { #他人に付加してもらったときは付加者のEnoを記録
        $e_no = $node_lefts[3]->attr("href");
        $e_no =~ /r(\d+)\.html/;
        $e_no = $1;
    }

    if ($node_lefts[1] =~ /HASH/ && $node_lefts[1]->as_text =~ /ItemNo.(\d+) (.+)/) {
        $target_i_no = $1;
        $target_name = $2 ? $2 : "";
    }

    if ($node =~ /HASH/ && $node->as_text =~ /ItemNo.(\d+) (.+)/) {
        $addition_i_no = $1;
        $addition_name = $2 ? $2 : "";

    }

    foreach my $node_right (@node_rights) {
        # 素材ノードの右側にあるノードを、ENoが出てくる（＝次の生産行動が出てくる）まで走査する。（常時スキルがあるとその判定が挟まるため）
        # 付加後の装備性能が出たところでデータを登録する
        if ($node_right =~ /HASH/ && $node_right->tag eq "a"){return;}
        if ($node_right =~ /HASH/ && $node_right->attr("class") && $node_right->attr("class") eq "Y3"){return;}

        if ($node_right =~ /／(.+)：強さ(\d+)／/) {
            $self->CrawlPassiveData(\@node_rights, $addition_id, $e_no);

            $self->{Datas}{Addition}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $self->{ENo}, $addition_id, $self->{LastResultNo}, $self->{LastGenerateNo}, $target_i_no, $target_name, $addition_i_no, $addition_name) ));
        }
    }
}

#-----------------------------------#
#    付加パッシブ発動走査
#------------------------------------
#    引数｜付加アイテム名ノード
#-----------------------------------#
sub CrawlPassiveData{
    my $self = shift;
    my $node_rights = shift;
    my $addition_id = shift;
    my $e_no = shift;

    foreach my $node_right (@$node_rights) {
        if ($node_right =~ /HASH/ && $node_right->tag eq "a") {return;}
        if ($node_right =~ /HASH/ && $node_right->attr("class") && $node_right->attr("class") eq "Y3"){return;}

        if ($node_right =~ /HASH/ && $node_right->tag eq "span" && $node_right->attr("class") eq "P3"){
            $self->GetPassive($node_right, $addition_id, $e_no);
        }

        if ($node_right =~ /／(.+)：強さ(\d+)／/) {return;}
    }
}

#-----------------------------------#
#    付加パッシブ発動データ取得
#------------------------------------
#    引数｜付加アイテム名ノード
#-----------------------------------#
sub GetPassive{
    my $self = shift;
    my $node = shift;
    my $addition_id = shift;
    my $e_no = shift;

    my ($skill_id, $result, $dice_total, $increase) = (0, -99, 0, 0);
    my @dice = (0, 0, 0, 0, 0, 0);

    my $span_L3_nodes = &GetNode::GetNode_Tag_Attr("span", "class", "L3", \$node);

    if (scalar(@$span_L3_nodes)){
        my $name = $$span_L3_nodes[0]->as_text;
        $name =~ s/！$//;

        $skill_id = exists($self->{CommonDatas}{Skill}{$e_no}{$name}) ? $self->{CommonDatas}{Skill}{$e_no}{$name} : 0;
    }

    my @child_nodes = $node->content_list;
    my $last_child = $child_nodes[$#child_nodes];

    if ($last_child =~ /HASH/ && $last_child->tag eq "span") {
        my $text = $last_child->as_text;

        if ($text =~ /！/) {
            my @texts = split(/！/, $text);

            if    ($texts[0] eq "成功") {$result = 1;}
            elsif ($texts[0] eq "大成功") {$result = 2;}
            elsif ($texts[0] eq "失敗") {$result = -1;}
            elsif ($texts[0] eq "不発") {$result = -1;}
            elsif ($texts[0] eq "大失敗") {$result = -2;}
            elsif ($texts[0] =~ /効果(\d+)のLVが(\d+)増加/) {
                $increase = $2;
            }
        }
    } else {
        my $text = $last_child;
        if ($text =~ /通常付加/) {$result = 0;}
    }

    my $b_nodes = &GetNode::GetNode_Tag("b", \$node);
    if (scalar(@$b_nodes)) {
        $dice_total = $$b_nodes[0]->as_text;
    }

    my $span_DC_nodes = &GetNode::GetNode_Tag_Attr("span", "class", "DC", \$node);
    if (scalar(@$span_DC_nodes)) {
        if ($$span_DC_nodes[0]->as_text =~ / /) {
            my @dice_dots = split(/ /, $$span_DC_nodes[0]->as_text);
            my $i = 0;

            foreach my $dice_dot (@dice_dots) {
                $dice[$i] = $dice_dot;

                $i += 1;
            }
        }
    }

    $self->{Datas}{Passive}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $addition_id, $skill_id, $result, $increase, $dice_total, $dice[0], $dice[1], $dice[2], $dice[3], $dice[4], $dice[5]) ));
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
