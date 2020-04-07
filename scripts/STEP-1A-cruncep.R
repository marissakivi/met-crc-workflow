####################
# Modeling Met Ensemble Workflow
# Step 1A :: Extraction of site-specific CRUNCEP data
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step contains a modified version of Christy Rollinson's site-specific data extraction script. 
# Since CRUNCEP is the only dataset that does not require the large raw grid files on the external hard drive, it is
# the only dataset that can be extracted on the CRC. Due to permission issues on the CRC, several workarounds were added to 
# this script in order to allow the download of the UDUNITS2 package. 

rm(list=ls())

## ADJUST VARIABLES HERE FOR SITE 
site.name = 'BONANZA'
site.lat = 45.45283
site.lon = -96.7144

wd.base = '~/met-crc-workflow/'
# adjust CRC username so that the script finds the correct Rlibs folder
#user = 'mkivi' 
##

#first = substr(user,1,1)

#if (!require('tibble', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('tibble',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('ncdf4', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('ncdf4',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('ggplot2', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('ggplot2',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('lubridate', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('lubridate',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('utils', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('utils',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('glue', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('glue',lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),repos='http://cran.us.r-project.org',dependencies=TRUE)

#Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv("LD_LIBRARY_PATH"), ":","/afs/crc.nd.edu/user/",first,"/",user,"/Rlibs/udunits/local/lib"))
#if (!require('udunits2', lib.loc = paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'))) install.packages('udunits2',type = 'source',repos = "http://cran.rstudio.com",lib=paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs'),dependencies=TRUE, configure.args=paste0('--with-udunits2-lib=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/udunits/local/lib --with-udunits2-include=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/udunits/local/include'))
#dyn.load(paste0("/afs/crc.nd.edu/user/",first,"/:",user,"/Rlibs/udunits/local/lib/libudunits2.so.0"))

require(ncdf4, lib.loc='~/Rlibs')
require(ggplot2, lib.loc='~/Rlibs')
require(lubridate, lib.loc='~/Rlibs')
require(utils, lib.loc='~/Rlibs')
require(tibble, lib.loc='~/Rlibs')
require(glue, lib.loc='~/Rlibs')
require(udunits2, lib.loc='~/Rlibs')

path.out = file.path(wd.base, 'data','paleon_sites',site.name)
path.pecan = file.path(wd.base,'functions')

source(file.path(path.pecan, 'download.CRUNCEP_Global.R'))
download.CRUNCEP(outfolder=file.path(path.out, "CRUNCEP"), 
                 start_date="1901-01-01", end_date="2010-12-31", 
                 site_id=site.name, lat.in=site.lat, lon.in=site.lon)
