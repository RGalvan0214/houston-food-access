# Houston Food Access: Grocery Store Coverage by Median Household Income
<img width="5846" height="4133" alt="food_access_map" src="https://github.com/user-attachments/assets/d8e2f864-8d14-4989-9f7e-f8198b82b04d" />



## Overview
This project maps grocery store coverage across Harris County's 1,115 census tracts, 
layering OpenStreetMap store locations against 2024 Census median household income data 
to identify potential food deserts across Houston.

The project is motivated in part by my experience volunteering with the Houston Food Bank, 
where I saw firsthand how uneven food access is across the city. This map is an attempt 
to quantify and visualize that unevenness at the neighborhood level.

**Status:** In progress. Current version includes income choropleth and grocery store 
point layer. Food bank locations and population density layer planned.

---

## Background

This project is part of a broader portfolio developing GIS, SQL, and data analytics 
skills applicable to infrastructure and resource distribution analysis. Future work 
includes a geospatial analysis of the Texas power grid and the 2021 Winter Storm Uri 
outage, applying similar network and spatial methods to energy infrastructure.

---

## Key Findings

- Harris County median household income ranges from **$13,491 to $246,500** across 
  1,115 census tracts, which is nearly a $233,000 gap within a single county
- Low-income tracts (under $41,000) in the **urban core and east Houston** show 
  notably lower grocery store density than higher-income suburban tracts to the 
  northwest and west
- **Southwest Houston** presents a nuanced pattern: moderate store coverage despite low income levels, suggesting that store count alone may not fully capture food access in that area.
- **13 tracts** have suppressed income data due to Census confidentiality thresholds 
  (insufficient survey respondents to produce a reliable estimate), so these appear as 
  white tracts on the map

---

## Data Sources

| Dataset | Source | Year |
|---|---|---|
| Median Household Income (Table S1901) | U.S. Census Bureau, ACS 5-Year Estimates | 2024 |
| Census Tract Boundaries | U.S. Census Bureau, TIGER/Line Shapefiles | 2024 |
| Grocery Store Locations | OpenStreetMap via Overpass Turbo | June 2026 |

---

## Tools

- **QGIS:** spatial join, choropleth styling, clipping, print layout export
- **SQLite / DB Browser for SQLite:** data cleaning, transformation, and joining 
  before loading into QGIS
- **Overpass Turbo:** querying OpenStreetMap for grocery store locations within 
  Harris County bounding box

---

## SQL Workflow

Raw Census data required cleaning before it could be joined to the shapefile. 
The queries below document each transformation step.

### Step 1: Remove header row and extract income column

Census CSV files include a second header row with human-readable labels. 
This query removes it and extracts only the median household income estimate.

<img width="720" height="301" alt="image" src="https://github.com/user-attachments/assets/2eaac149-b566-4dbc-a149-65fc3d752ee3" />



&nbsp;

```sql
CREATE TABLE income_clean AS
SELECT 
    GEO_ID,
    NAME,
    S1901_C01_012E AS median_household_income
FROM income_raw
WHERE GEO_ID != 'Geography';
```

### Step 2: Strip GEO_ID prefix and cast income as integer

The Census GEO_ID includes a `1400000US` prefix that the TIGER/Line shapefile 
GEOID column does not. This query strips the prefix so the join key matches, 
and converts income from text to integer while handling Census suppression 
symbols (such as `-`, `N`, `(X)`) and open-ended values (`250,000+`).

```sql
CREATE TABLE income_final AS
SELECT 
    REPLACE(GEO_ID, '1400000US', '') AS GEOID_clean,
    NAME,
    CASE 
        WHEN median_household_income IN ('-', 'N', '(X)') THEN NULL
        WHEN median_household_income LIKE '%+%' THEN 250000
        ELSE CAST(median_household_income AS INTEGER)
    END AS median_income
FROM income_clean;
```


### Exploratory Queries

```sql
-- Income range across Harris County
SELECT 
    MIN(median_income) AS lowest,
    MAX(median_income) AS highest,
    ROUND(AVG(median_income)) AS average
FROM income_final
WHERE median_income IS NOT NULL;

-- Ten lowest-income tracts
SELECT NAME, median_income
FROM income_final
WHERE median_income IS NOT NULL
ORDER BY median_income ASC
LIMIT 10;

-- Count of suppressed tracts
SELECT COUNT(*) AS suppressed_tracts
FROM income_final
WHERE median_income IS NULL;
```

---

## Limitations

- **OpenStreetMap coverage is community-maintained:** May undercount certain 
  stores. Some Walmart and H-E-B locations use non-standard tags 
  (`superstore`, `department_store`) and may not appear in results
- **Store count per tract does not capture effective access:** Walking distance, 
  car ownership rates, and transit availability all affect whether a nearby store 
  is actually reachable
- **Some tracts are not colored:** 13 tracts with suppressed income data appear blank on the map and are 
  excluded from income-based analysis
- **ACS estimates carry a margin of error:** Tract-level income figures are 
  survey-based and should be interpreted as estimates, not precise counts

---

## Next Steps

- Add Houston Food Bank distribution center locations as a third point layer
- Combine income and population into a single joined layer (tract_data table)
- Explore walking-distance buffer analysis around store locations
- Future analysis could incorporate car ownership and transit access data to better capture effective food access beyond store proximity. 

