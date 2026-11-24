# Islands in Motion: Technical Methods Appendix

**Project:** Coastal Change Across Three Torres Strait Islands\
**Author:** Kendra Sturdee\
**Assessment:** EV5502 Advanced Geographic Information Systems Major Project\
**Primary analytical record:** `Analysis_Log.md` (latest retrieved version modified 22 November 2026)\
**Scope:** Masig, Iama and Boigu only

## 1. Purpose and status

This appendix documents the GIS workflow used to compare whole-island coastal change and low-elevation terrain on three Torres Strait islands. It is intended to allow a GIS specialist to understand, audit and reproduce the final workflow without exposing workstation-specific paths.

The appendix distinguishes:

- **source data** from **derived analytical outputs**;
- **final methods** from exploratory or superseded steps;
- measured footprint change from inferred coastal processes;
- low-elevation screening from flood or storm-tide modelling.

The final project questions were:

1.  How did reconstructed island area change through the available record?
2.  Where did endpoint land persist, appear or disappear?
3.  What proportion of the historical envelope persisted in every accepted footprint?
4.  How did footprint centroids shift, and how variable were their annual paths?
5.  What were the endpoint changes when annualised by elapsed time?
6.  What proportions of valid LiDAR-covered land were at or below +1 m and +2 m AHD, and which low-elevation components contacted a mapped coastal buffer?

## 2. Study design

| Island | Geomorphic setting | Shoreline period | Accepted footprints | Baseline/final years | LiDAR survey |
|------------|------------|-----------:|-----------:|-----------:|-----------:|
| Masig | Coral cay | 1988–2025 | 33 | 1988/2025 | 2011 |
| Iama | Continental island with depositional margins | 1988–2025 | 34 | 1988/2025 | 2010 |
| Boigu | Low delta island with tidal channels | 2013–2025 | 8 | 2013/2025 | 2009 |

The records are not temporally equivalent. Boigu has a shorter and discontinuous eight-footprint series, so direct comparisons use both absolute values and values normalised to baseline area or elapsed years. No missing footprint year was interpolated.

## 3. Data inventory

| Data | Source/provider | Version/year and resolution | CRS/datum | Coverage | Role | Source/access record |
|-----------|-----------|-----------|-----------|-----------|-----------|-----------|
| DEA Coastlines annual shorelines and rates | Geoscience Australia, Digital Earth Australia | v3.1.0; annual 1988–2025; Landsat-derived | Source features: GDA94 / Australian Albers (EPSG:3577) in the retrieved workflow | Australian coast; spatially selected around each island | Annual shoreline observations, source certainty, shoreline-rate attributes | <https://knowledge.dea.ga.gov.au/data/product/dea-coastlines/>; 12 November 2026 |
| Complete GBR island and reef boundaries including Torres Strait | AIMS, TSRA, GBRMPA; NESP TWQ 3.13 | Version 1b | Masig extracts recorded in GDA2020 / MGA Zone 54 (EPSG:7854) | GBR and Torres Strait | Reference island/reef features; island selection and contextual validation, not a shoreline proxy | <https://data.gov.au/data/dataset/complete-great-barrier-reef-gbr-island-and-reef-feature-boundaries-including-torres-strait-vers>; 12 November 2026 |
| Satellite imagery | ArcGIS/available project imagery | Product, capture dates and native resolution not documented | Web display CRS varied; final presentation maps use EPSG:3857 | Island-specific visual coverage | Visual QC of reconstruction and contextual basemap | 12 November 2026 |
| Masig LiDAR DEM | Queensland Government | 2011; 1 m | Horizontal GDA94 / MGA Zone 54 (EPSG:28354); AHD reported in source metadata | Masig | Elevation and connectivity screening | Local survey metadata; 20 November 2026 |
| Iama LiDAR DEM | Queensland Government | 2010; 1 m | Horizontal GDA94 / MGA Zone 54; AHD reported in source metadata | Iama | Elevation and connectivity screening | Local survey metadata; 20 November 2026 |
| Boigu LiDAR tiles/DEM mosaic | Queensland Government via ELVIS/QSpatial | 2009; 39 tiles; native 1 m; metadata refer to later height adjustments | Horizontal GDA94 / MGA Zone 54; AHD reported by source metadata, but delivered mosaic has no embedded vertical CRS | Boigu; 95.133% valid coverage of rasterised 2025 footprint | Elevation and connectivity screening | Queensland LiDAR metadata; 20 November 2026 |
| Torres Strait coastal hazard mapping | TSRA | 2014; LiDAR-derived elevation and hazard thresholds | AHD for terrain products | Selected Torres Strait islands | Regional elevation/hazard context; not used to calibrate this project’s hypothetical thresholds | <https://catalogue.eatlas.org.au/geonetwork/srv/api/records/af907492-22f8-4073-90cb-f60f524cce6a> |
| Torres Strait Extreme Water Level Study | TSRA / Systems Engineering Australia | Final report, July 2011 | Water levels reported relative to local MSL | Torres Strait communities | Context for tides, surge and datum limitations; not numerically coupled to the DEMs | Final report in project library; 20 November 2026 |
| AusBathyTopo Torres Strait | Geoscience Australia | 2023; 30 m | Source metadata | Regional | Masig bathymetric/topographic context only; not used for final elevation results | <https://pid.geoscience.gov.au/dataset/ga/144348>; 12 November 2026 |

