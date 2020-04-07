####################
# Modeling Met Ensemble Workflow
# Step 7 :: Extraction of PRISM data 
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step contains a modified version of the PRISM extraction script within the PRISM Google Drive. It takes 
# a site's details and interpolates the 9 nearest PRISM grid cells in order to determine the location's data values. Since
# we already have the PRISM data for the 17 original PalEON sites, this script is intended to be used to extract data for 
# new sites. 
#
# Temparture Data Sources: 
# reconstruction - MANN data (500-2006)
# calibration - PRISM data (1895-2017)

# PDSI Data Sources: 
# reconstruction - LBDA data (1135-2005)
# calibration - ESRL data (1850-2014)
#
# Required functions: 
#
# Required libraries:
# - plyr
# - raster
# - data.table
# - rgdal
# - reshape2
# - ncdf4


####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
site = "BONANZA" # should be identical to paleon site name 
vers=".v1"

# Coordinates to run this script need to be re-projected from WGS 1984 
# coordinate system to NAD 83, a conversio that can be done at the following
# website: https://tagis.dep.wv.gov/convert/
# be sure to adjust the input and output types on the website 
site.lat  = 45.45283
site.lon  = -96.7144

CRC = TRUE

# working directory 
wd.base = '~/met-crc-workflow'


####################
# Step 1: Set up working directory
####################

if (!require('plyr',lib.loc ='~/Rlibs')) install.packages('plyr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('raster',lib.loc ='~/Rlibs')) install.packages('raster',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('data.table',lib.loc ='~/Rlibs')) install.packages('data.table',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('rgdal',lib.loc ='~/Rlibs')) install.packages('rgdal',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('reshape2',lib.loc ='~/Rlibs')) install.packages('reshape2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ncdf4',lib.loc ='~/Rlibs')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

require(plyr,lib.loc='~/Rlibs')
require(raster,lib.loc='~/Rlibs')
require(data.table,lib.loc='~/Rlibs')
require(rgdal,lib.loc='~/Rlibs')
require(reshape2, lib.loc='~/Rlibs')
require(ncdf4,lib.loc='~/Rlibs')

#require(plyr)
#require(raster)
#require(data.table)
#require(rgdal)
#require(reshape2)
#require(ncdf4)

path.in = file.path(wd.base,'data/weight/PRISM/raw')
path.out = file.path(wd.base,'data/weight/PRISM/paleon_sites')

# right now, weighting script only requires extracted mean temperature values
# four possible climate variables: maxTemp, minTemp, meanTemp and precip
var = 'meanTemp'

####################
# Step 2: Determine 9 PRISM grid cells within NLDAS grid cell for site
####################

# read in the NLDAS nc file
ncin <- nc_open(file.path(wd.base,'data/weight/PRISM','NLDAS_FORA0125_H.A20170101.nc'))

# get the lat,longs from the nc file
ncin.lon <- ncvar_get(ncin,'lon') #x
ncin.lat <- ncvar_get(ncin,'lat') #y

# randomly picked air temperature
data = ncvar_get(ncin,varid = c('air_temperature'))[,,1]

r1 <- raster(list(x=ncin.lon,y=ncin.lat,z=data))
plot(r1)
nldas <- as.data.frame(rasterToPoints(r1))

# create save data frame for the site 
site.info <- rep(0,4)
site.x = which.min(abs(ncin.lon-site.lon))
site.y = which.min(abs(ncin.lat-site.lat))

# determine site is in relation to grid cell 
if (site.lon < ncin.lon[site.x]){
  t.lon <- ncin.lon[site.x]
  l.lon <- ncin.lon[site.x-1]
}else{
  t.lon <- ncin.lon[site.x+1]
  l.lon <- ncin.lon[site.x]
}

if (site.lat < ncin.lat[site.y]){
  t.lat <- ncin.lat[site.y]
  l.lat <- ncin.lat[site.y-1]
}else{
  t.lat <- ncin.lat[site.y+1]
  l.lat <- ncin.lat[site.y]
}

# t/l.lat and t/l.lon are the latitude and longitude lines that enclose the NLDAS grid cell

# read in the filenames for PRISM files stack as rasters, extract raster to points
filenames <- list.files(path=path.in,pattern=paste(".*_",".*\\.bil$", sep = ""))

# use substring of date to later identify and organize data values for each site for the 4 variables needed 
dat_names <- substring(filenames, first = 26, last = 31) # adjusted as we need all of the available years and months
dat_names <- paste0(substring(dat_names,first=1,last=4),"_", substring(dat_names,first=5,last=6)) # cleaned up dates for easier reading 

pts <- c()

# use first date to find grid cell numbers to use (save as 'pts' variable)
loc <- stack(file.path(path.in,filenames[1]))

# get spatial coordinates for PRISM cells
loc.mat <- rasterToPoints(loc)
test.lon <- loc.mat[,1]
test.lat <- loc.mat[,2]

# find PRISM cells that fall into NLDAS grid cell 
for (i in 1:length(test.lon)){
  if ((test.lon[i] >= l.lon) && 
      (test.lon[i] <= t.lon) && 
      (test.lat[i] >= l.lat) && 
      (test.lat[i] <= t.lat)){
    pts = c(pts,i)
  }
}

# create storage matrix 
ndate <- length(filenames)
meanTemp <- matrix(0,ndate,9)

# extract mean data value for each measurement time from all points within grid cell for each site
for (i in 1:ndate){
  single.stack <- stack(file.path(path.in,filenames[i]))
  single.data <- rasterToPoints(single.stack)
  meanTemp[i,] <- single.data[pts,3]
}

# save to output directory 
save(meanTemp,file=file.path(path.out,paste0(site,'.meanTemp.Rdata')))
