####################
# Modeling Met Ensemble Workflow
# Step 3B :: Prediction of sub-daily values for ccsm4 GCM
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This sub-step is the sixth step of Christy's met workflow, which predicts subdaily values from 
# the daily ensembles using hte models generated in the former step. 
# 
# Required functions: 
# - align_met.R (PEcAn) 
# - tdm_model_train.R (PEcAn)
# - tdm_predict_subdaily_met.R (PEcAn)
# - tdm_lm_ensemble_sims.R (PEcAn)
# - tdm_subdaily_pred.R (PEcAn)
# 
# Required libraries: 
# - ncdf4
# - mgcv
# - MASS
# - lubridate
# - ggplot2
# - stringr
# - tictoc
# - parallel

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

site.name = "HEMLOCK"
vers=".v1"

# this variable determines the span of years that will be formatted 
# depending on paleon site type 
first.year = 850

ens.hr  <- 2 # Number of hourly ensemble members to create
n.day <- 25 # Number of daily ensemble members to process

# working directory
wd.base = "~/met-crc-workflow"

####################
# Step 1: Set up working directory 
####################

# check for un-installed packages
if (!require('ncdf4')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('mgcv')) install.packages('mgcv',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('MASS')) install.packages('MASS',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('lubridate')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('ggplot2')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('stringr')) install.packages('stringr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('tictoc')) install.packages('tictoc',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('parallel')) install.packages('parallel',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)

require(ncdf4, lib='~/Rlibs')
require(mgcv, lib='~/Rlibs')
require(MASS,lib='~/Rlibs')
require(lubridate,lib='~/Rlibs')
require(ggplot2,lib='~/Rlibs')
require(stringr,lib='~/Rlibs')
require(tictoc,lib='~/Rlibs')
require(parallel,lib='~/Rlibs')

path.train <- file.path(wd.base, "data/paleon_sites", site.name, "NLDAS")
path.lm <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/mods.tdm")
path.in <- file.path(wd.base, "ensembles", paste0(site.name, vers), "day/ensembles")
path.out <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/ensembles")
path.func <- file.path(wd.base, "functions")

# set & create the output directory
if(!dir.exists(path.out)) dir.create(path.out, recursive=T)

yrs.plot <- c(2015, 1985, 1920, 1875, 1800)
timestep="1hr"
yrs.sim=NULL

# set up the appropriate seed
set.seed(0017)
seed.vec <- sample.int(1e6, size=500, replace=F)

# load required functions
source(file.path(path.func, "tdm_predict_subdaily_met.R"))
source(file.path(path.func, "tdm_lm_ensemble_sims.R"))
source(file.path(path.func, "align_met.R"))
source(file.path(path.func, "tdm_subdaily_pred.R"))
source(file.path(path.func, "tdm_predict_subdaily_met.R"))

####################
# Step 1: Apply the model for GCM
####################

GCM="CCSM4"

# Set the directory where the output is & load the file
path.gcm <- file.path(path.in, GCM)
out.ens <- file.path(path.out, GCM)

# Doing this one ensemble member at at time
# Figure out what's been done already
ens.done <- str_split(dir(out.ens), "[.]")
if(length(ens.done)>0) ens.done <- unique(matrix(unlist(ens.done), ncol=length(ens.done[[1]]), byrow = T)[,1])

# Figure out what we can pull from
gcm.members <- dir(path.gcm)
if(length(ens.done)>0) gcm.members <- gcm.members[!gcm.members %in% ens.done]
gcm.now <- sample(gcm.members, min(n.day, length(gcm.members)))

#if(parallel==TRUE){
#  mclapply(gcm.now, predict_subdaily_met, mc.cores=min(length(gcm.now), cores.max),
#           outfolder=out.ens, in.path=file.path(path.in, GCM), 
#           lm.models.base=path.lm, path.train=path.train, direction.filter="backward",
#           yrs.predict=yrs.sim, ens.labs=str_pad(1:ens.hr, width=2, pad="0"),
#           resids=F, force.sanity=TRUE, sanity.attempts=5, overwrite=F,
#           seed=seed.vec[length(ens.done)+1], print.progress=F)
#} else {
for(ens.now in gcm.now){
  predict_subdaily_met(outfolder=out.ens, in.path=file.path(path.in, GCM),
                       in.prefix=ens.now, lm.models.base=path.lm,
                       path.train=path.train, direction.filter="backward", yrs.predict=yrs.sim,
                       ens.labs = str_pad(1:ens.hr, width=2, pad="0"), resids = FALSE, force.sanity=TRUE, sanity.attempts=5,
                       overwrite = FALSE, seed=seed.vec[length(ens.done)+1], print.progress = TRUE)
}
#}
# }
