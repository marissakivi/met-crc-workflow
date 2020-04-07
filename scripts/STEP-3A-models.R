####################
# Modeling Met Ensemble Workflow
# Step 3A :: Creation of met downscaling statistical models
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step combines the fifth, sixth, and seventh steps of Christy's met workflow, 
# which fits and stores the statistical models used to predict subdaily values from the daily ensembles, 
# applies the models to generate subdaily met ensembles, rejects and removes ensemble members containing 
# impossible values, and generates figures to visually check the quality of the predictions. 
# 
# Required functions: 
# - align_met.R (PEcAn) 
# - debias_met_regression.R (PEcAn)
# - tdm_generate_subdaily_models.R (PEcAn)
# - tdm_temporal_downscale_functions.R (PEcAn)
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
# - utils
# - stats

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################
wd.base <- "~/met-crc-workflow"

site.name = "BONANZA"
vers=".v1"

# this variable determines the span of years that will be formatted 
# depending on paleon site type 
first.year = 1800

####################
# Step 1: Set up working directory 
####################

# check for un-installed packages
if (!require('ncdf4',lib.loc='~/Rlibs')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('mgcv',lib.loc='~/Rlibs')) install.packages('mgcv',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('MASS',lib.loc='~/Rlibs')) install.packages('MASS',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('lubridate',lib.loc='~/Rlibs')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2',lib.loc='~/Rlibs')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('stringr',lib.loc='~/Rlibs')) install.packages('stringr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tictoc',lib.loc='~/Rlibs')) install.packages('tictoc',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('parallel',lib.loc='~/Rlibs')) install.packages('parallel',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('stats',lib.loc='~/Rlibs')) install.packages('stats',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('utils',lib.loc='~/Rlibs')) install.packages('utils',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

require(ncdf4, lib.loc='~/Rlibs')
require(mgcv, lib.loc='~/Rlibs')
require(MASS,lib.loc='~/Rlibs')
require(lubridate,lib='~/Rlibs')
require(ggplot2,lib.loc='~/Rlibs')
require(stringr,lib.loc='~/Rlibs')
require(tictoc,lib.loc='~/Rlibs')
require(parallel,lib.loc='~/Rlibs')
require(stats,lib.loc='~/Rlibs')
require(utils,lib.loc='~/Rlibs')

path.train <- file.path(wd.base, "data/paleon_sites", site.name, "NLDAS")
yrs.train=NULL

path.out <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/mods.tdm")
path.func <- file.path(wd.base,'functions')

fig.dir <- file.path(path.out, "model_qaqc")

if(!dir.exists(path.out)) dir.create(path.out, recursive = T)
if(!dir.exists(fig.dir)) dir.create(fig.dir, recursive = T)

# source necessary functions
source(file.path(path.func, "tdm_generate_subdaily_models.R"))
source(file.path(path.func, "tdm_temporal_downscale_functions.R"))
source(file.path(path.func, "tdm_model_train.R"))
source(file.path(path.func, "align_met.R"))
source(file.path(path.func, "tdm_predict_subdaily_met.R"))
source(file.path(path.func, "tdm_lm_ensemble_sims.R"))
source(file.path(path.func, "tdm_subdaily_pred.R"))

####################
# Step 2: Generate subdaily models
####################

gen.subdaily.models(outfolder=path.out, path.train=path.train,
                    yrs.train=NULL, direction.filter="backward", in.prefix=site.name,
                    n.beta=5000, day.window=7, seed=1026, resids = FALSE, 
                    parallel = FALSE, n.cores = NULL, overwrite = TRUE, verbose = FALSE, print.progress=TRUE) 

