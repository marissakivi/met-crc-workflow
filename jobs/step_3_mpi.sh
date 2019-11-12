#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 2
#$ -q long
#$ -N step3_mpi

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met-crc-workflow/scripts/STEP-3B-mpi-esm-p.R  output_3_mpi.out
