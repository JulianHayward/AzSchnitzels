#using the cmdlet here as this is handling nextLink
$relevantSubscriptions = (Get-AzSubscription -ErrorAction Stop).where( { $_.State -eq "Enabled" -and $_.SubscriptionPolicies.QuotaId -notlike "AAD*" }).Id
$relevantSubscriptionsCount = $relevantSubscriptions.Count

<#todo: nextLink handling
https://docs.microsoft.com/en-us/rest/api/resources/subscriptions/list
$path = "/subscriptions?api-version=2020-01-01"
$method = "GET"
$getSubscriptions = Invoke-AzRestMethod -Method $method -Path $path
$relevantSubscriptions = ($getSubscriptions.Content | ConvertFrom-Json).value.where( { $_.State -eq "Enabled" -and $_.SubscriptionPolicies.QuotaId -notlike "AAD*" } )
$relevantSubscriptionsCount = $relevantSubscriptions.count
#>

Write-Host "Running ARG query against $($relevantSubscriptionsCount) Subscriptions"

$data = [System.Collections.ArrayList]@()
$query = "resources | project id, name"

#Batching: https://docs.microsoft.com/en-us/azure/governance/resource-graph/troubleshoot/general#toomanysubscription
$counterBatch = [PSCustomObject] @{ Value = 0 }
$batchSize = 3 #max=1000
Write-Host "Subscriptions Batch size: $batchSize"

$resultsCollected = 0
$subscriptionsBatch = $relevantSubscriptions | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }
$batchCnt = 0
foreach ($batch in $subscriptionsBatch) { 

    $startBatch = get-date
    $batchCnt++
    Write-Host " processing Batch #$batchCnt/$(($subscriptionsBatch | Measure-Object).Count) ($(($batch.Group | Measure-Object).Count) Subscriptions)" -ForegroundColor Yellow
    $subscriptions = '"{0}"' -f ($batch.Group -join '","')

    $path = "/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
    $method = "POST"
    $payload = @"
{
	"query": "$($query)",
    "subscriptions": [$($subscriptions)]
}
"@

    $iteration = 0

    do {
        $iteration++
        Write-Host "  Batch #$($batchCnt); POST #$($iteration)"
        $invoke = Invoke-AzRestMethod -Method $method -Payload $payload -Path $path
        $result = $invoke.Content | ConvertFrom-Json
        Write-Host "  Batch #$($batchCnt); POST #$($iteration) Returned records: $($result.'count')"
        $resultsCollected = $resultsCollected + $result.Count
        $null = $data.AddRange($result.data)
        Write-Host "  Batch #$($batchCnt); POST #$($iteration) Status: total collected records: $($resultsCollected)"
        Write-Host "  Batch #$($batchCnt); POST #$($iteration) Array items (total): $($data.Count)" -ForegroundColor Blue
        if ($result.'$skipToken') {
            Write-Host "  Batch #$($batchCnt); POST #$($iteration) SkipToken present ($($result.'$skipToken'))" -ForegroundColor Cyan
            $payload = @"
{
	query: "$($query)",
    subscriptions: [$($subscriptions)],
    options: {
        `$skipToken: "$($result.'$skipToken')"
      }
}
"@
        }
        else {
            Write-Host "  Batch #$($batchCnt); POST #$($iteration) SkipToken NOT present"
        }
    }
    until(-not $result.'$skipToken')

    $endBatch = get-date
    Write-Host "  Batch #$batchCnt processing duration: $((NEW-TIMESPAN -Start $startBatch -End $endBatch).TotalMinutes) minutes ($((NEW-TIMESPAN -Start $startBatch -End $endBatch).TotalSeconds) seconds)"
}

Write-Host "Resources:" $data.count
