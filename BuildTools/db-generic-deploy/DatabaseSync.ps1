[CmdletBinding(
  SupportsShouldProcess=$true
)]
param(
  [string] $Environment,
  [string] $DbghostParamRollback,
  [string] $DbghostParamRollforward,
  [string] $DatabaseServer,
  [string] $DatabaseName,
  [string[]] $DatabaseInstances,
  [string] $RequestId,
  [boolean] $CreatePackageScripts
)

# for PS 2.0 support
if ( ! $PSScriptRoot) {
  $SCRIPT:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
. $PSScriptRoot\DatabaseSyncFunctions.ps1
. $PSScriptRoot\DatabaseBuildFunctions.ps1

$SCRIPT:ErrorActionPreference = "Stop"
trap [Exception] {
  Set-PSDebug -off | Out-Null
  $_
  Set-Location -Path $SCRIPT:OriginalDirectory | Out-Null
  [System.IO.Directory]::SetCurrentDirectory($SCRIPT:OriginalSystemDirectory) | Out-Null
  exit 1
}
$error.Clear()
$paramArgs = @{
  Environment=$Environment
  Database=$DatabaseName
  Server=$DatabaseServer
  Instances=$DatabaseInstances
  RollbackParams=$DbghostParamRollback
  RequestId=$requestId
  CreatePackageScripts=$CreatePackageScripts
}

$params = Get-Parameters @paramArgs

$DbGhostConfigDir = "$PSScriptRoot\DbGhostConfiguration"

Test-EnvironmentName -Instances $params.instances -Env $params.env

Write-Output 'Creating logins'
Set-Logins -Instances $params.instances -Users $params.users

Write-Output 'Creating template database'
Initialize-BuildDb -Server $params.server `
                   -Database $params.templateDatabase `
                   -Components $params.components `
                   -CreateScripts $params.createScripts `
                   -Users $params.users `
                   -DeploymentSettings $params.DeploymentSettings

Write-Output 'Ensuring Database exists'
Initialize-TargetDb -Instances $params.instances -Database $params.database

if ($params.doRollback) {
  Write-Output 'Generating roll back script'
  Invoke-DbGhost -Server $params.server `
                 -SourceDb $params.database `
                 -TargetDb $params.templateDatabase `
                 -Script "$DbGhostConfigDir\DBGhostChangeManagerSettings_rollback.dbgcm" `
                 -OtherArgs $DbghostParamRollback
}

Write-Output 'Running in changes and generating roll forward script'
Invoke-DbGhost -Server $params.server `
               -SourceDb $params.templateDatabase `
               -TargetDb $params.database `
               -Script "$DbGhostConfigDir\DBGhostChangeManagerSettings_rollforward.dbgcm" `
               -OtherArgs $dbghostParamRollforward

if ($params.env -eq 'PKG' -Or $params.createPackageScripts) {
  Write-Output 'Creating Packaging Scripts'
  Create-PackageScripts -Database $params.database `
                        -Users $params.users `
                        -IncludeRollback:($params.doRollback) `
                        -Suffix: @{$true="_$($params.env)";$false=''}[$params.env -ne 'PKG']
}

Set-Location -Path $OriginalDirectory | Out-Null
[System.IO.Directory]::SetCurrentDirectory($OriginalSystemDirectory) | Out-Null
exit 0
