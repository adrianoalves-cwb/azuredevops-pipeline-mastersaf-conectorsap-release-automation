$FromEmailAddress = $env:FROMEMAILADDRESS;
$ToEmailAddresses = $env:TOEMAILADDRESS;
$SmtpServer = $env:SMTPSERVER;
$Version = $env:VERSION;
$Status = $env:STATUS;
$Environment = $env:ENVIRONMENT
$conectorSAPName = $env:CONECTOR_SAP_NAME

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

    Write-host "Preparing to send email...";

    $Message = new-object System.Net.Mail.MailMessage;
    $Message.From = $FromEmailAddress;
    $Message.To.Add($ToEmailAddresses);
    $Message.IsBodyHtml = $True;
    $Message.Subject = $Subject;

    $Message.body = $Body;
    $Smtp = new-object System.Net.Mail.SmtpClient($SmtpServer);

    Write-Host "##[command]Sending the e-mail to: " $ToEmailAddresses;
    $Smtp.Send($Message);

    Write-Host "##[section]E-mail sent!";
}
Write-Host "Environment: " $Environment;
Write-Host "ConectorSAP Installation Version: " $Version

$Environment = "$($Environment)".Replace("refs/heads/qa", "QA").Replace("refs/heads/main", "PROD");

Write-Host $Status;
Write-Host $Environment;
Write-Host "Starting the Send Email Function...";
Switch ($Status)
{
    "Updated" {
        $Subject = "Mastersaf $($Environment): $conectorSAPName Successfully Updated!"
        $Body = "<h2>Mastersaf $conectorSAPName  $($Environment) has been updated to the latest available version: $($Version).</h2><br>"
        break
    }
    "Failed" {
        $Subject = "Mastersaf $($Environment): Failed to Update the $conectorSAPName"
        $Body = "<h2>Failed to update the Mastersaf $conectorSAPName $($Environment) to the latest available version.</h2><br><p>An error occurred while attempting to update the MRC. The version was not changed. Please check the error logs or contact technical support for further assistance.</p>"
        break
    }
}

SendEmail -ToEmailAddresses $ToEmailAddresses -Subject $Subject -Body $Body -SmtpServer $SmtpServer;

if ($Status -notlike "*Updated*") {
    Write-Host "The installation was unsuccessful. A notification email has been sent to $($ToEmailAddresses) regarding this issue.";
}