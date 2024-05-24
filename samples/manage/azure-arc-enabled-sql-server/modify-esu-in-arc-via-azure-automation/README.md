# Azure Connected Machine Extension Update Runbook

## Overview
This runbook provides detailed instructions for using Azure Automation to manage Azure Connected Machine extensions through PowerShell scripts. The process leverages a system-assigned managed identity that must have appropriate roles assigned to perform operations on Azure Arc-enabled servers.

## Prerequisites
- An active Azure subscription.
- Appropriate permissions in Azure to create Automation Accounts, assign roles, and manage Azure Arc-enabled servers.
- Azure PowerShell modules should be available within your Azure Automation account.

## Setup Azure Automation Account

### Step 1: Create an Azure Automation Account
1. **Navigate to the Azure Portal** at https://portal.azure.com.
2. Search for and select **Automation Accounts**.
3. Click **+ Create**.
4. Fill in the details:
   - **Name**: Provide a unique name.
   - **Subscription**: Select your subscription.
   - **Resource group**: Choose an existing group or create a new one.
   - **Location**: Select the region closest to your resources.
5. Click **Review + Create** and then **Create** to setup the Automation Account.

### Step 2: Enable and Assign System Assigned Managed Identity
1. Go to your newly created **Automation Account**.
2. Select **Identity** under **Account Settings**.
3. In the **System assigned** tab, toggle **Status** to **On** and click **Save**.
4. After enabling, Azure will automatically create a managed identity for the account.

### Step 3: Assign Azure Connected Machine Resource Administrator Role
1. After enabling the system-assigned identity, navigate to **Subscriptions**.
2. Select your subscription, then click on **Access control (IAM)**.
3. Click on **+ Add** and select **Add role assignment**.
4. In the **Role** dropdown, search for and select **Azure Connected Machine Resource Administrator** or your custom RBAC role.
5. Set **Assign access to** the option to **Managed Identity**.
6. Select your Automation Account's managed identity.
7. Click **Save** to apply the role assignment.

### Step 4: Import Necessary Modules
1. In the Automation Account, go to **Shared Resources** > **Modules**.
2. Click on **Browse gallery**.
3. Search and import the following modules if they are not already available:
   - `Az.Accounts`
   - `Az.Automation`
   - `Az.ConnectedMachine`

## Creating and Configuring the Runbook

### Step 5: Create and Edit a PowerShell Runbook
1. Within the Automation Account, navigate to **Process Automation** > **Runbooks**.
2. Click **+ Create a runbook**, enter a name, select **PowerShell** for runbook type, choose the latest runtime version.
3. After creation, click **Edit**, paste your PowerShell script into the runbook editor.
4. Adjust any parameters as necessary and click **Save**, then **Publish** to finalize the runbook.

## Running the Runbook

### Step 6: Start the Runbook
1. Open the runbook and click **Start**.
2. Enter required parameters like `SubscriptionId`, `ResourceGroup`, etc.
3. Click **OK** to execute.

### Step 7: Monitor and Troubleshoot
- View the runbook's execution status and results under **Jobs**.
- If errors occur, use the detailed logs provided to troubleshoot issues, ensuring that permissions and roles are correctly configured.

This comprehensive guide ensures that your Azure Automation setup is properly configured to manage Azure Connected Machine extensions using a secure and automated approach with the necessary permissions.
