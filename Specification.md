--- CONFIG START ---
### Model
| Name of Model files | type | PATH to .json file | HASH of file |
| ----------- | ----------- | ----------- | ----------- |
| CFE_SLOTH_realization | filesystem | /ngen/realization.json | d2c6fbda93c134de495d69745fae11087784d2aa |
| CFE_SLOTH_ini | filesystem | /ngen/cfe_sloth.ini | ab0c3dff59c4b282b172b90128159fda3386d012 |
### Forcings
| Name of Forcings | type | PATH to forcings file(s) | HASH of file(s) |
| ----------- | ----------- | ----------- | ----------- |
| Hurricane Zach | bucket | s3://awi-ciroh-ngen-data/AWI_001/forcings/ | 220fff8bdd3b85f23d93e73b4bc7e3bc2c7c0f35 |
### Hydrofabric
| Name of Hydrofabric | type | PATH to .json file | HASH of file |
| ----------- | ----------- | ----------- | ----------- |
| Catchment(s) File | bucket | s3://awi-ciroh-ngen-data/AWI_001/catchments.geojson | da39a3ee5e6b4b0d3255bfef95601890afd80709 |
| Nexus File | bucket | s3://awi-ciroh-ngen-data/AWI_001/nexus.geojson | cae054f62f697080d822fea9c7d9c268be8b7ac9 |
| Crosswalk File | bucket | s3://awi-ciroh-ngen-data/AWI_001/crosswalk.geojson | 4c39964d1e30779f9992d3c00e94a39952cb102a |

All values within each section are defined for the run to evaluate when a run is unique and the change that makes it so. For example changing the hash of any of the fields for the referenced files should change the RUN CONFIG into something new. 

Note: the Realization, Catchment, Nexus and other model-required files must be searching by name. 

| Valid | Not Valid |
| ----- | --------- | 
| hurricane_marty_realization.json | hurricane_marty.json | 
| Houston_catchments.geojson | Houston.geojson |  
| Nexus_2012_flood.geojson | 2012_flood.geojson |  
