#This code downloads spatial data for water, addresses, federal lands, oil fields and county shapefiles.
# Zip files are saved in zip_folder and unzipped data is saved in save_folder
#This code should run without additional input
#Start code, then go get a drink and come back in a couple of hours when done. Code takes a while to run

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
#Requires code to be run in Rstudio to work. If not run in R studio then set wd manually
loadPackage("rstudioapi") 
WD = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(WD)
##
# loadPackage("rgdal")
# loadPackage("sf")
# ##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
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
  download.file(url,file.path(main_folder, zip_folder, paste0(name,".zip")))
  print(paste(name, "data downloaded from", url))
  unzip(file.path(main_folder, zip_folder, paste0(name,".zip")),
        exdir = file.path(main_folder, save_folder,name))
  print(paste(name,"data saved in", file.path(main_folder, save_folder,name)))
  
}
##
#BLM data must be manually loaded from 
#https://navigator.blm.gov/data?keyword=surface&format=Data%20in%20a%20File%20Geodatabase%20(FileGDB%20Data)!!Compressed%20Archive%20File%20(ZIP)&fs_publicRegion=Colorado

#Download and unzip data from online
#hydrology data
download_data("https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/State/HighResolution/GDB/NHD_H_Colorado_State_GDB.zip", "hydrology",
              main_folder, zip_folder, save_folder)
# #Address Data
# download_data("https://data.colorado.gov/api/geospatial/n7je-akky?method=export&format=Shapefile", "addresses",
#               main_folder, zip_folder, save_folder)
# 

#Microsoft Building Data
download_data("https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Colorado.zip", "microsoft_buildings",
              main_folder, zip_folder, save_folder)


#COGCC Data
download_data("https://cogcc.state.co.us/documents/data/downloads/gis/2018_Init_97_2500ft_Buffer_Zones.zip", "cogcc_data",
              main_folder, zip_folder, save_folder)

#$COGCC field polygons
download_data("https://cogcc.state.co.us/documents/data/downloads/gis/COGCC_Fields.zip", "field_polygons", main_folder, zip_folder, save_folder)

#Wetlands
download_data("http://128.104.224.198/State-Downloads/CO_geodatabase_wetlands.zip", "wetlands", main_folder, zip_folder, save_folder)
##
#County Shapefiles From Census
download_data("https://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_us_county_5m.zip", "county_shapefiles", main_folder, zip_folder, save_folder)

