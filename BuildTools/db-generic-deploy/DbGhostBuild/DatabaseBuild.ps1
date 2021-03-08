[CmdletBinding()]
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

Write-Host "Generating $Server\$Database via DbGhost" -foregroundcolor "cyan"

# DBGhost paths are relative to the current path so change directory to DbGhost source files directory

Set-Location -Path "$scriptRoot\..\Database"

function RunSubBuildScripts {
  param (
    [string]$Path
  )

  if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
    Get-ChildItem -Recurse -Path $Path -Filter '*.sql' | Foreach-Object {
      Write-Verbose "Running sql file $_"
      Invoke-Sqlcmd -InputFile $_.FullName `
                    -ServerInstance $Server `
                    -Database $Database `
                    -QueryTimeout 120 -ConnectionTimeout 60
    }
  }
}

Write-Verbose "Running pre-build scripts"
RunSubBuildScripts -Path "$PWD\BuildScripts\PreBuild"

Set-BuildUsers -Users $Users `
               -Database $Database `
               -Server $Server

# DB Ghost requires a script that helps it figure out which DB to use (this is a bit of a hack!)
$template = "USE [$Database]"

$template | Out-File -FilePath "$PWD\SetDbContext.sql"

Invoke-DbGhost -Server $server `
               -SourceDb $database `
               -TargetDb $database `
               -Script "$PSScriptRoot\DBGhostChangeManagerSettings_Build.dbgcm" `
               -OtherArgs '/treatwarningsaserrors'

Write-Verbose "Running post-build scripts"
RunSubBuildScripts -Path "$PWD\BuildScripts\PostBuild"
