#===================================================================
#        作製結果取得パッケージ
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
package Make;

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
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "last_result_no",
                "last_generate_no",
                "i_no",
                "name",
                "kind_id",
                "strength",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/make_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/chara/make_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }
   
    return 0;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,キャラクターイメージデータノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $nodes = shift;
    
    $self->{ENo} = $e_no;

    my $action_div_node = $self->SearchDivNodeFromTitleImg($nodes, "action");

    if (!$action_div_node) { return;}

    $self->GetMakeData($action_div_node);
    
    return;
}

#-----------------------------------#
#    行動DIVノード取得
#------------------------------------
#    引数｜データノード
#          タイトル画像名
#-----------------------------------#
sub SearchDivNodeFromTitleImg{
    my $self = shift;
    my $nodes = shift;
    my $img_text   = shift;

    foreach my $node (@$nodes) {
        my $img_nodes = &GetNode::GetNode_Tag("img", \$node);

        if (!scalar(@$img_nodes)) { next;}

        my $title   = $$img_nodes[0]->attr("src");
        if ($title =~ /$img_text.png/) {

            return $node;
        }
    }

    return;
}

#-----------------------------------#
#    作製結果データ取得
#------------------------------------
#    引数｜アクションデータノード
#-----------------------------------#
sub GetMakeData{
    my $self = shift;
    my $node = shift;
 
    my @child_nodes = $node->content_list;

    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /作製し/) {
            $self->GetMake($child_node, 1);

        }
    }

    return;
}

#-----------------------------------#
#    作製結果データ取得
#------------------------------------
#    引数｜アクションデータノード
#-----------------------------------#
sub GetMake{
    my $self = shift;
    my $node = shift;
    my $is_success = shift;

    my ($e_no, $i_no, $source_name, $name, $kind_id, $strength) = ($self->{ENo}, -1, "", "", 0, 0);

    my @node_lefts = $node->left;
    @node_lefts = reverse(@node_lefts);
    my @node_rights = $node->right;

    $name = $node->as_text;

    if ($node_lefts[3] =~ /HASH/ && $node_lefts[3]->tag eq "a") { #他人に作製してもらったときは作製者のEnoを記録
        $e_no = $node_lefts[3]->attr("href");
        $e_no =~ /r(\d+)\.html/;
        $e_no = $1;
    }

    if ($node_lefts[1] =~ /HASH/ && $node_lefts[1]->as_text =~ /ItemNo.(\d+) (.+)/) {
        $i_no = $1;
        $source_name = $2 ? $2 : "";
    }

    if ($node_rights[2] =~ /／(.+)：強さ(\d+)／/) {
        $kind_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        $strength = $2;

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $self->{LastResultNo}, $self->{LastGenerateNo}, $i_no, $name, $kind_id, $strength) ));
    }
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
