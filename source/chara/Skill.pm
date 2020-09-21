#===================================================================
#        所持スキル情報取得パッケージ
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
package Skill;

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
    $self->{CommonDatas}{Passive} = {};
    
    #初期化
    $self->{Datas}{Skill} = StoreData->new();
    $self->{Datas}{SkillConcatenate} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "name",
                "skill_id",
                "lv",
    ];

    $self->{Datas}{Skill}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "skill_concatenate",
    ];

    $self->{Datas}{SkillConcatenate}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Skill}->SetOutputName           ( "./output/chara/skill_"             . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{SkillConcatenate}->SetOutputName( "./output/chara/skill_concatenate_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadLastData();
    $self->ReadOutputedData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/chara/skill_" . sprintf("%02d", ($self->{ResultNo} - 1)) . "_" . $i . ".csv" ;

        if(-f $file_name) {last;}
    }

    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $skill_datas = []; 
        @$skill_datas   = split(ConstData::SPLIT, $data_set);

        my $e_no       = $$skill_datas[2];
        my $skill_name = $$skill_datas[3];
        my $skill_id   = $$skill_datas[4];

        $self->{CommonDatas}{Skill}{$e_no}{$skill_name} = $skill_id;
    }

    return;
}

#-----------------------------------#
#    既に出力した同じ更新回のデータを読み込む
#    ・その更新でスキル名を変更した場合、解析一周では料理・付加の依頼者側から見て正しいスキル名を取得できないパターンがあるため
#-----------------------------------#
sub ReadOutputedData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/chara/skill_" . sprintf("%02d", $self->{ResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {last;}
    }

    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $skill_datas = []; 
        @$skill_datas   = split(ConstData::SPLIT, $data_set);

        my $e_no       = $$skill_datas[2];
        my $skill_name = $$skill_datas[3];
        my $skill_id   = $$skill_datas[4];

        $self->{CommonDatas}{Skill}{$e_no}{$skill_name} = $skill_id;
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
    my $e_no    = shift;
    my $div_y870_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $div_skill_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_skill");

    $self->GetSkillData($div_skill_node);
    
    return;
}

#-----------------------------------#
#    所持スキルデータ取得
#------------------------------------
#    引数｜所持スキルデータノード
#-----------------------------------#
sub GetSkillData{
    my $self  = shift;
    my $div_node = shift;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$div_node);

    $self->{CommonDatas}{Passive}{$self->{ENo}} = {};
    $self->{SkillConcatenate} = ",";
 
    $self->ParseTrData($$table_nodes[1]);
    $self->ParseTrData($$table_nodes[2]);

    $self->{Datas}{SkillConcatenate}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SkillConcatenate})));

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

    my $skill_concatenate = ",";
 
    foreach my $tr_node (@$tr_nodes){
        my ($name, $skill_id, $lv) = ("", 0, 0);
        my ($skill_name, $type_id, $element_id, $timing_id, $text) = ("", 0, 0, 0, "");

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);

        my $td0_text = $$td_nodes[1]->as_text;
        my @td0_child = $$td_nodes[1]->content_list;

        if (scalar(@td0_child) > 1) {
            $name       = $td0_child[0];
            $skill_name = $td0_child[2]->as_text;
            $skill_name =~ s/（//g;
            $skill_name =~ s/）//g;

        } else {
            $name       = $$td_nodes[1]->as_text;
            $skill_name = $$td_nodes[1]->as_text;
        }

        my $td0_class = $$td_nodes[1]->attr("class");
        if ($td0_class && $td0_class =~ /Z(\d)/) {
            $element_id = $1;
        }

        $text = $$td_nodes[5]->as_text;
        if ($text =~ s/(【.+】)//) {
            $type_id   = 1;
            $timing_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$skill_name, $type_id, $element_id, $$td_nodes[3]->as_text, $$td_nodes[4]->as_text, $timing_id, $text]);
        $lv = $$td_nodes[2]->as_text;

        $self->{Datas}{Skill}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $skill_id, $lv)));

        $self->{SkillConcatenate} .= $skill_name.",";

        if ($type_id == 1) { # パッシブスキルの時、上位生産発動判定のためにスキル名とスキルidを共通変数に記録
            $self->{CommonDatas}{Skill}{$self->{ENo}}{$name} = $skill_id;
        }
    }

    return;
}

#-----------------------------------#
#    タイトル画像からノードを探索
#------------------------------------
#    引数｜divY870ノード
#-----------------------------------#
sub SearchNodeFromTitleImg{
    my $self  = shift;
    my $div_nodes = shift;
    my $title = shift;

    foreach my $div_node (@$div_nodes){
        # imgの抽出
        my $img_nodes = &GetNode::GetNode_Tag("img",\$div_node);
        if (scalar(@$img_nodes) > 0 && $$img_nodes[0]->attr("src") =~ /$title/) {
            return $div_node;
        }
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
