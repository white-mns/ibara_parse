#===================================================================
#        料理結果取得パッケージ
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
package Cook;

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
    $self->{Datas}{Cook}  = StoreData->new();
    $self->{Datas}{Passive}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "requester_e_no",
                "cook_id",
                "last_result_no",
                "last_generate_no",
                "i_no",
                "source_name",
                "name",
    ];

    $self->{Datas}{Cook}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "requester_e_no",
                "cook_id",
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
    $self->{Datas}{Cook}->SetOutputName   ("./output/chara/cook_"         . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Passive}->SetOutputName("./output/chara/cook_passive_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
        $file_name = "./output/chara/cook_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

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

    $self->CrawlCookData($action_div_node);
    
    return;
}

#-----------------------------------#
#    料理結果データ取得
#------------------------------------
#    引数｜アクションdivノード
#-----------------------------------#
sub CrawlCookData{
    my $self = shift;
    my $node = shift;
 
    my @child_nodes = $node->content_list;

    my $cook_id = 0;
    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /をつく/) {
            $self->GetCook($child_node, 1, $cook_id);
            $cook_id += 1;

        }
    }

    return;
}

#-----------------------------------#
#    料理結果データ取得
#------------------------------------
#    引数｜料理アイテム名ノード
#-----------------------------------#
sub GetCook{
    my $self = shift;
    my $node = shift;
    my $is_success = shift;
    my $cook_id = shift;

    my ($e_no, $i_no, $source_name, $name) = ($self->{ENo}, -1, "", "");

    my @node_lefts = $node->left;
    @node_lefts = reverse(@node_lefts);
    my @node_rights = $node->right;

    $name = $node->as_text;

    if ($node_lefts[3] =~ /HASH/ && $node_lefts[3]->tag eq "a") { #他人に料理してもらったときは料理者のEnoを記録
        $e_no = $node_lefts[3]->attr("href");
        $e_no =~ /r(\d+)\.html/;
        $e_no = $1;
    }

    if ($node_lefts[1] =~ /HASH/ && $node_lefts[1]->as_text =~ /ItemNo.(\d+) (.+)/) {
        $i_no = $1;
        $source_name = $2 ? $2 : "";
    }

    foreach my $node_right (@node_rights) {
        # 料理名ノードの右側にあるノードを、ENoが出てくる（＝次の生産行動が出てくる）まで走査する。（常時スキルがあるとその判定が挟まるため）
        # 料理後の装備性能が出たところでデータを登録する
        if ($node_right =~ /HASH/ && $node_right->tag eq "a") {return;}
        if ($node_right =~ /HASH/ && $node_right->attr("class") && $node_right->attr("class") eq "Y3"){return;}

        my $node_right_text = $node_right;
        if ($node_right =~ /HASH/ && $node_right->as_text =~ /／(.+)：強さ(\d+)／/) {
            $node_right_text = $node_right->as_text;
        }

        if ($node_right_text =~ /／(.+)：強さ(\d+)／/) {
            $self->CrawlPassiveData(\@node_rights, $cook_id, $e_no);

            $self->{Datas}{Cook}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $self->{ENo}, $cook_id, $self->{LastResultNo}, $self->{LastGenerateNo}, $i_no, $source_name, $name) ));
        }
    }
}

#-----------------------------------#
#    料理パッシブ発動走査
#------------------------------------
#    引数｜料理アイテム名ノード
#-----------------------------------#
sub CrawlPassiveData{
    my $self = shift;
    my $node_rights = shift;
    my $cook_id = shift;
    my $e_no = shift;

    foreach my $node_right (@$node_rights) {
        if ($node_right =~ /HASH/ && $node_right->tag eq "a") {return;}
        if ($node_right =~ /HASH/ && $node_right->attr("class") && $node_right->attr("class") eq "Y3"){return;}

        if ($node_right =~ /HASH/ && $node_right->tag eq "span" && $node_right->attr("class") eq "P3"){
            $self->GetPassive($node_right, $cook_id, $e_no);
        }

        my $node_right_text = $node_right;
        if ($node_right =~ /HASH/ && $node_right->as_text =~ /／(.+)：強さ(\d+)／/) {
            $node_right_text = $node_right->as_text;
        }

        if ($node_right_text =~ /／(.+)：強さ(\d+)／/) {return;}
    }
}

#-----------------------------------#
#    料理パッシブ発動データ取得
#------------------------------------
#    引数｜料理アイテム名ノード
#-----------------------------------#
sub GetPassive{
    my $self = shift;
    my $node = shift;
    my $cook_id = shift;
    my $e_no = shift;

    my ($skill_id, $result, $dice_total) = (0, -99, 0);
    my @dice = (0, 0, 0, 0, 0, 0);

    my $span_L3_nodes = &GetNode::GetNode_Tag_Attr("span", "class", "L3", \$node);

    if (scalar(@$span_L3_nodes)){
        my $name = $$span_L3_nodes[0]->as_text;
        $name =~ s/！$//;
        if ($name eq "謎飯チャレンジ") { $name = "謎飯作製";}

        $skill_id = exists($self->{CommonDatas}{Skill}{$e_no}{$name}) ? $self->{CommonDatas}{Skill}{$e_no}{$name} : 0;
    }

    my @child_nodes = $node->content_list;
    my $last_child = $child_nodes[$#child_nodes];

    if ($last_child =~ /HASH/ && $last_child->tag eq "span") {
        my $text = $last_child->as_text;

        if ($text =~ /！/) {
            my @texts = split(/！/, $text);

            if    ($texts[0] =~ /大成功/) {$result = 2;}
            elsif ($texts[0] =~ /成功/)   {$result = 1;}
            elsif ($texts[0] =~ /大失敗/) {$result = -2;}
            elsif ($texts[0] =~ /失敗/)   {$result = -1;}

        }
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

    $self->{Datas}{Passive}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $cook_id, $skill_id, $result, 0, $dice_total, $dice[0], $dice[1], $dice[2], $dice[3], $dice[4], $dice[5]) ));
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
