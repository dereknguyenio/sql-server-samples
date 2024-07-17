// Extract SQL Virtual Machines information and join with Compute Virtual Machines
resources
| where type == "microsoft.sqlvirtualmachine/sqlvirtualmachines"
| project
    sqlVmName = name,
    location,
    virtualMachineResourceId = tostring(properties.virtualMachineResourceId),
    SubscriptionId = tostring(split(id, "/")[2]),
    ResourceGroupName = tostring(split(id, "/")[4]),
    sqlServerLicenseType = tostring(properties.sqlServerLicenseType),
    version = tostring(properties.sqlImageOffer),
    Edition = tostring(properties.sqlImageSku),
    osType = tostring(properties.osType),
    provisioningState = tostring(properties.provisioningState)
| join kind=inner (
    resources
    | where type == "microsoft.compute/virtualmachines"
    | project
        virtualMachineResourceId = tostring(id),
        vCores = tostring(properties.hardwareProfile.vmSize)
) on $left.virtualMachineResourceId == $right.virtualMachineResourceId
| project
    sqlVmName,
    location,
    SubscriptionId,
    ResourceGroupName,
    sqlServerLicenseType,
    version,
    Edition,
    vCores,
    osType,
    provisioningState
| order by sqlVmName asc
