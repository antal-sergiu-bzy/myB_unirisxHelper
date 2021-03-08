param([string]$sqlServerInstance,
      [string]$databaseName,
      [string]$loginDomain,
      [string]$loginName,
      [string]$suffixStyle,
      [string]$schema = 'dbo')

# for PS 2.0 support
if (-not $SCRIPT:PSScriptRoot) {
  $SCRIPT:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

$userCreationScript = "$PSScriptRoot\SqlCmdScripts\CreateUser.sql"

$loginDomainParam = "login_domain=$loginDomain"
$loginNameParam = "user_name=$loginName"
$loginSuffixStyleParam = "suffix_style=$($suffixStyle.ToUpper())"
$databaseNameParam = "databaseName=$databaseName"
$schemaParam = "schema=$schema"
$params = $databaseNameParam, $loginDomainParam, $loginNameParam, $loginSuffixStyleParam, $schemaParam

Write-Host "Invoke-Sqlcmd -InputFile $userCreationScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable '$params'"

Invoke-Sqlcmd -InputFile $userCreationScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable $params
