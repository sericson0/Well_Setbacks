Contains R code to download data and run analysis on the effects of well setbacks on oil availability.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!CODE WORKS BEST WHEN RUN IN RStudio!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
If not running code in RStudio you need to manually set working directory.

Code should be run as follows:
	1. Download_Data.R This code downloads shapefiles from internet, unzips and saves to local folder
	2. Project_Shapefiles.R This code projects shapefiles to single projection, and drops metadata for all but county data and oil fields. Saves files as .rdata  
	3. Generate_Setbacks.R This code combines addresses and vulnerable areas into single shapefile and creates setback polygons for various setback distances
   	   Files are saved in 'Setback Areas' folder
	4. Generate_Horizontal_And_Summary_Stats.R This code takes setback areas and creates surface area and underground area available to drilling.
   	   If horizontal is zero then this is the compliment of setback areas. Code also saves summary statistics for each county to folder 'Summary Statistics'
   	   as .csv files


Things to note:
	1. Setback distances are measured in feet, horizontal drilling is measured in miles, and areas are measured in meters squared. 
	   Apologies for the lack of consistency, but these are the units that seem common in discussions.
	2. Code take a very long time to fully run, but is highly parallelizable. Generate_Setbacks and Generate_Horizontal_And_Summary_Stats
	   take the majority of computing time, but are conducted at the county level so can easily get a 64X speedup (number of counties).
	3. Currently all setback areas are combined into a single shapefile (water and addresses). Can tweak Generate_Setbacks if you desire
	   only one setback.
	
Potential things to do
	1. Add check for sufficient surface area to drill. Can do this in the Genearte_Horizontal_And_Summary_Stats, but will take some thinking
	2. Probably would be best to have a separate file with all constants and chosen values, and then import into each code. (Can do this later)
	3. Generate_Horizontal_And_Summary_Stats should be broken into more functions for code readability.
	4. Work on ways to speed up computations.	