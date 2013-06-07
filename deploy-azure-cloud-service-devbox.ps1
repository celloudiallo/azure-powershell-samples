Param(
    [Parameter(Mandatory = $true)]
    [String]$ProjectFile
)

Function Generate-Cscfg
{
    Param(
        [Xml]$EnvXml,
        [String]$SourceCscfgFile
    )

    # Get content of the project default ServiceConfiguration.Cloud.cscfg
    [Xml]$cscfgXml = Get-Content $SourceCscfgFile #("{0}\ServiceConfiguration.Cloud.cscfg" -f (Get-Item $ProjectFile).DirectoryName)

    # Update the cscfg in memory
    Foreach ($role in $cscfgXml.ServiceConfiguration.Role)
    {

        # Change the diagnostics connection string to use the storage account created by create-azure-cloud-service-env.ps1
        Foreach ($setting in $role.ConfigurationSettings)
        {
            If ($setting.FirstChild.name -eq "Microsoft.WindowsAzure.Plugins.Diagnostics.ConnectionString")
            {
                $setting.FirstChild.value = $EnvXml.environment.storage.connectionString
                Break
            }
        }

        # Add the connection string for appdb
        $setting1 = $cscfgXml.CreateElement("Setting", "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration")
        $setting1.SetAttribute("name", "appdb")
        $setting1.SetAttribute("value", $EnvXml.environment.sqlAzure.appdb.connectionString)
        $temp = $role.ConfigurationSettings.AppendChild($setting1)

        # Add the connection string for DefaultConnection
        $setting2 = $cscfgXml.CreateElement("Setting", "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration")
        $setting2.SetAttribute("name", "DefaultConnection")
        $setting2.SetAttribute("value", $EnvXml.environment.sqlAzure.memberdb.connectionString)
        $temp = $role.ConfigurationSettings.AppendChild($setting2)
    }

    $file = "{0}\ServiceConfiguration.{1}.cscfg" -f $scriptPath, $EnvXml.environment.name
    $cscfgXml.InnerXml | Out-File -Encoding utf8 $file

    Return $file
}

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Mark the start time of the script execution
$startTime = Get-Date

# Get the directory of the current script
$scriptPath = Split-Path -parent $PSCommandPath

$publishDir = "{0}\" -f $scriptPath

# Generate the cscfg and cspkg files
& "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" $ProjectFile /t:Publish /p:TargetProfile=Local /p:PublishDir=$publishDir

# Read from cloud-service-environment.xml to get the environment name
[Xml]$envXml = Get-Content ("{0}\cloud-service-environment.xml" -f $scriptPath)

$cloudServiceName = $envXml.environment.name
$cscfg = Generate-Cscfg -EnvXml $envXml -SourceCscfgFile ("{0}ServiceConfiguration.Local.cscfg" -f $publishDir)
$cspkg = "{0}\{1}.cspkg" -f $scriptPath, (Get-Item $ProjectFile).BaseName

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