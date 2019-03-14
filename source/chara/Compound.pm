#===================================================================
#        合成結果取得パッケージ
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
package Compound;

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
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "last_result_no",
                "last_generate_no",
                "source_1_i_no",
                "source_1_name",
                "source_2_i_no",
                "source_2_name",
                "sources_name",
                "is_success",
                "compound_result_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/compound_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/chara/compound_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

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

    $self->GetCompoundData($action_div_node);
    
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
#    合成結果データ取得
#------------------------------------
#    引数｜キャラクターイメージデータノード
#-----------------------------------#
sub GetCompoundData{
    my $self = shift;
    my $node = shift;
 
    my @child_nodes = $node->content_list;

    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->left && $child_node->left =~ /合成し、/) {
            $self->GetSucceedCompound($child_node, 1);

        } elsif ($child_node =~ /HASH/ && $child_node->left && $child_node->left =~ /合成実験し、/) {
            $self->GetSucceedCompound($child_node, 2);

        } elsif ($child_node =~ /合成(実験)*しようとしましたが、LVが足りないようです。/) {
            $self->GetFailedCompound($child_node, -1);

        } elsif ($child_node =~ /合成(実験)*しようとしましたが、合成材料を見失ってしまいました。/) {
            $self->GetFailedCompound($child_node, -2);

        }
    }

    return;
}

#-----------------------------------#
#    合成・合成実験成功結果データ取得
#------------------------------------
#    引数｜キャラクターイメージデータノード
#-----------------------------------#
sub GetSucceedCompound{
    my $self = shift;
    my $node = shift;
    my $is_success = shift;

    my ($source_1_i_no, $source_1_name, $source_2_i_no, $source_2_name, $sources_name, $compound_result_id) = (-1, "", -1, "", "", 0);

    my @node_lefts = $node->left;
    @node_lefts = reverse(@node_lefts);

    if ($node_lefts[3] =~ /HASH/ && $node_lefts[3]->as_text =~ /ItemNo.(\d+) (.+)/) {
        $source_1_i_no = $1;
        $source_1_name = $2 ? $2 : "";
    }

    if ($node_lefts[1] =~ /HASH/ && $node_lefts[1]->as_text =~ /ItemNo.(\d+) (.+)/) {
        $source_2_i_no = $1;
        $source_2_name = $2 ? $2 : "";
    }

    $sources_name = join(" ", sort( ($source_1_name, $source_2_name) ));

    $compound_result_id = $self->{CommonDatas}{ProperName}->GetOrAddId($node->as_text);

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $source_1_i_no, $source_1_name, $source_2_i_no, $source_2_name, $sources_name, $is_success, $compound_result_id) ));
}

#-----------------------------------#
#    合成Lv不足データ取得
#------------------------------------
#    引数｜キャラクターイメージデータノード
#-----------------------------------#
sub GetFailedCompound{
    my $self = shift;
    my $text = shift;
    my $is_success = shift;

    my ($source_1_i_no, $source_1_name, $source_2_i_no, $source_2_name, $sources_name, $compound_result_id) = (-1, "", -1, "", "", 0);

    if ($text =~ /ItemNo.(\d+) (.+) に ItemNo.(\d+) (.+) を合成(実験)*しようとしましたが、LVが足りないようです。/) {
        $source_1_i_no = $1;
        $source_1_name = $2;
        $source_2_i_no = $3;
        $source_2_name = $4;

    } elsif ($text =~ /ItemNo.(\d+)\s{0,1}(.*) に ItemNo.(\d+)\s{0,1}(.*) を合成(実験)*しようとしましたが、合成材料を見失ってしまいました。/) {
        $source_1_i_no = $1;
        $source_1_name = $2 ? $2 : "";
        $source_2_i_no = $3;
        $source_2_name = $4 ? $4 : "";

    }
    
    $sources_name = join(" ", sort( ($source_1_name, $source_2_name) ));

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $source_1_i_no, $source_1_name, $source_2_i_no, $source_2_name, $sources_name, $is_success, $compound_result_id) ));
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
