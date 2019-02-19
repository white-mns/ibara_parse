#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

ZIP_NAME=${RESULT_NO}_$GENERATE_NO

mkdir ./data/orig/result${RESULT_NO}
mkdir ./data/orig/result${RESULT_NO}/now

wget -O ./data/orig/result${RESULT_NO}/s.css http://lisge.com/ib/s.css

for ((E_NO=1;E_NO <= 2000;E_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./data/orig/result${RESULT_NO}/now/r${E_NO}.html ]; then
            break
        fi

        wget -O ./data/orig/result${RESULT_NO}/now/r${E_NO}.html http://lisge.com/ib/k/now/r${E_NO}.html

        sleep 2

        if [ -s ./data/orig/result${RESULT_NO}/now/r${E_NO}.html ]; then
            break
        fi
    }
}

find ./data/orig/result${RESULT_NO} -type f -empty -delete

# ファイルを圧縮
if [ -d ./data/orig/result${RESULT_NO} ]; then
    
    cd ./data/orig/

    echo "orig zip..."
    zip -qr result${ZIP_NAME}.zip result${RESULT_NO}
    echo "rm directory..."
    rm  -r result${RESULT_NO}
        
    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
