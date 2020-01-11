#===================================================================
#        荊街用スクレイピング関数パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================

package GetIbaraNode;
use source::lib::GetNode;

#-----------------------------------#
#    アクションDIVノード取得
#    　「READY...?」「ACTION」などの一連の処理をまとめたブロックを取得
#------------------------------------
#    引数｜データノード
#          タイトル画像名
#-----------------------------------#
sub SearchDivNodeFromTitleImg{
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
#    対戦組み合わせTR取得
#------------------------------------
#    引数｜データノード
#          タイトル画像名
#-----------------------------------#
sub SearchMatchingTrNodeFromTitleImg{
    my $nodes = shift;
    my $img_text   = shift;

    foreach my $node (@$nodes) {
        my $img_nodes = &GetNode::GetNode_Tag("img", \$node);

        if (!scalar(@$img_nodes)) { next;}

        my $title   = $$img_nodes[0]->attr("src");
        if ($title =~ /$img_text.png/) {
            my $table_nodes = &GetNode::GetNode_Tag("table", \$node);
            if (!scalar(@$table_nodes)) {next;}
            my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$table_nodes[0]);

            return $$tr_nodes[0];
        }
    }

    return;
}

#-----------------------------------#
#    リンクからENoを取得する
#------------------------------------
#    引数｜リンクノード
#-----------------------------------#
sub GetENoFromLink{
    my $node = shift;
    
    if (!$node || $node !~ /HASH/) {return 0;}

    my $url = $node->attr("href");

    if ($url =~ /r(\d+).html/) {
        return $1;
    }

    return 0;

}

1;
