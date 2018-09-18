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

## Web Application

Created using vue-cli 3.

### Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Lints and fixes files
```
npm run lint
```

## Data Types

Data types returned from API.

```js
barrier = {
  id: '<string>',
  x_coord: '<number>',
  y_coord: '<number>',
  effect: '<number>',
  effect_ln: '<number>',
  delta: '<number>',
  type: '"dam"|"culvert"',
  lat: '<number>',
  lon: '<number>',
  node_id: '<string>',
}
node = {
  node_id: '<string>',
  x: '<number>',
  y: '<number>',
  lat: '<number>',
  lon: '<number>',
  cost: '<number>',
}
edge = {
  id: '<number>',
  start_id: '<string>',
  end_id: '<string>',
  length: '<number>',
  cost: '<number>',
  value: '<number>'
}
```

## Vuex Store

```js
{
  // barriers in region
  "barriers": [
    {
      "id": "c-328868",
      "x_coord": 1991570,
      "y_coord": 2441030,
      "effect": 0,
      "effect_ln": 0,
      "delta": 0,
      "type": "culvert",
      "lat": 42.6242,
      "lon": -71.2958,
      "node_id": "10088000436"
    },
    ...
  ],

  // project metadata
  "project": {
    "id": "<string>",
    "name": "<string>",
    "description": "<string>",
    "author": "<string>"
  },

  // project region (HUC8 or Draw)
  "region": {
    "type": "huc8|draw",
    "feature": {
      "type": "Feature",
      "properties": {...},
      "geometry": {
        "type": "Polygon",
        "coordinates": [...]
      }
    }
  },

  // active scenario
  "scenario": {
    "id": 2,
    "barriers": [],
    "status": "new"
  },

  // sequential ID for scenarios
  "scenarioSeqId": 2,

  // list of saved scenarios
  "scenarios": [
    {
      "id": 1,
      "status": "finished",

      // selected barriers
      "barriers": [
        {
          "id": "c-488893",
          "x_coord": 1991950,
          "y_coord": 2408090,
          "effect": 0,
          "effect_ln": 0,
          "delta": 0,
          "type": "culvert",
          "lat": 42.3385,
          "lon": -71.3947,
          "node_id": "10088004840"
        }, ...
      ],

      // trimmed network
      "network": {
        "edges": [
          {
            "id": 1011036,
            "start_id": "10088004360",
            "end_id": "10088004361",
            "length": 210,
            "cost": 32.634,
            "value": 1.72,
            "index": 0
          },
          ...
        ],
        "nodes": [
          {
            "node_id": "10088004358",
            "x": 1991470,
            "y": 2410100,
            "cost": 0
          },
          ...
        ]
      },

      // aquatic connectivity scores
      "results": {
        "delta": {
          "total": 2312.7088734182294,
          "values": [8.261281495911987, ...]
        },
        "effect": {
          "total": 450.47919337434206,
          "values": [2.0299148818526596, ...]
        },
        "kernels": {
          "base": [4.876707229460349, ...],
          "alt": [4.884968510956261, ...]
        }
      }
    },
    ...
  ]
}
```
