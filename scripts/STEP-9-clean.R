####################
# Modeling Met Ensemble Workflow
# Step 9 :: Cleaning up working directory 
####################
# This script has been modified so it can be run as a job submission to the CRC's machines. 
#   
# Description: This step contains part of the tenth step of Christy's met workflow, which originally compressed the hourly ensembles members so they could 
# more easily be relocated or downloaded by other users. This script has been altered so that it is compressing the linkages met folders and the weight files 
# into a smaller file for the same reason. Once the file has been compressed, you can delete all the other files. Please check to make sure the converted met is 
# in the "completed" folder before doing this though. 

# Required libraries:

####################
# ALTER ONLY THESE VARIABLES BEFORE SUBMITTING FOR NEW SITE
####################

# Load site and directory details
wd.base = '~/met'
site = "HARVARD" # should be identical to paleon site name 
site.lat  = 42.53
site.lon  = -72.18
vers=".v1"

# input years the met ensembles were generated for (long or short run?)
ens.yr1 = 850
ens.yr2 = 2015

####################
# Step 1: Compress folder
####################

# set up important file paths
in.base = file.path(wd.base, "ensembles", paste0(site, vers), "linkages")
out.base =  file.path(wd.base, "completed")

if(!dir.exists(out.base)) dir.create(out.base,recursive=T)

# compress met file and place in completed folder
system(paste0("tar -jcvf ", file.path(out.base, paste0(site,vers,".tar.bz2 ")), in.base), show.output.on.console = F)


