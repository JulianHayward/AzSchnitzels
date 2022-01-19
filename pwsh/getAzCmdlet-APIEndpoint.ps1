$ra = Get-AzRoleAssignment -debug 5>&1
($ra | Select-String -Pattern 'Absolute Uri:') | foreach-object {
    [regex]$regex = '(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})'
    [string]$_ | select-string -pattern $regex | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }
}
