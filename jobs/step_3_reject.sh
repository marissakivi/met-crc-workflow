#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N step3_reject

module load R
module load netcdf/4.7.0/intel/18.0
module load udunits
module load geos
module load gdal

R CMD BATCH ~/met-crc-workflow/scripts/STEP-3C-rejection.R  output_3_reject.out
~                                                                                    
