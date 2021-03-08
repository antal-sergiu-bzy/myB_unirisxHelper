param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$componentLogicalLabel,
      [string]$dbRoleGeneratorFolder)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

$roleCloseOutScriptPath = Join-Path $dbRoleGeneratorFolder DbRoleGenerator_20_CreateDbRoles.sql

Write-Host "Invoke-Sqlcmd -InputFile $($roleCloseOutScriptPath) -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

Invoke-Sqlcmd -InputFile $roleCloseOutScriptPath -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60 -Variable "componentName=$componentLogicalLabel"