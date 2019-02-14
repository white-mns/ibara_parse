#===================================================================
#        ハッシュデータ保存用基本パッケージ
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
package StoreHashData;

#-----------------------------------#
#        コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
    StoreData  => {},
    HeaderData => "",
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
    
    $self->{HeaderData} = "";
    foreach my $header(@$header_list){
        $self->{HeaderData} = $self->{HeaderData} . $header . ConstData::SPLIT;
    }
    
    return;
}

#-----------------------------------#
#
#        保存データ追加
#        引数：ファイルアドレス
#
#-----------------------------------#
sub AddData(){
    my $self   = shift;
    my $key    = shift;
    my $input  = shift;
    
    ${ $self->{StoreData} }{$key} = $input;
    return;
}
#-----------------------------------#
#
#        保存データ全取得
#        引数：ファイルアドレス
#
#-----------------------------------#
sub GetAllData(){
    my $self = shift;
    my $key  = shift;
    my %return_array = %{ $self->{StoreData} };
    return \%return_array
}

#-----------------------------------#
#
#        保存データ取得
#        引数：ファイルアドレス
#
#-----------------------------------#
sub GetData(){
    my $self = shift;
    my $key  = shift;
    
    if(${ $self->{StoreData} }{$key}){
        my $return_data = ${ $self->{StoreData} }{$key};
        return $return_data;
    }else{
        delete(${ $self->{StoreData} }{$key});
        print "notting : " . $key . "\n";
        return 0;
    }
}

#-----------------------------------#
#
#        データを所持しているか判定
#        引数：ファイルアドレス
#
#-----------------------------------#
sub CheckHaveData{
    my $self = shift;
    my $key  = shift;
    
    if(exists(${ $self->{StoreData} }{$key})){
        return 1;
    }else{
        return 0;
    }
}

#-----------------------------------#
#
#        出力先指定
#        引数：ファイルアドレス
#
#-----------------------------------#
sub Hash_to_Array(){
    my $self    = shift;
    my $output  = shift;
    
    my @key_list = "";
    if(scalar(@key_list = keys(%{ $self->{StoreData} }))){
        if($key_list[0] =~ /^[0-9]+$/){ #数字と文字によるソートの変更
            foreach my $key( sort { $a <=> $b } keys (%{ $self->{StoreData} })){
                $self->PushOutputData($output,$key);
            }
            }else{
            foreach my $key( sort { $a cmp $b } keys (%{ $self->{StoreData} })){
                $self->PushOutputData($output,$key);
            }
            
        }
        
    }
    
    return;
}

#-----------------------------------#
#
#    出力用データに追加する
#    引数：ファイルアドレス
#
#-----------------------------------#
sub PushOutputData(){
    my $self    = shift;
    my $output  = shift;
    my $key     = shift;
    
    my $output_word = "";

    if(ref(${$self->{StoreData}}{$key}) eq "ARRAY"){#中身が配列の時は結合する
        $output_word = $key . ConstData::SPLIT . join(ConstData::SPLIT, @{${$self->{StoreData}}{$key}});
    }else{
        $output_word = $key . ConstData::SPLIT . ${$self->{StoreData}}{$key};
    }

    push (@$output, $output_word);
    return;
}

#-----------------------------------#
#
#        引数：ファイルアドレス
#
#-----------------------------------#
sub SetOutputName(){
    my $self  = shift;
    my $name  = shift;
    
    $self->{Output} = $name;
    return;
}

#-----------------------------------#
#
#        引数：出力用配列
#
#-----------------------------------#
sub AddOutputHeader{
    my $self   = shift;
    my $output = shift;
    
    push (@{ $output }, $self->{HeaderData} );
}


sub Output(){
    my $self = shift;
    my @outputArray = ();
    &AddOutputHeader  ($self,           \@outputArray);
    &Hash_to_Array    ($self,           \@outputArray);
    &IO::OutputList   ($self->{Output}, \@outputArray );
    return;
}
1;
