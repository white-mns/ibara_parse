#===================================================================
#        固有情報記録パッケージ
#        　・固有名詞に識別番号を割り振り記録する。
#        　・固有名詞とデータの紐づけをDataMappingに保存
#        　・固有名詞とIDの紐づけをNameMappingに保存(固有名詞名からIDを求めるため)
#        　・ファイル記録・DB登録用のデータを出力直前にDataMappingからDataに書き出し
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
package StoreProperData;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
    my $class      = shift;
    my $result_no  = shift;
    
    bless {
          Datas   => {},
          DataNum => 0,
    }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self        = shift;
    my $header_list = shift;
    my $output_file = shift;
    my $id0_data    = shift;
    
    $self->{Datas}{Data}        = StoreData->new();
    $self->{Datas}{DataMapping} = StoreHashData->new();
    $self->{Datas}{NameMapping} = StoreHashData->new();

    $self->{Datas}{Data} -> Init($header_list);
    $self->{Datas}{Data} -> SetOutputName($output_file);
    
    $self->ReadLastData($output_file, $id0_data);
    
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    my $file_name = shift;
    my $id0_data = shift;
    
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);
        
        $self->{Datas}{DataMapping} -> AddData( $$data[1], $data);
        $self->{Datas}{NameMapping} -> AddData( $$data[1], $$data[0]);
        $self->{DataNum}++;
    }

    if(!$self->{DataNum}){
        $self->_SetData(0, $id0_data);
        $self->{DataNum}++;
    }
    return;
}

#-----------------------------------#
#    　識別番号を取得し、ない場合は新たに番号を割り振る
#    　内容が変化した場合、識別番号はそのままにデータを書き換える
#------------------------------------
#    引数：固有名詞
#    返り値：識別番号
#-----------------------------------#
sub GetOrAddId{
    my $self      = shift;
    my $is_update = shift;
    my $data      = shift;
    my $name = $$data[0];

    
    if(!$self->{Datas}{NameMapping}->CheckHaveData($name)){
        # 新しい固有名詞を記録
        my $id = $self->{DataNum}; 
        $self->{DataNum}++;
        $self->_SetData($id, $data);
        
        return $id;

    }elsif($self->CheckNeedUpdate($data)){
        # 新しい固有情報を更新
        my $id = $self->{Datas}{NameMapping}->GetData($name);
        if ($is_update){
            $self->_SetData($id, $data);
        }

        return $id;
    }
    
    return $self->{Datas}{NameMapping}->GetData($name);
}

#-----------------------------------#
#    　識別番号の存在判定、及び内容の更新判定
#------------------------------------
#    引数：データ配列　[固有名詞、データ1、データ2...]
#    返り値：内容が同じ => 0
#            内容が異なる => 1
#-----------------------------------#
sub CheckNeedUpdate{
    my $self = shift;
    my $data = shift;

    my $mapped_data = $self->{Datas}{DataMapping}->GetData($$data[0]);
    
    if (scalar(@$data) != scalar(@$mapped_data) - 1) { return 1;}

    for(my $i=0;$i<scalar(@$data);$i++){
        if($$data[$i] =~ /^[0-9]+$/){ # 比較演算子を判定
            if($$data[$i] != $$mapped_data[$i+1]){ return 1;}
        }else{
            if($$data[$i] ne $$mapped_data[$i+1]){ return 1;}
        }
    }

    return 0;

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
    
    if(!$self->{Datas}{NameMapping}->CheckHaveData($name)){
        return 0;
    }
    
    return $self->{Datas}{NameMapping}->GetData($name);
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

    $mapping_datas = $self->{Datas}{NameMapping}->GetAllData();
    foreach my $name(keys(%$mapping_datas)){
        push(@$return_data, $$mapping_datas{$name});
    }

    return $return_data;
}


#-----------------------------------#
#    固有名詞と識別番号、データの対応を記録
#-----------------------------------#
#    引数｜識別番号
#          データ配列　[固有名詞、データ1、データ2...]
#-----------------------------------#
sub _SetData {
    my $self = shift;
    my $id   = shift;
    my $data = shift;

    my $name = $$data[0];
    unshift(@$data, $id);

    $self->{Datas}{DataMapping}->AddData($name, $data);
    $self->{Datas}{NameMapping}->AddData($name, $id);

    return;    
}

#-----------------------------------#
#    　出力
#------------------------------------
#    引数：
#-----------------------------------#
sub Output {
    my $self = shift;
    
    my $mapping_datas = $self->{Datas}{DataMapping}->GetAllData();
    foreach my $data(sort{@$a[0] <=> @$b[0]} values(%$mapping_datas)){
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @$data));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
