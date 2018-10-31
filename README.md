Critical Linkages Web Application
=================================

Jeffrey D Walker, PhD  
[Walker Environmental Research LLC](https://walkerenvres.com)

and

Ben Letcher, PhD
[USGS Conte Anadromous Fish Lab](https://www.usgs.gov/centers/lsc) and [UMass Amherst](https://eco.umass.edu/people/faculty/letcher-ben/)

*Prepared for*:

Scott Jackson and Brad Compton  
[Critical Linkages Project](http://umasscaps.org/applications/critical-linkages.html)  
Dept of Environmental Conservation
UMass Amherst

## About

This repo contains the source code for the Critical Linkages Scenario Builder (CLSB) web application.

## Quick Start

Clone the repo

```
git clone git@github.com:walkerjeffd/umass-clsb.git
cd umass-clsb
```

Install npm packages

```
npm install
```

Set up configuration file for database operations (not required if just running the app).

```
cp config.template.sh config.sh
nano config.sh                   # set db connection settings
```

Set up configuration for API

```
cp api/config.template.js api/config.js
nano api/config.js               # set db connection settings
```

Run API and webpack dev server in separate terminals (both must be running at the same time). Use `screen` or `tmux` if appropriate.

```
npm run api                      # API on localhost:8000
npm run serve                    # app on localhost:8080
```

Open web browser at `http://localhost:8080`

## Datasets

### HUC Boundaries

Download WBD dataset (`NATIONAL_WBD_GDB.zip`) from [USGS NHD website](https://nhd.usgs.gov/data.html) and extract geodatabase from `NATIONAL_WBD_GDB.zip`.

### Town Boundaries

[National Boundary Dataset from The National Map](https://www.sciencebase.gov/catalog/item/4f70b219e4b058caae3f8e19)

Shapefiles: [ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/GovtUnit/Shape/]()

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

#### Barrier-HUC Lookup

Run `db/derived/barrier-huc.sh` to create the `barrier_huc` lookup table, and prune huc tables (limit to extent of barriers).

```
./barrier-huc.sh
```

#### Barrier-Node Lookup

Run `db/derived/barrier-node.sh` to create the `barrier_node` lookup table.

```
./barrier-node.sh
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
