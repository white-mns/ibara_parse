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
    $self->{Datas}{Data}  = StoreData->new();
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

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/cook_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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

    $self->GetCookData($action_div_node);
    
    return;
}

#-----------------------------------#
#    料理結果データ取得
#------------------------------------
#    引数｜アクションdivノード
#-----------------------------------#
sub GetCookData{
    my $self = shift;
    my $node = shift;
 
    my @child_nodes = $node->content_list;

    my $cook_id = 0;
    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /つくって/) {
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
        # 付加後の装備性能が出たところでデータを登録する
        if ($node_right =~ /HASH/ && $node_right->tag eq "a"){return;}
        if ($node_right =~ /／(.+)：強さ(\d+)／/) {

            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $self->{ENo}, $cook_id, $self->{LastResultNo}, $self->{LastGenerateNo}, $i_no, $source_name, $name) ));
        }
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
