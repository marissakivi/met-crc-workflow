####################
# Modeling Met Ensemble Workflow
# Step 6 :: Converstion to LINKAGES met formatting
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step takes the monthly ensembles for temperature and precipitation, transforms them to LINKAGES-friendly units, and saves 
# a separate Rdata file for each ensemble. 
# 
####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
site.name = "SYLVANIA"
wd.base = '~/met-crc-workflow'
vers=".v2"

# this variable depends on the paleon site type (long or short run) 
first.year=850
last.year=2015

####################
# Step 1: Set up working directory
####################

# set up important paths
path.out = file.path(wd.base,'ensembles',paste0(site.name,vers),'completed')
if (!dir.exists(path.out)) dir.create(path.out,recursive=TRUE)
path.in = file.path(wd.base,'ensembles',paste0(site.name,vers),'aggregated/month')
path.folder = file.path(path.out,'linkages')
if (!dir.exists(path.folder)) dir.create(path.folder,recursive=TRUE)

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
  
  # save after ensemble name
  save(precip.mat=precip.mat, temp.mat=temp.mat, file = file.path(path.folder,paste0(models[i],'.Rdata')))
}

ens = list.files(path.folder,full.names =T)
# check temperature
years_plot = c(1800,1900,2000)
jpeg(file.path(path.out,'linkages-temp-check.jpg'))
par(mfrow=c(2,2))
for (i in years_plot){
  plot(NULL, xlim=c(0,13), ylim = c(-20,60), 
       xlab = 'Months', ylab = 'Temperature (C)', main = paste('Mean air temperature in',i))
  id = i - first.year + 1
  for (e in ens){
    load(e)
    points(c(1:12),temp.mat[id,])
  }
}
dev.off()


# next precipitation
jpeg(file.path(path.out,'linkages-precip-check.jpg'))
par(mfrow=c(2,2))
for (i in years_plot){
  plot(NULL, xlim=c(0,13), ylim = c(0,20), 
       xlab = 'Months', ylab = 'Precipitation (cm)', main = paste('Precipitation in',i))
  id = i - first.year + 1
  for (e in ens){
    load(e)
    points(c(1:12),precip.mat[id,])
  }
}
dev.off()

