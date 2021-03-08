param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$dropDatabaseScript)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

Write-Host "Invoke-Sqlcmd -InputFile $dropDatabaseScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable 'DatabaseName=$($databaseName)'"

Invoke-Sqlcmd -InputFile $dropDatabaseScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable "DatabaseName=$databaseName"
