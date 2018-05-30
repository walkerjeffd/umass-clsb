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

This repo contains the source code for the Critical Linkages web application.

The web application is not currently live.

## Datasets

### Graph Tiles

The graph tiles are stored in a series of RDS binary data files.

The filename for each tile is: `graphXXXYYY.RDS` where `XXX` is the three digit row number and `YYY` is the three digit column number.

A list of all tiles including bounding box (xmin, xmax, ymin, ymax) is listed in the `graphtiles.txt` file.

### Stream Crossings

The stream crossings are stored in a simple (tab-delimited) text file: `link_crossings.txt`.

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

### Configuration

Copy `r/config.template.json` to `r/config.json` and fill out entries.

```bash
cp r/config.template.json r/config.json
nano r/config.json
``` 

## Database

Create a new database and set up schema:

```
createdb clsb
psql -d clsb -f db/schema.db
```

### Import Crossings

First, run `r/import-crossings.R` to reformat crossings file, select final columns, and save to csv.

```
cd r
Rscript import-crossings.R
```

Then run the `import/crossings.sh` bash script to populate the `crossings` table in the database.

```
cd db/import
./crossings.sh ../../r/csv/crossings.csv
```
