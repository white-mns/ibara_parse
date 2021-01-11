#===================================================================
#        研究取得パッケージ
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
package OneTimeStudy;

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
    $self->{Datas}{OneTimeStudy} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "skill_id",
                "depth",
    ];

    $self->{Datas}{OneTimeStudy}->Init($header_list);

    
    #出力ファイル設定
    $self->{Datas}{OneTimeStudy}->SetOutputName( "./output/chara/one_time_study_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/chara/one_time_study_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }
   
    return 0;
}



#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,ブロックdivノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $div_r870_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $action_div_node = &GetIbaraNode::SearchDivNodeFromTitleImg($div_r870_nodes, "action");
    
    if (!$action_div_node) { return;}

    $self->GetOneTimeStudyData($action_div_node);
    
    return;
}

#-----------------------------------#
#    研究結果ノード取得
#------------------------------------
#    引数｜準備divノード
#-----------------------------------#
sub GetOneTimeStudyData{
    my $self = shift;
    my $action_div_node = shift;

    my %studies = ();

    my @child_nodes = $action_div_node->content_list;

    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /を研究しました！/) {
            my $study_name = $child_node->as_text;

            $study_name =~ s/\s//;
            my $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(0, [$study_name, -1, -1, -1, -1, 0, ""]);
            $studies{$skill_id} += 1;
        }
    }

    foreach my $skill_id (sort{$a cmp $b} keys(%studies)) {
        $self->{Datas}{OneTimeStudy}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $skill_id, $studies{$skill_id})));
    }

    return;
}

#-----------------------------------#
#    研究データ取得
#------------------------------------
#    引数｜研究アイテム名ノード
#-----------------------------------#
sub GetOneTimeStudy{
    my $self = shift;
    my $one_time_study_node = shift;

    my ($i_no, $name, $recovery) = (0, "", 0);
    my $effects = [{"id"=> 0, "value"=> 0},{"id"=> 0, "value"=> 0},{"id"=> 0, "value"=> 0}];

    if ($one_time_study_node->as_text =~ /ItemNo\.(\d+) (.+)/){
        $i_no = $1;
        $name = $2;
    }
    my @mea_data_nodes = $one_time_study_node->right;

    foreach my $node (@mea_data_nodes) {
        if ($node !~ /HASH/) {next;}

        my $right_node = $node->right;
        my $text = $node->as_text;

        if ($right_node =~ /回復！（/) {
            $recovery =  $text;

        } elsif ($right_node =~ /が発揮されます。/){
            my @effect_texts = split(/ /, $text);
            shift(@effect_texts);
            my $i = 0;

            foreach my $effect_text (@effect_texts) {
                if ($effect_text =~ /(\D+)(\d+)/) {
                    $$effects[$i]{"id"} = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                    $$effects[$i]{"value"} = $2;
                } else {
                }

                $i += 1;
            }
        }

    }

    $self->{Datas}{OneTimeStudy}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $i_no, $name, $recovery,
                                                              $$effects[0]{"id"}, $$effects[0]{"value"},
                                                              $$effects[1]{"id"}, $$effects[1]{"value"},
                                                              $$effects[2]{"id"}, $$effects[2]{"value"})));
    
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
