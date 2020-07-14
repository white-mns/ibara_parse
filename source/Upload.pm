#===================================================================
#        データベースへのアップロード
#-------------------------------------------------------------------
#            (C) 2013 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/lib/IO.pm";

# パッケージの定義    ---------------#    
package Upload;
use strict;
use warnings;

# パッケージの使用宣言    ---------------#
use Encode;
use Encode 'from_to';

require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use DBI;
use DBIx::Custom;

use source::DbSetting; #データベース設定呼び出し
use ConstData_Upload;  #定数呼び出し

#-----------------------------------#
#        コンストラクタ
#-----------------------------------#
sub new {
    my $class = shift;
  
    bless {
        DBI   => "",
    }, $class;
}

# 宣言部    ---------------------------#

sub Upload {
    my $self      = shift;
    my $file_name = shift;
    my $for_table = shift;
    
    print "Uproad to \"$for_table\"...\n";
    #読み込んだファイル内容の展開
    if(&IO::Check($file_name)){
        
        $self->{FileData} = &IO::FileRead ($file_name);
        my @file_data = split(/\n/, $self->{FileData});
        
        my $data_head = shift(@file_data);
        $data_head =~ s/\r\n/\n/g;
        $data_head =~ s/\r/\n/g;
        chomp($data_head);
        my @data_head    = split(ConstData::SPLIT , $data_head );#先頭情報の除去
        
        my @data_que        = ();
        
        foreach my $lineData(@file_data){
        
            #行ごとのデータを展開
            my @one_file_data = split(ConstData::SPLIT, $lineData);
            
            #データ追加
            if (scalar(@one_file_data)){
                &AddArray($self, \@data_que, \@one_file_data, \@data_head, $for_table);
            }
            #データ100件ごとにデータ送信
            if(scalar(@data_que) > 100){
                &InsertDB($self,\@data_que,$for_table);
                if (scalar(@one_file_data) > 2) {
                    print $one_file_data[2] . "\n";
                }else{
                    print $one_file_data[0] . "\n";
                }
                @data_que =();
            }            
        }
        &InsertDB($self,\@data_que,$for_table);
    }
    

    return;
}

sub AddArray {
    my $self      = shift;
    my $data_que  = shift;
    my $add_data  = shift;
    my $data_head = shift;
    
    my $queData = {};
    
    my $max_data_size = scalar(@$data_head);
    
    foreach    (my $i="0";$i < $max_data_size;$i++){
        $$queData{$$data_head[$i]} = $$add_data[$i];
    }
    push (@$data_que, $queData);
    return;
}

sub GetMinimum{
    my $self   = shift;
    my $num_a  = shift;
    my $num_b  = shift;
    
    if($num_a < $num_b){
        return $num_a;
    }else{
        return $num_b;
    }

}

#-----------------------------------#
#
#        データの挿入
#
#-----------------------------------#
sub InsertDB{
    my $self        = shift;
    my $insert_data = shift;
    my $table_name  = shift;
    
    $self->{DBI}->insert($insert_data, table     => $table_name, bulk_insert => 1);

    if ( $@ ){
        if ( DBI::errstr &&  DBI::errstr =~ "for key 'PRIMARY'" ){
            my $errMes = "[一意制約]\n";
            print $errMes;
        } else {
            my $errMes = "$@";
            die $errMes;
        }
    }
    
    return;
}

#-----------------------------------#
#
#        テーブルデータの全削除
#
#-----------------------------------#
sub DeleteAll{
    my $self       = shift;
    my $table_name = shift;
    
    $self->{DBI}->delete_all( table => $table_name );
    return;
}

#-----------------------------------#
#
#    同じ日付のデータを削除する
#
#-----------------------------------#
sub DeleteSameDate{
    my $self       = shift;
    my $table_name = shift;
    my $date       = shift;

    print  $date . "\n";
    
    $self->{DBI}->delete(
        table => $table_name,
        where => {created_at => $date,}
        );
    return;
}

#-----------------------------------#
##
##               同じ更新回のデータを削除する
##
##-----------------------------------#
sub DeleteSameResult{
    my $self        = shift;
    my $table_name  = shift;
    my $result_no   = shift;
    my $generate_no = shift;
    
    $self->{DBI}->delete(
            table => $table_name,
            where => {result_no   => $result_no,}
                      #generate_no => $generate_no,}
        );
    return;
}

#-----------------------------------#
#
#        データベース接続
#
#-----------------------------------#
sub DBConnect {
    my $self = shift;
    
    # Connect
    $self->{DBI} = DBIx::Custom->connect(
        dsn      => DbSetting::DSN,
        user     => DbSetting::USER,
        password => DbSetting::PASS,
        option   => {mysql_enable_utf8 => 1},
    ) or die "cannot connect to MySQL: $self->{DBI}::errstr";
    
    return;
}
1;
