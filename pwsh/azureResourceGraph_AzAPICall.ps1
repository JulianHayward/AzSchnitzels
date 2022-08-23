<#
AzAPICall Powershell Module is required! https://www.powershellgallery.com/packages/AzAPICall
#>
param(
    [Parameter(Mandatory = $True)]
    [string]
    $ManagementGroupId, #the Id, not the displayName

    [Parameter(Mandatory = $false)]
    [int]
    $SubscriptionBatchSize = 1000  #max 1000
)

function getEntities {
    Write-Host 'Entities'
    $startEntities = Get-Date
    $currentTask = ' Getting Entities'
    Write-Host $currentTask
    #https://management.azure.com/providers/Microsoft.Management/getEntities?api-version=2020-02-01
    $uri = "$($azAPICallConf['azAPIEndpointUrls'].ARM)/providers/Microsoft.Management/getEntities?api-version=2020-02-01"
    $method = 'POST'
    $script:arrayEntitiesFromAPI = AzAPICall -AzAPICallConfiguration $azAPICallConf -uri $uri -method $method -currentTask $currentTask

    Write-Host "  $($arrayEntitiesFromAPI.Count) Entities returned"

    $endEntities = Get-Date
    Write-Host " Getting Entities duration: $((NEW-TIMESPAN -Start $startEntities -End $endEntities).TotalSeconds) seconds"

    $startEntitiesdata = Get-Date
    Write-Host ' Processing Entities data'
    $script:htSubscriptionsMgPath = @{}
    $script:htManagementGroupsMgPath = @{}
    $script:htEntities = @{}
    $script:htEntitiesPlain = @{}

    foreach ($entity in $arrayEntitiesFromAPI) {
        $script:htEntitiesPlain.($entity.Name) = @{}
        $script:htEntitiesPlain.($entity.Name) = $entity
    }

    foreach ($entity in $arrayEntitiesFromAPI) {
        if ($entity.Type -eq '/subscriptions') {
            $script:htSubscriptionsMgPath.($entity.name) = @{}
            $script:htSubscriptionsMgPath.($entity.name).ParentNameChain = $entity.properties.parentNameChain
            $script:htSubscriptionsMgPath.($entity.name).ParentNameChainDelimited = $entity.properties.parentNameChain -join '/'
            $script:htSubscriptionsMgPath.($entity.name).Parent = $entity.properties.parent.Id -replace '.*/'
            $script:htSubscriptionsMgPath.($entity.name).ParentName = $htEntitiesPlain.($entity.properties.parent.Id -replace '.*/').properties.displayName
            $script:htSubscriptionsMgPath.($entity.name).DisplayName = $entity.properties.displayName
            $array = $entity.properties.parentNameChain
            $array += $entity.name
            $script:htSubscriptionsMgPath.($entity.name).path = $array
            $script:htSubscriptionsMgPath.($entity.name).pathDelimited = $array -join '/'
            $script:htSubscriptionsMgPath.($entity.name).level = (($entity.properties.parentNameChain).Count - 1)
        }
        if ($entity.Type -eq 'Microsoft.Management/managementGroups') {
            if ([string]::IsNullOrEmpty($entity.properties.parent.Id)) {
                $parent = '__TenantRoot__'
            }
            else {
                $parent = $entity.properties.parent.Id -replace '.*/'
            }
            $script:htManagementGroupsMgPath.($entity.name) = @{}
            $script:htManagementGroupsMgPath.($entity.name).ParentNameChain = $entity.properties.parentNameChain
            $script:htManagementGroupsMgPath.($entity.name).ParentNameChainDelimited = $entity.properties.parentNameChain -join '/'
            $script:htManagementGroupsMgPath.($entity.name).ParentNameChainCount = ($entity.properties.parentNameChain | Measure-Object).Count
            $script:htManagementGroupsMgPath.($entity.name).Parent = $parent
            $script:htManagementGroupsMgPath.($entity.name).ChildMgsAll = ($arrayEntitiesFromAPI.where( { $_.Type -eq 'Microsoft.Management/managementGroups' -and $_.properties.ParentNameChain -contains $entity.name } )).Name
            $script:htManagementGroupsMgPath.($entity.name).ChildMgsDirect = ($arrayEntitiesFromAPI.where( { $_.Type -eq 'Microsoft.Management/managementGroups' -and $_.properties.Parent.Id -replace '.*/' -eq $entity.name } )).Name
            $script:htManagementGroupsMgPath.($entity.name).DisplayName = $entity.properties.displayName
            $script:htManagementGroupsMgPath.($entity.name).Id = ($entity.name)
            $array = $entity.properties.parentNameChain
            $array += $entity.name
            $script:htManagementGroupsMgPath.($entity.name).path = $array
            $script:htManagementGroupsMgPath.($entity.name).pathDelimited = $array -join '/'
        }

        $script:htEntities.($entity.name) = @{}
        $script:htEntities.($entity.name).ParentNameChain = $entity.properties.parentNameChain
        $script:htEntities.($entity.name).Parent = $parent
        if ($parent -eq '__TenantRoot__') {
            $parentDisplayName = '__TenantRoot__'
        }
        else {
            $parentDisplayName = $htEntitiesPlain.($htEntities.($entity.name).Parent).properties.displayName
        }
        $script:htEntities.($entity.name).ParentDisplayName = $parentDisplayName
        $script:htEntities.($entity.name).DisplayName = $entity.properties.displayName
        $script:htEntities.($entity.name).Id = $entity.Name
    }

    Write-Host "  $(($htManagementGroupsMgPath.Keys).Count) Management Groups returned"
    Write-Host "  $(($htSubscriptionsMgPath.Keys).Count) Subscriptions returned"

    $endEntitiesdata = Get-Date
    Write-Host " Processing Entities data duration: $((NEW-TIMESPAN -Start $startEntitiesdata -End $endEntitiesdata).TotalSeconds) seconds"

    if (-not $htManagementGroupsMgPath.($ManagementGroupId)){
        Write-Host "ManagementGroupId '$ManagementGroupId' could not be found" -ForegroundColor DarkRed
        throw
    }

    $script:arrayEntitiesFromAPISubscriptionsCount = ($arrayEntitiesFromAPI.where( { $_.type -eq '/subscriptions' -and $_.properties.parentNameChain -contains $ManagementGroupId } ) | Sort-Object -Property id -Unique).count
    $script:arrayEntitiesFromAPIManagementGroupsCount = ($arrayEntitiesFromAPI.where( { $_.type -eq 'Microsoft.Management/managementGroups' -and $_.properties.parentNameChain -contains $ManagementGroupId } )  | Sort-Object -Property id -Unique).count + 1

    $endEntities = Get-Date
    Write-Host "Processing Entities duration: $((NEW-TIMESPAN -Start $startEntities -End $endEntities).TotalSeconds) seconds"
}

