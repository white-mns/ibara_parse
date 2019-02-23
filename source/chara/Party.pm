#===================================================================
#        所属パーティ取得パッケージ
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
package Party;

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
                "party_type",
                "party",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/party_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $nodes = shift;
    
    $self->{ENo} = $e_no;

    my $ne0_tr = $self->SearchMatchingTrNodeFromTitleImg($nodes, "ne0");
    my $ne_tr  = $self->SearchMatchingTrNodeFromTitleImg($nodes, "ne");

    $self->GetParty    ($ne0_tr, 0);

    $self->GetParty    ($ne_tr,  1);
    
    return;
}

#-----------------------------------#
#    対戦組み合わせTR取得
#------------------------------------
#    引数｜データノード
#          タイトル画像名
#-----------------------------------#
sub SearchMatchingTrNodeFromTitleImg{
    my $self = shift;
    my $nodes = shift;
    my $img_text   = shift;

    foreach my $node (@$nodes) {
        my $img_nodes = &GetNode::GetNode_Tag("img", \$node);

        if (!scalar(@$img_nodes)) { next;}

        my $title   = $$img_nodes[0]->attr("src");
        if ($title =~ /$img_text.png/) {
            my $table_nodes = &GetNode::GetNode_Tag("table", \$node);
            my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$table_nodes[0]);

            return $$tr_nodes[0];
        }
    }

    return;
}

#-----------------------------------#
#    パーティ内で最も若いENoをパーティ番号として所属パーティ取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub GetParty{
    my $self = shift;
    my $node = shift;
    my $party_type = shift;

    if (!$node) {return;}

    my @td_nodes    = $node->content_list;

    my $table_nodes = &GetNode::GetNode_Tag("table", \$td_nodes[0]);
    if (!scalar(@$table_nodes)) {return;}

    my $td_nodes = &GetNode::GetNode_Tag_Attr("td", "align", "RIGHT", \$$table_nodes[0]);
    if (!scalar(@$td_nodes)) {return;}

    my $link_nodes = &GetNode::GetNode_Tag("a", \$$td_nodes[0]);

    my $party = $self->GetENoFromLink($$link_nodes[0]);

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $party_type, $party) ));
    

    return;
}

#-----------------------------------#
#    リンクからENoを取得する
#------------------------------------
#    引数｜リンクノード
#-----------------------------------#
sub GetENoFromLink{
    my $self = shift;
    my $node = shift;
    
    if (!$node || $node !~ /HASH/) {return 0;}

    my $url = $node->attr("href");

    if ($url =~ /r(\d+).html/) {
        return $1;
    }

    return 0;

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
