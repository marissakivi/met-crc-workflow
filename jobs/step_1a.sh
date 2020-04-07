#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 4
#$ -q long
#$ -N step_1a

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met-crc-workflow/scripts/STEP-1A-cruncep.R output_1a.out