function getSubscriptions {
    $startGetSubscriptions = Get-Date
    $currentTask = 'Getting all Subscriptions'
    Write-Host "$currentTask"
    $uri = "$($azAPICallConf['azAPIEndpointUrls'].ARM)/subscriptions?api-version=2020-01-01"
    $method = 'GET'
    $requestAllSubscriptionsAPI = AzAPICall -AzAPICallConfiguration $azAPICallConf -uri $uri -method $method -currentTask $currentTask

    Write-Host " $($requestAllSubscriptionsAPI.Count) Subscriptions returned"
    $script:htAllSubscriptionsFromAPI = @{}
    foreach ($subscription in $requestAllSubscriptionsAPI) {
        $script:htAllSubscriptionsFromAPI.($subscription.subscriptionId) = @{}
        $script:htAllSubscriptionsFromAPI.($subscription.subscriptionId).subDetails = $subscription
    }

    $endGetSubscriptions = Get-Date
    Write-Host "Getting all Subscriptions duration: $((NEW-TIMESPAN -Start $startGetSubscriptions -End $endGetSubscriptions).TotalSeconds) seconds"
}

function getInScopeSubscriptions {
    $childrenSubscriptions = $arrayEntitiesFromAPI.where( { $_.properties.parentNameChain -contains $ManagementGroupID -and $_.type -eq '/subscriptions' } ) | Sort-Object -Property id -Unique
    
    if (($childrenSubscriptions).Count -eq 0) {
        Write-Host "ManagementGroupId: $ManagementGroupId has $(($childrenSubscriptions).Count) child subscriptions" -ForegroundColor DarkRed
        throw
    }
    else {
        Write-Host "ManagementGroupId: $ManagementGroupId has $(($childrenSubscriptions).Count) child subscriptions"
    }
    
    $script:subsToProcessInCustomDataCollection = [System.Collections.ArrayList]@()
    $script:outOfScopeSubscriptions = [System.Collections.ArrayList]@()
    foreach ($childrenSubscription in $childrenSubscriptions) {
    
        $sub = $htAllSubscriptionsFromAPI.($childrenSubscription.name)
        if ($sub.subDetails.subscriptionPolicies.quotaId.startswith('AAD_', 'CurrentCultureIgnoreCase') -or $sub.subDetails.state -ne 'Enabled') {
            if (($sub.subDetails.subscriptionPolicies.quotaId).startswith('AAD_', 'CurrentCultureIgnoreCase')) {
                $null = $script:outOfScopeSubscriptions.Add([PSCustomObject]@{
                        subscriptionId      = $childrenSubscription.name
                        subscriptionName    = $childrenSubscription.properties.displayName
                        outOfScopeReason    = "QuotaId: AAD_ (State: $($sub.subDetails.state))"
                        ManagementGroupId   = $htSubscriptionsMgPath.($childrenSubscription.name).Parent
                        ManagementGroupName = $htSubscriptionsMgPath.($childrenSubscription.name).ParentName
                        Level               = $htSubscriptionsMgPath.($childrenSubscription.name).level
                    })
            }
            if ($sub.subDetails.state -ne 'Enabled') {
                $null = $script:outOfScopeSubscriptions.Add([PSCustomObject]@{
                        subscriptionId      = $childrenSubscription.name
                        subscriptionName    = $childrenSubscription.properties.displayName
                        outOfScopeReason    = "State: $($sub.subDetails.state)"
                        ManagementGroupId   = $htSubscriptionsMgPath.($childrenSubscription.name).Parent
                        ManagementGroupName = $htSubscriptionsMgPath.($childrenSubscription.name).ParentName
                        Level               = $htSubscriptionsMgPath.($childrenSubscription.name).level
                    })
            }
        }
        else {
    
            $null = $script:subsToProcessInCustomDataCollection.Add([PSCustomObject]@{
                    subscriptionId      = $childrenSubscription.name
                    subscriptionName    = $childrenSubscription.properties.displayName
                    subscriptionQuotaId = $sub.subDetails.subscriptionPolicies.quotaId
                })
        }
    }

    if (($subsToProcessInCustomDataCollection).Count -eq 0) {
        Write-Host "ManagementGroupId: $ManagementGroupId has no valid child subscriptions (check `$outOfScopeSubscriptions)" -ForegroundColor DarkRed
        throw
    }
    else {
        Write-Host "ManagementGroupId: $ManagementGroupId has $(($subsToProcessInCustomDataCollection).Count) valid child subscriptions (check `$outOfScopeSubscriptions)"
    }
}

