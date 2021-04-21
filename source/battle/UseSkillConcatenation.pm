#===================================================================
#        発動スキル解析パッケージ
#-------------------------------------------------------------------
#            (C) 2021 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";

require "./source/battle/Damage.pm";
require "./source/new/NewAction.pm";

use ConstData;        #定数呼び出し
use source::lib::GetNode;
use source::lib::GetIbaraNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package UseSkillConcatenation;

# 定数宣言    ---------------#   

use constant CONCATENATION_ALL => 0;
use constant CONCATENATION_ACTOR => 1;
use constant TIMING_ALL   => 0;
use constant TIMING_START => 1;

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
    $self->{Datas}{UseSkill} = StoreData->new();

    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_id",
                "concatenation_type",
                "timing_type",
                "e_no",
                "skill_concatenation",
    ];
    $self->{Datas}{UseSkill}->Init($header_list);
 
    #出力ファイル設定
    $self->{Datas}{UseSkill}->SetOutputName( "./output/battle/use_skill_concatenation_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->{UseSkill} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{UseSkillConcatenation::TIMING_ALL} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{UseSkillConcatenation::TIMING_START} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{UseSkillConcatenation::TIMING_ALL} = {};
    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{UseSkillConcatenation::TIMING_START} = {};

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜ターン数,e_no,スキル名
#-----------------------------------#
sub AddUseSkill{
    my $self      = shift;
    my $battle_id = shift;
    my $turn      = shift;
    my $e_no      = shift;
    my $name      = shift;

    my $is_start = ($turn == 0) ? 1 : 0;

    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{UseSkillConcatenation::TIMING_ALL}{$battle_id}{$name} += 1; # 戦闘別全発動スキル
    if ($is_start) {
        $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{UseSkillConcatenation::TIMING_START}{$battle_id}{$name} += 1; # 戦闘別戦闘開始時発動スキル
    }

    if ($e_no == 0) {return}

    $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{UseSkillConcatenation::TIMING_ALL}{$battle_id}{$e_no}{$name} += 1; # キャラ別全発動スキル
    if ($is_start) {
        $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{UseSkillConcatenation::TIMING_START}{$battle_id}{$e_no}{$name} += 1; # キャラ別戦闘開始時発動スキル
    }
    
    return;
}

#-----------------------------------#
#    戦闘開始時・行動番号をリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    $self->{BattleId} = shift;

}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;

    foreach my $timing_type (sort { $a <=> $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}}) {
        foreach my $battle_id (sort { $a <=> $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{$timing_type}}){
            my $skill_concatenation = ",";
            foreach my $name (sort { $a cmp $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{$timing_type}{$battle_id}}){
                my $use_count = $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ALL}{$timing_type}{$battle_id}{$name};
                $skill_concatenation .= "$name".",:"."$use_count,";
            }
            $self->{Datas}{UseSkill}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $battle_id, UseSkillConcatenation::CONCATENATION_ALL, $timing_type, 0, $skill_concatenation) ));
        }
    }

    foreach my $timing_type (sort { $a <=> $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}}) {
        foreach my $battle_id (sort { $a <=> $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{$timing_type}}){
            foreach my $e_no (sort { $a <=> $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{$timing_type}{$battle_id}}){
                my $skill_concatenation = ",";
                foreach my $name (sort { $a cmp $b } keys %{$self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{$timing_type}{$battle_id}{$e_no}}){
                    my $use_count = $self->{UseSkill}{UseSkillConcatenation::CONCATENATION_ACTOR}{$timing_type}{$battle_id}{$e_no}{$name};
                    $skill_concatenation .= "$name".",:"."$use_count,";
                }
                $self->{Datas}{UseSkill}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $battle_id, UseSkillConcatenation::CONCATENATION_ACTOR, $timing_type, $e_no, $skill_concatenation) ));
            }
        }
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
