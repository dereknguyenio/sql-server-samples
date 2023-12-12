# Script Title: Azure Arc Machine Deletion Script - Powershell
# Description: This script is designed to delete Azure Arc-enabled machines along with their SQL Server instances.
# It iterates over a list of machine names and deletes the machine and its associated SQL Server instance from Azure Arc.

# Define the resource group name where the Azure Arc machines are located
$resourceGroup = "azurearcsqlvmdev_group"

# List of Azure Arc machine names to delete
# Add or remove machine names as needed
$machineNames = @(
    "ArcSQLVM2"
    # "machine2"
    # "machine3"
    # Add more machine names here
)

# Loop through each machine name in the list
foreach ($machineName in $machineNames) {
    Write-Host "Deleting Azure Arc SQL Server instance for  ${machineName}..."
    try {
        Remove-AzResource -ResourceGroupName "${resourceGroup}" -ResourceType "Microsoft.AzureArcData/SqlServerInstances" -Name "${machineName}" -Force
    }
    catch {
        Write-Host "Error deleting SQL Server instance for  ${machineName}: $_"
        continue
    }

    Write-Host "Deleting Arc machine  ${machineName}..."
    try {
        Remove-AzConnectedMachine -Name "${machineName}" -ResourceGroupName "${resourceGroup}"
    }
    catch {
        Write-Host "Error deleting Arc machine ${machineName}: $_"
    }

    Write-Host " ${machineName} resources deleted."
}

Write-Host "All specified machines and their related resources have been deleted."
