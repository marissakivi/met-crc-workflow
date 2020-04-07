####################
# Modeling Met Ensemble Workflow
# Step 3C :: Rejection of bad ensembles
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step contains a modified version of the seventh step of Christy's met workflow, 
# which rejects and removes ensemble members containing impossible values and generates figures to 
# visually check the quality of the predictions. 
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

site.name = "BONANZA"
vers=".v1"

# this variable determines the span of years that will be formatted 
# depending on paleon site type 
first.year = 1800

# working directory
wd.base = "~/met-crc-workflow"

####################
# Step 1: Set up working directory 
####################

# check for un-installed packages
if (!require('ncdf4', lib.loc='~/Rlibs')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('lubridate', lib.loc='~/Rlibs')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2', lib.loc='~/Rlibs')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('stringr', lib.loc='~/Rlibs')) install.packages('stringr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

require(ncdf4, lib.loc='~/Rlibs')
require(lubridate,lib.loc='~/Rlibs')
require(ggplot2,lib.loc='~/Rlibs')
require(stringr,lib.loc='~/Rlibs')

GCM.list = c("CCSM4", "MIROC-ESM", "MPI-ESM-P", "bcc-csm1-1")
ens.hr  <- 2 # Number of hourly ensemble members to create

# Set up the appropriate seed
set.seed(0017)

####################
# Step 2: Remove bad ensemble members
####################

path.dat <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/ensembles/")
path.bad <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/rejected/")

if(!dir.exists(path.bad)) dir.create(path.bad, recursive = T)

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
dat.summary <- array(dim=c(n.files, length(var.names), 2, length(ens.mems))) # dim[3] == 2 so we can store min/max
dimnames(dat.summary)[[1]] <- seq(2015, first.year, by=-1)
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
    
    f.all <- rev(dir(file.path(path.dat, GCM.list[GCM], ens.gcm[ens])))
    
    for(fnow in 1:length(f.all)){
      ncT <- ncdf4::nc_open(file.path(path.dat, GCM.list[GCM], ens.gcm[ens], f.all[fnow]))
      
      for(v in length(var.names):1){
        dat.summary[fnow,v,1,ens.ind] <- min(ncdf4::ncvar_get(ncT, var.names[v]))
        dat.summary[fnow,v,2,ens.ind] <- max(ncdf4::ncvar_get(ncT, var.names[v]))
        
        setTxtProgressBar(pb, pb.ind)
        pb.ind <- pb.ind+1
      }
      
      ncdf4::nc_close(ncT)
    }
  }
}

# filter and identify outliers
ens.bad <- array(dim=c(n.files, length(ens.mems)))
dimnames(ens.bad)[[1]] <- dimnames(dat.summary)[[1]]
dimnames(ens.bad)[[2]] <- dimnames(dat.summary)[[4]]

sum.means <- apply(dat.summary[,,,], c(1, 2, 3), FUN=mean)
sum.sd    <- apply(dat.summary[,,,], c(1, 2, 3), FUN=sd)


for(i in 1:nrow(ens.bad)){
  for(j in 1:ncol(ens.bad)){

    vars.bad <- dat.summary[i,,1,j] < sum.means[i,,1] - 6*sum.sd[i,,1] | dat.summary[i,,2,j] > sum.means[i,,2] + 6*sum.sd[i,,2]    
    if(all(is.na(vars.bad))) next
    if(any(vars.bad)){
      ens.bad[i,j] <- length(which(vars.bad))
    }
  }
}

# summarizing bad ensembles 
yrs.bad <- apply(ens.bad, 1, sum, na.rm=TRUE)
summary(yrs.bad)

mems.bad <- apply(ens.bad, 2, sum, na.rm=TRUE)
length(which(mems.bad==0))/length(mems.bad)
summary(mems.bad)

quantile(mems.bad, 0.90)

# move the bad ensemble members
mems.bad[mems.bad>0]

for(mem in names(mems.bad[mems.bad>0])){
  GCM <- stringr::str_split(mem, "_")[[1]][1]
  system(paste("mv", file.path(path.dat, GCM, mem), file.path(path.bad, mem), sep=" "))
}

####################
# Step 3: Visually check predicted values 
####################

path.dat <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/ensembles/")
path.out <- file.path(wd.base, "ensembles", paste0(site.name, vers), "1hr/figures_qaqc")

dir.create(path.out, recursive=TRUE, showWarnings =FALSE)
GCM.list <- c("bcc-csm1-1", "CCSM4", "MIROC-ESM", "MPI-ESM-P")

n.day <- 4 # How many parent ensembles we want to graph
n.hr <- 4 # How many independent hourly ensembles we want to show

yrs.check <- c(2015, 1985, 1920, 1875, 1800)
days.graph <- data.frame(winter=(45-3):(45+3), spring=(135-3):(135+3), summer=(225-3):(225+3), fall=(315-3):(315+3))

vars.CF <- c("air_temperature", "precipitation_flux", "surface_downwelling_shortwave_flux_in_air", "surface_downwelling_longwave_flux_in_air", "air_pressure", "specific_humidity", "wind_speed")
vars.short <- c("tair", "precip", "swdown", "lwdown", "press", "qair", "wind")

