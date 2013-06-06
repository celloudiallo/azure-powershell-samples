Param(
    [Parameter(Mandatory = $true)]
    [String]$ProjectFile,
    [String]$Name
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Mark the start time of the script execution
$startTime = Get-Date

# Get the directory of the current script
$scriptPath = Split-Path -parent $PSCommandPath

$publishDir = "{0}\" -f $scriptPath

# Generate the cscfg and cspkg files
& "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" $ProjectFile /t:Publish /p:TargetProfile=Cloud /p:PublishDir=$publishDir

$cscfg = "{0}\ServiceConfiguration.Cloud.cscfg" -f $scriptPath
$cspkg = "{0}\{1}.cspkg" -f $scriptPath, (Get-Item $ProjectFile).BaseName

# If there is no existing deployment on the cloud service, create a new deployment
# Otherwise, upgrade the deployment using simultaneous mode
# Notice: first time deployment always uses simultaneous mode
$deployment = $null
Try
{
    $deployment = Get-AzureDeployment -ServiceName $Name
}
Catch
{
    New-AzureDeployment -ServiceName $Name -Slot Production -Configuration $cscfg -Package $cspkg
}
If ($deployment)
{
    Set-AzureDeployment -ServiceName $Name -Slot Production -Configuration $cscfg -Package $cspkg -Mode Simultaneous -Upgrade
}


# Mark the finish time of the script execution
$finishTime = Get-Date
# Output the time consumed in seconds
Write-Output ("Total time used (seconds): {0}" -f ($finishTime - $startTime).TotalSeconds)