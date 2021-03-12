####################
# Modeling Met Ensemble Workflow
# Step 5 :: PDSI Calculation
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step is the ninth step in Christy's workflow. It takes the aggregated monthly values from Step 4 and
# calculates monthly PDSI values for the site. In addition, it converts the precipitation flux and air temperature values
# and creates the ensemble data csv files used in the weighting script. 
# 
# Required functions: 
# - calc_pdsi.R
# - calc.awc.R
# - pdsi1.R
# - pdsix.R
# - PE.thornthwaite.R
# - soilmoi1.R
# 
# Required libraries: 
# - ggplot2 
# - ncdf4
# - stringr
# - abind
# - lubridate
# - R.matlab

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
site.name = "SYLVANIA"
site.lat = 46.2419
site.lon  = -89.3478

vers=".v2"

# this variable depends on the paleon site type (long or short run) 
first.year=850

# working directory
wd.base = "~/met-crc-workflow"

####################
# Step 1: Set up working directory
####################

# load required packages
# this section is no longer needed because there is a general script to download packages
#if (!require('ggplot2',lib.loc ='~/Rlibs')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('ncdf4',lib.loc ='~/Rlibs')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('stringr',lib.loc ='~/Rlibs')) install.packages('stringr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('abind',lib.loc ='~/Rlibs')) install.packages('abind',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('lubridate',lib.loc ='~/Rlibs')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
#if (!require('R.matlab',lib.loc ='~/Rlibs')) install.packages('R.matlab',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

require(ggplot2)
require(ncdf4,lib.loc='~/Rlibs')
require(stringr)
require(abind,lib.loc='~/Rlibs')
require(lubridate)
require(R.matlab,lib.loc='~/Rlibs')

# set up important file paths
in.base = file.path(wd.base, "ensembles", paste0(site.name, vers), "aggregated/month")
path.func = file.path(wd.base,'functions')
years.pdsi = NULL
years.calib = c(1931, 1990)

# load required functions
source(file.path(path.func,"calc_pdsi.R"))
source(file.path(path.func,"calc.awc.R"))
source(file.path(path.func,"pdsi1.R"))
source(file.path(path.func,"pdsix.R")) 
source(file.path(path.func,"PE.thornthwaite.R"))
source(file.path(path.func,"soilmoi1.R"))

path.soil <- file.path(wd.base,'data/soil')

####################
# Step 2: Get soil conditions for site 
####################

sand.t <- ncdf4::nc_open(file.path(path.soil, "paleon_soil_t_sand.nc"))
sand.s <- ncdf4::nc_open(file.path(path.soil, "paleon_soil_s_sand.nc"))
clay.t <- ncdf4::nc_open(file.path(path.soil, "paleon_soil_t_clay.nc"))
clay.s <- ncdf4::nc_open(file.path(path.soil, "paleon_soil_s_clay.nc"))
depth  <- ncdf4::nc_open(file.path(path.soil, "paleon_soil_soil_depth.nc"))

lon <- ncdf4::ncvar_get(sand.t, "longitude")
lat <- ncdf4::ncvar_get(sand.t, "latitude")

x.ind <- which(lon-0.25<=site.lon & lon+0.25>=site.lon)
y.ind <- which(lat-0.25<=site.lat & lat+0.25>=site.lat)

sand1 <- ncdf4::ncvar_get(sand.t, "t_sand", c(x.ind, y.ind), c(1,1))
sand2 <- ncdf4::ncvar_get(sand.s, "s_sand", c(x.ind, y.ind), c(1,1))
clay1 <- ncdf4::ncvar_get(clay.t, "t_clay", c(x.ind, y.ind), c(1,1))
clay2 <- ncdf4::ncvar_get(clay.s, "s_clay", c(x.ind, y.ind), c(1,1))
depth2 <- ncdf4::ncvar_get(depth, "soil_depth", c(x.ind, y.ind), c(1,1))

awc1 <- calc.awc(sand1, clay1)
awc2 <- calc.awc(sand2, clay2)

wcap1 <- awc1*ifelse(depth2>30, 30, depth2-1) * 1/2.54 # 30 cm top depth * 1 in / 2.54 cm
wcap2 <- awc2*ifelse(depth2>30, depth2-30, 1) * 1/2.54 # remaining depth * 1 in / 2.54 cm

watcap <- c(wcap1, wcap2)

####################
# Step 3: PDSI calculation
####################

