#!/bin/sh

function usage()
{
  printf "usage: %s [-g genome_assembly] [-b base_url]\n"
  exit 1
}



genome_assembly=
base_url=


while getopts g:b: opt
do
  case ${opt} in
  g) genome_assembly=${OPTARG};;
  b) base_url=${OPTARG};;
  *) usage;;
  esac
done

if [[ $genome_assembly == "" ]];then
  usage
fi



cat <<EOF


track aggregated_peaks
shortLabel aggregated_peaks
longLabel aggregated_peaks
superTrack on


EOF



for X in *${genome_assembly}*.bb
do

  n=$(basename $X .bb)
  cat <<EOF


track $n
shortLabel $n
longLabel $n
type bigBed 5
maxItems 25000
spectrum on
bigDataUrl ${base_url}/$X
parent aggregated_peaks
url http://chip-atlas.org/


EOF
done

