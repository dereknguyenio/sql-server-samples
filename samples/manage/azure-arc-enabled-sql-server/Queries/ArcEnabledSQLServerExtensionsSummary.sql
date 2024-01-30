// ArcEnabledSQLServerExtensionsSummary
// The query is intended to give a comprehensive overview of the SQL capabilities and extensions across hybrid compute resources, aiding in inventory management, compliance tracking, and resource optimization.
// Click the "Run query" command above to execute the query and see results.
// Query on 'microsoft.hybridcompute/machines'
Resources
| where type == 'microsoft.hybridcompute/machines'
| extend SubscriptionId = tostring(split(id, "/")[2])
| extend ResourceGroupName = tostring(split(id, "/")[4])
| extend MachineId = toupper(id)
| project
    id,
    SubscriptionId,
    ResourceGroupName,
    MachineId,
    ComputerName = tostring(properties.osProfile.computerName),
    OSName = tostring(properties.osName),
    ArcMachineStatus = tostring(properties.status),
    SqlDetected = tobool(coalesce(properties.detectedProperties.mssqldiscovered, properties.mssqlDiscovered)),
    Model = tostring(coalesce(properties.detectedProperties.model, properties.model))
| where SqlDetected == true
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
        //SqlServerLicenseType = tostring(properties.licenseType),
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
        ArcSqlLicenseType = tostring(properties.settings.LicenseType)
) on $left.MachineId == $right.ExtensionMachineId
| summarize ArcSqlLicenseType = any(ArcSqlLicenseType), Extensions = make_list(ExtensionName) 
    by id, SubscriptionId, ResourceGroupName, ComputerName, Model, OSName, ArcMachineStatus,  
    ServerInstanceName, vCores, SqlVersion, SqlEdition, SqlServerStatus, 
    CurrentSQLServerVersion, ProductId, PatchLevel, AzureDefenderStatus //, SqlServerLicenseType
| extend SqlServerExtensionExists = iff(array_index_of(Extensions, "WindowsAgent.SqlServer") != -1 
    or array_index_of(Extensions, "LinuxAgent.SqlServer") != -1, "Yes", "No")
| order by tolower(OSName) asc