met.plot <- list()
dat.hr <- NULL
for(GCM in GCM.list){
  met.plot[[GCM]] <- list()
  
  # Get a list of the *unique* daily ensemble members and then randomly sample 
  # *up to* n.day for plotting
  ens.all <- dir(file.path(path.dat, GCM))
  ens.names <- str_split(ens.all, "[.]")
  ens.names <- matrix(unlist(ens.names), ncol=length(ens.names[[1]]), byrow=TRUE)
  parent.day <- unique(ens.names[,1])
  
  # Randomly picking up to n.day ensemble members for plotting
  day.plot <- parent.day[sample(1:length(parent.day), min(length(parent.day), n.day))]
  
  # Extracting the hourly members
  for(ens.day in day.plot){
    # Get a list of the ensemble members
    hr.all <- dir(file.path(path.dat, GCM), ens.day)
    hr.plot <- hr.all[sample(1:length(hr.all), min(length(hr.all), n.hr))]
    
    # Extract our hourly info for the years we want and store in a dataframe
    for(ens.now in hr.all){
      for(yr in yrs.check){
        nday <- ifelse(lubridate::leap_year(yr), 366, 365)
        
        nc.now <- dir(file.path(path.dat, GCM, ens.now), paste(yr))
        if(length(nc.now)==0) next 
        
        ncT <- ncdf4::nc_open(file.path(path.dat, GCM, ens.now, nc.now))
        time.nc <- ncdf4::ncvar_get(ncT, "time")
        
        dat.temp <- data.frame(GCM=GCM, ens.day=ens.day, ens.hr=ens.now, year = yr, doy = rep(1:nday, each=24), hour=rep(seq(0.5, 24, by=1), nday))
        dat.temp$date <- as.POSIXct(strptime(paste(dat.temp$year, dat.temp$doy, dat.temp$hour, sep="-"), format=("%Y-%j-%H"), tz="UTC"))
        
        for(v in 1:length(vars.CF)){
          dat.temp[,vars.CF[v]] <- ncdf4::ncvar_get(ncT, vars.CF[v])
        }
        nc_close(ncT)
        dat.temp <- dat.temp[dat.temp$doy %in% unlist(days.graph),]
        
        if(is.null(dat.hr)){
          dat.hr <- dat.temp
        } else {
          dat.hr <- rbind(dat.hr, dat.temp)
        }
        
      }
    }
  }
  
}

dim(dat.hr)

# aggregating & graphing data
dat.hr$season <- ifelse(dat.hr$doy %in% days.graph$winter, "winter", 
                        ifelse(dat.hr$doy %in% days.graph$spring, "spring", 
                               ifelse(dat.hr$doy %in% days.graph$summer, "summer", "fall")))
dat.hr$season <- factor(dat.hr$season, levels=c("winter", "spring", "summer", "fall"))
dat.ind <- stack(dat.hr[,vars.CF])
names(dat.ind) <- c("mean", "ind")
dat.ind[,c("lwr", "upr")] <- NA
dat.ind[,c("GCM", "ens.day", "ens.hr", "year", "season", "doy", "hour", "date")] <- dat.hr[,c("GCM", "ens.day", "ens.hr", "year", "season", "doy", "hour", "date")]
dat.ind$doy2 <- dat.ind$doy+dat.ind$hour
summary(dat.ind)

dat.ens <- aggregate(dat.ind[,"mean"], by=dat.ind[,c("ind", "GCM", "ens.day", "year", "season", "doy", "hour")], FUN=mean)
names(dat.ens)[which(names(dat.ens)=="x")] <- "mean"
dat.ens$lwr <- aggregate(dat.ind[,"mean"], by=dat.ind[,c("ind", "GCM", "ens.day", "year", "season", "doy", "hour")], FUN=quantile, 0.025)$x
dat.ens$upr <- aggregate(dat.ind[,"mean"], by=dat.ind[,c("ind", "GCM", "ens.day", "year", "season", "doy", "hour")], FUN=quantile, 0.975)$x
dat.ens$date <- as.POSIXct(strptime(paste(dat.ens$year, dat.ens$doy, dat.ens$hour, sep="-"), format=("%Y-%j-%H"), tz="UTC"))
summary(dat.ens)

for(v in unique(dat.ens$ind)){
  pdf(file.path(path.out, paste0(v, "_ensembles.pdf")), width=10, height=8)
  for(yr in yrs.check[yrs.check %in% unique(dat.ens$year)]){
    print(
      ggplot(data=dat.ens[dat.ens$ind==v & dat.ens$year==yr,]) + facet_wrap(~season, scales="free_x") +
        geom_ribbon(aes(x=date, ymin=lwr, ymax=upr, fill=ens.day), alpha=0.5) +
        geom_line(aes(x=date, y=mean, color=ens.day)) +
        ggtitle(paste(v, yr, sep=" - "))
    )
  }
  dev.off()
  
  pdf(file.path(path.out, paste0(v, "_members.pdf")), width=10, height=8)
  for(yr in yrs.check[yrs.check %in% unique(dat.ens$year)]){
    print(
      ggplot(data=dat.ind[dat.ind$ind==v & dat.ind$year==yr,]) + facet_wrap(~season, scales="free_x") +
        geom_line(aes(x=date, y=mean, color=ens.day, group=ens.hr)) +
        ggtitle(paste(v, yr, sep=" - "))
    )
  }
  dev.off()
}

