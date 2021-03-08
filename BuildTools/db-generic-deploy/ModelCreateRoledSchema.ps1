param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$dbRoleGeneratorFolder,
      [string]$componentName,
      [switch]$componentIsASchema,
      [string[]]$createDatabaseObjectsScripts)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

$componentParams = "componentName=$componentName", "isComponentASchema=$(if ($componentIsASchema) { 1 } else { 0 })"

# run in the db object creation scripts
foreach($dbObjectScript in $createDatabaseObjectsScripts)
{
  Write-Host $dbObjectScript
}

# prep the role gen process
$rolePrepScriptPath = Join-Path $dbRoleGeneratorFolder "DbRoleGenerator_10_ProcessPrep.sql"

Write-Host "Invoke-Sqlcmd -InputFile $($rolePrepScriptPath) -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

Invoke-Sqlcmd -InputFile $rolePrepScriptPath -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60 -Variable $componentParams

# run in the db object creation scripts
foreach($dbObjectScript in $createDatabaseObjectsScripts)
{
  Write-Host "Invoke-Sqlcmd -InputFile $dbObjectScript -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

  Invoke-Sqlcmd -InputFile $dbObjectScript -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60 -Variable $componentParams
}

# finalise the role gen process
$roleCloseOutScriptPath = Join-Path $dbRoleGeneratorFolder DbRoleGenerator_20_CreateDbRoles.sql

Write-Host "Invoke-Sqlcmd -InputFile $($roleCloseOutScriptPath) -ServerInstance $($sqlServerInstance) -Database $($databaseName) -QueryTimeout 120 -ConnectionTimeout 60"

Invoke-Sqlcmd -InputFile $roleCloseOutScriptPath -ServerInstance $sqlServerInstance -Database $databaseName -QueryTimeout 120 -ConnectionTimeout 60 -Variable $componentParams
