$environment = $env:ENVIRONMENT
$conectorSAPInstallationDirectory = $env:CONECTORSAP_INSTALLATION_DIRECTORY
$versionTxtPath = $env:VERSION_TXT_PATH

#ConectorSAP Installation Version
$conectorSAPversion = Get-Content -Path "$versionTxtPath/BuildPipeline/drop/Version.txt"

#ConectorSAP Version from the log
$logFileVersion = Get-Content -Path "$conectorSAPInstallationDirectory/logs/conector-erp.log" | Select-String -Pattern $environment" - (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
$logVersion = $logFileVersion.Split('[main]')[0].Trim()

Write-Host "Expected version: $conectorSAPversion"
Write-Host "##vso[task.setvariable variable=deployVersion;isOutput=true]$conectorSAPversion"

Write-Host "Version found in the log: $logVersion"

if (("$conectorSAPversion".Trim() -replace '[^0-9.]', '') -eq ("$logVersion".Trim() -replace '[^0-9.]', '')) {
    Write-Host "Installation is successful"
    Write-Host "##vso[task.setvariable variable=StageOutputVar;isOutput=true]$logVersion"
} else {
    Write-Host "Installation is not successful, the versions do not match."
    exit 1
}