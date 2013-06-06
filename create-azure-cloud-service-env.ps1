Param(
    [Parameter(Mandatory = $true)]
    [String]$Name,

    [String]$Location = "West US",

    [String]$SqlDatabaseUserName = "dbuser",   # optional    default to "dbuser"
    
    [Parameter(Mandatory = $true)]
    [String]$SqlDatabasePassword,              # required    you can set the value here and make the parameter optional
    
                                               # optional    start IP address of the range you want to whitelist in SQL Azure firewall
    [String]$StartIPAddress,                   #             will try to detect if not specified

                                               # optional    end IP address of the range you want to whitelist in SQL Azure firewall
    [String]$EndIPAddress                      #             will try to detect if not specified
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Mark the start time of the script execution
$startTime = Get-Date

Write-Verbose ("[Start] creating Windows Azure cloud service environment {0}" -f $Name)

# Define the names of storage account, SQL Azure database and SQL Azure database server firewall rule
$Name = $Name.ToLower()
$storageAccountName = "{0}storage" -f $Name
$sqlDatabaseName = "appdb"
$sqlDatabaseServerFirewallRuleName = "{0}rule" -f $Name

# Get the directory of the current script
$scriptPath = Split-Path -parent $PSCommandPath

# Create a new cloud service
Write-Verbose ("[Start] creating cloud service {0} in location {1}" -f $Name, $Location)
New-AzureService -ServiceName $Name -Location $Location
Write-Verbose ("[Finish] creating cloud service {0} in location {1}" -f $Name, $Location)

# Create a new storage account
$storageAccount = & "$scriptPath\create-azure-storage.ps1" `
    -Name $storageAccountName `
    -Location $Location

# Create a SQL Azure database server and a database
$sql = & "$scriptPath\create-azure-sql.ps1" `
    -DatabaseName $sqlDatabaseName `
    -UserName $SqlDatabaseUserName `
    -Password $SqlDatabasePassword `
    -FirewallRuleName $sqlDatabaseServerFirewallRuleName `
    -StartIPAddress $StartIPAddress `
    -EndIPAddress $EndIPAddress `
    -Location $Location

# Set the default storage account of the subscription
# This storage account will be used when deploying the cloud service cspkg
$s = Get-AzureSubscription -Current
Set-AzureSubscription -SubscriptionName $s.SubscriptionName -CurrentStorageAccount $storageAccountName

Write-Verbose ("[Finish] creating Windows Azure cloud service environment {0}" -f $Name)

# Mark the finish time of the script execution
$finishTime = Get-Date
# Output the time consumed in seconds
Write-Output ("Total time used (seconds): {0}" -f ($finishTime - $startTime).TotalSeconds)