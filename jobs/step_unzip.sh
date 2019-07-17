#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1 
#$ -q long 
#$ -N unzip

module load R

R CMD BATCH ~/met/scripts/unzip_hourly.R  output_unzip.out
