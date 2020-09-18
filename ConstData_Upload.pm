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
        use constant EXE_DATA_PROPER_NAME        => 1;
        use constant EXE_DATA_SUPERPOWER_DATA    => 1;
        use constant EXE_DATA_SKILL_DATA         => 1;
        use constant EXE_DATA_SKILL_MASTERY      => 1;
    use constant EXE_CHARA                => 1;  
        use constant EXE_CHARA_NAME              => 1;
        use constant EXE_CHARA_WORLD             => 1;
        use constant EXE_CHARA_STATUS            => 1;
        use constant EXE_CHARA_ITEM              => 1;
        use constant EXE_CHARA_SUPERPOWER        => 1;
        use constant EXE_CHARA_SKILL             => 1;
        use constant EXE_CHARA_CARD              => 1;
        use constant EXE_CHARA_STUDY             => 1;
        use constant EXE_CHARA_ONE_TIME_STUDY    => 1;
        use constant EXE_CHARA_PLACE             => 1;
        use constant EXE_CHARA_PARTY             => 1;
        use constant EXE_CHARA_PARTY_INFO        => 1;
        use constant EXE_CHARA_COMPOUND          => 1;
        use constant EXE_CHARA_MOVE              => 1;
        use constant EXE_CHARA_MOVE_PARTY_COUNT  => 1;
        use constant EXE_CHARA_NEXT_BATTLE_INFO  => 1;
        use constant EXE_CHARA_NEXT_BATTLE_ENEMY => 1;
        use constant EXE_CHARA_MEAL              => 1;
        use constant EXE_CHARA_NEXT_DUEL_INFO    => 1;
        use constant EXE_CHARA_MAKE              => 1;
        use constant EXE_CHARA_AIDE              => 1;
        use constant EXE_CHARA_AIDE_CANDIDATE    => 1;
        use constant EXE_CHARA_SKILL_CONCATENATE => 1;
    use constant EXE_BATTLE               => 1;
        use constant EXE_BATTLE_INFO             => 1;
        use constant EXE_BATTLE_ACTION           => 1;
        use constant EXE_BATTLE_ACTER            => 1;
        use constant EXE_BATTLE_DAMAGE           => 1;
        use constant EXE_BATTLE_TARGET           => 1;
        use constant EXE_BATTLE_BUFFER           => 1;
        use constant EXE_BATTLE_RESULT           => 1;
        use constant EXE_BATTLE_ENEMY            => 1;
        use constant EXE_BATTLE_DUEL_INFO        => 1;
    use constant EXE_NEW                  => 1;
        use constant EXE_NEW_ITEM                => 1;
        use constant EXE_NEW_ITEM_FUKA           => 1;
        use constant EXE_NEW_ACTION              => 1;
        use constant EXE_NEW_NEXT_ENEMY          => 1;
        use constant EXE_NEW_BATTLE_ENEMY        => 1;
        use constant EXE_NEW_DEFEAT_ENEMY        => 1;

1;
