param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$dbRoleGeneratorFolder)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

$rolePrepScriptPath = Join-Path $dbRoleGeneratorFolder "DbRoleGenerator_10_ProcessPrep.sql"

Write-Host "Invoke-Sqlcmd -InputFile $($rolePrepScriptPath) -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

Invoke-Sqlcmd -InputFile $rolePrepScriptPath -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60
