#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1 
#$ -q long 
#$ -N unzip

module load R

R CMD BATCH ~/met-crc-workflow/scripts/extra_scripts/unzip_hourly.R  output_unzip.out
