//UPDATED KUSTO QUERY - Arc SQL Server Summary - Includes AVS + Onpremise
//The script is a Kusto query designed to summarize Azure Arc-enabled SQL Server instances, including Azure VMware Solution (AVS) and on-premise machines. It extends and joins various properties from resources to provide details such as subscription ID, resource group, machine ID, computer name, operating system, SQL server status, version, and license type, among others. The results are ordered by operating system name.

 
Resources
| where type == 'microsoft.hybridcompute/machines'
| extend SubscriptionId = tostring(split(id, "/")[2])
| extend ResourceGroupName = tostring(split(id, "/")[4])
| extend MachineId = toupper(id)
| extend Kind = tostring(kind)
| project
    id,
    SubscriptionId,
    ResourceGroupName,
    MachineId,
    Kind,
    ComputerName = tostring(properties.osProfile.computerName),
    OSName = tostring(properties.osName),
    ArcMachineStatus = tostring(properties.status),
    SqlDetected = tobool(coalesce(properties.detectedProperties.mssqldiscovered, properties.mssqlDiscovered)),
    Model = tostring(coalesce(properties.detectedProperties.model, properties.model))
| where SqlDetected == true and (Kind == '' or Kind == 'VMWare' or Kind == 'AVS')
| join kind=leftouter (
    Resources
    | where type == "microsoft.azurearcdata/sqlserverinstances"
    | where properties.containerResourceId != ""
    | project 
        ArcMachineId = toupper(tostring(properties.containerResourceId)),
        ServerInstanceName = tostring(properties.instanceName),
        vCores = toint(properties.vCore),
        SqlVersion = tostring(properties.version),
        SqlEdition = tostring(properties.edition),
        SqlServerStatus = tostring(properties.status),
        CurrentSQLServerVersion = tostring(properties.currentVersion),
        ProductId = tostring(properties.productId),
        PatchLevel = tostring(properties.patchLevel),
        AzureDefenderStatus = tostring(properties.azureDefenderStatus)
) on $left.MachineId == $right.ArcMachineId
| join kind=leftouter (
    Resources
    | where type == 'microsoft.hybridcompute/machines/extensions'
    | project
        ExtensionMachineId = toupper(substring(id, 0, indexof(id, '/extensions'))),
        ExtensionName = name,
        ArcSqlLicenseType = tostring(properties.settings.LicenseType),
        SqlServerExtensionVersion = iff(properties.type == "WindowsAgent.SqlServer", properties.instanceView.typeHandlerVersion, ""),
        SqlServerExtensionStatus = iff(properties.type == "WindowsAgent.SqlServer", properties.provisioningState, "")
        //SqlServerExtensionMessage = iff(properties.type == "WindowsAgent.SqlServer", properties.instanceView.status.message, "")
) on $left.MachineId == $right.ExtensionMachineId
| summarize ArcSqlLicenseType = any(ArcSqlLicenseType), Extensions = make_list(ExtensionName), 
    SqlServerExtensionVersion = any(SqlServerExtensionVersion), SqlServerExtensionStatus = any(SqlServerExtensionStatus)
    //SqlServerExtensionMessage = any(SqlServerExtensionMessage)  
    by id, SubscriptionId, ResourceGroupName, Kind, ComputerName, Model, OSName, ArcMachineStatus,  
    ServerInstanceName, vCores, SqlVersion, SqlEdition, SqlServerStatus, 
    CurrentSQLServerVersion, ProductId, PatchLevel, AzureDefenderStatus
| extend SqlServerExtensionExists = iff(array_index_of(Extensions, "WindowsAgent.SqlServer") != -1, "Yes", "No")
| order by tolower(OSName) asc
