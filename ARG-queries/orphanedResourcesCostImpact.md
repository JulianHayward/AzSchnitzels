# microsoft.compute/disks

```kql
resources
| where type has 'microsoft.compute/disks'
| where isempty(managedBy) or properties.diskState =~ 'unattached' and not(name endswith '-ASRReplica' or name startswith 'ms-asr-' or name startswith 'asrseeddisk-')
| project type, subscriptionId, Resource=id, Intent='cost savings'
```

# microsoft.network/applicationGateways

```kql
resources
| where type =~ 'microsoft.network/applicationgateways'
| extend backendPoolsCount = array_length(properties.backendAddressPools),SKUName= tostring(properties.sku.name), SKUTier= tostring(properties.sku.tier),SKUCapacity=properties.sku.capacity,backendPools=properties.backendAddressPools , AppGwId = tostring(id)
| project type, AppGwId, resourceGroup, location, subscriptionId, tags, name, SKUName, SKUTier, SKUCapacity
| join (
    resources
    | where type =~ 'microsoft.network/applicationgateways'
    | mvexpand backendPools = properties.backendAddressPools
    | extend backendIPCount = array_length(backendPools.properties.backendIPConfigurations)
    | extend backendAddressesCount = array_length(backendPools.properties.backendAddresses)
    | extend backendPoolName  = backendPools.properties.backendAddressPools.name
    | extend AppGwId = tostring(id)
    | summarize backendIPCount = sum(backendIPCount) ,backendAddressesCount=sum(backendAddressesCount) by AppGwId
) on AppGwId
| project-away AppGwId1
| where  (backendIPCount == 0 or isempty(backendIPCount)) and (backendAddressesCount == 0 or isempty(backendAddressesCount))
| project type, subscriptionId, Resource=AppGwId, Intent='cost savings'
```

# microsoft.network/ddosprotectionplans

```kql
resources
| where type =~ 'microsoft.network/ddosprotectionplans'
| where isnull(properties.virtualNetworks)
| project type, subscriptionId, Resource=id, Intent='cost savings'
```

# microsoft.network/natgateways

```kql
resources
| where type =~ 'microsoft.network/natgateways'
| where isnull(properties.subnets)
| project type, subscriptionId, Resource=id, Intent='cost savings'
```

# microsoft.network/publicIpAddresses static

```kql
resources | where type =~ 'microsoft.network/publicIpAddresses'
| where properties.ipConfiguration == '' and properties.natGateway == '' and properties.publicIPPrefix == '' and properties.publicIPAllocationMethod =~ 'Static'
| project type, subscriptionId, Resource=id, Intent='cost savings'
```

# microsoft.network/virtualnetworkgateways

```kql
resources
| where type =~ 'microsoft.network/virtualnetworkgateways'
| extend vpnClientConfiguration = properties.vpnClientConfiguration
| extend Resource = id
| join kind=leftouter (
    resources
    | where type =~ 'microsoft.network/connections'
    | mv-expand Resource = pack_array(properties.virtualNetworkGateway1.id, properties.virtualNetworkGateway2.id) to typeof(string)
    | project Resource, connectionId = id, ConnectionProperties=properties
    ) on Resource
| where isempty(vpnClientConfiguration) and isempty(connectionId)
| project type, subscriptionId, Resource, Intent='cost savings'
```

# microsoft.sql/servers/elasticpools

```kql
resources
| where type =~ 'microsoft.sql/servers/elasticpools'
| project type, elasticPoolId = tolower(id), Resource = id, resourceGroup, location, subscriptionId, tags, properties, Details = pack_all(), Intent='cost savings'
| join kind=leftouter (
    resources
    | where type =~ 'Microsoft.Sql/servers/databases'
    | project id, properties
    | extend elasticPoolId = tolower(properties.elasticPoolId)
) on elasticPoolId
| summarize databaseCount = countif(id != '') by type, Resource, subscriptionId, Intent
| where databaseCount == 0
| project-away databaseCount
```

# microsoft.Web/certificates

```kql
resources
| where type =~ 'microsoft.web/certificates'
| extend expiresOn = todatetime(properties.expirationDate)
| where expiresOn <= now()
| project type, subscriptionId, Resource=id, Intent='cost savings'
```

# microsoft.web/serverfarms

```kql
resources
| where type =~ 'microsoft.web/serverfarms'
| where properties.numberOfSites == 0 and sku.tier !~ 'Free'
| project type, subscriptionId, Resource=id, Intent='cost savings'
```


