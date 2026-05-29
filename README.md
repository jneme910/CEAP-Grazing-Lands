# CEAP Grazing Lands

## SSURGO query tooling and soil-characteristic extraction for grazing land analysis

This repository documents SQL workflows, reference materials, and supporting resources developed for **CEAP Grazing Lands** to extract and organize **SSURGO / gSSURGO soil characteristics** for modeling, analysis, and related project work.

The project focuses on helping users retrieve specific soil properties and component-level information that support **vegetation, hydrology, grazing-land assessment, and conservation-effect modeling**.

**Repository links**
- GitHub repository: [jneme910/CEAP-Grazing-Lands](https://github.com/jneme910/CEAP-Grazing-Lands)
- Project site: [jneme910.github.io/CEAP-Grazing-Lands](https://jneme910.github.io/CEAP-Grazing-Lands/)

---

## Project purpose

The goal of this work is to provide a practical way to extract soil characteristic data from **gSSURGO / SSURGO** for use in **CEAP Grazing Lands modeling and related analytical workflows**.

This includes support for:

- identifying soil properties that influence vegetation and water dynamics
- organizing data for modeling conservation practice effects
- enabling tabular and spatial review of soil component information
- improving access to soil characteristics needed by analysts and project collaborators

---

## Why this project matters

Grazing-land and conservation modeling often depend on access to well-structured soil data that is not always easy to assemble for analytical use. This repository helps bridge that gap by documenting SQL-based approaches for retrieving and organizing soils information relevant to project workflows.

It is particularly useful for users working with:

- SSURGO and gSSURGO data
- soil property extraction
- grazing-land assessment
- conservation analysis
- NRCS-related data workflows
- map-based and tabular soil review

---

## What this repository contains

This repository includes:

- SQL scripts for CEAP Grazing Lands data extraction
- supporting spreadsheets and reference documentation
- links to management studio and Soil Data Access versions of queries
- descriptions of key soil characteristics used in analysis
- supporting context for MLRAs and basemap layers

---

## Key resources

### Additional information
1. [SQL version provided by Paul Finnell](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/SQL-Library/Lori_CarrieAnn_NASIS%20script%20from%20Finnell.txt)
2. [Project spreadsheet and data requirements](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/documents/CEAP-GL_Soil%20App%20GUI_data%20to%20StoneEnviro_11-9-2020%20copy.xlsx?raw=true)

### SQL resources
1. [SSURGO QT Management Studio](https://github.com/jneme910/CEAP-Grazing-Lands/blob/master/SQL-Library/CEAP_Grazing.sql)
2. [SSURGO QT Soil Data Access - State or Soil Survey Area](https://raw.githubusercontent.com/jneme910/CEAP-Grazing-Lands/master/SQL-Library/STATE_CEAP_Grazing_2019_0213.txt)

---

## Soil characteristics addressed

The repository is designed to help retrieve and review soil information such as:

- soil moisture and temperature classes, subclasses, and regimes
- surface texture characteristics
- surface cover of coarse fragments
- coarse fragments in the top horizon
- soil depth
- water table information
- hydrologic group
- slope class
- available water capacity and storage
- soil chemistry characteristics
- restrictions and restriction kinds
- diagnostic horizons and features
- ecological site identifiers and names
- soil component names

These data elements help support deeper analytical understanding of the soil factors that influence grazing-land performance and conservation outcomes.

---

## Reference geography and map context

### Major Land Resource Areas (MLRAs)
Major Land Resource Areas are included as a reference layer to support querying and interpretation. They provide regional context tied to soils, climate, water resources, land use, physiography, geology, and biological resources.

### Base maps
The tool context uses standard basemap resources to provide geographic orientation and support interpretation of selected areas.

---

## Audiences

This repository is most useful for:

- soil scientists
- GIS specialists
- conservation analysts
- grazing-land modelers
- NRCS-related technical staff
- users needing structured soil-property extraction from SSURGO/gSSURGO

---

## Technologies and data themes

- SQL / T-SQL
- SSURGO / gSSURGO
- soil property extraction
- conservation analysis
- grazing lands
- NRCS workflows
- GitHub Pages

---

## Best-practice improvement ideas

To make this repository even stronger for technical audiences and hiring visibility, consider adding:

- sample outputs or screenshots from the tool
- a short workflow diagram showing how data moves from SSURGO to analysis
- a “how to use this repository” section for new users
- a file structure summary for SQL, documents, and site content
- notes on intended users and downstream modeling use cases

---

If you work with **soil data, grazing-land analysis, SSURGO workflows, or conservation modeling**, this repository provides a strong example of applied soil-data extraction for real-world analytical use.
