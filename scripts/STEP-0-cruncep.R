

rm(list=ls())
if (!require('ncdf4')) install.packages('ncdf4',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('lubridate')) install.packages('lubridate',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('utils')) install.packages('utils',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tibble')) install.packages('tibble',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('glue')) install.packages('glue',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('udunits2')) install.packages('udunits2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

require(ncdf4, lib='~/Rlibs')
require(ggplot2, lib='~/Rlibs')
require(lubridate, lib='~/Rlibs')
require(utils, lib='~/Rlibs')
require(tibble, lib='~/Rlibs')
require(glue, lib='~/Rlibs')
require(udunits2, lib='~/Rlibs')

site.name = 'HARVARD'
site.lat = 42.53
site.lon = -72.18

wd.base = '~/met-crc-workflow/'
path.out = file.path(wd.base, 'data','paleon_sites',site.name)
path.pecan = file.path(wd.base,'functions')

source(file.path(path.pecan, 'download.CRUNCEP_Global.R'))
download.CRUNCEP(outfolder=file.path(path.out, "CRUNCEP"), 
                 start_date="1901-01-01", end_date="1903-12-31", 
                 site_id=site.name, lat.in=site.lat, lon.in=site.lon)
