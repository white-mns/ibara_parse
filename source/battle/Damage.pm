#===================================================================
#        ダメージ解析パッケージ
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
package Damage;

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
    $self->{Datas}{Damage} = StoreData->new();
    $self->{Datas}{Target} = StoreData->new();
    $self->{Datas}{Buffer} = StoreData->new();

    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "damage_type",
                "element_id",
                "value",
    ];
    $self->{Datas}{Damage}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "target_type",
                "e_no",
                "enemy_id",
                "suffix_id",
    ];
    $self->{Datas}{Target}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "act_id",
                "act_sub_id",
                "buffer_type",
                "value",
    ];
    $self->{Datas}{Buffer}->Init($header_list);
  
    #出力ファイル設定
    $self->{Datas}{Damage}->SetOutputName( "./output/battle/damage_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Target}->SetOutputName( "./output/battle/target_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Buffer}->SetOutputName( "./output/battle/buffer_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    ダメージを解析
#    ダメージ種別
#      1:ダメージ
#      2:SPダメージ
#      3:HP回復
#      4:SP回復
#------------------------------------
#    引数｜ダメージノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseDamageNode{
    my $self          = shift;
    my $b_node        = shift;
    my $critical      = shift;
    $self->{ActId}    = shift;
    $self->{ActSubId} = shift;

    my ($target_type, $e_no, $enemy_id) = (-1, 0, 0);
    my $damage_type = -1;
    my $element_id  = 0;

    if (!$b_node || !$b_node->left || !$b_node->right) {return;}

    my $nickname = "";

    if ($b_node->left =~ /(.+)(に|が)/) {
        $nickname = $1;
    } elsif ($b_node->left =~ /(に|が)/) {
        #愛称の着色がある場合、一度親ノードを取得し、その子ノードとして愛称を取得する
        my $parent_node = $b_node->parent;
        my $nickname_nodes = &GetNode::GetNode_Tag("span", \$parent_node);

        if (!scalar(@$nickname_nodes)) {return;}

        $nickname = $$nickname_nodes[0]->as_text;
    }
    else {return;}

    $nickname =~ s/\s//g;
    $nickname =~ s/のSP//g;
    $nickname =~ s/のHP//g;

    if    ($b_node->right =~ /ダメージ！/ && $b_node->left =~ /SPに/) {$damage_type = 2;}
    elsif ($b_node->right =~ /ダメージ！/)                            {$damage_type = 1;}
    elsif ($b_node->right =~ /回復！/     && $b_node->left =~ /HPが/) {$damage_type = 3;}
    elsif ($b_node->right =~ /回復！/     && $b_node->left =~ /SPが/) {$damage_type = 4;}
    else                                {return;}

    $self->GetENoOrEnemyIdFromNickname($nickname, \$target_type, \$e_no, \$enemy_id);

    my $damage = $b_node->as_text;
 
    $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $damage_type, $element_id, $damage) ));
    $self->{Datas}{Target}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $target_type, $e_no, $enemy_id, 0) ));
    $self->{Datas}{Buffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $self->{CommonDatas}{ProperName}->GetOrAddId("Critical Hit"), $critical) ));
    
    $self->ParseProtectionNode($b_node);
    $self->ParseReflectionNode($b_node);

    return;
}

#-----------------------------------#
#    回避行動を解析
#    ダメージ種別
#      0:回避
#------------------------------------
#    引数｜回避テキストノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseDodgeNode{
    my $self          = shift;
    my $node          = shift;
    my $critical      = shift;
    $self->{ActId}    = shift;
    $self->{ActSubId} = shift;

    my ($target_type, $e_no, $enemy_id) = (-1, 0, 0);
    my $damage_type = 0;

    if (!$node) {return;}

    my $nickname = "";

    if ($node =~ /(.+)は攻撃を回避！$/)             { $nickname = $1;}
    elsif ($node =~ /HASH/ && $node->tag eq "b" && $node->as_text =~ /(.+)は攻撃を回避！$/) { $nickname = $1;}
    elsif ($node =~ /HASH/ && $node->tag eq "span" && $node->right =~ /は攻撃を回避！$/)  { $nickname = $node->as_text;}
    else                                            { return;}

    $nickname =~ s/^\s//g;

    $self->GetENoOrEnemyIdFromNickname($nickname, \$target_type, \$e_no, \$enemy_id);

    my $damage = -1;

    $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $damage_type, 0, $damage) ));
    $self->{Datas}{Target}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $target_type, $e_no, $enemy_id, 0) ));
    $self->{Datas}{Buffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $self->{CommonDatas}{ProperName}->GetOrAddId("Critical Hit"), $critical) ));

    return;
}

