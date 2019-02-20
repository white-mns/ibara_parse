#===================================================================
#        スキル習得条件取得パッケージ
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
package SkillMastery;

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

    $self->{SkillMastery} = {};

    my $header_list = "";
   
    $header_list = [
                "skill_id",
                "requirement_1_id",
                "requirement_1_lv",
                "requirement_2_id",
                "requirement_2_lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/data/skill_mastery.csv" );

    $self->ReadLastData( "./output/data/skill_mastery.csv" );

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData{
    my $self      = shift;
    my $file_name = shift;
    my $id0_name = shift;
    
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);
        
        $self->{SkillMastery}{$$data[0]} = {"requirement_1_id" => $$data[1], "requirement_1_lv" => $$data[2], "requirement_2_id" => $$data[3], "requirement_2_lv" =>$$data[4]};
    }
    
    return;
}


#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,divY870ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_node = shift;
    
    $self->ParseTrData($table_node);
    
    return;
}

#-----------------------------------#
#    tableノード解析・取得
#------------------------------------
#    引数｜スキルテーブルノード
#-----------------------------------#
sub ParseTrData{
    my $self  = shift;
    my $table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_node);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($skill_id, $skill_name, $type_id, $element_id, $timing_id, $text) = (0, "", 0, 0, 0, "");

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);

        $skill_name = $$td_nodes[1]->as_text;

        my $td1_class = $$td_nodes[1]->attr("class");
        if ($td1_class && $td1_class =~ /Z(\d)/) {
            $element_id = $1;
        }

        $text = $$td_nodes[4]->as_text;
        if ($text =~ s/(【.+】)//) {
            $type_id   = 1;
            $timing_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        }

        my $ep = ($$td_nodes[2]->as_text ne " ") ? $$td_nodes[2]->as_text : 0;
        my $sp = ($$td_nodes[3]->as_text ne " ") ? $$td_nodes[3]->as_text : 0;

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(1, [$skill_name, $type_id, $element_id, $ep, $sp, $timing_id, $text]);
        
        my ($requirement_1_id, $requirement_1_lv, $requirement_2_id, $requirement_2_lv) = (0, 0, 0, 0);

        if ($$td_nodes[0]->as_text =~ /(\D+)(\d+)(\D+)(\d+)/) {
            $requirement_1_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $requirement_1_lv = $2;
            $requirement_2_id = $self->{CommonDatas}{ProperName}->GetOrAddId($3);
            $requirement_2_lv = $4;

        } elsif ($$td_nodes[0]->as_text =~ /(\D+)(\d+)/) {
            $requirement_1_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $requirement_1_lv = $2;
        }

        $self->{SkillMastery}{sprintf("%05d",$skill_id)} = {"requirement_1_id" => $requirement_1_id, "requirement_1_lv" => $requirement_1_lv, "requirement_2_id" => $requirement_2_id, "requirement_2_lv" =>$requirement_2_lv}
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
    
    # スキル習得条件の書き出し
    foreach my $skill_id (sort{$a cmp $b} keys %{ $self->{SkillMastery} } ) {
        my $data = $self->{SkillMastery}{$skill_id};
        $self->{Datas}{Data}->AddData( join(ConstData::SPLIT, ($skill_id, $$data{"requirement_1_id"}, $$data{"requirement_1_lv"}, $$data{"requirement_2_id"}, $$data{"requirement_2_lv"})));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
