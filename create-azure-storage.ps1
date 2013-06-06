Param(
    [Parameter(Mandatory = $true)]
    [String]$Name,
    
    [String]$Location = "West US"
)

# Create a new storage account
Write-Verbose ("[Start] creating storage account {0} in location {1}" -f $Name, $Location)
$storageAccount = New-AzureStorageAccount -StorageAccountName $Name -Location $Location -Verbose
Write-Verbose ("[Finish] creating storage account {0} in location {1}" -f $Name, $Location)

Return $storageAccount