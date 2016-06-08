#!/bin/sh

function usage()
{
  printf "usage: %s [-i infile] [-s infile_selected] [-g genome_assembly]"
  exit 1
}

#
# default parameters
#
infile=experimentList.tab
genome_assembly=hg19
infile_selected=


while getopts i:s:g: opt
do
  case ${opt} in
  i) infile=${OPTARG};;
  s) infile_selected=${OPTARG};;
  g) genome_assembly=${OPTARG};;
  *) usage;;
  esac
done

if [[ $infile_selected == "" ]];then
  infile_selected=experimentList_${genome_assembly}_selected.list
fi


###
### prep
###
tmpdir=$(mktemp -d -p ${TMPDIR:-/tmp})
trap "[[ $tmpdir ]] && rm -rf $tmpdir" 0 1 2 3 15

cat $infile | sort > ${tmpdir}/all.txt
cat $infile_selected | sort > ${tmpdir}/selectedID.txt

join -t '	' \
  ${tmpdir}/all.txt \
  ${tmpdir}/selectedID.txt \
| awk \
  'BEGIN{FS="\t";OFS="\t"}{
     gsub(" ","_",$3);
     gsub(" ","_",$5);
     print
  }' \
> ${tmpdir}/selected.txt




cat <<EOF
track ChIP-Atlas,bigWig
shortLabel ChIP-Atlas,bigWig
longLabel ChIP-Atlas,bigWig
superTrack on



track ChIP-Atlas,bigBed
shortLabel ChIP-Atlas,bigBed
longLabel ChIP-Atlas,bigBed
superTrack on



EOF


###
### aggregators
###

for aClass in $( cat ${tmpdir}/selected.txt | cut -f 3 | sort | uniq )
do
  for cClass in $( cat ${tmpdir}/selected.txt \
                   | awk \
                     --assign aClass=$aClass \
                     'BEGIN{FS="\t";OFS="\t"}{if($3 == aClass){print} }' \
                   | cut -f 5 | sort | uniq )
  do
    for type in bigWig bigBed
    do
      cat <<EOF
track ${aClass},${cClass},${type}
shortLabel ${aClass},${cClass},${type}
longLabel ${aClass},${cClass},${type}
compositeTrack on
allButtonPair on
type ${type}
autoScale on
maxHeightPixels 100:16:8
parent ChIP-Atlas,${type}
visibility hide



EOF
    done
  done
done



###
### individuals (bigWig)
###

cat ${tmpdir}/selected.txt \
| awk \
  'BEGIN{FS="\t";OFS="\t"}{
    aClass = $3
    cClass = $5
    printf "track %sbw\n", $1
    printf "shortLabel %sbw\n" , $1
    printf "longLabel \"%s\"\n" , $9
    printf "type bigWig\n"
    printf "bigDataUrl http://dbarchive.biosciencedbc.jp/kyushu-u/%s/eachData/bw/%s.bw\n", $2, $1
    printf "parent %s,%s,bigWig on\n", aClass , cClass
    printf "url http://chip-atlas.org/view?id=%s\n" , $1
    printf "\n\n"
  }'


###
### individuals (bigBed)
###

cat ${tmpdir}/selected.txt \
| awk \
  'BEGIN{FS="\t";OFS="\t"}{
    threshold = "05"
    aClass = $3
    cClass = $5
    printf "track %sbb\n", $1
    printf "shortLabel %sbb\n" , $1
    printf "longLabel \"%s\"\n" , $9
    printf "type bigBed\n"
    printf "spectrum on\n"
    printf "color 0,60,120\n"
    printf "altColor 120,60,0\n"
    printf "bigDataUrl http://dbarchive.biosciencedbc.jp/kyushu-u/%s/eachData/bb%s/%s.%s.bb\n" , $2 , threshold, $1, threshold
    printf "parent %s,%s,bigBed on\n", aClass , cClass
    printf "url http://chip-atlas.org/view?id=%s\n" , $1
    printf "\n\n"
  }'

