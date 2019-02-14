#===================================================================
#        固有名詞記録パッケージ
#        　・固有名詞に識別番号を割り振り記録する。
#        　・固有名詞を聞いて番号を返す用のデータをMappingDataに保存
#        　・ファイル記録・DB登録用のデータをDataに保存
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package StoreProperName;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
    my $class      = shift;
    my $result_no  = shift;
    
    bless {
          Datas     => {},
          DataNum   => 0,
    }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self        = shift;
    my $header_list = shift;
    my $output_file = shift;
    my $id0_name    = shift;
    
    my $name_data    = StoreData->new();
    my $mapping_data = StoreHashData->new();
    $self->{Datas}{Data}        = $name_data;
    $self->{Datas}{MappingData} = $mapping_data;

    $self->{Datas}{Data} -> Init($header_list);
    $self->{Datas}{Data} -> SetOutputName($output_file);
    
    $self->ReadLastData($output_file, $id0_name);
    
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    my $file_name = shift;
    my $id0_name = shift;
    
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);
        
        $self->{Datas}{MappingData} -> AddData( $$data[1], $$data[0]);
        $self->{Datas}{Data}        -> AddData( join(ConstData::SPLIT, @$data) );
        $self->{DataNum}++;
    }

    if(!$self->{DataNum}){
        $self->_SetData(0, $id0_name);
        $self->{DataNum}++;
    }
    return;
}

#-----------------------------------#
#    　識別番号を指定して固有名詞を記録
#------------------------------------
#    引数：固有名詞
#    返り値：識別番号
#-----------------------------------#
sub SetId{
    my $self = shift;
    my $id   = shift;
    my $name = shift;
    
    if(!$self->{Datas}{MappingData}->CheckHaveData($name)){
        $self->_SetData($id, $name);
    }
    
    return;
}

#-----------------------------------#
#    　識別番号を取得し、ない場合は新たに番号を割り振る
#------------------------------------
#    引数：固有名詞
#    返り値：識別番号
#-----------------------------------#
sub GetOrAddId{
    my $self = shift;
    my $name = shift;

    if($name eq "") {return 0;}
    
    if(!$self->{Datas}{MappingData}->CheckHaveData($name)){
        # 新しい固有名詞を記録
        my $id = $self->{DataNum}; 
        $self->{DataNum}++;
        $self->_SetData($id, $name);
        
        return $id;
    }
    
    return $self->{Datas}{MappingData}->GetData($name);
}

#-----------------------------------#
#    　識別番号取得
#------------------------------------
#    引数：固有名詞
#    返り値：識別番号
#-----------------------------------#
sub GetId{
    my $self = shift;
    my $name = shift;
    
    if(!$self->{Datas}{MappingData}->CheckHaveData($name)){
        return 0;
    }
    
    return $self->{Datas}{MappingData}->GetData($name);
}
#-----------------------------------#
#    全識別番号の取得
#-----------------------------------#
#    引数｜
#-----------------------------------#
sub GetAllId {
    my $self          = shift;
    my $return_data   = [];
    my $mapping_datas = "";

    $mapping_datas = $self->{Datas}{MappingData}->GetAllData();
    foreach my $name(keys(%$mapping_datas)){
        push(@$return_data, $$mapping_datas{$name});
    }

    return $return_data;
}


#-----------------------------------#
#    固有名詞と識別番号の対応を記録
#-----------------------------------#
#    引数｜識別番号
#          固有名詞
#-----------------------------------#
sub _SetData {
    my $self = shift;
    my $id   = shift;
    my $name = shift;

    $self->{Datas}{MappingData}   ->AddData( $name, $id);
    $self->{Datas}{Data} ->AddData( join(ConstData::SPLIT, ($id, $name) ) );

    return;    
}

#-----------------------------------#
#    　出力
#------------------------------------
#    引数：
#-----------------------------------#
sub Output {
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
