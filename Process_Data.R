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
FEET_TO_METERS = 0.3048
SIMPLIFY_TOLERANCE = 100
MIN_SETBACK = 250
MAX_SETBACK = 3500
SETBACK_STEP = 250
##
#Folder paths. create new folders as needed
main_folder = "Spatial Data"
input_folder = file.path(main_folder, "Projected Data")
output_folder = file.path(main_folder, "Drillable Area")
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
#get_drillable_area gives county area which is not reserved for vulnerable areas
get_drillable_area = function(county, setback) {
  st_difference(county, setback)
}
##
#Create bounding box around county and add maximum setback. This solvesboarder spillover issue.
get_bounding_box = function(county, max_setback) {
  bound_box = st_bbox(county)
  bound_box[1:2] = bound_box[1:2] - max_setback * FEET_TO_METERS
  bound_box[3:4] = bound_box[3:4] + max_setback * FEET_TO_METERS
  return(bound_box)
}

#create_county_drillable_areas gives drillable area for each setback length and zero horizontal drilling given setback affects \
#either only water or addresses.
create_county_drillable_areas = function(county_name, county_shapefiles, wetlands, water_area, water_flow, water_body, addresses, 
                                         min_setback, max_setback, setback_step, output_folder) {
  #get county shapefile
  county = st_geometry(county_shapefiles[which(county_shapefiles$NAME == county_name), ])
    bound_box = get_bounding_box(county, max_setback)
  #Create first setback
  setback_m = min_setback*FEET_TO_METERS
  #
  water_buffers = do.call(c, list(st_buffer(st_crop(wetlands, bound_box), setback_m), st_buffer(st_crop(water_area, bound_box), setback_m),
                                  st_buffer(st_crop(water_flow, bound_box), setback_m),st_buffer(st_crop(water_body, bound_box), setback_m) ))
  ##
  #Unioning takes additional upfront time but reduces file sizes
  water_buffers = st_union(st_cast(water_buffers, 'MULTIPOLYGON'))
  address_buffers = st_union(st_buffer(st_crop(addresses, bound_box), setback_m))
  #Create directory to save data in
  dir.create(file.path(output_folder, county_name))
  #save drillable areas after minimum setback
  saveRDS(get_drillable_area(county, water_buffers), file.path(output_folder, county_name, paste0(county_name,"_", "drillable water_", min_setback, ".rdata")))
  saveRDS(get_drillable_area(county, address_buffers), file.path(output_folder, county_name, paste0(county_name,"_", "drillable addresses_", min_setback, ".rdata")))
  #loops through setback lengths and creates drillable area for each
  setback_lengths = seq(min_setback+setback_step, max_setback, setback_step)
  for(setback_ft in setback_lengths) {
    print(setback_ft)
    setback_step_m = setback_step * FEET_TO_METERS
    water_buffers = st_buffer(water_buffers, setback_step_m)
    address_buffers = st_buffer(address_buffers, setback_step_m)
    saveRDS(get_drillable_area(county, water_buffers), file.path(output_folder, county_name, paste0(county_name,"_", "drillable water_", setback_ft, ".rdata")))
    saveRDS(get_drillable_area(county, address_buffers), file.path(output_folder, county_name, paste0(county_name,"_", "drillable addresses_", setback_ft, ".rdata")))
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
#create drillable surface areas for each county. Takes several hours
for(county_name in county_names) {
  print(county_name)
  tme = proc.time()[3]
  create_county_drillable_areas(county_name, county_shapefiles, wetlands, water_area, water_flow, water_body, addresses, 
                                MIN_SETBACK, MAX_SETBACK, SETBACK_STEP, output_folder)
  print(paste("Creating drillable areas for", county_name, "took", (proc.time()[3] - tme)/60, "minutes"))
}
