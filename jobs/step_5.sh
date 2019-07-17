#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N test_5

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met/scripts/STEP-5-pdsi.R  output_5.out
