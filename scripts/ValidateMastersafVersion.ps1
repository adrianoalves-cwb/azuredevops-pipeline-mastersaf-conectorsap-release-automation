
$ArtifactsDirectory = $env:ARTIFACTSDIRECTORY
$ArtifactsDirectoryPath = "$($ArtifactsDirectory)/drop/Version.txt"

function ValidateVersion {
    param (
        [string]$ArtifactsDirectoryPath
    )
    $Version = Get-Content $ArtifactsDirectoryPath
    
    Write-host "Version: " $Version
    
    if ($Version.Contains("UpToDate"))
    {
        Write-host "Version UpToDate. Skipping this release."
        Write-Host "##vso[task.setvariable variable=ArtifactValidation;isOutput=true]false"
    }
    else{
        Write-Host "##vso[task.setvariable variable=StageOutputVar;isOutput=true]$Version"
        Write-Host "##vso[task.setvariable variable=ArtifactValidation;isOutput=true]true"
    }    
}

if([System.IO.File]::Exists($ArtifactsDirectoryPath)){
    ValidateVersion -ArtifactsDirectoryPath $ArtifactsDirectoryPath;
} else {
    Write-host "Artifact drop was not found for build. Skipping this release."
    Write-Host "##vso[task.setvariable variable=ArtifactValidation;isOutput=true]false"
}