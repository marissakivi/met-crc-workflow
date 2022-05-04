

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
if (!require('R.matlab',lib.loc ='~/Rlibs')) install.packages('R.matlab',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tictoc',lib.loc='~/Rlibs')) install.packages('tictoc',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('dplyr',lib.loc='~/Rlibs')) install.packages('dplyr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('tibble',lib.loc='~/Rlibs')) install.packages('tibble',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('withr',lib.loc='~/Rlibs')) install.packages('withr',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('ggplot2',lib.loc='~/Rlibs')) install.packages('ggplot2',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('udunits2', lib.loc ='~/Rlibs')) install.packages('udunits2',type = 'source',repos = "http://cran.rstudio.com",lib='~/Rlibs',dependencies=TRUE)
if (!require('rgdal',lib.loc ='~/Rlibs')) install.packages('raster',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)
if (!require('raster',lib.loc ='~/Rlibs')) install.packages('raster',lib='~/Rlibs',repos='http://cran.us.r-project.org',dependencies=TRUE)


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
require(withr,lib.loc='~/Rlibs')
require(ggplot2,lib.loc='~/Rlibs')
require(tibble,lib.loc='~/Rlibs')

