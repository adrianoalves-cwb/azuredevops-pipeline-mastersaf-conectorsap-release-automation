$conectorSAPName = $env:CONECTORSAPNAME
$serviceName = $env:SERVICENAME
$conectorSAPInstallationDirectory = $env:CONECTORSAPINSTALLATIONDIRECTORY
$backupFolderDirectory = $env:BACKUPFOLDERDIRECTORY

function DeleteTemporaryDirectory() {
    # Cleaning up contents
    Get-ChildItem -Path $tempConectorSAPDirectory -Recurse | 
    Sort-Object { $_.FullName.Split('\').Count } -Descending | 
    ForEach-Object { 
        Write-Host "Removing: " $_.Name
        Remove-Item $_.FullName -Force 
    }

    # Wait a bit to ensure removal of any locked files/folders
    Start-Sleep -Seconds 1

    # Cleanup parent folder
    Remove-Item $tempConectorSAPDirectory -Force
    Write-Host "#The Temp Directory was removed"
}

Write-Host "##[section]VARIABLES:"
Write-Host "------------------------------------------------------------------------------------------"
Write-Host "ConectorSAP Name: " $conectorSAPName
Write-Host "Service Name: " $serviceName
Write-Host "ConectorSAP Installation Directory: " $conectorSAPInstallationDirectory
Write-Host "Backup Folder Directory: " $backupFolderDirectory

#Copying Installation to a temp folder
Write-Host "##[section]COPYING THE INSTALLATION FILES:"
Write-Host "------------------------------------------------------------------------------------------"
$tempConectorSAPDirectory = $backupFolderDirectory + '\' + $conectorSAPName

if (Test-Path $tempConectorSAPDirectory) {
    DeleteTemporaryDirectory
}

Write-Host "Copying the ConectorSAP installation files to the Temp directory"
Copy-item -Force -Recurse $conectorSAPInstallationDirectory -Destination $tempConectorSAPDirectory

#Remove unneeded folders and files
Write-Host "Removing the unneeded files from the Temp directory"

Remove-item $tempConectorSAPDirectory\*.trc -Force
Remove-item $tempConectorSAPDirectory\logs -Recurse -Force
Remove-item $tempConectorSAPDirectory\assets -Recurse -Force

Write-Host "------------------------------------------------------------------------------------------"

#Creating the Zip file
Write-Host "##[section]ZIP FILE CREATION:"

$date = (Get-Date).ToString("ddMMyyyy.hhmmss")
$backupFileName = "bkp_" + $serviceName + "_" + $date

$zipFileFullPath = $backupFolderDirectory + "\" + $backupFileName + ".zip"

if (Test-Path $zipFileFullPath -PathType Leaf) {
    Remove-Item $zipFileFullPath
    Write-Host "Zip File FullPath Found and Removed"
}

Write-Host "Creating the zip file..." $backupFileName

Compress-Archive -Path $conectorSAPInstallationDirectory -DestinationPath $zipFileFullPath
Write-Host "Creating the zip file... done"

#Remove the backup file from Temp folder

if (Test-Path $tempConectorSAPDirectory) {
    DeleteTemporaryDirectory
}

