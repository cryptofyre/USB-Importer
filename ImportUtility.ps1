# Configuration
$usbDrive = "$($MyInvocation.MyCommand.Path.Substring(0,1)):\" # USB drive letter auto-detection by autorun.bat, this can be hardcoded if you so please. (ex. "E:\")
$dcimFolderName = "DCIM"  # Folder name to scan for files
$configFileName = "device_config.json"  # Configuration file name containing the device model
$nasBasePath = "\\NAS_Server\Media"  # Replace with the actual path to your NAS or physical mounted disk.
$fileTypes = @("*.MP4", "*.JPG", "*.MOV")  # Array of file types to import
$dateSortingScheme = "yyyy-MM"  # Date sorting scheme: "yyyy-MM", "yyyy-MM-dd", "yyyy"

# Read configuration from JSON file
$configFilePath = Join-Path -Path $usbDrive -ChildPath $configFileName
if (Test-Path -Path $configFilePath) {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
    $deviceModel = $config.model
} else {
    Write-Error "Configuration file not found. Please ensure '$configFilePath' exists."
    exit 1
}

# Set up paths
$dcimPath = Join-Path -Path $usbDrive -ChildPath $dcimFolderName
$logFilePath = Join-Path -Path $nasBasePath -ChildPath "imported_files.log"

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
    $logContent = Get-Content $logFilePath -ErrorAction SilentlyContinue
    return $logContent -contains $hash.Hash
}

# Function to log the imported file hash
function LogImportedFile {
    param (
        [string]$filePath
    )
    $hash = Get-FileHash $filePath -Algorithm MD5
    Add-Content $logFilePath -Value $hash.Hash
}

# Function to import and organize files
function ImportFiles {
    foreach ($fileType in $fileTypes) {
        $files = Get-ChildItem -Path $dcimPath -File -Recurse -Filter $fileType

        $totalFiles = $files.Count
        $currentFile = 0

        foreach ($file in $files) {
            $currentFile++
            Write-Progress -Activity "Importing files from $deviceModel" -Status "Processing file $currentFile of $totalFiles" -PercentComplete (($currentFile / $totalFiles) * 100)

            if (-not (IsFileImported $file.FullName)) {
                $fileDate = Get-DateFromMetadata $file.FullName
                $dateFolder = $fileDate.ToString($dateSortingScheme)
                $destinationFolder = Join-Path -Path $nasBasePath -ChildPath $deviceModel -ChildPath $dateFolder

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
    }

    Write-Output "Import complete. $currentFile files processed."
}

# Main script execution
ImportFiles