### 3.1 Source versus derived data

**Read-only source data** included DEA shorelines and rates, NESP reference boundaries, satellite imagery and Queensland LiDAR tiles/DEMs. Source datasets were not overwritten.

**Derived vector outputs** included island-specific annual shorelines, validated annual footprint polygons, annual centroids, historical envelopes, persistent cores, variable margins, persistence-frequency polygons, endpoint retained/gained/lost polygons and Boigu exclusion/connection features.

**Derived raster outputs** included LiDAR coverage masks/classes and final three-class +1 m and +2 m connectivity rasters.

**Derived tabular outputs** included annual morphology, exclusion, redistribution, centroid, connectivity and R-export CSV files. Figures were generated from processed tables, not by manually transcribing map labels.

## 4. Software and analytical environment

- **ArcGIS Pro 3.7.0** for project management, vector/raster analysis, mapping and publication preparation.
- **ArcPy** in the ArcGIS Pro Python environment for repeatable extraction, projection, geometry calculations, QC and export.
- **Spatial Analyst** for low-elevation raster classification and connected-component analysis.
- **R** for the CoastlinesR statistical figures and comparative data presentation.

## 5. Coordinate systems and transformations

| Use | CRS | Notes |
|------------------------|------------------------|------------------------|
| DEA source shoreline features | GDA94 / Australian Albers, EPSG:3577 | Metre-based continental source CRS |
| Final Masig/Iama morphology measurement | GDA2020 / MGA Zone 54, EPSG:7854 | Planar area/perimeter and centroid coordinates |
| LiDAR grids | GDA94 / MGA Zone 54, EPSG:28354 | Native 1 m grid retained for raster analysis |
| Final StoryMap presentation maps | WGS 1984 Web Mercator Auxiliary Sphere, EPSG:3857 | Display only; not used for metric calculations |

Where data crossed GDA94 and GDA2020, the documented transformation was `GDA_1994_To_GDA2020_1`. LiDAR calculations were snapped to each DEM’s native grid. Measurement was not performed in Web Mercator.

Boigu’s reconstructed footprint dataset was recorded in GDA94 / Australian Albers in the final log. It was projected to the LiDAR CRS for coverage and raster calculations.

## 6. Shoreline extraction and quality control

### 6.1 Spatial selection

Island AOIs/reference features were used to select intersecting DEA annual-shoreline and rate features. Selected source features were copied in full rather than clipped. This preserved source geometry and attributes.

For Masig, a preliminary 500 m reference-feature buffer was used for DEA extraction. For the later generalised workflow, the configured Iama AOI buffer was 0 m. These are different documented stages; they should not be silently treated as one universal buffer.

