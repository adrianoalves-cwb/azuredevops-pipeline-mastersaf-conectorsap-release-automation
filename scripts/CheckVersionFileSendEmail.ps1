
$FromEmailAddress = $env:FROMEMAILADDRESS
$ToEmailAddresses = $env:TOEMAILADDRESS
$SmtpServer = $env:SMTPSERVER
$Environment = $env:ENVIRONMENT
$VersionFilePath = $env:VERSION_FILE_PATH
$TRVersion = $env:VERSION

Function CheckVersionFile
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Version,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $VersionFilePath
    )

    if (Test-Path $VersionFilePath -PathType Leaf)
    {
        foreach($line in Get-Content $VersionFilePath) 
        {
            if ($line -match $Version)
            {
                write-host "The version: " $Version " is already in the VersionFile. The script is terminating..."
                return $true
            }
        }
    }

    write-host "The version: " $Version "is NOT in the VersionFile"
    return $false
}

Function AddToVersionFile
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Line,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $VersionFilePath
    )

    if (Test-Path $VersionFilePath -PathType Leaf)
    {
        Add-Content $VersionFilePath -Value $Line
    }
    Else
    {
        $Line | Out-File -FilePath $VersionFilePath
    }

    write-host $Line " Has been added to the Version file"
}

Function SendEmail()
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ToEmailAddresses,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Subject,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $Body,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $SmtpServer
    )

    Write-Host "##[section]---------------- CONFIRMATION EMAIL -------------------------------------"

    $Message = new-object System.Net.Mail.MailMessage 
    $Message.From = $FromEmailAddress 
    $Message.To.Add($ToEmailAddresses)
    $Message.IsBodyHtml = $True 
    $Message.Subject = $Subject 

    $Message.body = $Body
    $Smtp = new-object System.Net.Mail.SmtpClient($SmtpServer) 

    Write-Host "##[command]Sending the e-mail to: " $ToEmailAddresses
    $Smtp.Send($Message)

    Write-Host "##[section]E-mail sent!"
}

Function GetVersionFromTRVersion
{
    $SplitVersion = $TRVersion.Split('-')
    return $SplitVersion[0] -Replace '[^0-9.]', '' 
}

$Version = GetVersionFromTRVersion

#echo "##vso[build.addbuildtag]$Version

Write-Host "TRVersion: " $TRVersion
Write-Host "Version: " $Version
Write-Host "VersionFilePath: " $VersionFilePath
write-host ""

Write-Host "##[section]---------------- CHECK VERSION FILE -------------------------------------"
$IsVersionInProductionFile = CheckVersionFile -Version $Version -VersionFilePath $VersionFilePath

if ($IsVersionInProductionFile -eq $false)
{    
    $Now = Get-Date
    $DateStr = $Now.ToString("dd/MM/yyyy")

    $Line = $Version + " - " + $DateStr

    AddToVersionFile -Line $Line -VersionFilePath $VersionFilePath

    $Subject = "Mastersaf " + $Environment + " - Thomson Reuters has updated the ConectorSAP Version To: " + $Version

    $Body = "<h2>A new ConectorSAP version was released in " + $Environment + ": " + $Version + "</h2><br>"

    SendEmail -ToEmailAddresses $ToEmailAddresses -Subject $Subject -Body $Body -SmtpServer $SmtpServer

    Write-Host "##vso[task.setvariable variable=NewVersion;isOutput=true]true"

    $FileNameWithPath = $env:BUILD_ARTIFACTSTAGINGDIRECTORY + "/Version.txt"
    $Version | Out-File -FilePath $FileNameWithPath
}
else{
    
    $Version = "UpToDate";

    $FileNameWithPath = $env:BUILD_ARTIFACTSTAGINGDIRECTORY + "/Version.txt"
    $Version | Out-File -FilePath $FileNameWithPath

    Write-Host "##vso[task.setvariable variable=NewVersion;isOutput=true]true"
}

