#This code downloads spatial data 
#Files downloaded include:
#   -BLM land shapefiles from BLM
#   -Hydrology and Wetland data (I believe from USGS)
#   -Building footprint shapes from Microsoft
#   -County Shapefiles from Census
#
#All links were stable as of 2019-03-29
#Code downloads data from links and unzips data
# Zip files are saved in zip_folder and unzipped data is saved in save_folder
#This code should run without additional input
rm(list = ls())
##
#installs package if not currently installed
loadPackage = function(package) {
  if(!require(package, character.only = TRUE)){
    install.packages(package)
    require(package, character.only =TRUE)
  }
}
##

#Sets working directory to wherever code is saved.

#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
#*******!!!!!!!!!!!!!!!!!----------Requires code to be run in Rstudio to work. If not run in R studio then set WD manually----------!!!!!!!!!!!!**********
loadPackage("rstudioapi") 
WD = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(WD)
##
# loadPackage("rgdal")
# loadPackage("sf")
# ##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
#If analysis is for a different state then change this variable
#set folder names
main_folder = "Spatial Data"
zip_folder = "Zipped Data"
save_folder = "Raw Unzipped Data"
dir.create(main_folder)
dir.create(file.path(main_folder, zip_folder))
dir.create(file.path(main_folder, save_folder))
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
download_data = function(url, name, main_folder, zip_folder, save_folder) {
  download.file(url,file.path(main_folder, zip_folder, paste0(name,".zip")), mode = "wb")
  print(paste(name, "data downloaded from", url))
  unzip(file.path(main_folder, zip_folder, paste0(name,".zip")),
        exdir = file.path(main_folder, save_folder,name))
  print(paste(name,"data saved in", file.path(main_folder, save_folder,name)))
  
}

#Downloads BLM data
download_data("https://navigator.blm.gov/api/share/d8420fd21cd3f159", "blm", main_folder, zip_folder, save_folder)
unzip(file.path(main_folder, zip_folder, paste0("blm",".zip")),
      exdir = file.path(main_folder, save_folder,"blm"))
#All federal land data can be downloaded from https://nationalmap.gov/small_scale/atlasftp.html if looking at non-colorado data

#hydrology data
#Data can be found at http://prd-tnm.s3-website-us-west-2.amazonaws.com/?prefix=StagedProducts/Hydrography/NHD/State/HighResolution/Shape/
#For non-Colorado data change "Colorado" in below link to desired state name. 
download_data("https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/State/HighResolution/GDB/NHD_H_Colorado_State_GDB.zip", "hydrology",
              main_folder, zip_folder, save_folder)


#Microsoft Building Data
#We use the Microsoft building footpritnt data https://github.com/Microsoft/USBuildingFootprints
#if looking at non-Colorado Data change Colorado in below link
download_data("https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Colorado.zip", "microsoft_buildings",
              main_folder, zip_folder, save_folder)


#COGCC Data
#We use same projection as from earlier COGCC study
download_data("https://cogcc.state.co.us/documents/data/downloads/gis/2018_Init_97_2500ft_Buffer_Zones.zip", "cogcc_data",
              main_folder, zip_folder, save_folder)


#Wetlands data. Is not necessary to include as we already have most hydrology data. However, to keep close to COGCC analysis we included wetland data as well
download_data("http://128.104.224.198/State-Downloads/CO_geodatabase_wetlands.zip", "wetlands", main_folder, zip_folder, save_folder)
##
#County Shapefiles From Census
download_data("https://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_us_county_5m.zip", "county_shapefiles", main_folder, zip_folder, save_folder)

