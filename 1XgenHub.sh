#!/bin/sh

infile_param=10params.list
outfile_hub=hub.txt
outfile_genomes=genomes.txt
outfile_qclog=qc.log


#
# prep
#
echo > $outfile_genomes

#
# hub
#
cat <<EOF > $outfile_hub
hub ChIP-Atlas(test)
shortLabel ChIP-Atlas(test)
longLabel ChIP-Atlas(test)
genomesFile genomes.txt
email foo@example.com
descriptionUrl http://chip-atlas.org/

EOF


rm -f ${outfile_qclog}
for genome_assembly in hg19 mm9 ce10 dm3 sacCer3
do

  #
  # genomes.txt
  #
  cat <<EOF  >> $outfile_genomes
genome ${genome_assembly}
trackDb trackDb_${genome_assembly}.txt

EOF

  #
  # QC
  #
  sh 11qcPlot_selection.sh $(grep ${genome_assembly} ${infile_param}) >> ${outfile_qclog}


  #
  # trackDb_XYZ.txt
  #
  sh 12trackDb.sh -g ${genome_assembly}  > trackDb_${genome_assembly}.txt
done


