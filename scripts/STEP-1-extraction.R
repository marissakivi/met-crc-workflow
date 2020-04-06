
####################
# Modeling Met Ensemble Workflow
# Step 1: Extraction of Site Data
####################
# Unlike the rest of the met processing workflow, this script is not adapted to 
# running job submissions on the CRC, as the raw data files require the connection
# of the external harddrive that contains the raw gridded data files. 

# Description: 
# This step contains the script for the first script of Christy's met workflow, which extracts raw data from 
# each of the different data sources for a single point based on given latitude and longitude. The data 
# sources include NLDAS, CRUNCEP, and the four GCMs--CCSM4, MIROC-ESM, and MPI-ESM--which have both past millenium 
# and historical data. 

### When running this extraction script, there are certain storage capacity needs 
### that your local machine must meet. The size of each source is listed below. 
### The script has been adapted so that you can run each step separately, making it 
### easier to free up space after extracting one source by moving it to the CRC. 
### Use the "scp" function to do this from the command line or you can use 
### Cyberduck. 

# Required functions: 
# - extract_local_NLDAS.R (PEcAn) 
# - download.CRUNCEP_global.R (PEcAn)
# - extract_local_CMIP5.R (PEcAn)

# Required libraries: 
# - ggplot2 

rm(list=ls())

####################
# ALTER ONLY THESE VARIABLES FOR SCRIPT
####################

# site information 
site.name = 'BIGWOODS' 
site.lat  = 45.410739
site.lon  = -93.715137

# set working directory to location of met repo on external drive 
# this ensures that there is enough storage space for all of the data for one site
#wd.base <- "/Volumes/My\ Passport/met-crc-workflow"
wd.base <- "~/Desktop/met-crc-workflow"
setwd(wd.base)

# get path for connected external drive with raw grid files 
path.data = '/Volumes/My\ Passport/Meteorology'

## MSK: Other to-do: 
## - do these functions create a bunch of variables or just save them? Because maybe 
## we should be removing them after every extraction

####################
# Step 1: Set up working directory 
####################

library(ggplot2)
library(ncdf4)

# create and set important directories
path.out = file.path(wd.base, 'data','paleon_sites',site.name)
if (!dir.exists(path.out)){
  dir.create(path.out, recursive = TRUE)
  dir.create(file.path(path.out, 'NLDAS'))
  dir.create(file.path(path.out, 'CRUNCEP'))
  
  GCM.scenarios = c("p1000", "historical")
  GCM.list  = c("CCSM4", "bcc-csm1-1", "MIROC-ESM", "MPI-ESM-P")
  for (GCM in GCM.list){
    for (scen in GCM.scenarios){
      dir.create(file.path(path.out, GCM, scen), recursive = TRUE)
    }
  }
}
path.pecan <- file.path(wd.base, 'functions')

####################
# Step 2: Extract NLDAS data [1980-2015]
####################

source(file.path(path.pecan, "extract_local_NLDAS.R"))
path.nldas = file.path(path.data, 'LDAS', 'NLDAS_FORA0125_H.002', 'netcdf')
extract.local.NLDAS(outfolder=file.path(path.out, "NLDAS"), in.path=path.nldas, 
                    start_date="2009-01-01", end_date="2015-12-31", 
                    site_id=site.name, lat.in=site.lat, lon.in=site.lon)

####################
# Step 3: Extract CRUNCEP data [1901-2010]
####################

## This step has been moved to a separate script since it is the only extraction 
## process that can be completed on the CRC server. Less work for your machine! 

#source(file.path(path.pecan, "download.CRUNCEP_Global.R"))
#download.CRUNCEP(outfolder=file.path(path.out, "CRUNCEP"), 
                 #start_date="1901-01-01", end_date="1901-12-31", 
                 #site_id=site.name, lat.in=site.lat, lon.in=site.lon)

####################
# Step 4: Extract GCM data [p1000: 850-1849 || historical: 1850-2005]
####################

## MSK:: might be useful to do one GCM at a time here
  
