# Mass Download of R Packages for met workflow

# adjust these variables
user = 'mkivi'
# 

first = substr(user,1,1)

# attach all libraries that are available to all CRC users 
require(MASS)
require(colorspace)
require(data.table)
require(lubridate)
require(glue)
require(mgcv)
require(parallel)
require(plyr)
require(reshape2)
require(stringr)
require(stats)
require(stringr)
require(stats)
require(utils)

# download all required libraries that are not found on the CRC 
if (!require('abind',lib.loc ='~/Rlibs')) install.packages('abind',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('latex2exp',lib.loc='~/Rlibs')) install.packages('latex2exp',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('limSolve',lib.loc='~/Rlibs')) install.packages('limSolve',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('maps',lib.loc='~/Rlibs')) install.packages('maps',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=T)
if (!require('sp',lib.loc ='~/Rlibs')) install.packages('sp',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('raster',lib.loc ='~/Rlibs')) install.packages('raster',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

# install rgdal 
# prerequisites for installing rgdal R package
# manually install proj 
# proj_dir <- paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/proj')
# system(paste0("mkdir ", proj_dir))
# system(paste0("wget --directory-prefix=", proj_dir, " https://download.osgeo.org/proj/proj-6.0.0.tar.gz"))
# setwd(proj_dir)
# system("tar xzvf proj-6.0.0.tar.gz")
# setwd(file.path(proj_dir, "proj-6.0.0"))
# system(paste0("./configure --prefix=", proj_dir, "/local"))
# system("make")
# system("make install")
# 
# # manually install gdal
# gdal_dir <- paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/gdal')
# system(paste0("mkdir ", gdal_dir))
# system(paste0("wget --directory-prefix=", gdal_dir, " http://download.osgeo.org/gdal/3.0.4/gdal-3.0.4.tar.gz"))
# setwd(gdal_dir)
# system("tar xzvf gdal-3.0.4.tar.gz")
# setwd(file.path(gdal_dir, "gdal-3.0.4"))
# system(paste0("./configure --prefix=", gdal_dir, '/local --with-proj=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/proj/local'))
# system("make")
# system("make install")
#Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv("LD_LIBRARY_PATH"), ":","/afs/crc.nd.edu/user/",first,"/",user,"/Rlibs/gdal/"))

#if (!require('rgdal',lib.loc ='~/Rlibs')) install.packages('rgdal',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=FALSE)
#if (!require('rgdal',lib.loc ='~/Rlibs')) install.packages('rgdal',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=FALSE,
                                                           #configure.args = paste0('--with-gdal-config=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/gdal/local/bin/gdal-config',
                                                                                   #' --with-proj-include=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/proj/local/include')),
                                                                                  # ' --with-proj-lib=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/proj/local/lib'))
                                                                                   #' --with-proj-dir=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/proj/local/'))
                                                                                    
if (!require('R.matlab',lib.loc ='~/Rlibs')) install.packages('R.matlab',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tictoc',lib.loc='~/Rlibs')) install.packages('tictoc',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('dplyr',lib.loc='~/Rlibs')) install.packages('dplyr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tibble',lib.loc='~/Rlibs')) install.packages('tibble',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2',lib.loc='~/Rlibs')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)

# prerequisites to installing udunits2 R package
# manually install udunits
udunits_dir <- paste0('/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/udunits')
system(paste0("mkdir ", udunits_dir))
system(paste0("wget --directory-prefix=", udunits_dir, " https://artifacts.unidata.ucar.edu/repository/downloads-udunits/udunits-2.2.28.tar.gz"))
setwd(udunits_dir)
system("tar xzvf udunits-2.2.28.tar.gz")
setwd(file.path(udunits_dir, "udunits-2.2.28"))
system(paste0("./configure --prefix=", udunits_dir, "/local"))
system("make")
system("make install")

# install udunits2
Sys.setenv(LD_LIBRARY_PATH=paste0(Sys.getenv("LD_LIBRARY_PATH"), ":","/afs/crc.nd.edu/user/",first,"/",user,"/Rlibs/udunits/local/lib"))
if (!require('udunits2', lib.loc ='~/Rlibs')) install.packages('udunits2',type = 'source',repos = "http://cran.rstudio.com",lib='~/Rlibs',dependencies=TRUE, configure.args=paste0('--with-udunits2-lib=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/udunits/local/lib --with-udunits2-include=/afs/crc.nd.edu/user/',first,'/',user,'/Rlibs/udunits/local/include'))
dyn.load(paste0("/afs/crc.nd.edu/user/",first,"/",user,"/Rlibs/udunits/local/lib/libudunits2.so.0"))
#dyn.load(paste0("/afs/crc.nd.edu/user/",first,"/",user,"Rlibs/rgdal/libs/rgdal.so"))

# check to make sure all R packages were correctly installed
require(abind,lib.loc='~/Rlibs')
require(latex2exp,lib.loc='~/Rlibs')
require(limSolve,lib.loc='~/Rlibs')
require(maps,lib.loc='~/Rlibs')
require(ncdf4,lib.loc='~/Rlibs')
require(sp, lib.loc = '~/Rlibs')
require(raster, lib.loc='~/Rlibs')
#require(rgdal,lib.loc='~/Rlibs')
require(R.matlab,lib.loc='~/Rlibs')
require(tictoc,lib.loc='~/Rlibs')
require(udunits2,lib.loc='~/Rlibs')
require(dplyr,lib.loc='~/Rlibs')
require(ggplot2,lib.loc='~/Rlibs')
require(tibble,lib.loc='~/Rlibs')