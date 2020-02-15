

rm(list=ls())
if (!require('tibble', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('tibble',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ncdf4', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('ncdf4',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('ggplot2',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('lubridate', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('lubridate',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('utils', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('utils',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('glue', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('glue',lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv("LD_LIBRARY_PATH"), ":","/afs/crc.nd.edu/user/m/mkivi/Rlibs/udunits/local/lib"))
if (!require('udunits2', lib.loc = '/afs/crc.nd.edu/user/m/mkivi/Rlibs')) install.packages('udunits2',type = 'source',repos = "http://cran.rstudio.com",lib='/afs/crc.nd.edu/user/m/mkivi/Rlibs',dependencies=TRUE, configure.args='--with-udunits2-lib=/afs/crc.nd.edu/user/m/mkivi/Rlibs/udunits/local/lib --with-udunits2-include=/afs/crc.nd.edu/user/m/mkivi/Rlibs/udunits/local/include')
dyn.load(paste0("/afs/crc.nd.edu/user/m/mkivi/Rlibs/udunits/local/lib/libudunits2.so.0"))

require(ncdf4, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(ggplot2, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(lubridate, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(utils, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(tibble, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(glue, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')
require(udunits2, lib.loc='/afs/crc.nd.edu/user/m/mkivi/Rlibs')

site.name = 'SYLVANIA'
site.lat = 46.241944
site.lon = -89.347778

wd.base = '~/Desktop/met-crc-workflow/'
path.out = file.path(wd.base, 'data','paleon_sites',site.name)
path.pecan = file.path(wd.base,'functions')

source(file.path(path.pecan, 'download.CRUNCEP_Global.R'))
download.CRUNCEP(outfolder=file.path(path.out, "CRUNCEP"), 
                 start_date="1901-01-01", end_date="1910-12-31", 
                 site_id=site.name, lat.in=site.lat, lon.in=site.lon)
