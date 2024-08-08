Write-Host "$(Get-Date) Downloading Run Package AWI_16_2853886_006.tar.gz"
Invoke-WebRequest https://ciroh-ua-ngen-data.s3.us-east-2.amazonaws.com/AWI-006/AWI_16_2853886_006.tar.gz -o AWI_16_2853886_006.tar.gz
Write-Host "$(Get-Date) Decompressing Run Package AWI_16_2853886_006.tar.gz"
tar -xf .\AWI_16_2853886_006.tar.gz
rm .\AWI_16_2853886_006.tar.gz
cd .\AWI_16_2853886_006\
Write-Host "$(Get-Date) Running NextGen National Water Model Framework Package AWI_16_2853886_006.tar.gz"
docker run --rm -it -v .:/ngen/ngen/data awiciroh/ciroh-ngen-image:latest-x86 /ngen/ngen/data auto
Write-Host "Finished at $(Get-Date)"
