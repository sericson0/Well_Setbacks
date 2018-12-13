#This code takes in transformed shapefiles and returns the drillable surface area for each county. 
#Return files are drillable area if only addresses have setbacks and drillable area if only water has setbacks
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
source("./Constants.R")
#Constants 
# FEET_TO_METERS 
# MILES_TO_METERS 
# SIMPLIFY_TOLERANCE
# MIN_SETBACK 
# MAX_SETBACK 
# SETBACK_STEP
# MAX_HORIZONTAL
# HORIZONTAL_STEP
##
#Folder paths. create new folders as needed
main_folder = "Spatial Data"
input_folder = file.path(main_folder, "Projected Data")
output_folder = file.path(main_folder, "Setback Areas")
dir.create(output_folder)
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#Helper functions.
#Cast data transforms geometries to MULTIPOLYGON
cast_data = function(name, input_folder, to_shape = "MULTIPOLYGON") {
  st_cast(readRDS(file.path(input_folder, paste0(name, ".rdata"))), to = to_shape)
}
##
#Create bounding box around county and add maximum setback. This solves boarder spillover issue.
get_bounding_box = function(county, max_setback, max_horizontal) {
  bound_box = st_bbox(county)
  bound_box[1:2] = bound_box[1:2] - max_setback * FEET_TO_METERS - max_horizontal * MILES_TO_METERS
  bound_box[3:4] = bound_box[3:4] + max_setback * FEET_TO_METERS + max_horizontal * MILES_TO_METERS
  return(bound_box)
}


create_county_min_setback = function(county_name, county_shapefiles, wetlands, water_area, water_flow, water_body, addresses) {
  county = county = st_geometry(county_shapefiles[which(county_shapefiles$NAME == county_name),])
  bound_box = get_bounding_box(county, MAX_SETBACK, MAX_HORIZONTAL)
  setback_m = MIN_SETBACK*FEET_TO_METERS
  #
  print("starting to create setback shape")
  tme1 = proc.time()[3]
  minimum_setbacks = do.call(c, list(st_buffer(st_crop(wetlands, bound_box), setback_m), st_buffer(st_crop(water_area, bound_box), setback_m),
                                     st_buffer(st_crop(water_flow, bound_box), setback_m),st_buffer(st_crop(water_body, bound_box), setback_m),
                                     st_union(st_buffer(st_crop(addresses, bound_box), setback_m))))
  minimum_setbacks = st_union(minimum_setbacks)
  print(paste("time to create setback shape was", proc.time()[3] - tme1))
  return(minimum_setbacks)
}
##
create_buffer_zones = function(min_setback_shape, county_name, output_folder) {
  setback_add = SETBACK_STEP*FEET_TO_METERS
  county_output_folder = file.path(output_folder, county_name)
  dir.create(county_output_folder)
  setback_shape = min_setback_shape
  saveRDS(setback_shape, file.path(county_output_folder, paste0(county_name, "_setback_", MIN_SETBACK,".rdata")))
  #
  for(setback in  seq(MIN_SETBACK + SETBACK_STEP, MAX_SETBACK, SETBACK_STEP)) {
    print(setback)
    setback_shape = st_buffer(setback_shape, setback_add)
    saveRDS(setback_shape, file.path(county_output_folder, paste0(county_name, "_setback_", setback,".rdata")))
  }
}

#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#pre-process data
wetlands = cast_data("wetlands", input_folder) 
wetlands = st_simplify(wetlands, dTolerance = SIMPLIFY_TOLERANCE)
water_area = cast_data("water_area", input_folder)
water_area = st_simplify(water_area, dTolerance = SIMPLIFY_TOLERANCE)
##
water_body = cast_data("water_body", input_folder)
water_body = st_simplify(water_body, dTolerance = SIMPLIFY_TOLERANCE)
water_flow = readRDS(file.path(input_folder, "water_flow.rdata"))
addresses = readRDS(file.path(input_folder, "addresses.rdata"))
county_shapefiles = readRDS(file.path(input_folder, "county_shapefiles.rdata"))
county_names = as.character(county_shapefiles$NAME)
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#create drillable surface areas for each county. Takes several hours unless run in parallel
county_subset = county_names[1:length(county_names)]
#No Rio Grand
for(county_name in county_subset) {
  print(county_name)
  tme = proc.time()[3]
  create_buffer_zones(create_county_min_setback(county_name, county_shapefiles, wetlands, water_area, water_flow, water_body, addresses),
                      county_name, output_folder)
    print(paste("Creating setback areas for", county_name, "took", (proc.time()[3] - tme)/60, "minutes"))
}


