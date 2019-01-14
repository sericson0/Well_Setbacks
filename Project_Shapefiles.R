#This code reads in raw data, transforms to given projection (default projection is given by COGCC study),
#and drops z coordinates where necessary. Saves projected data as .rdata files in save_folder (default projected data)
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
FIPS_NUM = "08" #08 is for ColoradoChange if looking at a differe
main_folder = "Spatial Data"
raw_data_folder = "Raw Unzipped Data"
save_folder = "Projected Data"
dir.create(file.path(main_folder, save_folder))
##
#Folder paths is list of where data is saved to from Download_Data.R code
folder_paths = list("wetlands" = file.path("wetlands", "CO_geodatabase_wetlands.gdb"), "cogcc" = file.path("cogcc_data", "2018_Init_97_2500ft_Buffer_Zones.gdb" ),
                    "federal_lands" = file.path("cogcc_data", "2018_Init_97_2500ft_Buffer_Zones.gdb" ),
                    "field_polygons" = "field_polygons", "water_area" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"),
                    "water_body" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"), 
                    "water_flow" = file.path("hydrology", "NHD_H_Colorado_State_GDB.gdb"),
                    "addresses" = file.path("addresses", "CSAD2014PA.gdb"), "county_shapefiles" = "county_shapefiles",
                    "microsoft" = "microsoft_buildings")
#Layers is a list of layers to be extracted
layers = list("wetlands" =  "CO_Riparian", "cogcc" = "Occupied_Structure_and_Vulnerable_Areas_Combined_2500ft_Buffer_Init_97",
              "federal_lands" = "Colorado_Federal_Lands_2018_SOURCE_BLM", "field_polygons" = "COGCC_Fields", 
              "water_area" = "NHDArea", "water_flow" = "NHDFlowline", "water_body" = "NHDWaterbody",
              "addresses" = "CSAD2014PA", "county_shapefiles" = "cb_2017_us_county_5m")
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
#These shapefiles are in default projection so do not need to be projected. Only geometries are extracted
cogcc_setbacks = st_geometry(read_shapefile("cogcc", folder_paths, layers))
federal_lands = st_geometry(read_shapefile("federal_lands", folder_paths, layers))

##
save_shapefile(cogcc_setbacks, "cogcc_setbacks", main_folder, save_folder)
save_shapefile(federal_lands, "federal_lands", main_folder, save_folder)
#set projections to cogcc initial report projection
projection_string = as.character(st_crs(cogcc_setbacks))[2]
##
wetlands = st_geometry(read_shapefile("wetlands", folder_paths, layers))
wetlands = st_transform(wetlands, projection_string)
wetlands = st_union(wetlands)
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
#Oil field shapefiles
# ogrListLayers(field_folder)
# field_polygons = st_geometry(read_shapefile("field_polygons", folder_paths, layers))
#Keep field polygon metadata
field_polygons = read_shapefile("field_polygons", folder_paths, layers)
field_polygons = st_transform(field_polygons, projection_string)
save_shapefile(field_polygons, "field_polygons", main_folder, save_folder)
#Addresses take a couple of minutes to load, so be paitent.
# addresses = st_geometry(read_shapefile("addresses", folder_paths, layers))
# addresses = st_transform(addresses, projection_string)
# save_shapefile(addresses, "addresses", main_folder, save_folder)

#Microsoft Data
microsoft_addresses = geojson_sf(file.path(main_folder, raw_data_folder, folder_paths$microsoft, "Colorado.geojson"))
microsoft_addresses = st_transform(microsoft_addresses, projection_string)
microsoft_centroids = st_centroid(microsoft_addresses)
building_areas = st_area(microsoft_addresses)
save_shapefile(microsoft_centroids, "microsoft_centroids", main_folder, save_folder)
save_shapefile(microsoft_addresses, "microsoft_buildings", main_folder, save_folder)
##


##_______________________________________________________________________________________________
#keep county metadata for county names
counties = read_shapefile("county_shapefiles", folder_paths, layers)

counties = counties[which(counties$STATEFP %in% FIPS_NUM), ]
counties = st_transform(counties, projection_string)
save_shapefile(counties, "county_shapefiles", main_folder, save_folder)


# ba_1 = building_areas[which(as.numeric(building_areas) <= 1e3)]
# 
# pdf("Colorado Building Distribution.pdf", height = 6, width = 8)
# hist(ba_1, breaks = 100, xlab = "Size (m^2)", probability = T, col = "gray", main = "Colorado Building Size Distribution")
# dev.off()
# 
# 
# pdf("building centroids.pdf", height = 6, width = 8)
# plot(st_geometry(counties))
# plot(microsoft_centroids, pch = ".", add = T)
# dev.off()
# 
# pdf("Denver Buildings.pdf", height = 6, width = 8)
# plot(st_geometry(counties[which(counties$NAME == "Denver"), ]))
# plot(microsoft_addresses, col = "gray", add = T)
# dev.off()
# 
# 
# pdf("Denver Buildings_1.pdf", height = 6, width = 8)
# plot(microsoft_addresses, col = "gray", xlim = c(500000,510000), ylim = c(4390000, 4400000))
# dev.off()
# 
