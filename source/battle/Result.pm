#===================================================================
#        戦闘勝敗解析パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";

require "./source/new/NewBattleEnemy.pm";

use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Result;

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
    $self->{Datas}{BattleResult}  = StoreData->new();
    $self->{Datas}{BattleEnemy}   = StoreData->new();
    $self->{Datas}{New}   = NewBattleEnemy->new();
    
    $self->{Datas}{New}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    
    my $header_list = "";
 
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "battle_type",
                "enemy_id",
    ];

    $self->{Datas}{BattleEnemy}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "last_result_no",
                "last_generate_no",
                "battle_type",
                "battle_id",
                "battle_result",
    ];

    $self->{Datas}{BattleResult}->Init($header_list);
   
    #出力ファイル設定
    $self->{Datas}{BattleEnemy}->SetOutputName  ( "./output/battle/enemy_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{BattleResult}->SetOutputName ( "./output/battle/result_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
        $file_name = "./output/battle/result_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }
   
    return 0;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜戦闘管理番号,PT番号,戦闘番号,戦闘開始時・Result表記divノード
#-----------------------------------#
sub GetData{
    my $self          = shift;
    $self->{BattleId} = shift;
    $self->{PNo}      = shift;
    $self->{BattleNo} = shift;
    my $nodes         = shift;
    
    $self->GetResultData($nodes);
    
    return;
}

#-----------------------------------#
#    戦闘開始時・Result表記に使われるdivノードを解析
#------------------------------------
#    引数｜Result表記ノード
#-----------------------------------#
sub GetResultData{
    my $self = shift;
    my $nodes = shift;
    my $result = -2;

    if (!$nodes) {return;}

    my $battle_type = $self->GetBattleType($$nodes[0]);
    $self->GetBattleEnemy($$nodes[0], $battle_type);

    my @reversed_nodes = reverse(@$nodes);

    my $draw_nodes = &GetNode::GetNode_Tag_Attr("b", "class", "Y7i", \$reversed_nodes[0]);
    my $win_nodes  = &GetNode::GetNode_Tag_Attr("b", "class", "O7i", \$reversed_nodes[0]);
    my $lose_nodes = &GetNode::GetNode_Tag_Attr("b", "class", "R7i", \$reversed_nodes[0]);

    if    (scalar(@$win_nodes) > 0)  { $result =  1;}
    elsif (scalar(@$lose_nodes) > 0) { $result = -1;}
    elsif (scalar(@$draw_nodes) > 0) { $result =  0;}

    $self->{Datas}{BattleResult}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $battle_type, $self->{BattleId}, $result) ));

    return;
}

#-----------------------------------#
#    戦闘種別を解析
#------------------------------------
#    引数｜戦闘開始時ノード 
#            0:『遭遇戦』『採集』 
#            1:『開放戦』『特殊戦』
#            10:『決闘』
#            11:『練習戦』
#-----------------------------------#
sub GetBattleType{
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

    return $battle_type;
}

#-----------------------------------#
#    出現NPCを取得
#------------------------------------
#    引数｜戦闘開始データノード
#          戦闘タイプ 
#            0:『遭遇戦』『採集』
#            1:『開放戦』『特殊戦』
#-----------------------------------#
sub GetBattleEnemy{
    my $self = shift;
    my $node = shift;
    my $battle_type = shift;
    my $enemy_id = 0;

    if (!$node) {return;}

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$node);
    my @td_nodes    = $$tr_nodes[0]->content_list;

    my $child_table_nodes = &GetNode::GetNode_Tag("table", \$td_nodes[2]);
    if (!scalar(@$child_table_nodes)) {return;}

    my $a_nodes = &GetNode::GetNode_Tag("a", \$$child_table_nodes[0]);
    
    if(scalar(@$a_nodes) > 0) {return;} # 対人戦は除外

    my $b_nodes = &GetNode::GetNode_Tag("b", \$$child_table_nodes[0]);

    foreach my $b_node (@$b_nodes) {
        my $enemy_text = $b_node->as_text;
        $enemy_text =~ s/[A-Z]$//;
        my $enemy_id = $self->{CommonDatas}{ProperName}->GetOrAddId($enemy_text);

        $self->{Datas}{BattleEnemy}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PNo}, $battle_type, $enemy_id) ));
        
        $self->{Datas}{New}->RecordNewBattleEnemyData($enemy_id);
    }

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
