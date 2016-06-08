#!/bin/sh

infile=experimentList.tab
outdir_prefix=experimentList


cat $infile | while read line; do

  acc=$(echo $line | cut -f 1 -d ' ')
  genome=$(echo $line | cut -f 2 -d ' ')
  url="http://dbarchive.biosciencedbc.jp/kyushu-u/${genome}/eachData/bb05/${acc}.05.bb"
  outdir=${outdir_prefix}_${genome}_bb
  outfile=${outdir}/${acc}.05.bb

  if [[ ! -f $outfile ]];then
    mkdir -p $outdir
    wget -O $outfile $url 
  fi

done
