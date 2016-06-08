#!/bin/sh

function usage()
{
  printf "usage: %s [-i infile] [-o outfile] [-p outfilePDF] [-g genome_assembly] [-d duplicate_ratio_max] [-m mapped_ratio_min] [-r read_number_min]\n\n", $(basename $0)
  exit 1
}

#
# default parameters
#
infile="experimentList.tab"
read_number_min="1e7"
mapped_ratio_min="80"
duplicate_ratio_max="20"
genome_assembly="hg19"
outfile=
outfilePDF=

while getopts i:o:p:g:d:m:r: opt
do
  case ${opt} in
  i) infile=${OPTARG};;
  o) outfile=${OPTARG};;
  p) outfilePDF=${OPTARG};;
  g) genome_assembly=${OPTARG};;
  d) duplicate_ratio_max=${OPTARG};;
  m) mapped_ratio_min=${OPTARG};;
  r) read_number_min=${OPTARG};;
  *) usage;;
  esac
done

if [[ $outfile == "" ]];then
  outfile=$(basename $infile .tab)_${genome_assembly}_selected.list
fi

if [[ $outfilePDF == "" ]];then
  outfilePDF=$(basename $infile .tab)_${genome_assembly}_selected.pdf
fi

#
# internal setup
#
tmpdir=$(mktemp -d -p ${TMPDIR:-/tmp})
trap "[[ $tmpdir ]] && rm -rf $tmpdir" 0 1 2 3 15

#
# prep
#
cat $infile \
| cut -f 1-8 \
> ${tmpdir}/col_1_8.txt



cat <<EOF | R --slave 

library(tidyr)
library(dplyr)
library(ggplot2)

# -----------------------
# subroutine
# -----------------------

# Overview of each statistics plots
qcPlot <- function(df)
{
  gg = ggplot(data = df) +
    geom_histogram( aes(read_number) ) + 
    geom_vline(xintercept = ${read_number_min} , colour = "blue") +
    scale_x_log10()
  print(gg)

  gg = ggplot(data = df) +
    geom_histogram( aes(mapped_ratio) )  +
    geom_vline(xintercept = ${mapped_ratio_min} , colour = "blue" )
  print(gg)

  gg = ggplot(data = df) +
    geom_histogram( aes(duplicate_ratio) ) +
    geom_vline(xintercept = ${duplicate_ratio_max} , colour = "blue")
  print(gg)

  gg = ggplot(data = df) +
    geom_histogram( aes(peak_number) )
  print(gg)
}



# assign headers, based on https://github.com/inutano/chip-atlas/wiki#experimentList_schema
# (would be ideal if the original file could include the headers directly)
reshape_1_8 <- function(df)
{
  header = "
    Experimental_ID
    Genome_assembly
    Antigen_class
    Antigen
    Cell_type_class
    Cell_type
    Cell_type_description
    Processing_logs
"
  colnames(df) =
    read.table(textConnection(header))[,1]

  tmp = sapply(
    df[,"Processing_logs"] ,
    function(str) strsplit(str, ",")[[1]]
  ) %>% t

  df = cbind(
    df ,
    read_number = as.numeric(tmp[,1]) ,
    mapped_ratio = as.numeric(tmp[,2]) ,
    duplicate_ratio = as.numeric(tmp[,3]),
    peak_number = as.numeric(tmp[,4])
  )
  return(df)
}




#
# main
#

pdf("${outfilePDF}",height=5,width=10)
df = read.table("${tmpdir}/col_1_8.txt",sep="\t",as.is=T)
df = reshape_1_8(df)

# limit targets
dfAll =
  df %>%
  filter(Genome_assembly == "${genome_assembly}")

# QC plot for overview
qcPlot(dfAll)

# select experiments
dfSelected =
  dfAll %>%
  filter(read_number > ${read_number_min} ) %>%
  filter(mapped_ratio > ${mapped_ratio_min} ) %>%
  filter(duplicate_ratio < ${duplicate_ratio_max} )

# selection results
summary = merge(
  dfAll      %>% select( Antigen_class ) %>% table ,
  dfSelected %>% select( Antigen_class ) %>% table ,
  by = 1
)
colnames( summary ) = c("Antigen_class_${genome_assembly}", "all", "selected")
summary

# output selected list
write.table( dfSelected[,1] , row.names=F, quote=F, col.names=F, file="${outfile}")


EOF

