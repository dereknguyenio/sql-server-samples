# Instructions to Run the Script
# Save the Script: Save the script to a file, e.g., update_extension.ps1.

#https://learn.microsoft.com/en-us/sql/sql-server/end-of-support/sql-server-extended-security-updates?view=sql-server-ver16&tabs=cli#subscribe-instances-for-esus

# Explanation:
# - Login with Managed Identity: The script uses the managed identity to log in to Azure.
# - Set Subscription: Sets the Azure subscription to the specified subscription ID.
# - Update Extension: For each machine name in the $MachineNames array, the script updates the Azure Connected Machine extension with the specified settings.
# - Error Handling: The script checks if the extension update was successful and prints appropriate messages.

# How to setup Azure Automation Account and Runbook:

# Step 1: Create an Azure Automation Account
# Create an Automation Account:
# Go to the Azure Portal.
# Search for Automation Accounts and create a new account.
# Configure the necessary settings and create the account.
# Setup Systemed Assigned Managed Identity on the Azure Automation account and assign custom role to the managed identity to allow the managed identity to perform the Arc actions.
# Step 2: Import the Az.ConnectedMachine Module
# Navigate to the Automation Account:

# Go to your newly created Automation Account in the Azure Portal.
# Import Modules:

# In the Automation Account, go to Shared Resources > Modules.
# Click on Browse gallery.
# Search and Import the Module:

# In the Browse gallery, search for Az.ConnectedMachine.
# Select the Az.ConnectedMachine module from the list and click Import.
# Wait for the module to be imported. This might take a few minutes.
# Step 3: Create a Runbook
# Create a PowerShell Runbook:

# In your Automation Account, go to Process Automation > Runbooks.
# Click Create a runbook.
# Enter a name, select PowerShell as the runbook type, and create the runbook.

Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "<Arc Subscription ID>",

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "<Arc Resource Group>",

    [Parameter(Mandatory=$true)]
    [string]$Location = "<Arc Region ie eastus>",

    [Parameter(Mandatory=$true)]
    [string]$MachineName,

    [Parameter(Mandatory=$true)]
    [string]$Method = "SA",

    [Parameter(Mandatory=$false)]
    [string]$UAMI,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Paid", "LicenseOnly", "PAYG")]
    [string]$LicenseType,

    [Parameter(Mandatory=$true)]
    [bool]$EnableESU
)

$automationAccount = "xAutomationAccount"

# Ensures you do not inherit an AzContext in your runbook
$null = Disable-AzContextAutosave -Scope Process

# Connect using a Managed Service Identity
try {
    $AzureConnection = (Connect-AzAccount -Identity).context
    $AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureConnection
}
catch {
    Write-Output "There is no system-assigned user identity or failed to set context. Aborting." 
    exit
}

if ($Method -eq "SA") {
    Write-Output "Using system-assigned managed identity"
}
elseif ($Method -eq "UA") {
    Write-Output "Using user-assigned managed identity"
    $identity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroup -Name $UAMI -DefaultProfile $AzureContext

    if ($identity) {
        $AzureConnection = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context
        $AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureConnection
    } else {
        Write-Output "Invalid or unassigned user-assigned managed identity. Aborting."
        exit
    }
}
else {
    Write-Output "Invalid method specified. Please enter 'UA' for User-Assigned or 'SA' for System-Assigned."
    exit
}

# Prepare settings for Azure Connected Machine extension
$Settings = @{
    SqlManagement = @{ IsEnabled = $true }
    LicenseType = $LicenseType
    enableExtendedSecurityUpdates = $EnableESU
}

# Attempt to update the Azure Connected Machine extension
try {
    Set-AzConnectedMachineExtension -Name "WindowsAgent.SqlServer" -ResourceGroupName $ResourceGroup -MachineName $MachineName -Location $Location -Publisher "Microsoft.AzureData" -Settings $Settings -ExtensionType "WindowsAgent.SqlServer" -DefaultProfile $AzureContext

    Write-Output "Successfully updated extension for $MachineName."
}
catch {
    Write-Output "Failed to update extension for $MachineName. Error: $_"
}

# Output final context account ID
Write-Output "Account ID of current context: " + $AzureContext.Account.Id
