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

Write-Host "Generating $Server\$Database via SSDT sqlpackage publish" -foregroundcolor "cyan"
$dacPac = "$scriptRoot\..\Database\$($DeploymentSettings.dacPac)"
$sqlPackageArgs = @(
  '/Action:Publish',
  "/SourceFile:$dacPac",
  "/TargetServerName:$Server",
  "/TargetDatabaseName:$Database",
  "/TargetTimeout:60"
)

$sqlVersion = "12" #default to sqlpackage from Sql Server 2014

$dacVersion = "$($sqlVersion)0"
if($DeploymentSettings.dacVersion){
  $dacVersion = $DeploymentSettings.dacVersion
}

Write-Host "Using version $dacVersion of dacpac api"

& "$PSScriptRoot\bin\sqlpackage\DAC_$dacVersion\sqlpackage.exe" @sqlPackageArgs

Write-Host "Running Custom Scripts on $Server\$Database" -foregroundcolor "cyan"
if(Test-Path "$scriptRoot\CustomBuildSql\"){
  Get-ChildItem "$scriptRoot\CustomBuildSql\" -Filter *.sql -Recurse | Foreach-Object {
    Invoke-Sqlcmd -InputFile $_.FullName -ServerInstance $Server -Database $Database -QueryTimeout 120 -ConnectionTimeout 60
    Write-Host "  $_ - DONE" -foregroundcolor "yellow"
  }
}

Set-BuildUsers -Users $Users `
               -Database $Database `
               -Server $Server
