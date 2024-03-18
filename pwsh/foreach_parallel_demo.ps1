#how one may want to use parallel processing in PowerShell 7
#quick performance demo script on foreach parallel processing / at scale processing with inner parallelization and batching..
$arrayArrayItems = @(100, 1000, 10000, 30000)
foreach ($arrayItemCount in $arrayArrayItems) {
    Write-Host "Processing array with $arrayItemCount items" -ForegroundColor Magenta

    $arrayItems = $arrayItemCount
    $array = [System.Collections.ArrayList]@()
    $cnt = 0
    do {
        $null = $array.Add($cnt++)
    }
    until ($array.Count -eq $arrayItems)

    $ThrottleLimit = 5
    $MilliSeconds = 10

    #region foreach noParallel
    if ($arrayItems -le 100) {
        $foreachNoParallelWayArrayList = [System.Collections.ArrayList]@()
        $startForeachNoParallelWay = Get-Date
        foreach ($val in $array) {
            start-sleep -Milliseconds $MilliSeconds
            $null = $foreachNoParallelWayArrayList.Add([PSCustomObject]@{
                val = $val
                milliseconds = $MilliSeconds
            })
        }
        $endForeachNoParallelWay = Get-Date
        Write-Host " foreachNoParallel way duration: $(($endForeachNoParallelWay - $startForeachNoParallelWay).TotalSeconds) seconds; proof: `$foreachNoParallelWayArrayList.Count = $($foreachNoParallelWayArrayList.Count)" -ForegroundColor Green
    }
    else {
        Write-Host " foreachNoParallel way: skipped, will take too long.." -ForegroundColor "DarkGray"
    }
    #endregion foreach noParallel

    #foreachParallelUnBatched way
    if ($arrayItems -le 1000) {
        $foreachParallelUnBatchedWayArrayListSynchronized = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        $startforeachParallelUnBatchedWay = Get-Date
        $array | ForEach-Object -Parallel {
            $MilliSeconds = $using:MilliSeconds
            $foreachParallelUnBatchedWayArrayListSynchronized = $using:foreachParallelUnBatchedWayArrayListSynchronized
            start-sleep -Milliseconds $MilliSeconds
            $null = $foreachParallelUnBatchedWayArrayListSynchronized.Add([PSCustomObject]@{
                val = $val
                milliseconds = $MilliSeconds
            })
        } -ThrottleLimit $ThrottleLimit
        $endforeachParallelUnBatchedWay = Get-Date
        Write-Host " foreachParallelUnBatched way duration: $(($endforeachParallelUnBatchedWay - $startforeachParallelUnBatchedWay).TotalSeconds) seconds; proof: `$foreachParallelUnBatchedWayArrayListSynchronized.Count = $($foreachParallelUnBatchedWayArrayListSynchronized.Count)" -ForegroundColor Green
    }
    else {
        Write-Host " foreachParallelUnBatched way: skipped, will take too long.." -ForegroundColor "DarkGray"
    }

    #region foreachParallelBatched way
    if ($arrayItems -le 10000) {
    $batchSize = [math]::ceiling($array.Count / $ThrottleLimit)
    $counterBatch = [PSCustomObject] @{ Value = 0 }
    $arrayBatch = ($array) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

    $foreachParallelBatchedWayArrayListSynchronized = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    $startforeachParallelBatchedWay = Get-Date
    $arrayBatch | ForEach-Object -Parallel {
        $MilliSeconds = $using:MilliSeconds
        $foreachParallelBatchedWayArrayListSynchronized = $using:foreachParallelBatchedWayArrayListSynchronized
        foreach ($val in $_.Group) {
            start-sleep -Milliseconds $MilliSeconds
            $null = $foreachParallelBatchedWayArrayListSynchronized.Add([PSCustomObject]@{
                val = $val
                milliseconds = $MilliSeconds
            })
        }
    } -ThrottleLimit $ThrottleLimit
    $endforeachParallelBatchedWay = Get-Date
    Write-Host " foreachParallelBatched way duration: $(($endforeachParallelBatchedWay - $startforeachParallelBatchedWay).TotalSeconds) seconds; proof: `$foreachParallelBatchedWayArrayListSynchronized.Count = $($foreachParallelBatchedWayArrayListSynchronized.Count)" -ForegroundColor Green
    }
    else {
        Write-Host " foreachParallelBatched way: skipped, will take too long.." -ForegroundColor "DarkGray"
    }
    #endregion foreachParallelBatched way

    #region foreachParallelBatchedInnerParallel way
    $batchSize = [math]::ceiling($array.Count / $ThrottleLimit)
    $counterBatch = [PSCustomObject] @{ Value = 0 }
    $arrayBatch = ($array) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

    $foreachParallelBatchedInnerParallelWayArrayListSynchronized = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    $startforeachParallelBatchedInnerParallelWay = Get-Date
    $arrayBatch | ForEach-Object -Parallel {
        $MilliSeconds = $using:MilliSeconds
        $ThrottleLimit = $using:ThrottleLimit
        $foreachParallelBatchedInnerParallelWayArrayListSynchronized = $using:foreachParallelBatchedInnerParallelWayArrayListSynchronized

        $batchSize = [math]::ceiling($_.Group.Count / $ThrottleLimit)
        $counterBatch = [PSCustomObject] @{ Value = 0 }
        $arrayInnerBatch = ($_.Group) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

        $arrayInnerBatch | ForEach-Object -Parallel {
            $MilliSeconds = $using:MilliSeconds
            $foreachParallelBatchedInnerParallelWayArrayListSynchronized = $using:foreachParallelBatchedInnerParallelWayArrayListSynchronized
            foreach ($val in $_.Group) {
                start-sleep -Milliseconds $MilliSeconds
                $null = $foreachParallelBatchedInnerParallelWayArrayListSynchronized.Add([PSCustomObject]@{
                    val = $val
                    milliseconds = $MilliSeconds
                })
            }
        } -ThrottleLimit $ThrottleLimit

    } -ThrottleLimit $ThrottleLimit
    $endforeachParallelBatchedInnerParallelWay = Get-Date
    Write-Host " foreachParallelBatchedInnerParallel way duration: $(($endforeachParallelBatchedInnerParallelWay - $startforeachParallelBatchedInnerParallelWay).TotalSeconds) seconds; proof: `$foreachParallelBatchedInnerParallelWayArrayListSynchronized.Count = $($foreachParallelBatchedInnerParallelWayArrayListSynchronized.Count)" -ForegroundColor Green
    #endregion foreachParallelBatchedInnerParallel way

    #region foreachParallelBatchedInnerInnerParallel way
    $batchSize = [math]::ceiling($array.Count / $ThrottleLimit)
    $counterBatch = [PSCustomObject] @{ Value = 0 }
    $arrayBatch = ($array) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

    $foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    $startforeachParallelBatchedInnerInnerParallelkWay = Get-Date
    $arrayBatch | ForEach-Object -Parallel {
        $MilliSeconds = $using:MilliSeconds
        $ThrottleLimit = $using:ThrottleLimit
        $foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized = $using:foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized

        $batchSize = [math]::ceiling($_.Group.Count / $ThrottleLimit)
        $counterBatch = [PSCustomObject] @{ Value = 0 }
        $arrayInnerBatch = ($_.Group) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

        $arrayInnerBatch | ForEach-Object -Parallel {
            $MilliSeconds = $using:MilliSeconds
            $ThrottleLimit = $using:ThrottleLimit
            $foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized = $using:foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized

            $batchSize = [math]::ceiling($_.Group.Count / $ThrottleLimit)
            $counterBatch = [PSCustomObject] @{ Value = 0 }
            $arrayInnerInnerBatch = ($_.Group) | Group-Object -Property { [math]::Floor($counterBatch.Value++ / $batchSize) }

            $arrayInnerInnerBatch | ForEach-Object -Parallel {
                $MilliSeconds = $using:MilliSeconds
                $foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized = $using:foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized

                foreach ($val in $_.Group) {
                    start-sleep -Milliseconds $MilliSeconds
                    $null = $foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized.Add([PSCustomObject]@{
                        val = $val
                        milliseconds = $MilliSeconds
                    })
                }
            } -ThrottleLimit $ThrottleLimit

        } -ThrottleLimit $ThrottleLimit

    } -ThrottleLimit $ThrottleLimit
    $endforeachParallelBatchedInnerInnerParallelkWay = Get-Date
    Write-Host " foreachParallelBatchedInnerInnerParallel way duration: $(($endforeachParallelBatchedInnerInnerParallelkWay - $startforeachParallelBatchedInnerInnerParallelkWay).TotalSeconds) seconds; proof: `$foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized.Count = $($foreachParallelBatchedInnerInnerParallelWayArrayListSynchronized.Count)" -ForegroundColor Green
    #endregionforeachParallelBatchedInnerInnerParallel way
}
