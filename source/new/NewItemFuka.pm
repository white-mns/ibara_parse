#===================================================================
#        新出アイテム情報取得パッケージ
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
package NewItemFuka;

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
    $self->{Datas}{NewItemFuka} = StoreData->new();
    $self->{Datas}{AllItemFuka} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "fuka_id",
    ];

    $self->{Datas}{NewItemFuka}->Init($header_list);
    $self->{Datas}{AllItemFuka}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{NewItemFuka}->SetOutputName( "./output/new/item_fuka_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllItemFuka}->SetOutputName( "./output/new/all_item_fuka_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/new/all_item_fuka_" . sprintf("%02d", ($self->{ResultNo} - 1)) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_item_use_datas = []; 
        @$new_item_use_datas   = split(ConstData::SPLIT, $data_set);
        my $fuka_id = $$new_item_use_datas[2];
        if(!exists($self->{AllItemFuka}{$fuka_id})){
            $self->{AllItemFuka}{$fuka_id} = [$self->{ResultNo}, $self->{GenerateNo}, $fuka_id];
        }
    }

    return;
}

#-----------------------------------#
#    新出アイテム付加の判定と記録
#------------------------------------
#    引数｜固有名詞ID
#-----------------------------------#
sub RecordNewItemFukaData{
    my $self    = shift;
    my $fuka_id = shift;

    if (exists($self->{AllItemFuka}{$fuka_id})) {return;}

    $self->{Datas}{NewItemFuka}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $fuka_id) ));

    $self->{AllItemFuka}{$fuka_id} = [$self->{ResultNo}, $self->{GenerateNo}, $fuka_id];

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
    foreach my $id (sort{$a cmp $b} keys %{ $self->{AllItemFuka} } ) {
        $self->{Datas}{AllItemFuka}->AddData(join(ConstData::SPLIT, @{ $self->{AllItemFuka}{$id} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
