#===================================================================
#        データベース設定
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================

# パッケージの定義    ---------------#    
package DbSetting;

# 定数宣言    ---------------#
use constant HOST       => "localhost";
use constant DB         => "db_name";
use constant PORT       => "3306";
use constant DSN        => "dbi:mysql:database=" .DB . ";host=" . HOST . ":port=" . PORT;

use constant USER       => "user_name";
use constant PASS       => "password";

1;
