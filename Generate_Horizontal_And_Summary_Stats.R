#This code gets horizontal drilling underground areas and and calculates summary statistics
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
MILES_TO_METERS = FEET_TO_METERS * 5280
SIMPLIFY_TOLERANCE = 100
MIN_SETBACK = 250
MAX_SETBACK = 3500
SETBACK_STEP = 250
MAX_HORIZONTAL = 3
HORIZONTAL_STEP = .25
setback_distances = seq(MIN_SETBACK, MAX_SETBACK, SETBACK_STEP) 
horizontal_distances = seq(0, MAX_HORIZONTAL, HORIZONTAL_STEP)
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________

#Folder paths. create new folders as needed
main_folder = "Spatial Data"
projected_folder = file.path(main_folder, "Projected Data")
input_folder = file.path(main_folder, "Setback Areas")
output_folder = file.path(main_folder, "Drillable Areas")
summary_stats_folder = file.path(main_folder, "Summary Statistics")
dir.create(output_folder)
dir.create(summary_stats_folder)
##
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#____________________________________________________________________________________________________________________
#Helper functions
#Bounding box gets area reachable with maximum horizontal drilling
get_bounding_box_shape = function(county, max_horizontal) {
  bound_box = st_bbox(county)
  bound_box[1:2] = bound_box[1:2]  - max_horizontal * MILES_TO_METERS
  bound_box[3:4] = bound_box[3:4]  + max_horizontal * MILES_TO_METERS
  bound_box = st_as_sfc(bound_box)
  return(bound_box)
}
##
#Name of file to output to
get_output_name = function(output_folder, county_name, setback, horizontal) {
  file.path(output_folder, paste0(county_name, "_setback_", setback, "_horizontal_", horizontal, ".rdata"))
}
##Create summary statistics data frame
create_data_frame = function(county_name, setback_distances, horizontal_distances) {
  N_setback = length(setback_distances)
  N_horizontal = length(horizontal_distances)
  df = as.data.frame(rep(county_name, N_setback*N_horizontal))
  names(df) = "county"
  df$setback = rep(setback_distances, each = N_horizontal)
  df$horizontal = rep(horizontal_distances, N_setback)
  df$county_area_m2 = 0
  df$drillable_surface_m2 = 0
  df$drillable_underground_m2 = 0
  df$drillable_surface_pct = 0
  df$drillable_underground_pct = 0
  return(df)
}
##
get_area = function(shape) {
  area = as.numeric(st_area(shape))
  if(length(area) == 0) {
    return(0)
  } else{
    return(area)
  }

}
##
county_shapefiles = readRDS(file.path(projected_folder, "county_shapefiles.rdata"))
county_names = as.character(county_shapefiles$NAME)
##Loop through counties, setbacks and horizontal distances
county_name_subset = county_names[1:64] #There are 64 counties. Subset for parallel processes
for(county_name in county_name_subset) {
  tme = proc.time()[3]
  print(county_name)
  county_folder = file.path(output_folder, county_name) 
  dir.create(county_folder)
  county = st_geometry(county_shapefiles[which(county_shapefiles$NAME == county_name), ])
  df = create_data_frame(county_name, setback_distances, horizontal_distances)
  county_area = get_area(county)
  df$county_area_m2 = county_area
  ##
  for(setback in setback_distances) {
    print(setback)
    setback_shapes = readRDS(file.path(input_folder, county_name, paste0(county_name, "_setback_", setback,".rdata")))
    #st_buffer of 0 converts any lines to polygons
    drillable_surface_shapes = st_difference(get_bounding_box_shape(county, MAX_HORIZONTAL), st_buffer(setback_shapes, 0))
    drillable_surface_county = st_intersection(county, drillable_surface_shapes)
    saveRDS(drillable_surface_county, get_output_name(county_folder, county_name, setback, 0))
    #
    drillable_surface_area = get_area(drillable_surface_county)
    rm(drillable_surface_county)
    df$drillable_surface_m2[which(df$setback == setback)] = drillable_surface_area
    df$drillable_surface_pct[which(df$setback == setback)] = drillable_surface_area/county_area
    df$drillable_underground_m2[which(df$setback == setback & df$horizontal == 0)] = drillable_surface_area
    df$drillable_underground_pct[which(df$setback == setback & df$horizontal == 0)] = drillable_surface_area/county_area
    ##
    drillable_underground_shapes = drillable_surface_shapes
    rm(drillable_surface_shapes)
    gc()
    #Exclude zero horizontal
    for(horizontal in horizontal_distances[-1]) {
      # print(horizontal)
      drillable_underground_shapes = st_buffer(drillable_underground_shapes, HORIZONTAL_STEP*MILES_TO_METERS)
      drillable_underground_county = st_intersection(county, drillable_underground_shapes)
      drillable_underground_area = get_area(drillable_underground_county)
      df$drillable_underground_m2[which(df$setback == setback & df$horizontal == horizontal)] = drillable_underground_area
      df$drillable_underground_pct[which(df$setback == setback & df$horizontal == horizontal)] = drillable_underground_area/county_area
      saveRDS(drillable_underground_county, get_output_name(county_folder, county_name, setback, horizontal))
    }
    
  }
  write.csv(df, file.path(summary_stats_folder, paste0(county_name, ".csv")), row.names =FALSE)
  print(paste("Time to analyze", county_name, "was", (proc.time()[3]-tme)/60, "minutes."))
}


