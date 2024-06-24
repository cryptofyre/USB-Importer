# Define the path of the DCIM folder on the DJI drone and the NAS destination
$droneDrive = "$($MyInvocation.MyCommand.Path.Substring(0,1)):\" 
$droneDCIMPath = "$droneDrive\DCIM"
$configFilePath = "$droneDrive\drone_config.json"
$nasBasePath = "Z:\Personal\Drones"

# Read drone configuration
if (Test-Path -Path $configFilePath) {
    $droneConfig = Get-Content -Path $configFilePath | ConvertFrom-Json
    $droneModel = $droneConfig.model
} else {
    Write-Error "Configuration file not found. Please ensure '$configFilePath' exists."
    exit 1
}

# Create a log file to keep track of imported files
$logFile = "$nasBasePath\imported_files.log"

# Function to get the date from the file metadata
function Get-DateFromMetadata {
    param (
        [string]$filePath
    )
    $file = Get-Item $filePath
    return $file.CreationTime
}

# Function to check if the file has already been imported
function IsFileImported {
    param (
        [string]$filePath
    )
    $hash = Get-FileHash $filePath -Algorithm MD5
    $logContent = Get-Content $logFile -ErrorAction SilentlyContinue
    return $logContent -contains $hash.Hash
}

# Function to log the imported file hash
function LogImportedFile {
    param (
        [string]$filePath
    )
    $hash = Get-FileHash $filePath -Algorithm MD5
    Add-Content $logFile -Value $hash.Hash
}

# Function to import and organize files
function ImportFiles {
    $files = Get-ChildItem -Path $droneDCIMPath -File -Recurse -Filter *.MP4

    $totalFiles = $files.Count
    $currentFile = 0

    foreach ($file in $files) {
        $currentFile++
        Write-Progress -Activity "Importing files from $droneModel" -Status "Processing file $currentFile of $totalFiles" -PercentComplete (($currentFile / $totalFiles) * 100)

        if (-not (IsFileImported $file.FullName)) {
            $fileDate = Get-DateFromMetadata $file.FullName
            $monthFolder = $fileDate.ToString("yyyy-MM")
            $destinationFolder = "$nasBasePath\$droneModel\$monthFolder"

            if (-not (Test-Path -Path $destinationFolder)) {
                New-Item -Path $destinationFolder -ItemType Directory
            }

            Write-Output "Transferring '$($file.Name)' to '$destinationFolder'"
            Copy-Item -Path $file.FullName -Destination $destinationFolder
            LogImportedFile $file.FullName
        } else {
            Write-Output "Skipping already imported file: '$($file.Name)'"
        }
    }

    Write-Output "Import complete. $currentFile files processed."
}

# Main script execution
ImportFiles
