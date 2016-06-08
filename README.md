160609-ChIP-atlas-datahub
==========================
Test implementation of data hub for [ChIP-atlas](http://chip-atlas.org/)

How to run
--------

preparation (get file list):

  % sh 10getList.sh

generate configuration for individual tracks:

  % sh 1XgenHub.sh   

obtain peak (bigBed) files:

  % sh 20getBb.sh 

generate an aggregated peak file

  % sh 21aggregateBb.sh

generate additional entries to the data hub configuration.

  % sh 22addTrackDb.sh
