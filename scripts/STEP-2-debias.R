
####################
# Modeling Met Ensemble Workflow
# Step 2 :: Bias correction, bad ensemble rejection, and visual check 
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step combines the third and fourth steps of Christy's met workflow, 
# which correct for bias through the generation of daily ensembles using the three different 
# met data sources, reject ensemble members with unlikely values, and generate visual checks of the data. 
# 
# Required functions: 
# - align_met.R (PEcAn) 
# - debias_met_regression.R (PEcAn)
# 
# Required libraries: 
# - ncdf4
# - mgcv
# - ggplot2
# - stringr
# - lubridate

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
wd.base = '~/met'
site.name = "HARVARD"
site.lat  = 42.53
site.lon  = -72.18
vers=".v1"
ens=1:10

# this should be adjusted depending on the site type (short or long) 
first.year = 850 

####################
# Step 1: Set up working directory
####################

# install missing libraries in Rlibs folder on account if not already installed 
if (!require('ncdf4')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('ggplot2')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('mgcv')) install.packages('mgcv',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('stringr')) install.packages('stringr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('lubridate')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)

require(ncdf4,lib='~/Rlibs')
require(ggplot2,lib='~/Rlibs')
require(mgcv,lib='~/Rlibs')
require(stringr,lib='~/Rlibs')
require(lubridate,lib='~/Rlibs')

# Setting some important file paths
path.func <- file.path(wd.base,'functions')
path.in <- file.path(wd.base,'data/paleon_sites')
path.out <- file.path(wd.base,'ensembles')

# Set seed variable for repoducibility
sd = 1159

# Source necessary functions
source(file.path(path.func,"align_met.R"))
source(file.path(path.func,"debias_met_regression.R"))

####################
# Step 2: Bias-correction to generate smooth daily met ensembles 
# The end state of this step is continuous, smooth daily output from 850-2010+. The workflow of this step has three main bias-correction steps: 

#  1. Debias CRUNCEP data (1 series) using NLDAS training set (1 series) => saves 1901-1979
#  2. Debias GCM historical runs (1 series) using CRUNCEP (n.ens series) => saves 1850-1901
#  3. Debias GCM past millenium (1 series) using GCM historical (n.ens series) => saves 850-1849
  
# The daily ensembles are saved in: <wd.base>/ensembles/<site.name,vers>/day. 
####################

GCM.list=c("MIROC-ESM","MPI-ESM-P", "bcc-csm1-1", "CCSM4")
n.ens=length(ens)
ens.mems=str_pad(ens, 3, "left", pad=0)

# Set up the appropriate seeds to use when adding ensembles
set.seed(sd)
seed.vec <- sample.int(1e6, size=500, replace=F)
seed <- seed.vec[min(ens)] 
# This makes sure that if we add ensemble members, it gets a new, but reproducible seed

# Setting up file structure
out.base <- file.path(wd.base, "ensembles", paste0(site.name, vers), "day")
raw.base <- file.path(path.in,site.name)

# -----------------------------------
# Run a loop to do all of the downscaling steps for each GCM and put in one place
# -----------------------------------

for(GCM in GCM.list){
  ens.ID=GCM
  
  # Set up a file path for our ensemble to work with now
  train.path <- file.path(out.base, "ensembles", GCM)
  dir.create(train.path, recursive=T, showWarnings=F)
  
  # --------------------------
  # Set up ensemble structure; copy LDAS into ensemble directories
  # --------------------------

  files.ldas <- dir(file.path(raw.base, "NLDAS_day"))

  for(i in 1:n.ens){
    # Create a directory for each ensemble member
    path.ens <- file.path(train.path, paste(ens.ID, ens.mems[i], sep="_"))
    dir.create(path.ens, recursive=T, showWarnings=F)
  
    # Copy LDAS in there with the new name
    for(j in 1:length(files.ldas)){
      yr <- strsplit(files.ldas[j], "[.]")[[1]][2]
      name.new <- paste(ens.ID, ens.mems[i], yr, "nc", sep=".")
      cmd.call <- paste("cp", file.path(raw.base, "NLDAS_day", files.ldas[j]), 
                      file.path(path.ens, name.new), sep=" ")
      system(cmd.call)
    }
  }

  # --------------------------
  # Step 1 :: Debias CRUNCEP using LDAS 
  # --------------------------
  # 1. Align CRU 6-hourly with LDAS daily
  source.path <- file.path(raw.base, "CRUNCEP")

  # We're now pulling an ensemble because we've set up the file paths and copied LDAS over 
  # (even though all ensemble members will be identical here)
  met.out <- align.met(train.path, source.path, yrs.train=NULL, yrs.source=NULL, n.ens=n.ens, seed=201708, 
                     pair.mems = FALSE, mems.train=paste(ens.ID, ens.mems, sep="_"))

  # Calculate wind speed if it's not already there
  if(!"wind_speed" %in% names(met.out$dat.source)){
    met.out$dat.source$wind_speed <- sqrt(met.out$dat.source$eastward_wind^2 + met.out$dat.source$northward_wind^2)
  }

  # 2. Pass the training & source met data into the bias-correction functions; this will get written to the ensemble
  debias.met.regression(train.data=met.out$dat.train, source.data=met.out$dat.source, n.ens=10, 
                        vars.debias=NULL, CRUNCEP=TRUE, pair.anoms = TRUE, pair.ens = FALSE, 
                        uncert.prop="mean", resids = FALSE, seed=Sys.Date(), outfolder=train.path, 
                        yrs.save=NULL, ens.name=ens.ID, ens.mems=ens.mems, lat.in=site.lat, lon.in=site.lon,
                        save.diagnostics=TRUE, path.diagnostics=file.path(out.base, "bias_correct_qaqc_CRU"),
                        parallel = FALSE, n.cores = NULL, overwrite = TRUE, verbose = FALSE) 

  # --------------------------
  # Step 2 :: Debias GCM historical runs using CRUNCEP
  # --------------------------
  # 1. Align GCM daily with our current ensemble
  source.path <- file.path(raw.base, GCM, "historical")

  # We're now pulling an ensemble because we've set up the file paths and copied LDAS over 
  # (even though all ensemble members will be identical here)

  met.out <- align.met(train.path, source.path, yrs.train=1901:1920, n.ens=n.ens, seed=201708, 
                      pair.mems = FALSE, mems.train=paste(ens.ID, ens.mems, sep="_"))

  # Calculate wind speed if it's not already there
  if(!"wind_speed" %in% names(met.out$dat.source)){
   met.out$dat.source$wind_speed <- sqrt(met.out$dat.source$eastward_wind^2 + met.out$dat.source$northward_wind^2)
  }

  # With MIROC-ESM, running into problem with NAs in 2005, so lets cut it all at 2000
  for(v in names(met.out$dat.source)){
    if(v=="time") next
    met.out$dat.source[[v]] <- matrix(met.out$dat.source[[v]][which(met.out$dat.source$time$Year<=2000),], ncol=ncol(met.out$dat.source[[v]]))
  }
  met.out$dat.source$time <- met.out$dat.source$time[met.out$dat.source$time$Year<=2000,]

  # 2. Pass the training & source met data into the bias-correction functions; this will get written to the ensemble
  debias.met.regression(train.data=met.out$dat.train, source.data=met.out$dat.source, n.ens=10, 
                        vars.debias=NULL, CRUNCEP=FALSE, pair.anoms = FALSE, pair.ens = FALSE, 
                        uncert.prop="mean", resids = FALSE, seed=Sys.Date(),outfolder=train.path, 
                        yrs.save=1850:1900, ens.name=ens.ID, ens.mems=ens.mems, lat.in=site.lat, 
                        lon.in=site.lon, save.diagnostics=TRUE, 
                        path.diagnostics=file.path(out.base, paste0("bias_correct_qaqc_",GCM,"_hist")),
                        parallel = FALSE, n.cores = NULL, overwrite = TRUE, verbose = FALSE) 

  #  --------------------------
  #  Step 3 :: Debias GCM past millennium using GCM Historical
  # --------------------------
  # 1. Align GCM daily with our current ensemble
  source.path <- file.path(raw.base, GCM, "p1000")

  # We're now pulling an ensemble because we've set up the file paths and copied LDAS over 
  # (even though all ensemble members will be identical here)

  met.out <- align.met(train.path, source.path, yrs.train=1850:1900, yrs.source=first.year:1849, n.ens=n.ens, 
                      seed=201708, pair.mems = FALSE, mems.train=paste(ens.ID, ens.mems, sep="_"))

  # Calculate wind speed if it's not already there
  if(!"wind_speed" %in% names(met.out$dat.source)){
    met.out$dat.source$wind_speed <- sqrt(met.out$dat.source$eastward_wind^2 + met.out$dat.source$northward_wind^2)
  }

  # 2. Pass the training & source met data into the bias-correction functions; this will get written to the ensemble
  debias.met.regression(train.data=met.out$dat.train, source.data=met.out$dat.source, n.ens=10, 
                        vars.debias=NULL, CRUNCEP=FALSE, pair.anoms = FALSE, pair.ens = FALSE, 
                        uncert.prop="mean", resids = FALSE, seed=Sys.Date(),
                        outfolder=train.path, yrs.save=NULL, ens.name=ens.ID, ens.mems=ens.mems, 
                        lat.in=site.lat, lon.in=site.lon, save.diagnostics=TRUE, 
                        path.diagnostics=file.path(out.base, paste0("bias_correct_qaqc_",GCM,"_p1000")),
                        parallel = FALSE, n.cores = NULL, overwrite = TRUE, verbose = FALSE) 

}

####################
# Step 3: Reject bad, outlying ensemble members 
# This step removes ensemble members which contain impossible or unlikely values (i.e. values that fall far outside the distributon of values). It moves the bad ensembles to  <wd.base>/ensembles/<site.name,vers>/day/rejected where they will not be considered for future steps. 
####################

# set up path to good and bad ensembles
path.dat <- file.path(wd.base, "ensembles", paste0(site.name, vers), "day/ensembles/")
path.bad <- file.path(wd.base, "ensembles", paste0(site.name, vers), "day/rejected/")
if(!dir.exists(path.bad)) dir.create(path.bad, recursive = T)

# -----------------------------------
# Get list of GCM and ensemble members and set up data array
# -----------------------------------
GCM.list <- dir(path.dat)

ens.mems <- vector()
n.files <- 0
var.names <- vector()
for(GCM in GCM.list){
  ens.now <- dir(file.path(path.dat, GCM))
  ens.mems <- c(ens.mems, ens.now)
  
  files.now <- dir(file.path(path.dat, GCM, ens.now[1]))
  n.files <- max(n.files, length(files.now))
  
  ncT <- ncdf4::nc_open(file.path(path.dat, GCM, ens.now[1], files.now[1]))
  var.names <- names(ncT$var)
  ncdf4::nc_close(ncT)
}

# Set up a blank array to store everything in
dat.summary <- array(dim=c(n.files, length(var.names), 2, length(ens.mems))) 
# dim[3] == 2 so we can store min/max
dimnames(dat.summary)[[1]] <- seq(1800, length.out=n.files, by=1)
dimnames(dat.summary)[[2]] <- var.names
dimnames(dat.summary)[[3]] <- c("yr.min", "yr.max")
dimnames(dat.summary)[[4]] <- ens.mems
names(dimnames(dat.summary)) <- c("Year", "Var", "max.min", "ensemble.member")
summary(dimnames(dat.summary))

# Loop through and get the summary stats
pb <- txtProgressBar(min=0, max=dim(dat.summary)[1]*dim(dat.summary)[2]*dim(dat.summary)[4], style=3)
pb.ind=1

for(GCM in 1:length(GCM.list)){
  ens.gcm <- dir(file.path(path.dat, GCM.list[GCM]))
  
  for(ens in 1:length(ens.gcm)){
    ens.ind <- which(ens.mems == ens.gcm[ens])
    
    f.all <- dir(file.path(path.dat, GCM.list[GCM], ens.gcm[ens]))
    
    for(fnow in 1:length(f.all)){
      ncT <- ncdf4::nc_open(file.path(path.dat, GCM.list[GCM], ens.gcm[ens], f.all[fnow]))
      
      for(v in 1:length(var.names)){
        dat.summary[fnow,v,1,ens.ind] <- min(ncdf4::ncvar_get(ncT, var.names[v]))
        dat.summary[fnow,v,2,ens.ind] <- max(ncdf4::ncvar_get(ncT, var.names[v]))
        
        setTxtProgressBar(pb, pb.ind)
        pb.ind <- pb.ind+1
      }
      
      ncdf4::nc_close(ncT)
    }
  }
}

# -----------------------------------
# Filter and identify outliers
# -----------------------------------
ens.bad <- array(dim=c(n.files, length(ens.mems)))
dimnames(ens.bad)[[1]] <- dimnames(dat.summary)[[1]]
dimnames(ens.bad)[[2]] <- dimnames(dat.summary)[[4]]

sum.means <- apply(dat.summary[,,,], c(1, 2, 3), FUN=mean)
sum.sd    <- apply(dat.summary[,,,], c(1, 2, 3), FUN=sd)

for(i in 1:nrow(ens.bad)){
  for(j in 1:ncol(ens.bad)){
    vars.bad <- dat.summary[i,,1,j] < sum.means[i,,1] - 6*sum.sd[i,,1] | dat.summary[i,,2,j] > sum.means[i,,2] + 6*sum.sd[i,,2]
    if(any(vars.bad)){
      ens.bad[i,j] <- length(which(vars.bad==T))
    }
  }
}

# Summarizing bad ensembles 
yrs.bad <- apply(ens.bad, 1, sum, na.rm=T)
summary(yrs.bad)

mems.bad <- apply(ens.bad, 2, sum, na.rm=T)
length(which(mems.bad==0))/length(mems.bad)
summary(mems.bad)

quantile(mems.bad, 0.90)

# -----------------------------------
# Move the bad ensemble members
# -----------------------------------
mems.bad[mems.bad>0]

for(mem in names(mems.bad[mems.bad>0])){
  GCM <- stringr::str_split(mem, "_")[[1]][1]
  system(paste("mv", file.path(path.dat, GCM, mem), file.path(path.bad, mem), sep=" "))
}

#Step 4: Generate figures to visually check debiased data 

#This step generates QAQC for generated ensembles. These figures should be checked to ensure that the means and variances look more or less OK. 

# variables to maintain: wd.base, path.func, site.name, vers, site.lat, site.lon, align.met function, 

GCM.list <- c("bcc-csm1-1", "CCSM4", "MIROC-ESM", "MPI-ESM-P")
#GCM.list <- c("MIROC-ESM")

# Setting up some file paths, etc
path.raw.base <- file.path(wd.base, "data/paleon_sites", site.name)
path.day.base <- file.path(wd.base, "ensembles", paste0(site.name, vers), "day")

# defining some variable names
vars.CF <- c("air_temperature_minimum", "air_temperature_maximum", "precipitation_flux", 
             "surface_downwelling_shortwave_flux_in_air", "surface_downwelling_longwave_flux_in_air", 
             "air_pressure", "specific_humidity", "wind_speed")
vars.short <- c("tair.min", "tair.max", "precip", "swdown", "lwdown", "press", "qair", "wind")

# -----------------------------------
# 1. Read in met data
# -----------------------------------
# Use the align.met funciton to get everything harmonized
#source("~/Desktop/pecan/modules/data.atmosphere/R/align_met.R")

# ---------
# 1.1. Raw Data
# ---------
# Do this once with NLDAS and CRUNCEP
met.base <- align.met(train.path=file.path(path.raw.base, "NLDAS_day"), 
                      source.path = file.path(path.raw.base, "CRUNCEP"), n.ens=1, seed=20170905)

met.raw <- data.frame(met.base$dat.train$time)
met.raw$dataset <- "NLDAS"
met.raw$tair.min <- met.base$dat.train$air_temperature_minimum[,1]
met.raw$tair.max <- met.base$dat.train$air_temperature_maximum[,1]
met.raw$precip   <- met.base$dat.train$precipitation_flux[,1]
met.raw$swdown   <- met.base$dat.train$surface_downwelling_shortwave_flux_in_air[,1]
met.raw$lwdown   <- met.base$dat.train$surface_downwelling_longwave_flux_in_air[,1]
met.raw$press    <- met.base$dat.train$air_pressure[,1]
met.raw$qair     <- met.base$dat.train$specific_humidity[,1]
met.raw$wind     <- met.base$dat.train$wind_speed[,1]

met.tmp <- data.frame(met.base$dat.source$time)
met.tmp$dataset <- "CRUNCEP"
met.tmp$tair.min <- met.base$dat.source$air_temperature_minimum[,1]
met.tmp$tair.max <- met.base$dat.source$air_temperature_maximum[,1]
met.tmp$precip   <- met.base$dat.source$precipitation_flux[,1]
met.tmp$swdown   <- met.base$dat.source$surface_downwelling_shortwave_flux_in_air[,1]
met.tmp$lwdown   <- met.base$dat.source$surface_downwelling_longwave_flux_in_air[,1]
met.tmp$press    <- met.base$dat.source$air_pressure[,1]
met.tmp$qair     <- met.base$dat.source$specific_humidity[,1]
met.tmp$wind     <- sqrt(met.base$dat.source$eastward_wind[,1]^2 + met.base$dat.source$northward_wind[,1]^2)

met.raw <- rbind(met.raw, met.tmp)

# Loop through the GCMs to extract
for(GCM in GCM.list){
  for(experiment in c("historical", "p1000")){
    if(experiment == "p1000"){
      met.base <- align.met(train.path=file.path(path.raw.base, "NLDAS_day"), 
                            source.path = file.path(path.raw.base, GCM, experiment), yrs.source=1800:1849, 
                            n.ens=1, seed=20170905, pair.mems = FALSE)
    } else {
      met.base <- align.met(train.path=file.path(path.raw.base, "NLDAS_day"), 
                            source.path = file.path(path.raw.base, GCM, experiment), yrs.source=NULL, n.ens=1, 
                            seed=20170905, pair.mems = FALSE)
    }
    
    met.tmp <- data.frame(met.base$dat.source$time)
    met.tmp$dataset <- paste(GCM, experiment, sep=".")
    met.tmp$tair.min <- met.base$dat.source$air_temperature_minimum[,1]
    met.tmp$tair.max <- met.base$dat.source$air_temperature_maximum[,1]
    met.tmp$precip   <- met.base$dat.source$precipitation_flux[,1]
    met.tmp$swdown   <- met.base$dat.source$surface_downwelling_shortwave_flux_in_air[,1]
    met.tmp$lwdown   <- met.base$dat.source$surface_downwelling_longwave_flux_in_air[,1]
    met.tmp$press    <- met.base$dat.source$air_pressure[,1]
    met.tmp$qair     <- met.base$dat.source$specific_humidity[,1]
    if("wind_speed" %in% names(met.base$dat.source)){
      met.tmp$wind     <- met.base$dat.source$wind_speed[,1]
    } else {
      met.tmp$wind     <- sqrt(met.base$dat.source$eastward_wind[,1]^2 + met.base$dat.source$northward_wind[,1]^2)
    }
    
    met.raw <- rbind(met.raw, met.tmp)
  } # End experiment loop
} # end GCM loop

# ---------
# 1.2. Bias-Corrected data
# ---------

met.bias <- list()
for(GCM in GCM.list){
  print(GCM)
  met.base <- align.met(train.path=file.path(path.raw.base, "NLDAS_day"), 
                        source.path = file.path(path.day.base, "ensembles", GCM), n.ens=10, pair.mems=FALSE, 
                        seed=201709)
  
  met.tmp <- list()
  met.tmp$mean <- data.frame(met.base$dat.source$time)
  met.tmp$mean$dataset <- GCM
  met.tmp$mean$tair.min <- apply(met.base$dat.source$air_temperature_minimum, 1, mean, na.rm=T)
  met.tmp$mean$tair.max <- apply(met.base$dat.source$air_temperature_maximum, 1, mean, na.rm=T)
  met.tmp$mean$precip   <- apply(met.base$dat.source$precipitation_flux     , 1, mean, na.rm=T)
  met.tmp$mean$swdown   <- apply(met.base$dat.source$surface_downwelling_shortwave_flux_in_air, 1, mean, 
                                 na.rm=T)
  met.tmp$mean$lwdown   <- apply(met.base$dat.source$surface_downwelling_longwave_flux_in_air , 1, mean, 
                                 na.rm=T)
  met.tmp$mean$press    <- apply(met.base$dat.source$air_pressure           , 1, mean, na.rm=T)
  met.tmp$mean$qair     <- apply(met.base$dat.source$specific_humidity      , 1, mean, na.rm=T)
  met.tmp$mean$wind     <- apply(met.base$dat.source$wind_speed             , 1, mean, na.rm=T)
  
  met.tmp$lwr <- data.frame(met.base$dat.source$time)
  met.tmp$lwr$dataset <- GCM
  met.tmp$lwr$tair.min <- apply(met.base$dat.source$air_temperature_minimum, 1, quantile, 0.025, na.rm=T)
  met.tmp$lwr$tair.max <- apply(met.base$dat.source$air_temperature_maximum, 1, quantile, 0.025, na.rm=T)
  met.tmp$lwr$precip   <- apply(met.base$dat.source$precipitation_flux     , 1, quantile, 0.025, na.rm=T)
  met.tmp$lwr$swdown   <- apply(met.base$dat.source$surface_downwelling_shortwave_flux_in_air, 1, quantile, 
                                0.025, na.rm=T)
  met.tmp$lwr$lwdown   <- apply(met.base$dat.source$surface_downwelling_longwave_flux_in_air , 1, quantile, 
                                0.025, na.rm=T)
  met.tmp$lwr$press    <- apply(met.base$dat.source$air_pressure           , 1, quantile, 0.025, na.rm=T)
  met.tmp$lwr$qair     <- apply(met.base$dat.source$specific_humidity      , 1, quantile, 0.025, na.rm=T)
  met.tmp$lwr$wind     <- apply(met.base$dat.source$wind_speed             , 1, quantile, 0.025, na.rm=T)
  
  
  met.tmp$upr <- data.frame(met.base$dat.source$time)
  met.tmp$upr$dataset <- GCM
  met.tmp$upr$tair.min <- apply(met.base$dat.source$air_temperature_minimum, 1, quantile, 0.975, na.rm=T)
  met.tmp$upr$tair.max <- apply(met.base$dat.source$air_temperature_maximum, 1, quantile, 0.975, na.rm=T)
  met.tmp$upr$precip   <- apply(met.base$dat.source$precipitation_flux     , 1, quantile, 0.975, na.rm=T)
  met.tmp$upr$swdown   <- apply(met.base$dat.source$surface_downwelling_shortwave_flux_in_air, 1, quantile, 
                                0.975, na.rm=T)
  met.tmp$upr$lwdown   <- apply(met.base$dat.source$surface_downwelling_longwave_flux_in_air, 1, quantile, 
                                0.975, na.rm=T)
  met.tmp$upr$press    <- apply(met.base$dat.source$air_pressure           , 1, quantile, 0.975, na.rm=T)
  met.tmp$upr$qair     <- apply(met.base$dat.source$specific_humidity      , 1, quantile, 0.975, na.rm=T)
  met.tmp$upr$wind     <- apply(met.base$dat.source$wind_speed             , 1, quantile, 0.975, na.rm=T)
  
  if(length(met.bias)==0){
    met.bias <- met.tmp
  } else {
    met.bias$mean <- rbind(met.bias$mean, met.tmp$mean)
    met.bias$lwr  <- rbind(met.bias$lwr , met.tmp$lwr )
    met.bias$upr  <- rbind(met.bias$upr , met.tmp$upr )
  }
}

# -----------------------------------
# 2. QAQC graphing
# -----------------------------------
met.bias.yr.mean <- aggregate(met.bias$mean[,vars.short], by=met.bias$mean[,c("Year", "dataset")], FUN=mean)
met.bias.yr.lwr  <- aggregate(met.bias$lwr [,vars.short], by=met.bias$lwr [,c("Year", "dataset")], FUN=mean)
met.bias.yr.upr  <- aggregate(met.bias$upr [,vars.short], by=met.bias$upr [,c("Year", "dataset")], FUN=mean)
summary(met.bias.yr.mean)

# Stacking everything together
met.bias.yr <- stack(met.bias.yr.mean[,vars.short])
names(met.bias.yr) <- c("mean", "met.var")
met.bias.yr[,c("Year", "dataset")] <- met.bias.yr.mean[,c("Year", "dataset")]
met.bias.yr$lwr <- stack(met.bias.yr.lwr[,vars.short])[,1]
met.bias.yr$upr <- stack(met.bias.yr.upr[,vars.short])[,1]
summary(met.bias.yr)

# Raw met
met.raw.yr1 <- aggregate(met.raw[,vars.short], by=met.raw[,c("Year", "dataset")], FUN=mean)
met.raw.yr1$dataset2 <- as.factor(met.raw.yr1$dataset)
for(i in 1:nrow(met.raw.yr1)){
  met.raw.yr1[i,"dataset"] <- stringr::str_split(met.raw.yr1[i,"dataset2"], "[.]")[[1]][1]
}
met.raw.yr1$dataset <- as.factor(met.raw.yr1$dataset)
summary(met.raw.yr1)

met.raw.yr <- stack(met.raw.yr1[,vars.short])
names(met.raw.yr) <- c("raw", "met.var")
met.raw.yr[,c("Year", "dataset", "dataset2")] <- met.raw.yr1[,c("Year", "dataset", "dataset2")]
summary(met.raw.yr)

png(file.path(path.day.base, "Raw_Annual.png"), height=8, width=10, units="in", res=220)
print(
  ggplot(data=met.raw.yr[,]) + facet_wrap(~met.var, scales="free_y") +
    geom_path(aes(x=Year, y=raw, color=dataset, group=dataset2), size=0.5) +
    geom_vline(xintercept=c(1850, 1901, 2010), linetype="dashed") +
    scale_x_continuous(expand=c(0,0)) +
    theme_bw()
)
dev.off()

png(file.path(path.day.base, "Debias_Annual.png"), height=8, width=10, units="in", res=220)
print(
  ggplot(data=met.bias.yr[, ]) + facet_wrap(~met.var, scales="free_y") +
    geom_ribbon(aes(x=Year, ymin=lwr, ymax=upr, fill=dataset), alpha=0.5) +
    geom_path(aes(x=Year, y=mean, color=dataset), size=0.5) +
    geom_vline(xintercept=c(1850, 1901, 2010), linetype="dashed") +
    scale_x_continuous(expand=c(0,0)) +
    theme_bw()
)
dev.off()

# Save the summaries of the raw and bias-corrected data to quickly make some customized graphs elsewhere
write.csv(met.raw.yr, file.path(path.day.base, "Met_Raw_Annual.csv"      ), row.names=F)
write.csv(met.bias.yr, file.path(path.day.base, "Met_Corrected_Annual.csv"), row.names=F)

# Looking at the seasonal cycle
met.bias.doy.mean <- aggregate(met.bias$mean[,vars.short], by=met.bias$mean[,c("DOY", "dataset")], FUN=mean, 
                               na.rm=T)
met.bias.doy.lwr  <- aggregate(met.bias$lwr [,vars.short], by=met.bias$lwr [,c("DOY", "dataset")], FUN=mean, 
                               na.rm=T)
met.bias.doy.upr  <- aggregate(met.bias$upr [,vars.short], by=met.bias$upr [,c("DOY", "dataset")], FUN=mean, 
                               na.rm=T)
summary(met.bias.doy.mean)

# Stacking everything together
met.bias.doy <- stack(met.bias.doy.mean[,vars.short])
names(met.bias.doy) <- c("mean", "met.var")
met.bias.doy[,c("DOY", "dataset")] <- met.bias.doy.mean[,c("DOY", "dataset")]
met.bias.doy$lwr <- stack(met.bias.doy.lwr[,vars.short])[,1]
met.bias.doy$upr <- stack(met.bias.doy.upr[,vars.short])[,1]
summary(met.bias.doy)

# met.raw$dataset <- as.character(met.raw$dataset2)
met.raw.doy1 <- aggregate(met.raw[,vars.short], by=met.raw[,c("DOY", "dataset")], FUN=mean, na.rm=T)
met.raw.doy1$dataset2 <- as.factor(met.raw.doy1$dataset)
for(i in 1:nrow(met.raw.doy1)){
  met.raw.doy1[i,"dataset"] <- stringr::str_split(met.raw.doy1[i,"dataset2"], "[.]")[[1]][1]
}
met.raw.doy1$dataset <- as.factor(met.raw.doy1$dataset)

met.raw.doy <- stack(met.raw.doy1[,vars.short])
names(met.raw.doy) <- c("raw", "met.var")
met.raw.doy[,c("DOY", "dataset", "dataset2")] <- met.raw.doy1[,c("DOY", "dataset", "dataset2")]
summary(met.raw.doy)

summary(met.raw.doy1)
summary(met.bias.doy.mean)

png(file.path(path.day.base, "Raw_DOY.png"), height=8, width=10, units="in", res=220)
print(
  ggplot(data=met.raw.doy[,]) + facet_wrap(~met.var, scales="free_y") +
    geom_path(data=met.raw.doy[met.raw.doy$dataset=="NLDAS",], aes(x=DOY, y=raw), color="black", size=1) +
    geom_path(data=met.raw.doy[met.raw.doy$dataset!="NLDAS",], aes(x=DOY, y=raw, color=dataset, group=dataset2), size=0.5) +
    scale_x_continuous(expand=c(0,0)) +
    theme_bw()
)
dev.off()

png(file.path(path.day.base, "Debias_DOY.png"), height=8, width=10, units="in", res=220)
print(
  ggplot(data=met.bias.doy[, ]) + facet_wrap(~met.var, scales="free_y") +
    geom_path(data=met.raw.doy[met.raw.doy$dataset=="NLDAS",], aes(x=DOY, y=raw), color="black", size=1) +
    geom_ribbon(aes(x=DOY, ymin=lwr, ymax=upr, fill=dataset), alpha=0.5) +
    geom_path(aes(x=DOY, y=mean, color=dataset), size=0.5) +
    # geom_vline(xintercept=c(1850, 1901, 2010), linetype="dashed") +
    scale_x_continuous(expand=c(0,0)) +
    theme_bw()
)
dev.off()

# Save the summaries of the raw and bias-corrected data to quickly make some customized graphs elsewhere
write.csv(met.raw.doy , file.path(path.day.base, "Met_Raw_DOY.csv"      ), row.names=F)
write.csv(met.bias.doy, file.path(path.day.base, "Met_Corrected_DOY.csv"), row.names=F)

```
