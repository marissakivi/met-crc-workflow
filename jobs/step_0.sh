#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 4
#$ -q long
#$ -N step_download

module load R
module load netcdf/4.7.0/intel/18.0
module load udunits
module load gdal 
module load geos

R CMD BATCH ~/met-crc-workflow/scripts/extra_scripts/download_rpackages.R output_download.out
