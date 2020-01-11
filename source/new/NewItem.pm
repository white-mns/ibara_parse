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
package NewItem;

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
    $self->{Datas}{NewItem} = StoreData->new();
    $self->{Datas}{AllItem} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "name",
    ];

    $self->{Datas}{NewItem}->Init($header_list);
    $self->{Datas}{AllItem}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{NewItem}->SetOutputName( "./output/new/item_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllItem}->SetOutputName( "./output/new/all_item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/new/all_item_" . sprintf("%02d", ($self->{ResultNo} - 1)) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_item_use_datas = []; 
        @$new_item_use_datas   = split(ConstData::SPLIT, $data_set);
        my $item_name = $$new_item_use_datas[2];
        if(!exists($self->{AllItem}{$item_name})){
            $self->{AllItem}{$item_name} = [$self->{ResultNo}, $self->{GenerateNo}, $item_name];
        }
    }

    return;
}

#-----------------------------------#
#    新出アイテムの判定と記録
#------------------------------------
#    引数｜アイテム名
#-----------------------------------#
sub RecordNewItemData{
    my $self    = shift;
    my $item_name = shift;

    if (exists($self->{AllItem}{$item_name})) {return;}

    $self->{Datas}{NewItem}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $item_name) ));

    $self->{AllItem}{$item_name} = [$self->{ResultNo}, $self->{GenerateNo}, $item_name];

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
    foreach my $id (sort{$a cmp $b} keys %{ $self->{AllItem} } ) {
        $self->{Datas}{AllItem}->AddData(join(ConstData::SPLIT, @{ $self->{AllItem}{$id} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
