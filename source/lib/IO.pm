#===================================================================
#        ファイル入出力に関わるパッケージ
#-------------------------------------------------------------------
#            (C) 2014 @white_mns
#===================================================================

package IO;
use Cwd;

#-----------------------------------#
#
#        ディレクトリを開く
#
#-----------------------------------#
sub DirectoryOpen{
    (my $directoryNum,$directoryName) = @_;
    
    #ディレクトリを開き、ファイル名リストを取得
    opendir (DIR, "$directoryName");
    my @tmpList = readdir (DIR);
    @fileList = grep(/$attach[$directoryNum]\w+.html/,@tmpList);
    closedir (DIR);
    @returnData = ($directoryName,\@fileList);
    return \@returnData;
}

#-----------------------------------#
#
#        出力用配列をcsvに書き出し
#
#-----------------------------------#
sub OutputList {
    my ($fileName,$output) = @_;
    open OUTLIST,"> $fileName";
    foreach(@{$output}){
        print OUTLIST "$_\n";
    }
    close OUTLIST;
}

#-----------------------------------#
#
#        書き出し
#
#-----------------------------------#
sub FileWrite{
    my ($fileName,$content) = @_; # アクセスする URL
    
    open ( FILEWRITE , " > $fileName ");
    print FILEWRITE $content;
    close(FILEWRITE);
    return;
}

#-----------------------------------#
#
#        追記
#
#-----------------------------------#
sub FileADD{
    my ($fileName,$content) = @_; # アクセスする URL
    
    open ( FILEWRITE , " >> $fileName ");
    print FILEWRITE $content;
    close(FILEWRITE);
    return;
}

#-----------------------------------#
#
#        読み込み
#
#-----------------------------------#
sub FileRead{
    my($fileName) = @_;
    
    open(FILEHANDLE , " < $fileName");
    my @in = <FILEHANDLE>;
    close FILEHANDLE;
    
    my $content = join('', @in);
    
    return $content;
}

#-----------------------------------#
#
#        読み込み
#
#-----------------------------------#
sub GzipRead{
    my($fileName) = @_;
    
    open(FILEHANDLE , "zcat $fileName 2>/dev/null |");
    my @in = <FILEHANDLE>;
    close FILEHANDLE;
    
    my $content = join('', @in);
    
    return $content;
}


#-----------------------------------#
#
#        存在のチェック
#
#-----------------------------------#
sub Check{
    
    my($fileName) = @_;
    unless (-e "$fileName"){
        print "NotExist:$fileName\n";
        return 0;
    }
    return 1;
}
1;
