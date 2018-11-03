Contains R code to download data and run analysis on the effects of well setbacks on oil availability.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!CODE WORKS BEST WHEN RUN IN RStudio!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
If not running code in RStudio you need to manually set working directory.

Code should be run as follows:
1. Download_Data.R This code downloads shapefiles from internet, unzips and saves to local folder
2. Project_Shapefiles.R This code projects shapefiles to single projection, and drops metadata for all but county data and oil fields. Saves files as .rdata  