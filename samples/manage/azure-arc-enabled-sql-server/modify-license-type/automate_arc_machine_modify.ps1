<#
SYNOPSIS
Azure Arc Machine License Type Modification Script

DESCRIPTION
This PowerShell script is designed to change the license type for a list of Azure Arc-enabled machines.
It takes a list of machine names and applies the specified license type to each machine.
The script requires the Azure subscription ID, the resource group name, the machine names, and the license type as inputs.

PARAMETER SubId
The ID of the Azure subscription.

PARAMETER ResourceGroup
The name of the Azure resource group containing the machines.

PARAMETER MachineNames
An array of machine names whose license type will be modified.

PARAMETER LicenseType
The license type to apply to the machines (e.g., "Paid", "PAYG").

EXAMPLE
.\automate_arc_machine_modify.ps1 -SubId "your_subscription_id" -ResourceGroup "your_resource_group" -MachineNames "machine1","machine2","machine3" -LicenseType "Paid"

#>

param(
    [string]$SubId,
    [string]$ResourceGroup,
    [string[]]$MachineNames, # Array of machine names
    [string]$LicenseType
)

function Modify-LicenseType {
    param(
        [string]$MachineName
    )

    # Executes the modify-license-type.ps1 script with provided parameters to change the license type of the given machine
    .\modify-license-type.ps1 -SubId $SubId -ResourceGroup $ResourceGroup -MachineName $MachineName -LicenseType $LicenseType -Force
    Write-Host "License type for $MachineName modified."
}

# Iterating over each machine name provided and modifying its license type
foreach ($MachineName in $MachineNames) {
    Modify-LicenseType -MachineName $MachineName
}
