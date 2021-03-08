param (
  $Server,
  $Database,
  $Components,
  $ModelCreateScripts,
  $Users,
  $DeploymentSettings
)

# for PS 2.0 support
if (-not $SCRIPT:PSScriptRoot) {
  $SCRIPT:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$scriptRoot = "$PSScriptRoot\.."
$userRoleAddScript = "$scriptRoot\SqlCmdScripts\AddUserRole.sql"

& "$scriptRoot\ModelDelete.ps1" -sqlServerInstance $Server `
                                -databaseName $Database `
                                -dropDatabaseScript $scriptRoot\SqlCmdScripts\DropDatabase.sql

& "$scriptRoot\ModelPrep.ps1" -sqlServerInstance $Server `
                              -databaseName $Database `
                              -createDatabaseScript $scriptRoot\SqlCmdScripts\CreateDatabase.sql

Write-Host "Generating $Server\$Database via Entity Framework Migration" -foregroundcolor "cyan"
$migrateArgs = @(
  $DeploymentSettings.schemaAssembly,
  '/connectionProviderName="System.Data.SqlClient"',
  "/connectionString=`"Data Source=`"$Server`";Initial Catalog=`"$Database`";Integrated Security=True`"",
  "/startUpDirectory=`"$scriptRoot\..\Model`""
)
& "$scriptRoot\..\Model\migrate.exe" @migrateArgs

Write-Host "Running Custom Scripts on $Server\$Database" -foregroundcolor "cyan"

if(Test-Path "$scriptRoot\CustomBuildSql\"){
  Get-ChildItem "$scriptRoot\CustomBuildSql\" -Filter *.sql -Recurse | % {
    Invoke-Sqlcmd -InputFile $_.FullName -ServerInstance $Server -Database $Database -QueryTimeout 120 -ConnectionTimeout 60
    Write-Host "  $_ - DONE" -foregroundcolor "yellow"
  }
}

Set-BuildUsers -Users $Users `
               -Database $Database `
               -Server $Server
