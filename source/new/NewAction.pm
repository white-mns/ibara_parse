#===================================================================
#        新出発動スキル・付加情報取得パッケージ
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
package NewAction;

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
    $self->{Datas}{NewAction} = StoreData->new();
    $self->{Datas}{AllAction} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "skill_id",
                "fuka_id",
    ];

    $self->{Datas}{NewAction}->Init($header_list);
    $self->{Datas}{AllAction}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{NewAction}->SetOutputName( "./output/new/action_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllAction}->SetOutputName( "./output/new/all_action_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastNewData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastNewData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/new/all_action_" . sprintf("%02d", ($self->{ResultNo} - 1)) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_item_use_datas = []; 
        @$new_item_use_datas   = split(ConstData::SPLIT, $data_set);
        my $skill_id = $$new_item_use_datas[2];
        my $fuka_id  = $$new_item_use_datas[3];
        my $key = $skill_id."_".$fuka_id;
        if(!exists($self->{AllAction}{$key})){
            $self->{AllAction}{$key} = [$self->{ResultNo}, $self->{GenerateNo}, $skill_id, $fuka_id];
        }
    }

    return;
}

#-----------------------------------#
#    新規発動スキル・付加の判定と記録
#------------------------------------
#    引数｜固有名詞ID（スキル管理ID、付加管理ID）
#-----------------------------------#
sub RecordNewActionData{
    my $self    = shift;
    my $skill_id = shift;
    my $fuka_id = shift;

    if (exists($self->{AllAction}{$skill_id."_".$fuka_id})) {return;}

    $self->{Datas}{NewAction}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $skill_id, $fuka_id) ));

    $self->{AllAction}{$skill_id."_".$fuka_id} = [$self->{ResultNo}, $self->{GenerateNo}, $skill_id, $fuka_id];

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
    foreach my $skillid_fukaid (sort{$a cmp $b} keys %{ $self->{AllAction} } ) {
        $self->{Datas}{AllAction}->AddData(join(ConstData::SPLIT, @{ $self->{AllAction}{$skillid_fukaid} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