### 6.2 Annual checks

For each candidate year, the workflow inspected:

- parsed year and source certainty;
- component count;
- closure/open endpoints;
- geometry validity and positive area;
- multipart status;
- overlap and area plausibility against reference or accepted footprints;
- visual consistency with imagery for anomalous cases.

A preliminary diagnostic polygon was not automatically an accepted footprint. `PRELIMINARY_PASS` and `PENDING_VISUAL_QC` are workflow states, not final scientific acceptance.

### 6.3 Accepted and excluded observations

#### Masig

Accepted years (33): 1988, 1989, 1990, 1993, 1994, 1995, 1996, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2021, 2022, 2023, 2024, 2025.

Excluded years (5): 1991, 1992, 1997, 2012 and 2020. Recorded reasons include aerosol/source-certainty issues, multiple components and an open 2020 shoreline with a 791 m gap. The final Masig reconstruction required one candidate component and used a 0.01 m closure tolerance.

#### Iama

Accepted footprints: 34 between 1988 and 2025.

Excluded years: 1991, 2004 and 2024. The 1991 line had `aerosol issues` certainty and an approximately 18 ha anomaly relative to adjacent accepted observations. The 2004 and 2024 candidates failed overlap and area-ratio checks.

#### Boigu

Accepted project years (8): 2013, 2015, 2018, 2020, 2022, 2023, 2024 and 2025.

Unreconstructed/incomplete years (5): 2014, 2016, 2017, 2019 and 2021. They were not interpolated.

## 7. Footprint reconstruction

### 7.1 Masig and Iama

Accepted closed shoreline linework was converted to polygon footprints with ArcGIS `Feature To Polygon`, followed by geometry and area checks. Annual polygons were stored in island geodatabases and measured only after projection to the final measurement CRS where required.

### 7.2 Boigu-specific reconstruction

Boigu required additional treatment because tidal channels, river mouths and detached features fragmented the annual linework.

1.  The original DEA inspection dataset contained 145 components for 2013–2025.
2.  A manually delineated Aubussi Island exclusion removed 10 neighbouring-island components.
3.  A detached 0.420 ha offshore polygon was identified from 2025 linework. A 100 m exclusion buffer removed only components entirely contained in the exclusion geometry; partial intersections were retained for review.
4.  The final cleaned annual-shoreline dataset contained 132 components after three additional offshore exclusions.
5.  For 2013, 20 cleaned components produced 40 open endpoints. Nineteen mutual-nearest endpoint connections within 100 m were generated. `Unsplit Line` produced one continuous open coastline; the remaining 165.141 m opening was closed with a final straight connection before polygonisation.
6.  For batch years, mutual-nearest connections were proposed within 100 m. If one continuous open line remained, a final closure was tested only when the endpoint separation was no greater than 250 m.
7.  Candidate polygons were screened for positive area, singlepart geometry, area between 6,500 and 7,600 ha, at least 95% overlap with the 2025 footprint, no geometry issues and no material overlap with the offshore exclusion.
8.  Passing candidates were consolidated; failing years were not forced or interpolated.

These numeric thresholds were reconstruction/QC rules for Boigu, not physical thresholds for erosion, accretion or channel behaviour. Straight closure segments may bridge dynamic tidal openings and remain an important uncertainty.

## 8. Whole-island morphology

For each accepted footprint:

- planar area was calculated in hectares;
- planar perimeter was calculated in metres;
- the polygon geometric centroid was recorded as projected X/Y coordinates

Endpoint net area change was:

``` text
net change (ha) = final area - baseline area
net change (%)  = 100 × net change / baseline area
```

Interval changes used the actual time gap between consecutive accepted years:

``` text
interval rate (ha/year) = (area_t2 - area_t1) / (year_t2 - year_t1)
```

The endpoint annualised rate used the full baseline-to-final elapsed years. It is a normalised summary, not a fitted linear trend and not evidence of constant change.

Final endpoint results:

