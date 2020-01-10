#===================================================================
#    データベースへのアップロード
#-------------------------------------------------------------------
#        (C) 2019 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/Upload.pm";
require "./source/lib/time.pm";

# パッケージの使用宣言    ---------------#
use strict;
use warnings;
require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

# 変数の初期化    ---------------#
use ConstData_Upload;        #定数呼び出し

my $timeChecker = TimeChecker->new();

# 実行部    ---------------------------#
$timeChecker->CheckTime("start  \t");

&Main;

$timeChecker->CheckTime("end    \t");
$timeChecker->OutputTime();
$timeChecker = undef;

# 宣言部    ---------------------------#

sub Main {
    my $result_no = $ARGV[0];
    my $generate_no = $ARGV[1];
    my $upload = Upload->new();

    if (!defined($result_no) || !defined($generate_no) || $result_no !~ /^[0-9]+$/ || $generate_no !~ /^[0-9]+$/) {
        print "Error:Unusual ResultNo or GenerateNo\n";
        return;
    }

    $result_no = sprintf ("%02d", $result_no);

    $upload->DBConnect();
    
    $upload->DeleteSameResult("uploaded_checks", $result_no, $generate_no);

    if (ConstData::EXE_DATA) {
        &UploadData($upload, ConstData::EXE_DATA_PROPER_NAME,     "proper_names",    "./output/data/proper_name.csv");
        &UploadData($upload, ConstData::EXE_DATA_SUPERPOWER_DATA, "superpower_data", "./output/data/superpower_data.csv");
        &UploadData($upload, ConstData::EXE_DATA_SKILL_DATA,      "skill_data",      "./output/data/skill_data.csv");
        &UploadData($upload, ConstData::EXE_DATA_SKILL_MASTERY,   "skill_masteries", "./output/data/skill_mastery.csv");
    }
    if (ConstData::EXE_NEW) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_NEW_ITEM_FUKA,           "new_item_fukas",      "./output/new/item_fuka_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_NEW_ACTION,              "new_actions",         "./output/new/action_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_NEW_NEXT_ENEMY,          "new_next_enemies",    "./output/new/next_enemy_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_NEW_BATTLE_ENEMY,        "new_battle_enemies",  "./output/new/battle_enemy_");
    }
    if (ConstData::EXE_CHARA) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_NAME,              "names",               "./output/chara/name_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_WORLD,             "worlds",              "./output/chara/world_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_STATUS,            "statuses",            "./output/chara/status_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_ITEM,              "items",               "./output/chara/item_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_SUPERPOWER,        "superpowers",         "./output/chara/superpower_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_SKILL,             "skills",              "./output/chara/skill_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_CARD,              "cards",               "./output/chara/card_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_STUDY,             "studies",             "./output/chara/study_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_PLACE,             "places",              "./output/chara/place_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_PARTY,             "parties",             "./output/chara/party_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_PARTY_INFO,        "party_infos",         "./output/chara/party_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_COMPOUND,          "compounds",           "./output/chara/compound_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_MOVE,              "moves",               "./output/chara/move_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_MOVE_PARTY_COUNT,  "move_party_counts",   "./output/chara/move_party_count_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_NEXT_BATTLE_INFO,  "next_battle_infos",   "./output/chara/next_battle_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_NEXT_BATTLE_ENEMY, "next_battle_enemies", "./output/chara/next_battle_enemy_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_MEAL,              "meals",               "./output/chara/meal_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_NEXT_DUEL_INFO,    "next_duel_infos",     "./output/chara/next_duel_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_MAKE,              "makes",               "./output/chara/make_");
    }
    if (ConstData::EXE_BATTLE) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_INFO,             "battle_infos",        "./output/battle/info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_RESULT,           "battle_results",      "./output/battle/result_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_ENEMY,            "battle_enemies",      "./output/battle/enemy_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_DUEL_INFO,        "duel_infos",          "./output/battle/duel_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_ACTION,           "battle_actions",      "./output/battle/action_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_ACTER,            "battle_acters",       "./output/battle/acter_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_DAMAGE,           "battle_damages",      "./output/battle/damage_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_TARGET,           "battle_targets",      "./output/battle/target_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_BUFFER,           "battle_buffers",      "./output/battle/buffer_");
    }
        &UploadResult($upload, $result_no, $generate_no, 1,                                      "uploaded_checks",     "./output/etc/uploaded_check_");
    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}

#-----------------------------------#
#       結果番号に依らないデータをアップロード
#-----------------------------------#
#    引数｜アップロードオブジェクト
#    　　　アップロード定義
#          テーブル名
#          ファイル名
##-----------------------------------#
sub UploadData {
    my ($upload, $is_upload, $table_name, $file_name) = @_;

    if ($is_upload) {
        $upload->DeleteAll($table_name);
        $upload->Upload($file_name, $table_name);
    }
}

#-----------------------------------#
#       更新結果データをアップロード
#-----------------------------------#
#    引数｜アップロードオブジェクト
#    　　　更新番号
#    　　　再更新番号
#    　　　アップロード定義
#          テーブル名
#          ファイル名
##-----------------------------------#
sub UploadResult {
    my ($upload, $result_no, $generate_no, $is_upload, $table_name, $file_name) = @_;

    if($is_upload) {
        $upload->DeleteSameResult($table_name, $result_no, $generate_no);
        $upload->Upload($file_name . $result_no . "_" . $generate_no . ".csv", $table_name);
    }
}
