# set up important file paths
site = 'GILL'
vers = '.v1'
wd.base = '~/met'

unzips = file.path(wd.base,'ensembles',paste0(site,vers),'1hr/ensembles')
GCM.list = dir(unzips)

for (GCM in GCM.list){
  files.list = list.files(file.path(unzips,GCM), pattern = "\\.bz2$")

  if (length(files.list)>0){
    for (file in files.list){
      # unzip
      path = file.path(unzips,GCM,file)
      system(paste0("tar -xjf ",path," -C ",file.path(unzips,GCM)))
      system(paste0("rm ",path))
    }
  }
}