| Island | Net change | Net % | Elapsed years | Endpoint annualised ha/year | Endpoint annualised %/year |
|------------|-----------:|-----------:|-----------:|-----------:|-----------:|
| Masig | −1.41 ha | −0.87% | 37 | −0.038 | −0.024% |
| Iama | +13.74 ha | +8.12% | 37 | +0.371 | +0.219% |
| Boigu | approximately +27.60 ha | +0.39% | 12 | approximately +2.300 | +0.032% |

## 9. Endpoint land redistribution

The baseline and final polygons were overlaid using polygon intersection and difference:

``` text
persistent endpoint land = baseline ∩ final
lost land                = baseline - final
gained land              = final - baseline
```

Area-balance checks were:

``` text
baseline ≈ persistent + lost
final    ≈ persistent + gained
```

| Island | Persistent endpoint land | Gained | Lost | Net |
|---------------|--------------:|--------------:|--------------:|--------------:|
| Masig | 155.99 ha | 4.14 ha | 5.55 ha | −1.41 ha |
| Iama | 167.13 ha | 15.89 ha | 2.16 ha | +13.74 ha |
| Boigu | not separately reported in the accepted brief | approximately 31.47 ha | approximately 3.87 ha | approximately +27.60 ha |

The method describes mapped footprint redistribution. It does not independently identify sediment sources, erosion mechanisms or accretion causes.

## 10. Historical envelope, persistent core and persistence frequency

For all accepted annual footprints:

``` text
historical envelope = union of all accepted footprints
persistent core      = intersection of all accepted footprints
variable margins     = historical envelope - persistent core
```

Persistence frequency was calculated by iterative polygon intersection/difference. Each region received an overlap count:

``` text
persistence (%) = 100 × overlap count / number of accepted footprints
```

The persistent-core percentage reported in the StoryMap is relative to the historical envelope, not to the baseline footprint.

| Island | Historical envelope | Persistent core | Core/envelope |
|--------|--------------------:|----------------:|--------------:|
| Masig  |         170.0661 ha |     152.8036 ha |        89.85% |
| Iama   |         189.1929 ha |     163.6740 ha |        86.51% |
| Boigu  |                     |                 |        99.02% |

**Persistence versus endpoint overlap:** endpoint persistence requires presence in only the first and last footprints; the persistent core requires presence in every accepted footprint. Neither metric means that the island physically moved as a rigid body.

## 11. Centroid analysis

Each annual polygon’s geometric centroid represented the centre of its mapped footprint. For centroid coordinates `(x, y)`:

``` text
interval distance = sqrt((x2 - x1)^2 + (y2 - y1)^2)
cumulative path   = sum of interval distances
net displacement  = distance from baseline centroid to final centroid
```

Grid bearing was measured clockwise from north where reported. Missing years were not interpolated.

| Island | Endpoint centroid displacement |
|--------|-------------------------------:|
| Masig  |                        17.25 m |
| Iama   |                        36.03 m |
| Boigu  |                        14.94 m |

The cumulative path measures the sequence of mapped centroid changes and is more sensitive to annual positional uncertainty. The final StoryMap emphasises endpoint displacement and uses the annual sequence as contextual variability.

## 12. LiDAR preparation and coverage

Each accepted 2025 footprint was projected to the corresponding DEM CRS and rasterised at 1 m with the DEM as the snap raster. Cell counts defined area. Within the footprint:

- Class 1 = valid elevation;
- Class 2 = missing elevation;
- NoData = outside mapped land.

NoData was retained as unknown and was not recoded as low, high, wet or dry.

Coverage checks included vector-versus-rasterised area, total cell balance and alignment to the DEM grid.

- Masig: 160.130 ha rasterised land; 100.000% valid LiDAR coverage.
- Iama: 0.348 ha missing elevation was recorded; the final log did not state a rounded coverage percentage.
- Boigu: 6,756.739 ha valid and 345.659 ha missing; 95.133% valid and 4.867% missing coverage.