source(file.path(path.pecan, "extract_local_CMIP5.R"))
path.cmip5 = file.path(path.data, 'CMIP5')
#GCM.scenarios = c("p1000", "historical")
GCM.scenarios = c('p1000')
GCM.list = c('CCSM4','bcc-csm1-1')
#GCM.list  = c("CCSM4", "bcc-csm1-1", "MIROC-ESM", "MPI-ESM-P")
for(GCM in GCM.list){
  for(scenario in GCM.scenarios){
    if(scenario=="p1000"){
      cmip5.start = "0850-01-01"
      cmip5.end   = "1849-12-31"
    } else if (scenario == "historical"){
      cmip5.start = "1850-01-01"
      cmip5.end   = "2005-12-31"
    } else {
      stop("Scenario not implemented yet")
    }

    print(paste(GCM, scenario, sep=" - "))
    extract.local.CMIP5(outfolder = file.path(path.out, GCM, scenario), in.path = file.path(path.cmip5, GCM, scenario),
                        start_date = cmip5.start, end_date = cmip5.end,
                        site_id = site.name, lat.in = site.lat, lon.in = site.lon,
                        model = GCM, scenario = scenario, ensemble_member = "r1i1p1")
  }
}

## MSK: Plotting would have to occur in CRC because not all of the data will fit on the local machine
## UNLESS we put the extracted data on the external hard drive and then move it to CRC when
## everything is good 



####################
# Step 5: Extract GCM data
####################

# Graphing the output just to make sure everythign looks okay
met.qaqc <- c("NLDAS", "CRUNCEP")
#for(met in c("NLDAS", "CRUNCEP")){
for (met in c('NLDAS')){
  # Extract & print QAQC graphs for NLDAS
  dat.qaqc <- NULL
  files.qaqc <- dir(file.path(path.out, met))
  for(i in 1:length(files.qaqc)){
    y.now <- as.numeric(strsplit(files.qaqc[i], "[.]")[[1]][2])
    nday <- ifelse(lubridate::leap_year(y.now), 366, 365)

    ncT <- ncdf4::nc_open(file.path(path.out, met, files.qaqc[i]))
    nc.time <- ncdf4::ncvar_get(ncT, "time")/(60*60*24)
    day.step <- length(nc.time)/nday

    dat.temp <- data.frame(Year=y.now, DOY=rep(1:nday, each=day.step), time=1:day.step-(24/day.step/2))
    for(v in names(ncT$var)){
      dat.temp[,v] <- ncdf4::ncvar_get(ncT, v)
    }
    ncdf4::nc_close(ncT)

    if(is.null(dat.qaqc)){
      dat.qaqc <- dat.temp
    } else {
      dat.qaqc <- rbind(dat.qaqc, dat.temp)
    }
  }

  dat.qaqc2 <- aggregate(dat.qaqc[,4:ncol(dat.qaqc)], by=dat.qaqc[,c("Year", "DOY")], FUN=mean)

  dat.yr1 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"Year"]), FUN=mean)
  names(dat.yr1)[1] <- "Year"
  dat.yr <- stack(dat.yr1[,2:ncol(dat.yr1)])
  dat.yr$Year <- dat.yr1$Year
  summary(dat.yr)

  library(ggplot2)
  png(file.path(path.out, paste0("MetQAQC_", met, "_annual.png")), height=8, width=8, units="in", res=220)
  print(
    ggplot(data=dat.yr) + facet_wrap(~ind, scales="free_y") +
      geom_line(aes(x=Year, y=values))
  )
  dev.off()

  dat.doy1 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=mean)
  dat.doy2 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=quantile, 0.025)
  dat.doy3 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=quantile, 0.975)
  names(dat.doy1)[1] <- "DOY"
  dat.doy <- stack(dat.doy1[,2:ncol(dat.doy1)])
  dat.doy$DOY <- dat.doy1$DOY
  dat.doy$lwr <- stack(dat.doy2[,2:ncol(dat.doy2)])[,1]
  dat.doy$upr <- stack(dat.doy3[,2:ncol(dat.doy3)])[,1]
  summary(dat.doy)

  png(file.path(path.out, paste0("MetQAQC_", met, "_DOY.png")), height=8, width=8, units="in", res=220)
  print(
    ggplot(data=dat.doy) + facet_wrap(~ind, scales="free_y") +
      geom_ribbon(aes(x=DOY, ymin=lwr, ymax=upr), alpha=0.5) +
      geom_line(aes(x=DOY, y=values))
  )
  dev.off()
}