try {
    $azAPICallConf = initAzAPICall #-DebugAzAPICall $True
}
catch {
    Write-Host "Install AzAPICall Powershell Module https://www.powershellgallery.com/packages/AzAPICall" -ForegroundColor DarkRed
    Write-Host "Install-Module -Name AzAPICall" -ForegroundColor Yellow
    throw
}

getEntities
getSubscriptions
getInScopeSubscriptions

$queryName = 'VMQuery'
$query = @"
resources
| where type == 'microsoft.compute/virtualmachines'
| extend lname = tolower(name)
| extend platform = properties.storageProfile.imageReference.offer
| extend operatingSystem = properties.storageProfile.imageReference.sku
| extend resourceGroup = resourceGroup
| extend vmId = properties.vmId
| extend subscriptionId = subscriptionId
| extend azureDatacenter = location
| extend sku = properties.hardwareProfile.vmSize
// vcpu -- monitor
// memory -- monitor
// privateIp
| join kind=leftouter(resources
    | where type =~ 'microsoft.network/networkinterfaces'
    | extend privateIp = properties.ipConfigurations[0].properties.privateIPAddress
    | extend vmId = properties.virtualMachine.id
    | extend lname = tolower(tostring(split(vmId,'/')[8]))
    | project lname, privateIp ) on lname
//
| extend department = tags.department
| extend environment = tags.environment
| extend application = tags.application
| extend fcc = tags.fcc
| extend poc = tags.poc
| extend quality = tags.quality
// backupVault -- monitor
// sqlVersion
| join kind=leftouter(resources
    | where type =~ 'microsoft.sqlvirtualmachine/sqlvirtualmachines'
    | extend sqlImage = properties.sqlImageOffer
    | extend lname = tolower(name)
    | project lname, sqlImage ) on lname
//
| sort by lname asc
| project lname, platform, operatingSystem, resourceGroup, vmId, subscriptionId, azureDatacenter, sku, privateIp, department, environment, application, fcc, poc, quality, sqlImage
"@

$arrayResults = [System.Collections.ArrayList]@()

$counterBatch = [PSCustomObject] @{ Value = 0 }
$subscriptionsBatch = $subsToProcessInCustomDataCollection | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $SubscriptionBatchSize) }
$subscriptionsBatchCount = ($subscriptionsBatch | Measure-Object).Count
$uri = "$($azAPICallConf['azAPIEndpointUrls'].ARM)/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
$method = "POST"
$cnt = 0
foreach ($batch in $subscriptionsBatch) { 
    $cnt++
    Write-Host " Batch #$($cnt)/$subscriptionsBatchCount - Executing query for $($batch.Group.subscriptionId.Count) Subscriptions"
    $subscriptions = '"{0}"' -f ($batch.Group.subscriptionId -join '","')
    $body = @"
{
"query": "$($query)",
"subscriptions": [$($subscriptions)]
}
"@

    $res = (AzAPICall -AzAPICallConfiguration $azAPICallConf -uri $uri -method $method -body $body -listenOn 'Content' -currentTask $queryName)
    if ($res.count -gt 0) {
        foreach ($result in $res) {
            $mgInfo = $htSubscriptionsMgPath.($result.subscriptionId)
            $result | Add-Member -MemberType NoteProperty -Name 'ManagementGroupId' -Value $mgInfo.Parent
            $result | Add-Member -MemberType NoteProperty -Name 'ManagementGroupPath' -Value $mgInfo.ParentNameChainDelimited
            $result | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $mgInfo.DisplayName
            $null = $arrayResults.Add($result)
        }
    }
    Write-Host " Batch #$($cnt)/$subscriptionsBatchCount - $($res.count) results found"
}

$arrayResults
