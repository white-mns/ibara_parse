#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%02d" $1`
GENERATE_NO=$2

ZIP_NAME=${RESULT_NO}_$GENERATE_NO

mkdir ./data/orig/result${RESULT_NO}
mkdir ./data/orig/result${RESULT_NO}/k
mkdir ./data/orig/result${RESULT_NO}/k/now

cd ./data/orig/result${RESULT_NO}

wget -O s.css http://lisge.com/ib/s.css

for ((E_NO=1;E_NO <= 2000;E_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./k/now/r${E_NO}.html ]; then
            break
        fi

        wget -O ./k/now/r${E_NO}.html http://lisge.com/ib/k/now/r${E_NO}.html

        sleep 2

        if [ -s ./k/now/r${E_NO}.html ]; then
            break
        fi
    }
}

cd $CURENT  #元のディレクトリに戻る

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
