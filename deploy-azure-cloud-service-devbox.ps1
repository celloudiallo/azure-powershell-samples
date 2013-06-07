Param(
    [Parameter(Mandatory = $true)]
    [String]$ProjectFile
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Mark the start time of the script execution
$startTime = Get-Date

# Get the directory of the current script
$scriptPath = Split-Path -parent $PSCommandPath

$publishDir = "{0}\" -f $scriptPath

# Generate the cscfg and cspkg files
# & "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" $ProjectFile /t:Publish /p:TargetProfile=Cloud /p:PublishDir=$publishDir

[Xml]$envXml = Get-Content ("{0}\cloud-service-environment.xml" -f $scriptPath)
[Xml]$cscfgXml = Get-Content ("{0}\ServiceConfiguration.Cloud.cscfg" -f (Get-Item $ProjectFile).DirectoryName)

Foreach ($role in $cscfgXml.ServiceConfiguration.Role)
{

    Foreach ($setting in $role.ConfigurationSettings)
    {
        If ($setting.FirstChild.name -eq "Microsoft.WindowsAzure.Plugins.Diagnostics.ConnectionString")
        {
            $setting.FirstChild.value = $envXml.environment.storage.connectionString.ToString()
            Break
        }
    }

    # Add the connection string for appdb
    $setting1 = $cscfgXml.CreateElement("Setting", "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration")
    $setting1.SetAttribute("name", "appdb")
    $setting1.SetAttribute("value", $envXml.environment.sqlAzure.appdb.connectionString)
    $temp = $role.ConfigurationSettings.AppendChild($setting1)

    # Add the connection string for DefaultConnection
    $setting2 = $cscfgXml.CreateElement("Setting", "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration")
    $setting2.SetAttribute("name", "DefaultConnection")
    $setting2.SetAttribute("value", $envXml.environment.sqlAzure.DefaultConnection.connectionString)
    $temp = $role.ConfigurationSettings.AppendChild($setting2)
}

$cscfgXml.InnerXml

<#

$cscfg = "{0}\ServiceConfiguration.Cloud.cscfg" -f $scriptPath
$cspkg = "{0}\{1}.cspkg" -f $scriptPath, (Get-Item $ProjectFile).BaseName

# Read from cloud-service-environment.xml to get the environment name
[Xml]$envXml = Get-Content ("{0}\cloud-service-environment.xml" -f $scriptPath)
$cloudServiceName = $envXml.environment.name

# If there is no existing deployment on the cloud service, create a new deployment
# Otherwise, upgrade the deployment using simultaneous mode
# Notice: first time deployment always uses simultaneous mode
$deployment = $null
Try
{
    $deployment = Get-AzureDeployment -ServiceName $cloudServiceName
}
Catch
{
    New-AzureDeployment -ServiceName $cloudServiceName -Slot Production -Configuration $cscfg -Package $cspkg
}
If ($deployment)
{
    Set-AzureDeployment -ServiceName $cloudServiceName -Slot Production -Configuration $cscfg -Package $cspkg -Mode Simultaneous -Upgrade
}


# Mark the finish time of the script execution
$finishTime = Get-Date
# Output the time consumed in seconds
Write-Output ("Total time used (seconds): {0}" -f ($finishTime - $startTime).TotalSeconds)
#>