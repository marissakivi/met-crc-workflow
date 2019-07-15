#!/bin/bash

#$ -M netid@nd.edu	# email address for job notification
#$ -m abe 		# send when job aborts, begins, and ends
#$ -pe smp 2 		# 'smp' if number is lower than 24
			# 'mpi-24' if greater than 24, 2 here is the number of 
			# cores being used (adjust as needed)
#$ -q long		# using long queue ... use 'long' for met stuff
#$ -N job_name		# job name for easy reference

module load R 		# this opens up the R module so it can read R scripts
module load netcdf/4.7.0/intel/18.0	# this module enables use of ncdf4 lib

R CMD BATCH ~/met/scripts/<script.name.R> output_file_name & 
R -e "markdown::render('myfile.Rmd')" &
