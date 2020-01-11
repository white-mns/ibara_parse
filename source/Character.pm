#===================================================================
#        キャラステータス解析パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;


require "./source/lib/IO.pm";
require "./source/lib/time.pm";

require "./source/chara/Name.pm";
require "./source/chara/World.pm";
require "./source/chara/Status.pm";
require "./source/chara/Item.pm";
require "./source/chara/Superpower.pm";
require "./source/chara/Skill.pm";
require "./source/chara/Card.pm";
require "./source/chara/Study.pm";
require "./source/chara/Place.pm";
require "./source/chara/Party.pm";
require "./source/chara/Compound.pm";
require "./source/chara/Move.pm";
require "./source/chara/NextBattle.pm";
require "./source/chara/Meal.pm";
require "./source/chara/Make.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Character;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
    ResultNo      => "",
    GenerateNo    => "",
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    $self->{ResultNo0} = sprintf ("%02d", $self->{ResultNo});

    #インスタンス作成
    if (ConstData::EXE_CHARA_NAME)        { $self->{DataHandlers}{Name}       = Name->new();}
    if (ConstData::EXE_CHARA_WORLD)       { $self->{DataHandlers}{World}      = World->new();}
    if (ConstData::EXE_CHARA_STATUS)      { $self->{DataHandlers}{Status}     = Status->new();}
    if (ConstData::EXE_CHARA_ITEM)        { $self->{DataHandlers}{Item}       = Item->new();}
    if (ConstData::EXE_CHARA_SUPERPOWER)  { $self->{DataHandlers}{Superpower} = Superpower->new();}
    if (ConstData::EXE_CHARA_SKILL)       { $self->{DataHandlers}{Skill}      = Skill->new();}
    if (ConstData::EXE_CHARA_CARD)        { $self->{DataHandlers}{Card}       = Card->new();}
    if (ConstData::EXE_CHARA_SKILL)       { $self->{DataHandlers}{Study}      = Study->new();}
    if (ConstData::EXE_CHARA_PLACE)       { $self->{DataHandlers}{Place}      = Place->new();}
    if (ConstData::EXE_CHARA_PARTY)       { $self->{DataHandlers}{Party}      = Party->new();}
    if (ConstData::EXE_CHARA_COMPOUND)    { $self->{DataHandlers}{Compound}   = Compound->new();}
    if (ConstData::EXE_CHARA_MOVE)        { $self->{DataHandlers}{Move}       = Move->new();}
    if (ConstData::EXE_CHARA_NEXT_BATTLE) { $self->{DataHandlers}{NextBattle} = NextBattle->new();}
    if (ConstData::EXE_CHARA_MEAL)        { $self->{DataHandlers}{Meal}       = Meal->new();}
    if (ConstData::EXE_CHARA_MAKE)        { $self->{DataHandlers}{Make}       = Make->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }
    
    return;
}

