#===================================================================
#        データ保存用基本パッケージ
#-------------------------------------------------------------------
#            (C) 2013 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/IO.pm";
use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#        パッケージの定義
#------------------------------------------------------------------#     
package StoreData;

#-----------------------------------#
#        コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
    StoreData  => [],
    Output     => "",
  }, $class;
}

#-----------------------------------#
#        初期化
#        (入力としてデータの目次を入れる)
#-----------------------------------#
sub Init(){
    my $self        = shift;
    my $header_list = shift;
    
    my $data_head = "";
    foreach my $header(@$header_list){
        $data_head = $data_head . $header . ConstData::SPLIT;
    }
    
    push (@{ $self->{StoreData} }, $data_head );
    return;
}

#-----------------------------------#
#
#        保存データ追加
#        引数：ファイルアドレス
#
#-----------------------------------#
sub AddData(){
    my $self  = shift;
    my $input = shift;
    
    push (@{ $self->{StoreData} }, $input );
    return;
}

#-----------------------------------#
#
#        保存データ追加
#        引数：ファイルアドレス
#
#-----------------------------------#
sub GetAllData(){
    my $self = shift;
    my @return_array = @{ $self->{StoreData} };
    return \@return_array;
}
#-----------------------------------#
#
#        保存データ追加
#        引数：ファイルアドレス
#
#-----------------------------------#
sub DeleteAllData(){
    my $self = shift;
    @{ $self->{StoreData} } = ();
    return;
}
#-----------------------------------#
#
#        出力先指定
#        引数：ファイルアドレス
#
#-----------------------------------#
sub SetOutputName(){
    my $self = shift;
    my $name = shift;
    
    $self->{Output} = $name;
    return;
}

#-----------------------------------#
#
#        出力
#        引数：ファイルアドレス
#
#-----------------------------------#
sub Output(){
    my $self = shift;
    
    &IO::OutputList($self->{Output}, \@{ $self->{StoreData} } );
    return;
}
1;
