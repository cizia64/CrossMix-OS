# Define the base directory to be scanned
$baseDirectory = "..\..\"

# Function to add a .gitkeep file to empty folders
function Add-GitKeep {
    param (
        [string]$folder
    )

    # Check if the folder is empty
    $files = Get-ChildItem -Path $folder
    if ($files.Count -eq 0) {
        # Create a .gitkeep file
        New-Item -Path (Join-Path -Path $folder -ChildPath ".gitkeep") -ItemType File -Force | Out-Null
        Write-Output "Added .gitkeep to $folder"
    }
}

# Retrieve all subfolders from the home directory
$subfolders = Get-ChildItem -Path $baseDirectory -Recurse -Directory

# Add a .gitkeep to each empty subfolder
foreach ($folder in $subfolders) {
    Add-GitKeep -folder $folder.FullName
}
