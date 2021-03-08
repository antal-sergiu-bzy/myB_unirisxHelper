param([string]$loginCreationScript,
      [string]$sqlServerInstance,
      [string]$loginDomain,
      [string]$loginName,
      [string]$suffixStyle)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

$loginDomainParam = "login_domain=$loginDomain"
$loginNameParam = "user_name=$loginName"
$loginSuffixStyleParam = "suffix_style=$($suffixStyle.ToUpper())"
$params = $loginDomainParam, $loginNameParam, $loginSuffixStyleParam

Write-Host "Invoke-Sqlcmd -InputFile $loginCreationScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable '$params'"

Invoke-Sqlcmd -InputFile $loginCreationScript -ServerInstance $sqlServerInstance -QueryTimeout 120 -ConnectionTimeout 60 -Variable $params