#-----------------------------------#
#    クリティカルを解析
#------------------------------------
#    引数｜クリティカルノード
#          行動番号
#          行動サブ番号
#-----------------------------------#
sub ParseCriticalNode{
    my $self          = shift;
    my $i_node        = shift;

    if (!$i_node) {return 0;}

    my $value = (() = $i_node->as_text =~ /Critical Hit!!/g);

    return $value;
}

#-----------------------------------#
#    守護を解析
#------------------------------------
#    引数｜ダメージノード
#-----------------------------------#
sub ParseProtectionNode{
    my $self          = shift;
    my $b_node        = shift;

    if (!$b_node) {return 0;}

    my @right_nodes = $b_node->right;

    if ($right_nodes[2] && $right_nodes[2] =~ /HASH/ &&  $right_nodes[2]->attr("class") && $right_nodes[2]->attr("class") =~ /BS\d/ && $right_nodes[2]->as_text =~ /（守護(\d+)減）/) {
        my $value = $1;
        $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, 5, 0, -1) ));
        $self->{Datas}{Buffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $self->{CommonDatas}{ProperName}->GetOrAddId("守護"), $value) ));
    }

    return;
}

#-----------------------------------#
#    反射を解析
#------------------------------------
#    引数｜ダメージノード
#-----------------------------------#
sub ParseReflectionNode{
    my $self          = shift;
    my $b_node        = shift;

    if (!$b_node) {return 0;}

    my @right_nodes = $b_node->right;

    if ($right_nodes[2] && $right_nodes[2] =~ /HASH/ && $right_nodes[2]->attr("class") && $right_nodes[2]->attr("class") =~ /BS\d/ && $right_nodes[2]->as_text =~ /（反射(\d+)減）/) {
        my $value = $1;
        $self->{Datas}{Buffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleId}, $self->{ActId}, $self->{ActSubId}, $self->{CommonDatas}{ProperName}->GetOrAddId("反射"), $value) ));
    }

    return;
}


#-----------------------------------#
#    対象のENoおよび敵番号を取得
#------------------------------------
#    引数｜愛称
#          対象種別
#            0:PC
#            1:NPC
#          ENo
#          敵ID
#-----------------------------------#
sub GetENoOrEnemyIdFromNickname{
    my $self = shift;
    my $nickname = shift;
    my $type = shift;
    my $e_no = shift;
    my $enemy_id = shift;

    if (exists($self->{NicknameToEno}{$nickname})) {
        $$e_no = $self->{NicknameToEno}{$nickname};
        $$type = 0;

    } else {
        $nickname =~ s/[A-Z]$//;
        if (exists($self->{NicknameToEnemyId}{$nickname})) {
            $$enemy_id = $self->{NicknameToEnemyId}{$nickname};
            $$type = 1;
        }
    }
}

#-----------------------------------#
#    戦闘参加者の愛称索引を設定
#------------------------------------
#    引数｜
#-----------------------------------#
sub SetNicknameIndex{
    my $self = shift;
    $self->{NicknameToEno}     = shift;
    $self->{NicknameToEnemyId} = shift;
}

#-----------------------------------#
#    戦闘開始時・行動番号をリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    $self->{BattleId} = shift;

    $self->{ActId} = 0;
    $self->{ActSubId} = 0;
    $self->{NicknameToEno}  = {};
    $self->{NicknameToEnemyId} = {};
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
