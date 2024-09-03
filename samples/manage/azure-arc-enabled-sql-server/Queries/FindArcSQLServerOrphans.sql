//Two Methods

//Method 1: Works if you do not have duplicate Arc SQL Server Instances

// Step 1: Get all SQL Server instances with their containerResourceId
resources
| where type == "microsoft.azurearcdata/sqlserverinstances"
| extend containerResourceId = trim_end("/", tostring(tolower(parse_json(properties)["containerResourceId"])))  // Remove trailing slashes
| project SQL_Instance = name, containerResourceId//, Original_containerResourceId = containerResourceId
// Step 2: Join with Hybrid Compute Machines on containerResourceId
| join kind=leftouter (
    resources
    | where type == "microsoft.hybridcompute/machines"
    | extend id_normalized = trim_end("/", tolower(id))  // Normalize and remove trailing slashes
    | project containerResourceId2 = id_normalized
) on $left.containerResourceId == $right.containerResourceId2
// Step 3: Project and compare the original and normalized values
//| where containerResourceId2==""
| project SQL_Instance, containerResourceId, containerResourceId2

//Method 2: Works if you do have duplicate Arc SQL Server Instances

// Step 1: Get all SQL Server instances with their containerResourceId
resources
| where type == "microsoft.azurearcdata/sqlserverinstances"
| extend containerResourceId = trim_end("/", tostring(tolower(parse_json(properties)["containerResourceId"])))  // Normalize and remove trailing slashes
| project SQL_Instance = name, containerResourceId
// Step 2: Left join with Hybrid Compute Machines on containerResourceId
| join kind=leftouter (
    resources
    | where type == "microsoft.hybridcompute/machines"
    | extend id_normalized = trim_end("/", tolower(id))  // Normalize and remove trailing slashes
    | project containerResourceId2 = id_normalized
) on $left.containerResourceId == $right.containerResourceId2
// Step 3: Group by containerResourceId and count matches
| summarize TotalInstances = count(), MatchedInstances = countif(containerResourceId2 != "") by SQL_Instance, containerResourceId
// Step 4: Filter where not all instances have a match
| where MatchedInstances < TotalInstances
// Step 5: Project final output
| project SQL_Instance, containerResourceId