GCM.list  = c("MIROC-ESM", "MPI-ESM-P", "bcc-csm1-1", "CCSM4")
for(GCM in GCM.list){
  #for(scenario in c("historical", "p1000")){
  for (scenario in c('p1000')){
    # Extract & print QAQC graphs for NLDAS
    dat.qaqc <- NULL
    files.qaqc <- dir(file.path(path.out, GCM, scenario))
    for(i in 1:length(files.qaqc)){
      y.now <- strsplit(files.qaqc[i], "[.]")[[1]]
      y.now <- as.numeric(y.now[length(y.now)-1])
      nday <- ifelse(lubridate::leap_year(y.now), 366, 365)

      ncT <- ncdf4::nc_open(file.path(path.out, GCM, scenario, files.qaqc[i]))
      nc.time <- ncdf4::ncvar_get(ncT, "time")/(60*60*24)
      day.step <- length(nc.time)/nday

      dat.temp <- data.frame(Year=y.now, DOY=rep(1:nday, each=day.step), time=1:day.step-(24/day.step/2))
      for(v in names(ncT$var)){
        dat.temp[,v] <- ncdf4::ncvar_get(ncT, v)
      }
      ncdf4::nc_close(ncT)

      if(is.null(dat.qaqc)){
        dat.qaqc <- dat.temp
      } else {
        dat.qaqc <- rbind(dat.qaqc, dat.temp)
      }
    }

    dat.qaqc2 <- aggregate(dat.qaqc[,4:ncol(dat.qaqc)], by=dat.qaqc[,c("Year", "DOY")], FUN=mean)

    dat.yr1 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"Year"]), FUN=mean)
    names(dat.yr1)[1] <- "Year"
    dat.yr <- stack(dat.yr1[,2:ncol(dat.yr1)])
    dat.yr$Year <- dat.yr1$Year
    summary(dat.yr)

    library(ggplot2)
    png(file.path(path.out, paste0("MetQAQC_", GCM, "_", scenario, "_annual.png")), height=8, width=8, units="in", res=220)
    print(
      ggplot(data=dat.yr) + facet_wrap(~ind, scales="free_y") +
        geom_line(aes(x=Year, y=values))
    )
    dev.off()

    dat.doy1 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=mean, na.rm=T)
    dat.doy2 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=quantile, 0.025, na.rm=T)
    dat.doy3 <- aggregate(dat.qaqc2[,3:ncol(dat.qaqc2)], by=list(dat.qaqc2[,"DOY"]), FUN=quantile, 0.975, na.rm=T)
    names(dat.doy1)[1] <- "DOY"
    dat.doy <- stack(dat.doy1[,2:ncol(dat.doy1)])
    dat.doy$DOY <- dat.doy1$DOY
    dat.doy$lwr <- stack(dat.doy2[,2:ncol(dat.doy2)])[,1]
    dat.doy$upr <- stack(dat.doy3[,2:ncol(dat.doy3)])[,1]
    summary(dat.doy)

    png(file.path(path.out, paste0("MetQAQC_", GCM, "_", scenario, "_DOY.png")), height=8, width=8, units="in", res=220)
    print(
      ggplot(data=dat.doy) + facet_wrap(~ind, scales="free_y") +
        geom_ribbon(aes(x=DOY, ymin=lwr, ymax=upr), alpha=0.5) +
        geom_line(aes(x=DOY, y=values))
    )
    dev.off()
  }
}

