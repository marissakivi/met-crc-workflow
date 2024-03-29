#!/bin/bash

#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N step3_models

module load R
module load netcdf/4.7.0/intel/18.0
module load udunits
module load geos
module load gdal

R CMD BATCH ~/met-crc-workflow/scripts/STEP-3A-models.R  output_3_models.out