out.save <- NULL
GCM.list <- c('bcc-csm1-1','CCSM4','MIROC-ESM','MPI-ESM-P')
for(GCM in GCM.list){
  print(GCM)
  
  gcm.ens <- dir(file.path(in.base, GCM))
  #print(gcm.ens)
  pb <- txtProgressBar(min=0, max=length(gcm.ens), style=3)
  pb.ind=1
  for(ens in gcm.ens){
    print(ens)
    ens.out <- calc.pdsi(path.in=file.path(in.base, GCM, ens), 
                         years.pdsi=NULL, years.calib=years.calib, 
                         watcap=watcap)
    
    if(is.null(out.save)){
      out.save <- list()
      out.save$Temp   <- data.frame(ens=as.vector(t(ens.out$T)))
      out.save$Precip <- data.frame(ens=as.vector(t(ens.out$P)))
      out.save$PDSI   <- data.frame(ens=as.vector(t(ens.out$X)))
      
      names(out.save$Temp) <- names(out.save$Precip) <- names(out.save$PDSI) <- ens
      row.labs <- paste(rep(row.names(ens.out$T), each=ncol(ens.out$T)), stringr::str_pad(1:ncol(ens.out$T), 2, pad="0"), sep="-")
      row.names(out.save$Temp) <- row.names(out.save$Precip) <- row.names(out.save$Precip) <- row.labs 
      
      temp.array   <- array(ens.out$T, dim=c(dim(ens.out$T), 1))
      precip.array <- array(ens.out$P, dim=c(dim(ens.out$P), 1))
      pdsi.array   <- array(ens.out$X, dim=c(dim(ens.out$X), 1))
    } else {
      out.save$Temp  [,ens] <- as.vector(t(ens.out$T))
      out.save$Precip[,ens] <- as.vector(t(ens.out$P))
      out.save$PDSI  [,ens] <- as.vector(t(ens.out$X))
      
      temp.array   <- abind::abind(temp.array, ens.out$T, along=3)
      precip.array <- abind::abind(precip.array, ens.out$P, along=3)
      pdsi.array   <- abind::abind(pdsi.array, ens.out$X, along=3)
    }
    
    setTxtProgressBar(pb, pb.ind)
    pb.ind=pb.ind+1
  } # End ensemble member loop
  print("")
} # End GCM Loop

# Save the Output
# Temperature is in F and precipitation is inches/months
write.csv(out.save$Temp, file.path(in.base, "Temperature_AllMembers.csv"), row.names=TRUE)
write.csv(out.save$Precip, file.path(in.base, "Precipitation_AllMembers.csv"), row.names=TRUE)
write.csv(out.save$PDSI, file.path(in.base, "PDSI_AllMembers.csv"), row.names=TRUE)

####################
# Step 4: Graphing
####################

tair.ann <- data.frame(apply(temp.array, c(1,3), mean, na.rm=TRUE))
precip.ann <- data.frame(apply(precip.array, c(1,3), sum, na.rm=TRUE))
pdsi.ann <- data.frame(apply(pdsi.array, c(1,3), mean, na.rm=TRUE))


tair.summ <- data.frame(var="Temperature", 
                        year=first.year:2015, 
                        median=apply(tair.ann, 1, median, na.rm=TRUE),
                        lwr =apply(tair.ann, 1, quantile, 0.025, na.rm=TRUE),
                        upr =apply(tair.ann, 1, quantile, 0.975, na.rm=TRUE))
precip.summ <- data.frame(var="Precipitation",
                          year=first.year:2015, 
                          median=apply(precip.ann, 1, median, na.rm=TRUE),
                          lwr =apply(precip.ann, 1, quantile, 0.025, na.rm=TRUE),
                          upr =apply(precip.ann, 1, quantile, 0.975, na.rm=TRUE))
pdsi.summ <- data.frame(var="PDSI",
                        year=first.year:2015, 
                        median=apply(pdsi.ann, 1, median, na.rm=TRUE),
                        lwr =apply(pdsi.ann, 1, quantile, 0.025, na.rm=TRUE),
                        upr =apply(pdsi.ann, 1, quantile, 0.975, na.rm=TRUE))

met.all <- rbind(tair.summ, precip.summ, pdsi.summ)

png(file.path(in.base, "Met_Summary_Annual.png"), height=8.5, width=11, unit="in", res=220)
print(
  ggplot(data=met.all) + facet_grid(var~., scales="free_y") +
    geom_ribbon(aes(x=year, ymin=lwr, ymax=upr, fill=var), alpha=0.5) +
    geom_line(aes(x=year, y=median, color=var)) + 
    geom_vline(xintercept=c(2010, 1900, 1849), linetype="dashed", size=0.5) +
    scale_fill_manual(values=c("red", "blue2", "green3")) +
    scale_color_manual(values=c("red", "blue2", "green3")) +
    theme_bw() +
    theme(legend.position="top")
)
dev.off()

# Tricking the PDSI CI into not being ridiculous
met.all[met.all$var=="PDSI" & met.all$lwr < -5, "lwr"] <- -5
met.all[met.all$var=="PDSI" & met.all$upr > 7.5, "upr"] <- 7.5
png(file.path(in.base, "Met_Summary_Annual2.png"), height=8.5, width=11, unit="in", res=220)
print(
  ggplot(data=met.all) + facet_grid(var~., scales="free_y") +
    geom_ribbon(aes(x=year, ymin=lwr, ymax=upr, fill=var), alpha=0.5) +
    geom_line(aes(x=year, y=median, color=var)) + 
    geom_vline(xintercept=c(2010, 1900, 1849), linetype="dashed", size=0.5) +
    scale_fill_manual(values=c("red", "blue2", "green3")) +
    scale_color_manual(values=c("red", "blue2", "green3")) +
    # scale_x_continuous(expand=c(0,0)) +
    scale_y_continuous((expand=c(0,0))) +
    # coord_cartesian(ylim=c(-15,15)) +
    theme_bw() +
    theme(legend.position="top")
)
dev.off()
# -----------------------------------
