#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe 
#$ -pe smp 1
#$ -q long
#$ -N test_3_bcc

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met/scripts/STEP-3B-bcc.R  output_3_bcc.out