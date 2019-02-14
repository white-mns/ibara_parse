#===================================================================
#        定数設定
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================

# パッケージの定義    ---------------#    
package ConstData;

# パッケージの使用宣言    ---------------#
use strict;
use warnings;

# 定数宣言    ---------------#
    use constant SPLIT => "\t"; # 区切り文字

# ▼ 実行制御 =============================================
#      実行する場合は 1 ，実行しない場合は 0 ．
    
    use constant EXE_DATA                 => 1;
        use constant EXE_DATA_PROPER_NAME      => 1;
    use constant EXE_CHARA                => 1;
        use constant EXE_CHARA_NAME            => 1;
        use constant EXE_CHARA_WORLD           => 1;
    use constant EXE_BATTLE               => 1;

1;
