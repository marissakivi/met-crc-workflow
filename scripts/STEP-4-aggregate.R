
####################
# Modeling Met Ensemble Workflow
# Step 4 :: Aggregate subdaily values to monthly 
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step is the eighth step of Christy's met workflow. It takes the subdaily values created in Step 3 
# and aggregates them to monthly resolution. 
# 
# Required functions: 
# - aggregate_met.R
# - aggregate_file.R
#
# Required libraries: 
# - parallel

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
wd.base = '~/met'
site.name = "NRP"
site.lat  = 42.84514
site.lon  = -72.4473
vers=".v1"

####################
# Step 1: Set up working directory
####################

if (!require('parallel')) install.packages('parallel',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('ncdf4')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('lubridate')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)

require(parallel,lib='~/Rlibs')
require(ncdf4,lib='~/Rlibs')
require(lubridate,lib='~/Rlibs')

path.func = file.path(wd.base,'functions')

source(file.path(path.func,"aggregate_met.R"))
source(file.path(path.func,"aggregate_file.R"))

in.base = file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/ensembles/")
out.base = file.path(wd.base, "ensembles", paste0(site.name, vers) ,"aggregated")

GCM.list <- dir(in.base)
for(GCM in GCM.list){
  print(GCM)
  gcm.ens <- dir(file.path(in.base, GCM))
  pb <- txtProgressBar(min=0, max=length(gcm.ens), style=3)
  pb.ind=1
  for(ens in gcm.ens){
    aggregate.met(path.in=file.path(in.base, GCM, ens), 
                  years.agg=NULL, save.day=F, save.month=T, 
                  out.base=out.base, day.dir=file.path("day", GCM, ens), mo.dir=file.path("month", GCM, ens), 
                  add.vars=c("daylength", "air_temperature_maximum", "air_temperature_minimum"),
                  parallel=F, n.cores=8, 
                  print.progress=F, verbose=FALSE)
    
    setTxtProgressBar(pb, pb.ind)
    pb.ind=pb.ind+1
  }
  print("")
}
