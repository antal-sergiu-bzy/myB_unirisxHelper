param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$createDatabaseScript,
      [string]$createDatabaseObjectsScript)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

Write-Host "Invoke-Sqlcmd -InputFile $createDatabaseScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable 'DatabaseName=$($databaseName)'"

Invoke-Sqlcmd -InputFile $createDatabaseScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable "DatabaseName=$databaseName"

Write-Host "Invoke-Sqlcmd -InputFile $createDatabaseObjectsScript -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

Invoke-Sqlcmd -InputFile $createDatabaseObjectsScript -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60