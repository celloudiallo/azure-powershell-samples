Param(
    [String]$Name,
    [String]$Location = "West US"
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -parent $PSCommandPath

# Select-AzureSubscription "Azpad054VSS8333"
$s = Get-AzureSubscription -Current
# $s.CurrentStorageAccount
Set-AzureSubscription -SubscriptionName $s.SubscriptionName -CurrentStorageAccount "guayanstorage01"

# $cs = New-AzureService -ServiceName $Name -Location $Location
$cscfg = "C:\Users\guayan\Documents\visual studio 2012\Projects\WindowsAzure1\WindowsAzure1\ServiceConfiguration.Cloud.cscfg"
$cspkg = "C:\Users\guayan\Documents\visual studio 2012\Projects\WindowsAzure1\WindowsAzure1\bin\Release\app.publish\WindowsAzure1.cspkg"
# Set-Location "C:\Users\guayan\Documents\visual studio 2012\Projects\WindowsAzure1\WindowsAzure1"
# Save-AzureServiceProjectPackage
# Set-Location $scriptPath
Try
{
    $deployment = Get-AzureDeployment -ServiceName $Name
}
Catch
{
    New-AzureDeployment -ServiceName $Name -Slot Production -Configuration $cscfg -Package $cspkg
}
Set-AzureDeployment -ServiceName $Name -Slot Production -Configuration $cscfg -Package $cspkg -Mode Simultaneous -Upgrade