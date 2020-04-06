#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 4 
#$ -q long 
#$ -N step1b

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met-crc-workflow/scripts/STEP-1B-nldas_day.R output_1b.out
