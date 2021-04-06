# SSURGO-Query Tool (SSURGO-QT)
## National SSURGO Data Filter and Download Tool, developed for CEAP-Grazing Lands

This was created through a partnership with the NRCS Resource Assessment Branch CEAP-Grazing Lands, Soil and Plant Sciences Division, Resource Management Systems LLC, and Stone Environmental.  The tool is intended to aid soil scientists, ecological site developers, modelers, and conservation planners with a quick geospatial soil characteristic selection filter. The soil characteristics within SSURGO-QT have been chosen because they drive plant community and ecological site concepts, either singly or in combination with additional characteristics.  It is different than other SSURGO tools in that it starts with querying soil properties and not soil map units.

# Soil characteristics "deep dive" for CEAP Grazing Lands
This will help parse out (tabularly and spatially) soil map unit component data elements that drive vegetation and water dynamics and help contribute to modeling conservation practice effects and ecological site development concepts. This type of data dive and display can also help both discretize and aggregate heterogenous landscapes into “modelable” units and use in CART layers.


This project would extract specific soil characteristic data from gSSURGO for use in CEAP-Grazing Land modeling and other project work. The attached spreadsheet outlines each characteristic needed, plus identifies certain depth or thickness criteria to break up a given characteristic. This feeds into ESD concepts as well as modeling efforts. The request would ideally produce both tabular and spatial data.

### Additional Information
1. SQL version provided by Paul Finnell: [Click here](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/SQL-Library/Lori_CarrieAnn_NASIS%20script%20from%20Finnell.txt)
2. Spreadsheet: [Click here](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/documents/CEAP-GL_Soil%20App%20GUI_data%20to%20StoneEnviro_11-9-2020%20copy.xlsx?raw=true)


### SQL
1. Management Studio [Click here](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/SQL-Library/CEAP_Grazing.sql)
2. Soil Data Access - State or Soil Survey Area [Click here](https://raw.githubusercontent.com/jneme910/CEAP-Grazing-Lands/master/SQL-Library/STATE_CEAP_Grazing_2019_0213.txt)


# Detailed Soil Survey Data (SSURGO/gSSURGO) 
The underlying data source for this application is derived from the July 2020 release of the USDA-NRCS SSURGO spatial and tabular data (Soil Survey Staff 2020).  A custom SQL query was written to extract data fields relevant to the CEAP-GL interests for this application. The data will be refreshed annually following the official release from the USDA-NRCS, throughout the life cycle of the application.  Soil properties and characteristics queried from the SSURGO dataset and displayed as filter criteria within the SSURGO-QT application are included in the list below. Note that when you download the data, there is additional tabular data provided that was not included in the filter. That additional data may be useful to the user, but the CEAP-GL team intentionally excluded it from being filterable for various reasons. 

1.	Soil Moisture and Temperature (class, subclass and regimes)
2.	Surface Texture Characteristics
3.	Surface Cover of Coarse Fragments
4.	Coarse Fragments in Top Horizon
5.	Soil Depth
6.	Water Table
7.	Hydrologic Group
8.	Slope Class (percent)
9.	Available Water (both capacity and storage)
10.	Soil Chemistry Characteristics (Electrical Conductivity, Sodium Adsorption Ratio, Calcium Carbonate Equivalent, and Percent Gypsum, Subgroup and Great Group taxonomy for selected chemistries)
11.	Restrictions (with choice of restriction kind)
12.	Diagnostic Horizon or Feature
13.	Ecological Site (by ID or name)
14.	Soil Component (by name)

Major Land Resource Areas (MLRAs) 
Major Land Resource Areas (MLRAs) as published in 2006 are provided as a reference map layer as a starting point for querying SSURGO data. The MLRA Geographic Database serves as the geospatial expression of the map products presented and described in Agricultural Handbook 296 (USDA-NRCS 2006).   
Major land resource areas are geographically associated land resource units. They have unique soils, climate, water resources and land use as well as physiography, geology, and biological resources. Identification of these large areas is important in statewide agricultural planning and has value in interstate, regional, and national planning. 

## Base Maps  

The basemap displayed in the tool is the Esri World Topographic Map, which displays a series of relevant place names, administrative boundaries, hydrologic features, road, and other standard basemap features, overlaid on a hillshade relief basemap to display relief and elevational reference.  This basemap is compiled and provided directly from Esri as a hosted service, and includes data from a variety of sources.  The Basemap Switcher tool is located in the upper right corner of the tool (see image below), and provides a wide array of basemaps if the user wishes to view the data with a basemap other than the World Topographic default basemap.   

