Critical Linkages Web Application
=================================

Jeffrey D Walker, PhD  
[Walker Environmental Research LLC](https://walkerenvres.com)

*Prepared for*:

Scott Jackson and Brad Compton  
[Critical Linkages Project](http://umasscaps.org/applications/critical-linkages.html)  
Dept of Environmental Conservation
UMass Amherst

## About

This repo contains the source code for the Critical Linkages Scenario Builder (CLSB) web application.

The development version of the shiny app is available at: http://shiny.ecosheds.org/users/jeff/clsb

## Datasets

### HUC Boundaries

Download WBD dataset (`NATIONAL_WBD_GDB.zip`) from [USGS NHD website](https://nhd.usgs.gov/data.html) and extract geodatabase from `NATIONAL_WBD_GDB.zip`.

### Graph Tiles

The graph tiles are stored in a series of RDS binary data files.

The filename for each tile is: `graphXXXYYY.RDS` where `XXX` is the three digit row number and `YYY` is the three digit column number.

A list of all tiles including bounding box (xmin, xmax, ymin, ymax) is listed in the `graphtiles.txt` file.

### Barriers

The geospatial culverts and dams layers can be downloaded from: https://scholarworks.umass.edu/data/55/

Download the zip file and extract shapefiles.

### Geospatial Projection

All geospatial data (i.e. stream crossings) are stored in [NAD83 / Conus Albers (EPSG:5070)](http://prj2epsg.org/epsg/5070)

```txt
PROJCS["NAD_1983_Albers",
  GEOGCS["GCS_North_American_1983",
    DATUM["D_North_American_1983",
      SPHEROID["GRS_1980",6378137.0,298.257222101]],
    PRIMEM["Greenwich",0.0],
    UNIT["Degree",0.0174532925199433]],
  PROJECTION["Albers"],
  PARAMETER["False_Easting",0.0],
  PARAMETER["False_Northing",0.0],
  PARAMETER["Central_Meridian",-96.0],
  PARAMETER["Standard_Parallel_1",29.5],
  PARAMETER["Standard_Parallel_2",45.5],
  PARAMETER["Latitude_Of_Origin",23.0],
  UNIT["Meter",1.0]]
```

## Database

### Initialization

Create a new database and set up schema:

```
cd db
./init.sh
```

### Import Data

Set working directory to `db/import` folder

```
cd db/import
```

#### Culverts

Run the `culverts.sh` bash script to import the DSL shapefile into the `culverts` table in the database.

```
./culverts.sh /path/to/DSL_critical_linkages_culverts_v3.0.shp
```

#### Dams

Run the `dams.sh` bash script to import the DSL shapefile into the `dams` table in the database.

```
./dams.sh /path/to/DSL_critical_linkages_dams_v3.0.shp
```

#### HUC Layers

Run `wbd-huc.sh` script to populate the `wbdhu{4,6,8,10,12}` tables.

```
./wbd-huc.sh /path/to/NATIONAL_WBD_GDB.gdb
```

### Derived Data

Set working directory to `db/derived` folder

```
cd db/derived
```

#### Barriers

Merge the `culverts` and `dams` tables into a single `barriers table`.

```
./barriers.sh
```

#### Barriers-Huc Lookup

Run `db/derived/barriers-huc.sh` to create the `barriers_huc` lookup table, and prune huc tables (limit to extent of barriers).

```
./barriers-huc.sh
```

## Model Code

### Algorithm

```txt
graph.linkages
  get.graph.tiles
    trim.graph
    find.nodes
    trim.along.graph
    graph.kernel.spread
  graph.kernel
    graph.kernel.spread
```

Each function is stored within its own R script i nthe `r/functions/` directory.

The `r/load-functions.R` script will load all functions are once (requires `cwd = r/`).

### Demo Calculation

Run the `r/demo.R` code line-by-line.

## Shiny App

After setting up database, first create huc8.geojson file.

```
cd db/export/
./huc8-geojson.sh ../../r/geojson/huc8.geojson
```

Then run `r/load-huc8.R` to convert from geojson to rds.

```
cd r
Rscript load-huc8.R
```

Create symbolic link to shiny app for deployment

```
cd ~/ShinyApps
ln -s ~/path/to/umass-clsb/r/shiny ~/ShinyApps/clsb
```
