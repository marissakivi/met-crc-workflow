#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe 
#$ -pe smp 1
#$ -q long
#$ -N step3_bcc

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met-crc-workflow/scripts/STEP-3B-bcc-csm1-1.R  output_3_bcc.out