#-----------------------------------#
#    圧縮結果から詳細データファイルを抽出
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/orig/result' . $self->{ResultNo0} . '_' . $self->{GenerateNo} . '/k/now';
    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = GetMaxFileNo($directory,"r");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for (my $e_no=$start; $e_no<=$end; $e_no++) {
        if ($e_no % 10 == 0) {print $e_no . "\n"};

        $self->ParsePage($directory."/r".$e_no.".html",$e_no);
    }
    
    return ;
}
#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
#    　　　ENo
##-----------------------------------#
sub ParsePage{
    my $self        = shift;
    my $file_name   = shift;
    my $e_no        = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $div_cnm_nodes         = &GetNode::GetNode_Tag_Attr("div", "class", "CNM",     \$tree);
    my $div_cimgjn1_nodes     = &GetNode::GetNode_Tag_Attr("div", "class", "CIMGJN1", \$tree);
    my $div_cimgnm1_nodes     = &GetNode::GetNode_Tag_Attr("div", "class", "CIMGNM1", \$tree);
    my $div_cimgnm2_nodes     = &GetNode::GetNode_Tag_Attr("div", "class", "CIMGNM2", \$tree);
    my $div_cimgnm3_nodes     = &GetNode::GetNode_Tag_Attr("div", "class", "CIMGNM3", \$tree);
    my $div_cimgnm4_nodes     = &GetNode::GetNode_Tag_Attr("div", "class", "CIMGNM4", \$tree);
    my $div_align_right_nodes = &GetNode::GetNode_Tag_Attr("div", "align", "RIGHT",   \$tree);
    my $div_r870_nodes        = &GetNode::GetNode_Tag_Attr("div", "class", "R870",    \$tree);
    my $div_y870_nodes        = &GetNode::GetNode_Tag_Attr("div", "class", "Y870",    \$tree);

    my $div_cimgnm_nodes      = ["", $$div_cimgnm1_nodes[0], $$div_cimgnm2_nodes[0], $$div_cimgnm3_nodes[0], $$div_cimgnm4_nodes[0]];
    
    if(!scalar(@$div_align_right_nodes)) {
        $tree = $tree->delete;
        return;
    };

    # データリスト取得
    if (exists($self->{DataHandlers}{Name}))       {$self->{DataHandlers}{Name}->GetData       ($e_no, $$div_cnm_nodes[0], $$div_align_right_nodes[ scalar(@$div_align_right_nodes)-1 ])};
    if (exists($self->{DataHandlers}{World}))      {$self->{DataHandlers}{World}->GetData      ($e_no, $$div_cimgjn1_nodes[0])};
    if (exists($self->{DataHandlers}{Status}))     {$self->{DataHandlers}{Status}->GetData     ($e_no, $$div_cimgjn1_nodes[0], $div_cimgnm_nodes)};
    if (exists($self->{DataHandlers}{Item}))       {$self->{DataHandlers}{Item}->GetData       ($e_no, $div_y870_nodes)};
    if (exists($self->{DataHandlers}{Superpower})) {$self->{DataHandlers}{Superpower}->GetData ($e_no, $div_y870_nodes)};
    if (exists($self->{DataHandlers}{Skill}))      {$self->{DataHandlers}{Skill}->GetData      ($e_no, $div_y870_nodes)};
    if (exists($self->{DataHandlers}{Card}))       {$self->{DataHandlers}{Card}->GetData       ($e_no, $div_y870_nodes)};
    if (exists($self->{DataHandlers}{Study}))      {$self->{DataHandlers}{Study}->GetData      ($e_no, $div_y870_nodes)};
    if (exists($self->{DataHandlers}{Place}))      {$self->{DataHandlers}{Place}->GetData      ($e_no, $$div_cimgnm4_nodes[0])};
    if (exists($self->{DataHandlers}{Party}))      {$self->{DataHandlers}{Party}->GetData      ($e_no, $div_r870_nodes)};
    if (exists($self->{DataHandlers}{Compound}))   {$self->{DataHandlers}{Compound}->GetData   ($e_no, $div_r870_nodes)};
    if (exists($self->{DataHandlers}{Move}))       {$self->{DataHandlers}{Move}->GetData       ($e_no, $div_r870_nodes, $div_cimgnm_nodes)};
    if (exists($self->{DataHandlers}{NextBattle})) {$self->{DataHandlers}{NextBattle}->GetData ($e_no, $div_r870_nodes)};
    if (exists($self->{DataHandlers}{Meal}))       {$self->{DataHandlers}{Meal}->GetData       ($e_no, $div_r870_nodes)};
    if (exists($self->{DataHandlers}{Make}))       {$self->{DataHandlers}{Make}->GetData       ($e_no, $div_r870_nodes)};

    $tree = $tree->delete;
}

#-----------------------------------#
#       最大ファイル番号を取得
#-----------------------------------#
#    引数｜ディレクトリ名
#    　　　ファイル接頭辞
##-----------------------------------#
sub GetMaxFileNo{
    my $directory   = shift;
    my $prefix    = shift;

    #ファイル名リストを取得
    my @fileList = grep { -f } glob("$directory/$prefix*.html");

    my $max= 0;
    foreach (@fileList) {
        $_ =~ /$prefix(\d+).html/;
        if ($max < $1) {$max = $1;}
    }
    return $max
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
