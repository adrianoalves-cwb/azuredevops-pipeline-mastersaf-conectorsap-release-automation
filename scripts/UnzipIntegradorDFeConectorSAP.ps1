$sourceDir = $env:SOURCE_DIR
$destinationDir = $env:DESTINATION_DIR

$finalFolder = Join-Path $destinationDir "ConectorSAP"
$tempDir = Join-Path $destinationDir "tempDir"
$normalizedZip = Join-Path $destinationDir "ConectorSAP.zip"

function New-DirectoryIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Reset-Directory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -Confirm:$false
    }

    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

function Find-FirstZipByName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$root,

        [Parameter(Mandatory = $true)]
        [string]$pattern
    )

    $file = Get-ChildItem -Path $root -Recurse -File |
    Where-Object { $_.Name -like $pattern } |
    Select-Object -First 1

    if (-not $file) {
        throw "No file matching '$pattern' found under $root"
    }

    Write-Host "Found ZIP: $($file.FullName)"
    return $file
}

function Find-FirstFolderByName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$root,

        [Parameter(Mandatory = $true)]
        [string]$pattern
    )

    $folder = Get-ChildItem -Path $root -Recurse -Directory |
    Where-Object { $_.Name -like $pattern } |
    Select-Object -First 1

    if (-not $folder) {
        throw "No folder matching '$pattern' found under $root"
    }

    Write-Host "Found folder: $($folder.FullName)"
    return $folder
}

function Copy-AsFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$sourceFile,

        [Parameter(Mandatory = $true)]
        [string]$destinationFolder,

        [Parameter(Mandatory = $true)]
        [string]$newFileName
    )

    $destinationFile = Join-Path $destinationFolder $newFileName
    Copy-Item -Path $sourceFile -Destination $destinationFile -Force
    Write-Host "Copied to: $destinationFile"
    return $destinationFile
}

function Remove-IfExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$path,

        [switch]$Recurse
    )

    if (Test-Path $path) {
        if ($Recurse) {
            Remove-Item -Path $path -Recurse -Force -Confirm:$false
        }
        else {
            Remove-Item -Path $path -Force -Confirm:$false
        }

        Write-Host "Removed: $path"
    }
    else {
        Write-Host "Skipping, not found: $path"
    }
}

if (-not (Test-Path $sourceDir)) {
    throw "Source directory does not exist: $sourceDir"
}

New-DirectoryIfNotExists -path $destinationDir
Reset-Directory -path $tempDir

Write-Host "Step 1: Find downloaded installation ZIP"
$downloadedInstallationZipFile = Find-FirstZipByName -root $sourceDir -pattern '*ConectorSAP*.zip'

Write-Host "Step 2: Extract installation ZIP"
Expand-Archive -Path $downloadedInstallationZipFile.FullName -DestinationPath $tempDir -Force

Write-Host "Step 3: Find nested ConectorSAP ZIP"
$conectorZipFile = Find-FirstZipByName -root $tempDir -pattern '*ConectorSAP*.zip'

Write-Host "Step 4: Copy nested ZIP as ConectorSAP.zip to destination"
Copy-AsFileName -sourceFile $conectorZipFile.FullName -destinationFolder $destinationDir -newFileName 'ConectorSAP.zip' | Out-Null

Write-Host "Step 5: Reset temp directory"
Reset-Directory -path $tempDir

Write-Host "Step 6: Extract normalized ZIP"
Expand-Archive -Path $normalizedZip -DestinationPath $tempDir -Force

Write-Host "Step 7: Delete normalized ZIP"
Remove-IfExists -path $normalizedZip

Write-Host "Step 8: Find ConectorSAP folder"
$conectorSAPFolder = Find-FirstFolderByName -root $tempDir -pattern 'ConectorSAP*'

Write-Host "Step 9: Replace final ConectorSAP folder"
Remove-IfExists -path $finalFolder -Recurse
Copy-Item -Path $conectorSAPFolder.FullName -Destination $finalFolder -Recurse -Force
Write-Host "Copied folder to: $finalFolder"

Write-Host "Step 10: Clean temp directory"
Remove-IfExists -path $tempDir -Recurse

Write-Host "Step 11: Remove unneeded folders and files"
$foldersToRemove = @('config', 'assets', 'logs')
$filesToRemove = @('logback.xml', 'bin\wrapper.conf')

foreach ($folder in $foldersToRemove) {
    $folderPath = Join-Path $finalFolder $folder
    Remove-IfExists -path $folderPath -Recurse
}

foreach ($file in $filesToRemove) {
    $filePath = Join-Path $finalFolder $file
    Remove-IfExists -path $filePath
}

Write-Host "Completed successfully."