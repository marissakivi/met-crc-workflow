#!/bin/bash
#$ -M mkivi@nd.edu
#$ -m abe
#$ -pe smp 1 
#$ -q long 
#$ -N step9

module load R

R CMD BATCH ~/met-crc-workflow/scripts/STEP-9-clean.R  output_step9.out

