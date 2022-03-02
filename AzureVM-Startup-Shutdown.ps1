param(
    [Parameter(Mandatory)][string]$powerMgmtTag,
    [Parameter(Mandatory)][ValidateSet("Startup", "Shutdown")][string]$action
)

## Import Powershell Modules
Import-Module Az.Accounts
Import-Module Az.Compute
Import-Module Az.Resources

## Get service principal details from shared resources
$azureSpCreds = Get-AutomationPSCredential -Name ''
$tenantId = Get-AutomationVariable -Name ''
$SubId = Get-AutomationVariable -Name ''

## Disabling autosaving of Azure credentials
Disable-AzContextAutoSave

## Auth with service principal
Connect-AzAccount -ServicePrincipal -Credential $azureSpCreds -Tenant $tenantId

Set-AzContext -Subscription $SubId

$azureVMs = Get-AzResource -Tag @{ "Power Management" = $powerMgmtTag } | Where-Object -FilterScript { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" }

switch ($action) {

    Shutdown {

        ## Loop over each item and stop the VM
        foreach ($azureVm in $azureVms ) {

            try {
                Write-Output "Shutting down $($azureVm.Name)"
                Stop-AzVM -Name $azureVm.Name -ResourceGroup $azureVm.ResourceGroupName -Force
                Write-Output "$($azureVm.Name) has been deallocated"
            }

            catch {

                Write-Output "Something went wrong shutting down $($azureVm.Name)"
                Write-Output $_
            }
        }
    }

    Startup {

        foreach ($azureVm in $azureVms ) {

            try {
                Write-Output "Starting up $($azureVm.Name)"
                Start-AzVM -Name $azureVm.Name -ResourceGroup $azureVm.ResourceGroupName
                Write-Output "$($azureVm.Name) has been started"
            }

            catch {

                Write-Output "Something went wrong starting up $($azureVm.Name)"
                Write-Output $_
            }
          }  
        }
    }