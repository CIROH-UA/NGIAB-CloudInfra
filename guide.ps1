$ErrorActionPreference = "Stop"

Write-Host "Welcome to CIROH-UA : Nextgen National Water Model guide!" -ForegroundColor White -BackgroundColor Black

Write-Host "Looking for a directory containing the following directories: forcings outputs config"
Write-Host "forcings" -ForegroundColor Blue -BackgroundColor Black
Write-Host "is the input data for your model(s)."
Write-Host "outputs " -ForegroundColor Magenta -BackgroundColor Black
Write-Host "is where we'll put your data when it's finished running"
Write-Host "config" -ForegroundColor Green -BackgroundColor Black
Write-Host "is where changes to models can be made"
Write-Host "`n"
Write-Host "Make sure to use an absolute path."
$HOST_DATA_PATH = Read-Host "Enter your data directory file path: "

Write-Host "The Directory you've given is:" ; Write-Host "$HOST_DATA_PATH"

# We should check for these directories first 
# and exit early if HOST_DATA_PATH doesn't have the expected directory structure
if (Test-Path "$HOST_DATA_PATH/outputs") {
    $Outputs_Count = (Get-ChildItem -Path "$HOST_DATA_PATH/outputs" | Measure-Object).Count
} else {
    $Outputs_Count = 0
}

# Validate paths exist
if (Test-Path "$HOST_DATA_PATH/forcings") {
Write-Host "forcings exists. $((Get-ChildItem -Path $HOST_DATA_PATH/forcings).Count) forcings found." -ForegroundColor Blue
} else {
Write-Error "Error: Directory $HOST_DATA_PATH/forcings does not exist."
}

if (Test-Path "$HOST_DATA_PATH/outputs") {
Write-Host "outputs exists. $((Get-ChildItem -Path $HOST_DATA_PATH/outputs).Count) outputs found." -ForegroundColor Magenta
} else {
Write-Error "Error: Directory $HOST_DATA_PATH/outputs does not exist."
}

if (Test-Path "$HOST_DATA_PATH/config") {
Write-Host "config exists. $((Get-ChildItem -Path $HOST_DATA_PATH/config).Count) configs found." -ForegroundColor Green
} else {
Write-Error "Error: Directory $HOST_DATA_PATH/config does not exist."
}

Write-Host "Looking in the provided directory gives us:"

$HYDRO_FABRIC_CATCHMENTS = Get-ChildItem -Path $HOST_DATA_PATH -Filter "catchment.geojson" -Recurse
$HYDRO_FABRIC_NEXUS = Get-ChildItem -Path $HOST_DATA_PATH -Filter "nexus.geojson" -Recurse
$NGEN_REALIZATIONS = Get-ChildItem -Path $HOST_DATA_PATH -Filter "realization.json" -Recurse

Write-Host "Found these Catchment files:" -ForegroundColor Green ; Start-Sleep -Seconds 1 ; Write-Output $HYDRO_FABRIC_CATCHMENTS.FullName
Write-Host "Found these Nexus files:" -ForegroundColor Green ; Start-Sleep -Seconds 1 ; Write-Output $HYDRO_FABRIC_NEXUS.FullName
Write-Host "Found these Realization files:" -ForegroundColor Green ; Start-Sleep -Seconds 1 ; Write-Output $NGEN_REALIZATIONS.FullName

# Detect Arch
$AARCH = [System.Environment]::Is64BitOperatingSystem
Write-Host "Detected ISA = $AARCH"

if (Get-Command -Name "docker" -ErrorAction SilentlyContinue) {
Write-Host "Docker found"
} else {
Write-Host "Docker not found"
break
}

$modelrun = Read-Host "run_NextGen or exit"
switch ($modelrun) {
    'run_NextGen' {
        Write-Host "Pulling and running AWI NextGen Image"
        break
    }
    'exit' {
        Write-Host "Have a nice day."
        exit 0
    }
    default {
        Write-Host "Invalid option $modelrun, 1 to continue and 2 to exit"
    }
}


if (($env:PROCESSOR_ARCHITECTURE) -like "*arm64*") {
    docker pull awiciroh/ciroh-ngen-image:latest-arm
    Write-Host "pulled arm ngen image"
    $IMAGE_NAME = "awiciroh/ciroh-ngen-image:latest-arm"
} else {
    docker pull awiciroh/ciroh-ngen-image:latest-x86
    Write-Host "pulled x86 ngen image"
    $IMAGE_NAME = "awiciroh/ciroh-ngen-image:latest-x86"
}

Write-Host "Running NextGen in Docker."
Write-Host "Running container mounting local host directory $HOST_DATA_PATH to /ngen/ngen/data within the container."
docker run --rm -it -v "${HOST_DATA_PATH}:/ngen/ngen/data" $IMAGE_NAME "/ngen/ngen/data/"

$Final_Outputs_Count = (Get-ChildItem -Path $HOST_DATA_PATH/outputs | Measure-Object).Count
$count = $Final_Outputs_Count - $Outputs_Count
Write-Host "$count new outputs created."

Write-Host "Have a nice day!"
exit 0

