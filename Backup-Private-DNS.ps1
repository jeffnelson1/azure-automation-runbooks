## Import Powershell Modules
Import-Module Az.Accounts
Import-Module Az.Storage
Import-Module Az.PrivateDns

## Get service principal details from shared resources
$azureSpCreds = Get-AutomationPSCredential -Name ''
$tenantId = Get-AutomationVariable -Name ''
$SubId = Get-AutomationVariable -Name ''

## Disabling autosaving of Azure credentials
Disable-AzContextAutoSave

## Authenticating to Azure with service principal
Connect-AzAccount -ServicePrincipal -Credential $azureSpCreds -Tenant $tenantID

## Setting the context to the Digital Engineering subscription
Set-AzContext -SubscriptionId $SubId

$dnsZoneBackupFileName = "dnsZoneBackup_$(get-date -f yyyy-MM-dd).csv"
$dnsRecordBackupFileName = "dnsRecordBackup_$(get-date -f yyyy-MM-dd).csv"

$null = Get-AzPrivateDnsZone | Select-Object Name, ResourceGroupName, NumberOfRecordSets, Tags | Export-Csv $dnsZoneBackupFileName

$privateDnsZones = Get-AzPrivateDnsZone

foreach ($privateDnsZone in $privateDnsZones) {
    
    $null = Get-AzPrivateDnsRecordSet -ZoneName $privateDnsZone.Name -ResourceGroupName $privateDnsZone.ResourceGroupName | Select-Object Name, ZoneName, Ttl, RecordType | Export-Csv -Path $dnsRecordBackupFileName -Append -NoClobber

}

#Get key to storage account
$acctKey = (Get-AzStorageAccountKey -Name "saname" -ResourceGroupName RgName).Value[0]

#Map to the reports BLOB context
$storageContext = New-AzStorageContext -StorageAccountName "saname" -StorageAccountKey $acctKey

#Copy the dnsZoneBackup file to the storage account
Write-Output "Sending the dnsZoneBackup file to the storage account"
Set-AzStorageBlobContent -File $dnsZoneBackupFileName -Container "azure**" -BlobType "Block" -Context $storageContext -Verbose

#Copy the dnsRecordBackup file to the storage account
Write-Output "Sending the dnsRecordBackup file to the storage account"
Set-AzStorageBlobContent -File $dnsRecordBackupFileName -Container "azure**" -BlobType "Block" -Context $storageContext -Verbose