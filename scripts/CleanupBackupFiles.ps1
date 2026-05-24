
$backupFolderDirectory = $env:BACKUPFOLDERDIRECTORY


Write-Host "Checking the Backup Directory: " $backupFolderDirectory

$fileCount = (Get-ChildItem -Path $backupFolderDirectory -Filter *.zip).Count

$oldFilesCount = Get-ChildItem -Path $backupFolderDirectory -Filter *.zip | Where-Object {$_.LastWriteTime -lt (get-date).adddays(-15)}

foreach ($f in $oldFilesCount){

    if ($fileCount -gt 5)
    {    
        Write-Host "Deleting the file: " $f
        Remove-Item $f.FullName
    }

    $fileCount --
}


