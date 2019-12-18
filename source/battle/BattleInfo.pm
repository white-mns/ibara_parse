#===================================================================
#        戦闘情報パッケージ
#        　・全戦闘結果をIDで管理する
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
package BattleInfo;

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
    $self->{Datas}{BattleInfo} = StoreData->new();
    $self->{Datas}{DuelInfo}   = StoreData->new();
    $self->{BattleId} = -1;
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "battle_page",
                "battle_type",
    ];
    $self->{Datas}{BattleInfo}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "left_party_no",
                "right_party_no",
    ];

    $self->{Datas}{DuelInfo}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{BattleInfo}->SetOutputName ( "./output/battle/info_"      . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{DuelInfo}->SetOutputName   ( "./output/battle/duel_info_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetBattleId{
    my $self            = shift;
    $self->{BattlePage} = shift;
    $self->{PNo}        = shift;
    $self->{BattleNo}   = shift;
    my $node            = shift;

    $self->{BattleId} += 1;

    $self->GetBattleInfo($node);
    $self->GetDuelInfo($node);
    
    return $self->{BattleId};
}

#-----------------------------------#
#    戦闘種別を解析
#------------------------------------
#    引数｜戦闘開始時ノード 
#            0:『遭遇戦』『採集』 
#            1:『開放戦』『特殊戦』
#            10:『決闘』
#            11:『練習戦』
#            20:闘技大会
#-----------------------------------#
sub GetBattleInfo{
    my $self = shift;
    my $turn_node = shift;

    my $battle_type = -1;

    if (!$turn_node) {return;}

    my $img_nodes = &GetNode::GetNode_Tag("img", \$turn_node);

    if (!scalar(@$img_nodes)) {return;}

    my $src = $$img_nodes[0]->attr("src");

    if   ($src =~ /ne0/) {$battle_type = 0;}
    elsif($src =~ /nm0/) {$battle_type = 1;}
    elsif($src =~ /nd0/) {$battle_type = 10;}
    elsif($src =~ /ng0/) {$battle_type = 11;}

    $self->{Datas}{BattleInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{BattlePage}, $battle_type) ));

    return;
}

#-----------------------------------#
#    対人戦情報を解析
#------------------------------------
#    引数｜戦闘開始時ノード 
#-----------------------------------#
sub GetDuelInfo{
    my $self = shift;
    my $turn_node = shift;

    if (!$turn_node) {return;}

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$turn_node);
    my @td_nodes    = $$tr_nodes[0]->content_list;

    my $left_link_nodes = &GetNode::GetNode_Tag("a", \$td_nodes[0]);
    my $right_link_nodes = &GetNode::GetNode_Tag("a", \$td_nodes[2]);

    if (!scalar(@$left_link_nodes) || !scalar(@$right_link_nodes)) {return;}

    my $left_party_no  = &GetIbaraNode::GetENoFromLink($$left_link_nodes[0]);
    my $right_party_no = &GetIbaraNode::GetENoFromLink($$right_link_nodes[0]);

    $self->{Datas}{DuelInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $left_party_no, $right_party_no) ));

    return;
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
