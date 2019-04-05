#This code reads in raw data, transforms to given projection (default projection is given by COGCC study),
#and drops z coordinates where necessary. Saves projected data as .rdata files in save_folder (default projected data)
#Code takes around 10-15 minutes to run
rm(list = ls())
##
#installs package if not currently installed
loadPackage = function(package) {
  if(!require(package, character.only = TRUE)){
    install.packages(package)
    require(package, character.only =TRUE)
  }
}
#Sets working directory to wherever code is saved.
#Requires code to be run in Rstudio to work. If not run in R studio then set wd manually
loadPackage("rstudioapi") 
WD = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(WD)
##
loadPackage("sf")
loadPackage("geojsonsf")
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
FIPS_NUM = "08" #08 is for ColoradoChange if looking at a different county then changer FIPS NUM
main_folder = "Spatial Data"
raw_data_folder = "Raw Unzipped Data"
save_folder = "Projected Data"
dir.create(file.path(main_folder, save_folder))
##
#Folder paths is list of where data is saved to from Download_Data.R code
folder_paths = list("wetlands" = file.path("wetlands", "CO_geodatabase_wetlands.gdb"), 
                    "cogcc" = file.path("cogcc_data", "2018_Init_97_2500ft_Buffer_Zones.gdb" ),
                    "water_area" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"),
                    "water_body" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"), 
                    "water_flow" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"),
                    "county_shapefiles" = "county_shapefiles",
                    "microsoft" = "microsoft_buildings", 
                    "blm" = "blm")
#Layers is a list of layers to be extracted
layers = list("wetlands" =  "CO_Riparian", 
              "cogcc" = "Occupied_Structure_and_Vulnerable_Areas_Combined_2500ft_Buffer_Init_97",
              "water_area" = "NHDArea", 
              "water_flow" = "NHDFlowline", 
              "water_body" = "NHDWaterbody",
              "county_shapefiles" = "cb_2017_us_county_5m", 
              "blm" = "BLM_CO_SMA_20181221")
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
read_shapefile = function(name, folder_paths, layers) {
  st_read(dsn = file.path(main_folder, raw_data_folder, as.character(folder_paths[name])), layer = as.character(layers[name]))
}
##
save_shapefile = function(shapes, name, main_folder, save_folder) {
  saveRDS(shapes, file.path(main_folder, save_folder, paste0(name, ".rdata")))
}
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
##_______________________________________________________________________________________________
#Use for projection string and for comparison, otherwise not required in analysis.
#Projection string is "+proj=utm +zone=13 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs" 
cogcc_setbacks = st_geometry(read_shapefile("cogcc", folder_paths, layers))

#set projections to cogcc projection
projection_string = as.character(st_crs(cogcc_setbacks))[2]
##
save_shapefile(cogcc_setbacks, "cogcc_setbacks", main_folder, save_folder)

##
wetlands = st_geometry(read_shapefile("wetlands", folder_paths, layers))
wetlands = st_transform(wetlands, projection_string)
save_shapefile(wetlands, "wetlands", main_folder, save_folder)
##
water_area = st_geometry(read_shapefile("water_area", folder_paths, layers))
water_area = st_transform(water_area, projection_string)
water_area = st_zm(water_area) #drop altitude
save_shapefile(water_area, "water_area", main_folder, save_folder)
##
water_body = st_geometry(read_shapefile("water_body", folder_paths, layers))
water_body = st_transform(water_body, projection_string)
water_body = st_zm(water_body)
save_shapefile(water_body, "water_body", main_folder, save_folder)
##
water_flow = st_geometry(read_shapefile("water_flow", folder_paths, layers))
water_flow = st_transform(water_flow, projection_string)
water_flow = st_zm(water_flow)
save_shapefile(water_flow, "water_flow", main_folder, save_folder)

rm(water_flow); gc() #free up memory space



#Microsoft Data
#For some large non-Colorado shapefiles the file may be too big for geojson_sf (reaches string limit for texas). For these states the geojson file 
#may be split, loaded separately, and then recombined once loaded into R. 
#If looking at non-Colorado state then change Colorado.geojson below to desired State.
microsoft_addresses = geojson_sf(file.path(main_folder, raw_data_folder, folder_paths$microsoft, "Colorado.geojson"))
microsoft_addresses = st_transform(microsoft_addresses, projection_string)
save_shapefile(microsoft_addresses, "microsoft_buildings", main_folder, save_folder)
##
#Project county data
counties = read_shapefile("county_shapefiles", folder_paths, layers)
counties = counties[which(counties$STATEFP %in% FIPS_NUM), ]
counties = st_transform(counties, projection_string)
save_shapefile(counties, "county_shapefiles", main_folder, save_folder)

##Project BLM Federal Land Data
federal = read_shapefile("blm", folder_paths, layers)
blm = federal[which(federal$adm_manage == "BLM"), ]
blm = st_transform(blm, projection_string)
blm = st_union(blm)
save_shapefile(blm, "blm", main_folder, save_folder)
##
federal = st_transform(federal, projection_string)
federal = st_union(federal)
save_shapefile(federal, "federal", main_folder, save_folder)