The LiDAR and footprint dates differ by 14 years for Masig, 15 years for Iama and 16 years for Boigu. The raster therefore represents historical terrain sampled inside a 2025 planform, not a same-date topographic survey.

## 13. Final low-elevation and coastal-contact method

### 13.1 Thresholds

The final comparison used two hypothetical AHD thresholds:

- +1.0 m AHD;
- +2.0 m AHD.

For each island and threshold, valid DEM cells at or below the threshold were identified. Percentages used **valid LiDAR-covered land** as the denominator.

### 13.2 Connectivity

1.  Apply threshold within the valid-land mask.
2.  Group qualifying cells with **eight-neighbour** connectivity, allowing edge or diagonal contact.
3.  Construct a **10 m inland buffer** from the 2025 footprint boundary.
4.  Identify low-elevation components intersecting that buffer.
5.  Classify intersecting components as coastal-contact.
6.  Classify remaining low-elevation components as connectivity unconfirmed.
7.  Classify remaining valid cells as above threshold.

Final classes:

|  Value | Class                                                |
|-------:|------------------------------------------------------|
|      1 | Coastal-contact low-lying land                       |
|      2 | Low-lying land with unconfirmed coastal connectivity |
|      3 | Land above the selected threshold                    |
| NoData | Outside valid LiDAR-covered land                     |

### 13.3 Final results

| Island | Threshold | Coastal-contact | Unconfirmed | Total low-lying |
|--------|----------:|----------------:|------------:|----------------:|
| Masig  |      +1 m |           0.97% |       0.04% |           1.02% |
| Masig  |      +2 m |           2.88% |       1.10% |           3.99% |
| Iama   |      +1 m |          25.99% |       0.43% |          26.43% |
| Iama   |      +2 m |          38.38% |       0.65% |          39.03% |
| Boigu  |      +1 m |           6.93% |       3.96% |          10.90% |
| Boigu  |      +2 m |          98.24% |       0.07% |          98.31% |

Rounded components may not sum exactly because source areas were calculated from integer 1 m cells before percentage rounding.

### 13.4 Superseded exploratory workflow

Earlier tests used a 2 m coastal seed buffer and five thresholds (+0.5, +1.0, +1.5, +2.0 and +2.5 m). Those runs informed method development but are not the final StoryMap method. The final comparative outputs use only +1 m and +2 m with the 10 m inland coastal buffer.

The earlier outputs were sometimes labelled “inundation”. The final interpretation is **elevation-based coastal-connectivity screening**. The rasters are not flood predictions.

## 14. Validation and quality control

Validation steps recorded in the project included:

- source-versus-output feature counts;
- parsed-year and duplicate-year checks;
- null, zero-area, multipart and geometry checks;
- candidate-count and endpoint-gap checks;
- comparison with reference footprints and imagery;
- projected versus source-area checks;
- endpoint area-balance checks for redistribution;
- envelope/core/variable-margin area conservation;
- persistence-region sum versus envelope area;
- containment of persistent core within every accepted footprint;
- centroid and endpoint anchor comparisons;
- vector footprint versus rasterised cell-area comparison;
- valid/missing cell-count balance;
- monotonicity of low-elevation area with increasing thresholds;
- consistent class codes and symbology among islands;
- checks that source data remained unchanged.

Passing automated QC does not replace visual inspection or independent field validation. In particular, Boigu closure lines require explicit visual sign-off.

## 15. Assumptions and uncertainty

