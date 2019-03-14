#===================================================================
#        移動取得パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し
use source::lib::GetNode;


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Move;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
        Datas => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Move}                = StoreData->new();
    $self->{Datas}{MovePartyCount} = StoreData->new();
    $self->{MoveParty} = {};

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "move_no",
                "field_id",
                "area",
                "area_column",
                "area_row",
                "landform_id",
    ];

    $self->{Datas}{Move}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "landform_id",
                "move_count",
    ];

    $self->{Datas}{MovePartyCount}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Move}->SetOutputName          ( "./output/chara/move_"             . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{MovePartyCount}->SetOutputName( "./output/chara/move_party_count_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,キャラクターイメージデータノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no = shift;
    my $div_r870_nodes = shift;
    my $div_cimgnm_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $next_div_node = $self->SearchDivNodeFromTitleImg($div_r870_nodes, "next");
    
    if (!$next_div_node) { return;}

    $self->InitializePartyMove();
    $self->GetMoveData($next_div_node, $div_cimgnm_nodes);
    
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,キャラクターイメージデータノード
#-----------------------------------#
sub InitializePartyMove{
    my $self = shift;
    
    if (!exists ($self->{PartyMove}{sprintf("%04d", $self->{CommonDatas}{Party}{$self->{ENo}})})) {
            $self->{PartyMove}{sprintf("%04d", $self->{CommonDatas}{Party}{$self->{ENo}})} = {};
        for(my $i=1;$i<=5;$i++) {
            $self->{PartyMove}{sprintf("%04d", $self->{CommonDatas}{Party}{$self->{ENo}})}{$i} = 0;
        }
    }
    
    return;
}
#-----------------------------------#
#    行動DIVノード取得
#------------------------------------
#    引数｜データノード
#          タイトル画像名
#-----------------------------------#
sub SearchDivNodeFromTitleImg{
    my $self = shift;
    my $nodes = shift;
    my $img_text   = shift;

    foreach my $node (@$nodes) {
        my $img_nodes = &GetNode::GetNode_Tag("img", \$node);

        if (!scalar(@$img_nodes)) { next;}

        my $title   = $$img_nodes[0]->attr("src");
        if ($title =~ /$img_text.png/) {

            return $node;
        }
    }

    return;
}

#-----------------------------------#
#    移動結果データ取得
#------------------------------------
#    引数｜キャラクターイメージデータノード
#-----------------------------------#
sub GetMoveData{
    my $self = shift;
    my $next_div_node = shift;
    my $div_cimgnm_nodes = shift;
    my $move_no = 0;
 
    my @child_nodes = $next_div_node->content_list;

    for my $child_node (@child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->right && $child_node->right =~ /移動！/) {
            $move_no += 1;
            $self->GetMove($child_node, $move_no);
        }
    }
    if ($move_no == 0) {
        $self->GetPlaceData($div_cimgnm_nodes, $move_no);
    }

    return;
}

#-----------------------------------#
#    移動・移動実験成功結果データ取得
#------------------------------------
#    引数｜キャラクターイメージデータノード
#-----------------------------------#
sub GetMove{
    my $self = shift;
    my $node = shift;
    my $move_no = shift;

    my ($field_id, $area, $area_column, $area_row, $landform_id) = (0, "", "", 0, 0);

    if ($node->as_text =~ /(.+) (\D+\-\d+)（(.+)）/){
    
        $field_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        $landform_id = $self->GetLandformId($3);
    
        $area = $2;
        my @area = split("-", $area);
        $area_column = $area[0];
        $area_row    = $area[1];
        
    }

    $self->{Datas}{Move}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $move_no, $field_id, $area, $area_column, $area_row, $landform_id) ));
    
    $landform_id = ($landform_id == 6) ? 1 : $landform_id; # チェックポイントの敵判定は道路として扱う
    $self->{PartyMove}{sprintf("%04d", $self->{CommonDatas}{Party}{$self->{ENo}})}{$landform_id} += 1;
}

#-----------------------------------#
#    現在地データ取得
#------------------------------------
#    引数｜現在地データノード
#-----------------------------------#
sub GetPlaceData{
    my $self = shift;
    my $nodes = shift;
    my $move_no = shift;
    my ($field_id, $area, $area_column, $area_row, $landform_id) = (0, "", "", 0, 0);
 
    my $node4_b_nodes = &GetNode::GetNode_Tag("b", \$$nodes[4]);

    $field_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($$node4_b_nodes[0]->as_text);

    $area = $$node4_b_nodes[0]->right->right;
    my @area = split("-", $area);
    $area_column = $area[0];
    $area_row    = $area[1];

    my $node1_img_nodes = &GetNode::GetNode_Tag("img", \$$nodes[1]);
    if ($$node1_img_nodes[0]->attr("src") =~ /p\/a(\d).png/) {
        $landform_id = $1;
    }

    $self->{Datas}{Move}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $move_no, $field_id, $area, $area_column, $area_row, $landform_id)));
    
    $landform_id = ($landform_id == 6) ? 1 : $landform_id; # チェックポイントの敵判定は道路として扱う
    $self->{PartyMove}{sprintf("%04d", $self->{CommonDatas}{Party}{$self->{ENo}})}{$landform_id} += 1;

    return;
}

#-----------------------------------#
#    地形文字列を数字に変換
#------------------------------------
#    引数｜地形テキスト
#-----------------------------------#
sub GetLandformId{
    my $self = shift;
    my $text = shift;

    my %landforms = ("道路" => 1, "草原" => 2, "沼地" => 3, "森林" => 4, "山岳" => 5, "チェックポイント" => 6);

    if (exists($landforms{$text})) {
        return $landforms{$text};
    }

    return 0;
}
#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $party_no (sort{$a cmp $b} keys %{$self->{PartyMove}}) {
        foreach my $landform_id (keys %{$self->{PartyMove}{$party_no}}) {
            my $count = $self->{PartyMove}{$party_no}{$landform_id};
    
            $self->{Datas}{MovePartyCount}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $party_no, $landform_id, $count)));
        }
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
