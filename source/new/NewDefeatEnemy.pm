#===================================================================
#        NPC初突破取得パッケージ
#-------------------------------------------------------------------
#            (C) 2020 @white_mns
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
package NewDefeatEnemy;

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
    ($self->{BeforeResultNo}, $self->{BeforeGenerateNo}) = ($self->{ResultNo} - 1, 0);
    $self->{AllDefeatIDPnoMemNum} = {};
    
    #初期化
    $self->{Datas}{NewDefeatEnemy} = StoreData->new();
    $self->{Datas}{AllDefeatEnemy} = StoreData->new();
    $self->{Datas}{BeforeDefeatEnemy} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "before_result_no",
                "before_generate_no",
                "party_no",
                "enemy_id",
                "member_num",
                "is_boss",
    ];

    $self->{Datas}{NewDefeatEnemy}->Init($header_list);
    $self->{Datas}{AllDefeatEnemy}->Init($header_list);
    $self->{Datas}{BeforeDefeatEnemy}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{NewDefeatEnemy}->SetOutputName( "./output/new/defeat_enemy_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllDefeatEnemy}->SetOutputName( "./output/new/all_defeat_enemy_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastNewData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastNewData(){
    my $self      = shift;
    
    my $file_name = "";
    $file_name = "./output/new/all_defeat_enemy_" . ($self->{ResultNo} - 1) . "_0.csv" ;
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_defeat_enemy_datas = [];
        @$new_defeat_enemy_datas   = split(ConstData::SPLIT, $data_set);
        my $key = $$new_defeat_enemy_datas[2];
        if(!exists($self->{AllDefeatEnemy}{$key})){
            $self->{AllDefeatEnemy}{$key}    = [$self->{ResultNo}, $self->{GenerateNo}, $key];
            $self->{BeforeDefeatEnemy}{$key} = [$self->{ResultNo}, $self->{GenerateNo}, $key];
        }
    }

    return;
}

#-----------------------------------#
#    NPC初突破の判定と記録
#------------------------------------
#    引数｜固有名詞ID
#-----------------------------------#
sub RecordNewDefeatEnemyData{
    my $self    = shift;
    my $enemy_id = shift;
    my $member_num  = shift;
    my $is_boss = shift;
    my $party_no  = shift;

    my $key = $enemy_id . "_" . $member_num;
    my $party_key = $enemy_id . "_" . $party_no . "_" . $member_num;

    if (exists($self->{BeforeDefeatEnemy}{$key})) {return;}
    if (exists($self->{AllDefeatIDPnoMemNum}{$party_key})) {return;} # 戦闘中二体以上同じ敵がいたときに二体目以降を除外

    $self->{Datas}{NewDefeatEnemy}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BeforeResultNo}, $self->{BeforeGenerateNo}, $party_no, $enemy_id, $member_num, $is_boss) ));
    
    $self->{AllDefeatIDPnoMemNum}{$party_key} = 1;

    if (exists($self->{AllDefeatEnemy}{$key})) {return;}

    $self->{AllDefeatEnemy}{$key} = [$self->{ResultNo}, $self->{GenerateNo}, $key];

    return;
}
#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;

    # 新出データ判定用の既出情報の書き出し
    foreach my $key (sort{$a cmp $b} keys %{ $self->{AllDefeatEnemy} } ) {
        $self->{Datas}{AllDefeatEnemy}->AddData(join(ConstData::SPLIT, @{ $self->{AllDefeatEnemy}{$key} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
