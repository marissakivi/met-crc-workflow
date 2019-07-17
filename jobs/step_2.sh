#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1 
#$ -q long 
#$ -N test

module load R
module load netcdf/4.7.0/intel/18.0

R CMD BATCH ~/met/scripts/STEP-2-debias.R  output_2.out
