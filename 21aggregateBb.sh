#!/bin/sh

function usage()
{
  printf "usage: %s [-i infile] [-s infile_selected] [-g genome_assembly] [-b bbdir_prefix] [-o outprefix]"
  exit 1
}



#
# default parameters
#

infile=experimentList.tab
genome_assembly=hg19
bbdir=
infile_selected=
outprefix=

while getopts i:s:g:b:o: opt
do
  case ${opt} in
  i) infile=${OPTARG};;
  s) infile_selected=${OPTARG};;
  g) genome_assembly=${OPTARG};;
  b) bbdir=${OPTARG};;
  o) outprefix=${OPTARG};;
  *) usage;;
  esac
done

if [[ $infile_selected == "" ]];then
  infile_selected=experimentList_${genome_assembly}_selected.list
fi

if [[ $outprefix == "" ]];then
  outprefix=${genome_assembly}
fi

if [[ $bbdir == "" ]];then
  bbdir=experimentList_${genome_assembly}_bb
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
     gsub(" ","_",$4);
     gsub(" ","_",$5);
     gsub(" ","_",$6);
     print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
  }' \
> ${tmpdir}/selected.txt



for aClass in $(cat ${tmpdir}/selected.txt  | cut -f 3 -d '	' | sort | uniq  | head )
do

  printf "" > ${tmpdir}/one.bed

  cat ${tmpdir}/selected.txt | while read line ; do

    experiment_id=$(echo "$line" | cut -f 1 -d '	')
    genome_assembly=$(echo "$line" | cut -f 2 -d '	')
    antigen_class=$(echo "$line" | cut -f 3 -d '	')
    antigen=$(echo "$line" | cut -f 4 -d '	')
    cell_type=$(echo "$line" | cut -f 6 -d '	')
    bbfile=${bbdir}/${experiment_id}.05.bb

    if [[ $aClass != $antigen_class ]]; then
      continue
    fi

    bigBedToBed ${bbfile} /dev/stdout \
    | awk \
       --assign antigen=$antigen \
       --assign cell_type=$cell_type \
      'BEGIN{FS="\t";OFS="\t"}{
       name=antigen"@"cell_type;
       score=$4
       if ( score > 1000 ) {score = 1000}
       if ( score < 0 ) {score = 0}
       print $1,$2,$3,name,score
      }' \
    >> ${tmpdir}/one.bed

  done

  sort -k1,1 -k2,2n ${tmpdir}/one.bed > ${tmpdir}/one.sorted.bed

  bedToBigBed \
    ${tmpdir}/one.sorted.bed \
    chrom_sizes/${genome_assembly}.chrom_sizes  \
    ${tmpdir}/one.sorted.bb

  cp ${tmpdir}/one.sorted.bb ${outprefix}_${aClass}.bb

done