1.  **Shoreline proxy.** DEA Coastlines estimates a tidally constrained annual shoreline from medium-resolution satellite observations. Residual tidal, compositing, cloud/aerosol, pixel and model uncertainty remains.
2.  **Footprint closure.** Polygon reconstruction assumes accepted linework represents the island boundary. Boigu’s channel and river-mouth closures introduce greater interpretive uncertainty.
3.  **Observation gaps.** Excluded or unreconstructed years were not interpolated. Persistence frequency uses accepted observations only.
4.  **Unequal periods.** Masig/Iama cover 37 elapsed years; Boigu covers 12. Annualisation normalises elapsed time but does not make the records statistically equivalent.
5.  **Centroids.** A centroid is a geometry summary, not a marker moving with sediment or a community.
6.  **LiDAR age.** DEMs are from 2009–2011, whereas footprints are from 2025. Later terrain modification and coastal works are not represented.
7.  **Vertical reference.** Source metadata identify AHD, but Boigu’s raster lacks an embedded vertical CRS and its corrected-version provenance remains unresolved. Equal AHD thresholds are not equivalent local tidal levels.
8.  **Connectivity.** Eight-neighbour grouping permits diagonal links. The 10 m coastal buffer is a spatial proxy for contact, not a verified hydraulic entrance.
9.  **Missing DEM cells.** Missing cells are unknown and may interrupt apparent connectivity.
10. **Processes omitted.** The analysis does not simulate tides, surge, waves, overtopping, water depth, velocity, duration, drainage, roughness or defences.
11. **Exposure omitted.** Infrastructure, population, ecosystem and cultural-site exposure were not counted.
12. **Causation.** Polygon differences do not independently establish why a shoreline changed.

## 16. Output inventory and StoryMap use

| Output | Type | Purpose/StoryMap role |
|------------------------|------------------------|------------------------|
| `<Island>_AnnualFootprints_Validated` | Feature class | Accepted annual whole-island footprints |
| `<Island>_AnnualCentroids_Validated` | Feature class | Annual centroid map and trajectories |
| `<Island>_HistoricalEnvelope` | Feature class | Area occupied in at least one accepted footprint |
| `<Island>_PersistentCore` | Feature class | Land present in all accepted footprints |
| `<Island>_VariableMargins` | Feature class | Envelope outside persistent core |
| `<Island>_FootprintPersistence` | Feature class | Spatial persistence-frequency classes |
| `<Island>_PersistentLand_<start>_<end>` | Feature class | Endpoint intersection |
| `<Island>_LandLost_<start>_<end>` | Feature class | Baseline minus final |
| `<Island>_LandGained_<start>_<end>` | Feature class | Final minus baseline |
| `<Island>_2025_LiDAR_CoverageMask` | Raster | Aligned 2025 land mask |
| `<Island>_2025_LiDAR_CoverageClasses` | Raster | Valid versus missing elevation |
| Final +1 m/+2 m three-class rasters | Raster | Coastal-contact, unconfirmed and above-threshold classes |
| `Masig_04_AnnualMorphology_1988_2025.csv` | CSV | Annual Masig area, perimeter and centroids |
| `Iama_04_AnnualMorphology_Diagnostics.csv` | CSV | Annual Iama morphology and interval rates |
| `Boigu_AnnualMorphology_2013_2025.csv` | CSV | Eight-year Boigu morphology and QC status |
| `ThreeIsland_CoastalConnectivity_Comparison.csv` | CSV | Final class percentages for +1 m and +2 m |
| CoastlinesR Figures 1–5 | Figure files | Annual area, centroid, redistribution, persistence and annualised rates |

Six +1 m/+2 m connectivity scenario maps were prepared for the three islands. Local outputs were verified in the analysis log. ArcGIS Online sharing and the final Boigu endpoint-comparison item should be checked before public release.

## 17. Core references

