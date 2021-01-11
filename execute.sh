#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%02d" $1`
GENERATE_NO=$2

if [ -z "$RESULT_NO" ]; then
    exit
fi

# 再更新番号の指定がない場合、取得済みで最も再更新番号の大きいファイルを探索して実行する
if [ -z "$2" ]; then
    for ((GENERATE_NO=5;GENERATE_NO >=0;GENERATE_NO--)) {
        
        ZIP_NAME=${RESULT_NO}_$GENERATE_NO

        echo "test $ZIP_NAME"
        if [ -f ./data/orig/result${ZIP_NAME}.zip ]; then
            echo "execute $ZIP_NAME"
            break
        fi
    }
fi

if [ $GENERATE_NO -lt 0 ]; then
    exit
fi

ZIP_NAME=${RESULT_NO}_$GENERATE_NO

#------------------------------------------------------------------
# 圧縮結果をダウンロード。なければ各個アクセスするシェルスクリプトを実行
if [ ! -f ./data/orig/result${ZIP_NAME}.zip ]; then
    wget -O data/orig/result${ZIP_NAME}.zip http://lisge.com/ib/k/result${RESULT_NO}.zip
fi

if [ ! -f ./data/orig/result${ZIP_NAME}.zip ] || [ ! -s ./data/orig/result${ZIP_NAME}.zip ]; then
    ./_result_download.sh $RESULT_NO $GENERATE_NO
fi


# 圧縮結果ファイルを展開
if [ -f ./data/orig/result${ZIP_NAME}.zip ]; then

    echo "open archive..."
    
    cd ./data/orig

    rm  -rf result
    rm  -rf result${RESULT_NO}
    rm  -rf result${ZIP_NAME}

    unzip -q result${ZIP_NAME}.zip
    if [ -d result ]; then
        mv result  result${ZIP_NAME}
    elif [ -d result${RESULT_NO} ]; then
        mv result${RESULT_NO}  result${ZIP_NAME}
    fi

    cd ../../

    perl ./GetData.pl      $RESULT_NO $GENERATE_NO
    #perl ./UploadParent.pl $RESULT_NO $GENERATE_NO

#------------------------------------------------------------------
# 展開したファイルを削除
    
    echo "rm archive..."
    cd ./data/orig
    rm  -rf result${ZIP_NAME}
    cd ../../

fi

cd $CURENT  #元のディレクトリに戻る

