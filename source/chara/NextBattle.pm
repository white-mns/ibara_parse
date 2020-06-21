#===================================================================
#        戦闘予告取得パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";

require "./source/new/NewNextEnemy.pm";

use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package NextBattle;

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
    $self->{Datas}{NextBattleEnemy} = StoreData->new();
    $self->{Datas}{NextBattleInfo}  = StoreData->new();
    $self->{Datas}{NextDuelInfo}    = StoreData->new();
    $self->{Datas}{New}   = NewNextEnemy->new();
    
    $self->{Datas}{New}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "battle_type",
                "enemy_id",
    ];

    $self->{Datas}{NextBattleEnemy}->Init($header_list);
 
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "battle_type",
                "enemy_party_name_id",
                "member_num",
    ];

    $self->{Datas}{NextBattleInfo}->Init($header_list);
  
    $header_list = [
                "result_no",
                "generate_no",
                "left_party_no",
                "right_party_no",
                "battle_type",
    ];

    $self->{Datas}{NextDuelInfo}->Init($header_list);
   
  
    #出力ファイル設定
    $self->{Datas}{NextBattleEnemy}->SetOutputName( "./output/chara/next_battle_enemy_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{NextBattleInfo}->SetOutputName ( "./output/chara/next_battle_info_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{NextDuelInfo}->SetOutputName   ( "./output/chara/next_duel_info_"    . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
    my $nodes = shift;
    
    $self->{ENo} = $e_no;
    
    my $ne_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ne");
    my $nm_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nm");
    my $nd_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "nd");
    my $ng_tr  = &GetIbaraNode::SearchMatchingTrNodeFromTitleImg($nodes, "ng");

    if (!$self->CheckPartyHead($ne_tr) && !$self->CheckPartyHead($nm_tr) && !$self->CheckPartyHead($nd_tr) && !$self->CheckPartyHead($ng_tr)) { return;}
    
    $self->{PNo} = $e_no;

    $self->GetNextBattleEnemy($ne_tr,  0);
    $self->GetNextBattleInfo ($ne_tr,  0);
    
    $self->GetNextBattleEnemy($nm_tr,  1);
    $self->GetNextBattleInfo ($nm_tr,  1);
    
    if ($self->CheckPartyHead($nd_tr)) {
        $self->GetNextDuelInfo ($nd_tr,  10);
    }

    if ($self->CheckPartyHead($ng_tr)) {
        $self->GetNextDuelInfo ($ng_tr,  11);
    }


    return;
}

#-----------------------------------#
#    パーティ内で最も若いENoをパーティ番号として戦闘予告取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          戦闘タイプ 
#            0:『遭遇戦』『採集』
#            1:『開放戦』『特殊戦』
#-----------------------------------#
sub GetNextBattleEnemy{
    my $self = shift;
    my $node = shift;
    my $battle_type = shift;
    my $enemy_id = 0;

    if (!$node) {return;}

    my @td_nodes    = $node->content_list;

    my $child_table_nodes = &GetNode::GetNode_Tag("table", \$td_nodes[2]);
    if (!scalar(@$child_table_nodes)) {return;}

    my $b_nodes = &GetNode::GetNode_Tag("b", \$$child_table_nodes[0]);

    foreach my $b_node (@$b_nodes) {
        my $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($b_node->as_text);

        $self->{Datas}{NextBattleEnemy}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $battle_type, $enemy_id) ));
    
        $self->{Datas}{New}->RecordNewNextEnemyData($enemy_id);
    }

    return;
}

#-----------------------------------#
#    パーティ内で最も若いENoの時、そのEnoをパーティ番号としてパーティ情報を取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          戦闘タイプ 
#            0:今回戦闘
#            1:次回予告
#-----------------------------------#
sub GetNextBattleInfo{
    my $self = shift;
    my $node = shift;
    my $battle_type = shift;

    if (!$node) {return;}

    my @td_nodes    = $node->content_list;

    # パーティ情報の取得
    my ($name_id, $member_num) = (0, 0);

    my $b_nodes = &GetNode::GetNode_Tag("b", \$td_nodes[2]);
    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$td_nodes[2]);

    $name_id = $self->{CommonDatas}{ProperName}->GetOrAddId($$b_nodes[0]->as_text);
    $member_num = int( scalar(@$tr_nodes) );

    $self->{Datas}{NextBattleInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $battle_type, $name_id, $member_num) ));

    return;
}

#-----------------------------------#
#    左側で最も若いENoの時、対人戦情報を取得
#------------------------------------
#    引数｜対戦組み合わせデータノード
#          戦闘タイプ 
#            10:決闘
#            11:練習試合
#-----------------------------------#
sub GetNextDuelInfo{
    my $self = shift;
    my $node = shift;
    my $battle_type = shift;

    if (!$node) {return;}

    my @td_nodes    = $node->content_list;

    my $left_link_nodes = &GetNode::GetNode_Tag("a", \$td_nodes[0]);
    my $right_link_nodes = &GetNode::GetNode_Tag("a", \$td_nodes[2]);

    if (!scalar(@$left_link_nodes) || !scalar(@$right_link_nodes)) {return;}

    my $left_party_no  = &GetIbaraNode::GetENoFromLink($$left_link_nodes[0]);
    my $right_party_no = &GetIbaraNode::GetENoFromLink($$right_link_nodes[0]);

    $self->{Datas}{NextDuelInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $left_party_no, $right_party_no, $battle_type) ));

    return;
}


#-----------------------------------#
#    パーティ内で最も若いENoの時に正を返す
#------------------------------------
#    引数｜対戦組み合わせデータノード
#-----------------------------------#
sub CheckPartyHead{
    my $self = shift;
    my $node = shift;

    if (!$node) {return 0;}

    my @td_nodes    = $node->content_list;

    my $link_nodes = &GetNode::GetNode_Tag("a", \$td_nodes[0]);

    # 先頭ENoの判定
    if ($self->{ENo} == &GetIbaraNode::GetENoFromLink($$link_nodes[0]) ) { return 1;}

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
