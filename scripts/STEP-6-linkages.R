####################
# Modeling Met Ensemble Workflow
# Step 6 :: Converstion to LINKAGES met formatting
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step takes the subdaily values 
# 
####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
<<<<<<< HEAD
site.name = "GILL"
=======
wd.base = '~/met'
site.name = "NRP"
site.lat  = 42.84514
site.lon  = -72.4473
>>>>>>> d20f600a3bc85f6130b9a66bbda69b04062b8c3e
vers=".v1"

# this variable depends on the paleon site type (long or short run) 
first.year=1800
last.year=2015

####################
# Step 1: Set up working directory
####################
<<<<<<< HEAD
if (!require('here')) install.packages('here',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
require(here,lib='~/Rlibs')

# set up important paths
path.out = here::here('ensembles',paste0(site.name,vers),'linkages')
if (!dir.exists(path.out)) dir.create(path.out,recursive=T)
path.in = here::here('ensembles',paste0(site.name,vers),'aggregated/month')
=======

# set up important paths
path.out = file.path(wd.base,'ensembles',paste0(site.name,vers),'linkages')
if (!dir.exists(path.out)) dir.create(path.out)
path.in = file.path(wd.base,'ensembles',paste0(site.name,vers),'aggregated/month')
>>>>>>> d20f600a3bc85f6130b9a66bbda69b04062b8c3e

####################
# Step 2: Load monthly data 
####################

# load ensemble temperature data (in degrees Fahrenheit)
tair <- read.csv(file.path(wd.base,"ensembles",paste0(site.name,vers),'aggregated/month',"Temperature_AllMembers.csv"), 
                 stringsAsFactors=FALSE, header=TRUE)
precip <- read.csv(file.path(wd.base,"ensembles",paste0(site.name,vers),'aggregated/month',"Precipitation_AllMembers.csv"), 
                 stringsAsFactors=FALSE, header=TRUE)

# find the number of ensembles and remove the dates 
n_models <- ncol(tair) - 1
dates <- tair[,1]
years <- c()
for (j in 1:length(dates)){
  years <- c(years, as.numeric(substr(dates[j],1,(nchar(dates[j])-3))))
}
models <- colnames(tair)[-1]
yr.id = unique(years)

# need to loop through each model, convert data to appropriate unit, put in appropriate storage matrix, and save 
# as climate.Rdata in a folder titled with the ensemble name 
for (i in 1:n_models){
  
  # extract data for model 
  df = data.frame(year=years, temp=tair[,(i+1)], precip = precip[,(i+1)])
  
  # create storage matrices for linkages met
  precip.mat = matrix(0,length(yr.id),12)
  temp.mat = matrix(0,length(yr.id),12)
  rownames(precip.mat) = yr.id
  rownames(temp.mat) = yr.id
  
  # loop through years 
  for (k in 1:length(yr.id)){
    yr = yr.id[k]
    # convert from F to C
    temp.mat[k,] = (df$temp[df$year==yr]-32) * (5/9)
    # convert from inchest to cm
    precip.mat[k,] = (df$precip[df$year==yr]) * 2.54 #cm/in
  }
  
  # save as climate.Rdata in a folder named after ensemble
  folder = file.path(path.out,models[i])
  if (!dir.exists(folder)) dir.create(folder, recursive=T)
  
  save(precip.mat=precip.mat, temp.mat=temp.mat, file = file.path(folder,'climate.Rdata'))
}



<<<<<<< HEAD
# next precipitation
jpeg(file.path(path.out,'linkages-precip-check.jpg'))
par(mfrow=c(2,2))
for (i in years){
  plot(NULL, xlim=c(0,13), ylim = c(0,20), 
       xlab = 'Months', ylab = 'Precipitation (cm)', main = paste('Precipitation in',i))
  id = i - first.year + 1
  for (e in ens){
    load(paste0(path.out,'/',e,'/climate.Rdata'))
    points(c(1:12),precip.mat[id,])
  }
}
dev.off()
=======



>>>>>>> d20f600a3bc85f6130b9a66bbda69b04062b8c3e
