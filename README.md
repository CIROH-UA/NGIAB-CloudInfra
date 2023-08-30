###Reproducing

Get the files from the appropriate bucket & RUN_CONFIG
```
wget --no-parent https://awi-ciroh-ngen-data.s3.us-east-2.amazonaws.com/AWI_001/AWI_03W_113060_001.tar.gz .

tar -xvf AWI_03W_113060_001.tar.gz
```
Then we can confirm file location and integrity against the example JSON file.
```
{
	"RUN_CONFIG": {
		"description": "Run Config for AWI_03W_113060_001",
		"Model": {
			"realization": {
				"Name": "AWI_simplified_realization",
				"Type": "filesystem",
				"Path": "AWI_03W_113060_001/config/awi_simplified_realization.json",
				"Hash": "792554dcf48b61120cfc648cc6711d2b5e61d321"
			},
			"configuration": {
				"Name": "CFE_SLOTH_ini",
				"Type": "filesystem",
				"Path": "AWI_03W_113060_001/config/awi_config.ini",
				"Hash": "e8283864026040ce1ce5a7dca79b9f4f04744b47"
			}
		},
		"Forcings": {
			"inputs": {
				"Name": "Hurricane Zach",
				"Type": "filesystem",
				"Path": "AWI_03W_113060_001/forcings",
				"Hash": "da39a3ee5e6b4b0d3255bfef95601890afd80709"
			},
			"Hydrofabric": {
				"catchment": {
					"Name": "Catchment(s) File v1.0",
					"Type": "bucket",
					"Path": "AWI_03W_113060_001/config/catchment_data.geojson",
					"Hash": "880feb145f254976600bd8968ef730105de6cbee"
				},
				"nexus": {
					"Name": "Nexus File v1.0",
					"Type": "bucket",
					"Path": "AWI_03W_113060_001/config/nexus_data.geojson",
					"Hash": "86a029a15e7cf67bc69f2390038a74b69b09af04"
				},
			}
		}
	}
}
```
Note that to recreate the sums for the focings file, I simply summed the files then piped the output to its own sum.
```
shasum -a 256 AWI_03W_113060_001/forcings/ | shasum
```