1.  Parnell KE, Smithers SG. Regional and local variability in coastal processes in Torres Strait, Australia, and its importance for climate change planning. *Journal of Coastal Research*. 2020;95(sp1):616–620. <https://doi.org/10.2112/SI95-120.1>
2.  Duce SJ, Parnell KE, Smithers SG, McNamara KE. *A Synthesis of Climate Change and Coastal Science to Support Adaptation in the Communities of Torres Strait*. Reef and Rainforest Research Centre; 2010. <https://researchonline.jcu.edu.au/18087/>
3.  Torres Strait Island Regional Council. *Zenadth Kes Coastal Hazard Adaptation Strategy*. 2024. <https://tsirc.qld.gov.au/documents/zenadth-kes-coastal-hazard-adaptation-strategy/>
4.  Bishop-Taylor R, Nanson R, Sagar S, Lymburner L. Mapping Australia’s dynamic coastline at mean sea level using three decades of Landsat imagery. *Remote Sensing of Environment*. 2021;267:112734. <https://doi.org/10.1016/j.rse.2021.112734>
5.  Geoscience Australia. *DEA Coastlines v3.1.0*. <https://knowledge.dea.ga.gov.au/data/product/dea-coastlines/>
6.  Lazarus E, Duce S, Lewis S, Smithers S. The Reef Island Geomorphic Activity Assessment: a new approach to quantify cay geomorphic change. *Global and Planetary Change*. 2025;247:104743. <https://doi.org/10.1016/j.gloplacha.2025.104743>
7.  Albert S, Leon JX, Grinham AR, Church JA, Gibbes BR, Woodroffe CD. Interactions between sea-level rise and wave exposure on reef island dynamics in the Solomon Islands. *Environmental Research Letters*. 2016;11(5):054011. <https://doi.org/10.1088/1748-9326/11/5/054011>
8.  Webb AP, Kench PS. The dynamic response of reef islands to sea-level rise. *Global and Planetary Change*. 2010;72(3):234–246. <https://doi.org/10.1016/j.gloplacha.2010.05.003>
9.  Kench PS, Ford MR, Owen SD. Patterns of island change and persistence offer alternate adaptation pathways for atoll nations. *Nature Communications*. 2018;9:605. <https://doi.org/10.1038/s41467-018-02954-1>
10. Woodroffe CD. Reef-island topography and the vulnerability of atolls to sea-level rise. *Global and Planetary Change*. 2008;62(1–2):77–96. <https://doi.org/10.1016/j.gloplacha.2007.11.001>
11. Duvat VKE. A global assessment of atoll island planform changes over the past decades. *WIREs Climate Change*. 2019;10(1):e557. <https://doi.org/10.1002/wcc.557>
12. Systems Engineering Australia Pty Ltd. *Torres Strait Extreme Water Level Study: Final Report*. Prepared for TSRA; 2011.
13. TSRA. *Torres Strait Coastal Hazard Mapping 2014* [dataset]. <https://catalogue.eatlas.org.au/geonetwork/srv/api/records/af907492-22f8-4073-90cb-f60f524cce6a>
14. Queensland Government. *Queensland LiDAR Data—North Queensland 2009 Project* [metadata]. <https://qldspatial.information.qld.gov.au/catalogueadmin/catalog/search/resource/details.page?uuid=%7BB3EB5D7D-BBFE-48C5-963D-5C482EB98BF5%7D>
15. AIMS, TSRA, GBRMPA. *Complete GBR Island and Reef Feature Boundaries Including Torres Strait, version 1b* [dataset]. <https://data.gov.au/data/dataset/complete-great-barrier-reef-gbr-island-and-reef-feature-boundaries-including-torres-strait-vers>
16. Parnell KE, Smithers SG, Ischenko L. *Understanding Climate Change Driven Coastal Erosion and Inundation Impacts on Torres Strait Communities and the Development of Adaptation Options*. James Cook University; 2012. <https://researchonline.jcu.edu.au/36881/>
17. McLean R, Kench P. Destruction or persistence of coral atoll islands in the face of 20th and 21st century sea-level rise? *WIREs Climate Change*. 2015;6(5):445–463. <https://doi.org/10.1002/wcc.350>
18. Perris L, Salles T, Fellowes TE, Duce S, Webster J, Vila-Concejo A. The influence of coral reef spur and groove morphology on wave energy dissipation in contrasting reef environments. *Journal of Geophysical Research: Earth Surface*. 2024;129:e2023JF007424. <https://doi.org/10.1029/2023JF007424>
19. Kench PS, Thompson D, Ford MR, Ogawa H, McLean RF. Coral islands defy sea-level rise over the past century. *Geology*. 2015;43(6):515–518. <https://doi.org/10.1130/G36555.1>
