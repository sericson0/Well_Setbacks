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
#Constants include :
# FEET_TO_METERS
# MILES_TO_METERS 
# SIMPLIFY_TOLERANCE
# MIN_SETBACK 
# MAX_SETBACK 
# SETBACK_STEP 
# MAX_HORIZONTAL
# HORIZONTAL_STEP
# setback_distances
# horizontal_distances 
#REMOVE_SMALL_AREAS
#MIN_WELLPAD_ACRES 
#ADD_FEDERAl_LANDS 
#SUBSET_FEDERAL_LANDS_TO_BLM
source("./Constants.R")
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
get_drillable_county_shape = function(county, shape, federal = NULL) {
  drillable_shape = st_intersection(st_buffer(county,0), st_buffer(shape,0))
  drillable_shape = st_buffer(st_difference(st_buffer(drillable_shape,0), st_buffer(federal,0)),0)
  return(drillable_shape)
}

##
#gets rid of small areas where a well pad could not be placed
remove_small_surface_areas = function(multipoly, min_wellpad_acres) {
  poly = st_cast(multipoly, "POLYGON")
  poly = poly[which(as.numeric(st_area(poly)) >= min_wellpad_acres * ACRES_TO_METERS)]
  return(st_union(poly))
}
##
blm_lands = readRDS(file.path(projected_folder, "blm.rdata"))
federal_lands = readRDS(file.path(projected_folder, "federal.rdata"))

county_shapefiles = readRDS(file.path(projected_folder, "county_shapefiles.rdata"))
county_names = as.character(county_shapefiles$NAME)
##Loop through counties, setbacks and horizontal distances
county_name_subset = county_names[which(county_names == "Montrose"):64] #there are 64 counties. Subset for parallel processes
for(county_name in county_name_subset) {
  tme = proc.time()[3]
  print(county_name)
  county_folder = file.path(output_folder, county_name) 
  dir.create(county_folder)
  #subset to county
  county = st_geometry(county_shapefiles[which(county_shapefiles$NAME == county_name), ])
  county_bound_box =  get_bounding_box_shape(county, MAX_HORIZONTAL)
  blm_county_bound_box = st_intersection(st_buffer(blm_lands, 0), county_bound_box)
  blm_county = st_intersection(blm_county_bound_box, county)
  federal_county = st_intersection(county, st_buffer(federal_lands, 0))
  #
  df = create_data_frame(county_name, setback_distances, horizontal_distances)
  county_area = get_area(county)
  df$county_area_m2 = county_area
  df$federal_lands_m2 = get_area(federal_county)
  df$blm_lands_m2 = get_area(blm_county)
  df$non_federal_county_area_m2 = df$county_area_m2[1] - df$federal_lands_m2[1]
  ##
  #Gets either full county area or area not off-limits from federal land
  county_area = df$non_federal_county_area_m2[1]
  ##

  for(setback in setback_distances) {
    t = proc.time()[3]
    print(setback)
    setback_shapes = readRDS(file.path(input_folder, county_name, paste0(county_name, "_setback_", setback,".rdata")))
    #st_buffer of 0 converts any lines to polygons
    drillable_surface_shapes = st_difference(get_bounding_box_shape(county, MAX_HORIZONTAL), st_buffer(setback_shapes, 0))
    #Add BLM land back in
    drillable_surface_shapes = st_union(st_difference(st_buffer(drillable_surface_shapes, 0), st_buffer(federal_county,0)), st_buffer(blm_county_bound_box, 0))
    #
    if(REMOVE_SMALL_AREAS == TRUE) {
      drillable_surface_shapes = remove_small_surface_areas(drillable_surface_shapes, MIN_WELLPAD_ACRES)
    }
    #
    #Remove federal lands and subset to county
    
    drillable_surface_county = get_drillable_county_shape(st_buffer(county,0), st_buffer(drillable_surface_shapes,0), st_buffer(federal_county, 0))
    saveRDS(drillable_surface_county, get_output_name(county_folder, county_name, setback, 0))
    #
    drillable_surface_area = get_area(drillable_surface_county)
    df$drillable_surface_m2[which(df$setback == setback)] = drillable_surface_area
    df$drillable_surface_pct[which(df$setback == setback)] = drillable_surface_area/county_area
    df$drillable_underground_m2[which(df$setback == setback & df$horizontal == 0)] = drillable_surface_area
    df$drillable_underground_pct[which(df$setback == setback & df$horizontal == 0)] = drillable_surface_area/county_area
    ##
    rm(drillable_surface_county)
    ##
    drillable_underground_shapes = drillable_surface_shapes
    rm(drillable_surface_shapes)
    gc()
    print(paste("time for setback preprocessing", t - tme))
    #Exclude zero horizontal
    for(horizontal in horizontal_distances[-1]) {
      # print(horizontal)
      #buffer area to generate horizontal setback
      t = proc.time()[3]
      drillable_underground_shapes = st_buffer(drillable_underground_shapes, HORIZONTAL_STEP*MILES_TO_METERS)
      # print(paste("horizontal 1", round((proc.time()[3]-t)/60, 2)))
      t = proc.time()[3]
      drillable_underground_county = get_drillable_county_shape(county, drillable_underground_shapes, st_buffer(federal_county, 0 ))
      # print(paste("horizontal 2", round((proc.time()[3]-t)/60, 2)))
      #
      drillable_underground_area = get_area(drillable_underground_county)
      df$drillable_underground_m2[which(df$setback == setback & df$horizontal == horizontal)] = drillable_underground_area
      df$drillable_underground_pct[which(df$setback == setback & df$horizontal == horizontal)] = drillable_underground_area/county_area
      saveRDS(drillable_underground_county, get_output_name(county_folder, county_name, setback, horizontal))
      # print(paste("horizontal times", proc.time()[3]-t))
    }
  }
  write.csv(df, file.path(summary_stats_folder, paste0(county_name, ".csv")), row.names =FALSE)
  print(paste("Time to analyze", county_name, "was", (proc.time()[3]-tme)/60, "minutes."))
}
##

