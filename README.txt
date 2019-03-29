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
______________________________________________________________________________________________________________________________________________________________
Things to note:
	-Code can run quite slowly and may require significant amounts of memory and computing power. 
	 This is primary true for the Generate_Horizontal_And_Summary_Stats.R section
	 Each county can be run in parallel so we suggest separating and running on multiple computers.
	 Even so, the process may take several days to a couple of weeks to complete.
	
	-All download links were stable as of 2019-03-29 but no guarantee they will be stable in coming years. If a download fails then you may need to 
	 change the urls in the Download_Data.R code. 
______________________________________________________________________________________________________________________________________________________________
Data is retreived from:
	-Buearu of Land Management (BLM) Data https://navigator.blm.gov/api/share/d8420fd21cd3f159
	 If wanting to run analysis on non-Colrado counties then can download BLM data from https://nationalmap.gov/small_scale/atlasftp.html
 	
	-Hydrology data https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/State/HighResolution/GDB/NHD_H_Colorado_State_GDB.zip
	 Can find hydrology data for all states at 
	 http://prd-tnm.s3-website-us-west-2.amazonaws.com/?prefix=StagedProducts/Hydrography/NHD/State/HighResolution/Shape/
	
	-Wetland data for Colorado http://128.104.224.198/State-Downloads/CO_geodatabase_wetlands.zip
	 Hydrology data covers almost all the same area so may not need to download for non-Colorado data
	
	-County Shapefiles https://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_us_county_5m.zip

	-Building footprint data from Microsoft https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Colorado.zip
	 Data for all states is given at https://github.com/Microsoft/USBuildingFootprints

	-Colorado Oil and Gas Comission (COGCC) data for comparison 
	 https://cogcc.state.co.us/documents/data/downloads/gis/2018_Init_97_2500ft_Buffer_Zones.zip

______________________________________________________________________________________________________________________________________________________________
Things to note:
	1. Setback distances are measured in feet, horizontal drilling is measured in miles, and areas are measured in meters squared. 
	   Apologies for the lack of consistency, but these are the units that seem common in discussions.
	2. Code take a very long time to fully run, but is highly parallelizable. Generate_Setbacks and Generate_Horizontal_And_Summary_Stats
	   take the majority of computing time, but are conducted at the county level so can easily get a 64X speedup (number of counties).
	3. Currently all setback areas are combined into a single shapefile (water and addresses). Can tweak Generate_Setbacks if you desire
	   only one setback.
	4. Code corrects for boarder effects within Colorado counties, so each county value is as if the code were run on the entire state.
	   However, the code treats Colorado as if it were an island, meaning no potential drilling from neighboring states. 
