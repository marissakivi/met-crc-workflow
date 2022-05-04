#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N step4

module load R
module load netcdf/4.7.0/intel/18.0
module load udunits
module load gdal
module load geos

R CMD BATCH ~/met-crc-workflow/scripts/STEP-4-aggregate.R  output_4.out
