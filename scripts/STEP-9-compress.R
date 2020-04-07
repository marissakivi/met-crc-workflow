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
site = "BONANZA" # should be identical to paleon site name 
vers=".v1"

# working directory
wd.base = '~/met-crc-workflow'

####################
# Compress hourly ensembles for CyVerse
####################

# set up important file paths
in.base = file.path(wd.base, "ensembles", paste0(site, vers), "1hr","ensembles")

# get all GCMs for this site
GCMs = list.files(in.base, recursive = FALSE, full.names = TRUE) 

# loop through GCMs and compress files 
for (gcm in GCMs){
  to_comp = list.files(gcm, recursive = FALSE, full.names = FALSE)
  
  for (file in to_comp){
    system(paste0("tar -jcvf ", file.path(gcm,paste0(file, '.tar.bz2 ')), file.path(gcm,file)))
  }
}
