#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N step7

module load R
module load netcdf/4.7.0/intel/18.0
module load gdal/3.0.0/gcc/4.8.5 
module load geos
module load udunits

R CMD BATCH ~/met-crc-workflow/scripts/STEP-7-prism.R  output_7.out
