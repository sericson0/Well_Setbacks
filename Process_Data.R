#This code transforms projected data into a format conducive for analysis
#Processing steps consist of simplifying data and prebuffering.Files are saved in output_folder
#Processing Steps include:
#     1. wetlands, water_area and water_body are cast into MULTIPOLYGONS format 
#     2. all water data is simplified at the SIMPLIFY_TOLERANCE level (default is 100 meters)
#        This reduces the accuracy of the data, but allows for a reduction in file sizes and computation times
#     3. wetlands, water_area and water body are unionized into a single shapefile titled water
#     4. water is buffered at the MIN_BUFFER_LEN (default is 250 feet) and saved in Water Min Buffer folder as water_buffer_0.rdata 
#     5. water_flow, which is a large file (1.3Gb) is buffered in segments (default of 100,000 objects in each segment) 
#        saved in Min Buffer folder as water_buffer_0 - water_buffer_N
#     6. addresses are buffered in the same way
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#The usual
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
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#Constants 
FOOT_TO_METERS = 0.3048
MIN_BUFFER_LEN = 250*FOOT_TO_METERS
SIMPLIFY_TOLERANCE = 100
CUTOFF = 100000
##
#Folder paths. create new folders as needed
main_folder = "Spatial Data"
input_folder = file.path(main_folder, "Projected Data")
output_folder = file.path(main_folder, "Transformed Data")
water_buffer_folder = file.path(output_folder, "Water Min Buffers")
address_buffer_folder = file.path(output_folder, "Address Min Buffers")
dir.create(output_folder)
dir.create(water_buffer_folder)
dir.create(address_buffer_folder)
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#Helper functions.
#Cast data transforms geometries to MULTIPOLYGON
cast_data = function(name, input_folder, to_shape = "MULTIPOLYGON") {
  st_cast(readRDS(file.path(input_folder, paste0(name, ".rdata"))), to = to_shape)
}
##
#buffer_in_segments buffers at buffer_len by segments - cutoff determining number of objects per segment - and saves 
#buffered segments as output_basename_i for each increment i
buffer_in_segments = function(df, output_basename, cutoff, buffer_len) {
  N = ceiling(length(df)/cutoff)
  for(i in 1:N) {
    tme = proc.time()[3]
    print(paste(i, "of", N))
    saveRDS(st_union(st_buffer(df[((i-1)*cutoff + 1):min(length(water_flow), i*cutoff)], buffer_len)), 
            paste0(output_basename, "_", i, ".rds"))
    print(proc.time()[3] - tme)
  }
}
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#Process wetlands, water area and water body data
wetlands = cast_data("wetlands", input_folder) 
wetlands = st_simplify(wetlands, dTolerance = SIMPLIFY_TOLERANCE)
water_area = cast_data("water_area", input_folder)
water_area = st_simplify(water_area, dTolerance = SIMPLIFY_TOLERANCE)
##
water = st_union(wetlands)
water_area = st_union(water_area)
water = st_union(water, water_area)
##
water_body = cast_data("water_body", input_folder)
water_body = st_union(st_simplify(water_body, dTolerance = SIMPLIFY_TOLERANCE))
water = st_union(water, water_body)
saveRDS(water, file.path(output_folder, "water_simplified.rdata"))
saveRDS(st_buffer(water, MIN_BUFFER_LEN), file.path(water_buffer_folder, "water_buffer_0.rdata"))
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#process water flow data
water_flow = readRDS(file.path(input_folder, "water_flow.rdata"))
water_flow = st_simplify(water_flow, SIMPLIFY_TOLERANCE)
saveRDS(water_flow, "water_flow_simplified.rdata")
buffer_in_segments(water_flow, file.path(water_buffer_folder, "water_buffer"), CUTOFF, MIN_BUFFER_LEN)
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#process address data
addresses = readRDS(file.path(input_folder, "addresses.rdata"))
buffer_in_segments(addresses, file.path(address_buffer_folder, "address_buffer"), CUTOFF, MIN_BUFFER_LEN)

#process other data. Default is no processing
federal_lands = readRDS(file.path(input_folder, "federal_lands.rdata"))
saveRDS(federal_lands, file.path(output_folder, "federal_lands.rdata"))

county_shapefiles = readRDS(file.path(input_folder, "county_shapefiles.rdata"))
saveRDS(county_shapefiles, file.path(output_folder, "county_shapefiles.rdata")) 

field_polygons = readRDS(file.path(input_folder, "field_polygons.rdata"))
saveRDS(field_polygons, file.path(output_folder, "field_polygons.rdata"))
