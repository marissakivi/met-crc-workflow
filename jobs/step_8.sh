#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1
#$ -q long
#$ -N test_8

module load R
module load netcdf/4.7.0/intel/18.0

RUN Rscript -e "rmarkdown::render('~/met/scripts/STEP-8-weights.Rmd')"  