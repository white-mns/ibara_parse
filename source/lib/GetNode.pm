#===================================================================
#        スクレイピング用基本パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================

package GetNode;
use HTML::TreeBuilder;

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、属性名、条件
#-----------------------------------#
sub GetNode_Tag_Attr_RegExp {
    my $tag_name   = shift;
    my $attr_name  = shift;
    my $attr_value = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_Attr:$tag_name, $attr_name, $attr_value]\n";
        return $return_nodes;
    }

    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr($attr_name)){
                        $_[0]->attr($attr_name) =~ $attr_value
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、属性名、条件
#-----------------------------------#
sub GetNode_Tag_Attr {
    my $tag_name   = shift;
    my $attr_name  = shift;
    my $attr_value = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_Attr:$tag_name, $attr_name, $attr_value]\n";
        return $return_nodes;
    }

    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr($attr_name)){
                        $_[0]->attr($attr_name) eq $attr_value
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名
#-----------------------------------#
sub GetNode_Tag {
    my $tag_name  = shift;
    my $node      = shift;
    
    my $return_nodes            = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag:$tag_name]\n";
        return $return_nodes;
    }

    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
    );
    return $return_nodes;
}

1;
