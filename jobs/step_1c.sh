#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 2 
#$ -q long 
#$ -N step_1c

module load R
module load netcdf/4.7.0/intel/18.0
module load udunits
module load gdal
module load geos

R CMD BATCH ~/met-crc-workflow/scripts/STEP-1C-nldas_day.R output_1c.out
