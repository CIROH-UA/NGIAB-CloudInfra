# Archive

This folder contains deprecated files that were formerly used alongside this repository. While they may still be of use, the contents of this folder are not actively maintained.

- `config/`: Contains a realization file that calibrated for the [AWI-009 sample input dataset](https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-009/AWI_16_10154200_009.tar.gz). (*Warning: link leads to large file download*)
- `docs/`: Some stray planning documents. Likely outdated.
- `terraform/`: Older configurations for running NGIAB on CIROH's AWS servers. Superceded by [DataStreamCLI](https://github.com/CIROH-UA/ngen-datastream).
- `AWI_007_windows_test.ps1`: A PowerShell script that invokes NGIAB on Windows. Somewhat redundant, since the container runs on WSL anyway.
- `Example.json`: An example realization file.