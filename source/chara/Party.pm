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
use source::lib::GetIbaraNode;


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
    $self->{Datas}{Party}     = StoreData->new();
    $self->{Datas}{PartyInfo} = StoreData->new();
    $self->{CommonDatas}{Party} = {};

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "party_type",
                "party_no",
    ];

    $self->{Datas}{Party}->Init($header_list);
 
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "party_type",
                "name",
                "member_num",
    ];

    $self->{Datas}{PartyInfo}->Init($header_list);
   
    #出力ファイル設定
    $self->{Datas}{Party}->SetOutputName    ( "./output/chara/party_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{PartyInfo}->SetOutputName( "./output/chara/party_info_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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

    my $ne0_tr = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ne0");
    my $nm0_tr = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nm0");
    my $nd0_tr = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nd0");
    my $ng0_tr = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ng0");
    my $ne_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ne");
    my $nm_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nm");
    my $nd_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nd");
    my $ng_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ng");

    $self->{CommonDatas}{Party}{$self->{ENo}} = $self->{ENo};

    $self->GetParty    ([$ne0_tr, $nm0_tr, $nd0_tr, $ng0_tr], 0);
    $self->GetPartyInfo([$ne0_tr, $nm0_tr, $nd0_tr, $ng0_tr], 0);

    $self->GetParty    ([$ne_tr, $nm_tr, $nd_tr, $ng_tr],  1);
    $self->GetPartyInfo([$ne_tr, $nm_tr, $nd_tr, $ng_tr],  1);
    
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
    my $nodes = shift;
    my $party_type = shift;

    foreach my $node (@$nodes) {
        if (!$node) {next;}
    
        my @td_nodes    = $node->content_list;
    
        foreach my $td_node (@td_nodes) {
            if ($td_node !~ /HASH/) {next;}

            my $child_table_nodes = &GetNode::GetNode_Tag("table", \$td_node);
            if (!scalar(@$child_table_nodes)) {next;}
    
            my $child_td_nodes = &GetNode::GetNode_Tag_Attr("td", "nowrap", "NOWRAP", \$$child_table_nodes[0]);
            if (!scalar(@$child_td_nodes)) {next;}
            
            my $party_all_link_nodes = &GetNode::GetNode_Tag("a", \$$child_table_nodes[0]);
            if (!$self->isExecEnoInParty($party_all_link_nodes)) {next;}
    
            my $link_nodes = &GetNode::GetNode_Tag("a", \$$child_td_nodes[0]);
    
            my $party = &GetIbaraNode::GetENoFromLink($$link_nodes[0]);
    
            $self->{Datas}{Party}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $party_type, $party) ));
            
            $self->{CommonDatas}{Party}{$self->{ENo}} = $party;

            return 1; #いずれかの戦闘でPT情報が取得できれば終了
        }
    }

    return 0;
}

#-----------------------------------#
#    パーティ内で最も若いENoの時、そのEnoをパーティ番号としてパーティ情報を取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub GetPartyInfo{
    my $self = shift;
    my $nodes = shift;
    my $party_type = shift;

    foreach my $node (@$nodes) {
        if (!$node) {next;}
    
        my @td_nodes    = $node->content_list;
    
        foreach my $td_node (@td_nodes) {
            if ($td_node !~ /HASH/) {next;}

            my $child_table_nodes = &GetNode::GetNode_Tag("table", \$td_node);
            if (!scalar(@$child_table_nodes)) {next;}
    
            my $child_td_nodes = &GetNode::GetNode_Tag_Attr("td", "nowrap", "NOWRAP", \$$child_table_nodes[0]);
            if (!scalar(@$child_td_nodes)) {next;}
    
            my $child_link_nodes = &GetNode::GetNode_Tag("a", \$$child_td_nodes[0]);
   
            if ($self->{ENo} != &GetIbaraNode::GetENoFromLink($$child_link_nodes[0]) ) { next;} # 戦闘ENoの判定
    
            # パーティ情報の取得
            my ($name, $member_num) = (0, 0);
    
            my $b_nodes = &GetNode::GetNode_Tag("b", \$td_node);
            my $party_all_link_nodes = &GetNode::GetNode_Tag("a", \$$child_table_nodes[0]);
    
            $name = $$b_nodes[0]->as_text;
            $member_num = int( scalar(@$party_all_link_nodes)/2 );
    
            $self->{Datas}{PartyInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $party_type, $name, $member_num) ));
            
            return 1; #いずれかの戦闘でPT情報が取得できれば終了
        }
    }

    return 0;
}

#-----------------------------------#
#    パーティ内で最も若いENoの時、そのEnoをパーティ番号としてパーティ情報を取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          パーティタイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub isExecEnoInParty{
    my $self = shift;
    my $nodes = shift;

    foreach my $node (@$nodes) {
        if ($self->{ENo} == &GetIbaraNode::GetENoFromLink($node) ) { return 1;} # 戦闘ENoの判定
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
