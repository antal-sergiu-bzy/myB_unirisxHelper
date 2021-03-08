param (
  $Server,
  $Database,
  $Components,
  $ModelCreateScripts,
  $Users
)

# for PS 2.0 support
if (-not $SCRIPT:PSScriptRoot) {
  $SCRIPT:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$userRoleAddScript = "$PSScriptRoot\SqlCmdScripts\AddUserRole.sql"

& "$PSScriptRoot\ModelDelete.ps1" -sqlServerInstance $Server `
                                  -databaseName $Database `
                                  -dropDatabaseScript $PSScriptRoot\SqlCmdScripts\DropDatabase.sql

& "$PSScriptRoot\ModelPrep.ps1" -sqlServerInstance $Server `
                                -databaseName $Database `
                                -createDatabaseScript $PSScriptRoot\SqlCmdScripts\CreateDatabase.sql

$Users | Foreach-Object {
  & "$PSScriptRoot\ModelUserCreate.ps1" `
      -sqlServerInstance $Server `
      -databaseName $Database `
      -loginDomain $_.domain `
      -loginName $_.userName `
      -suffixStyle $_.suffixStyle
}

$Components | Foreach-Object {
  $componentName = if ($_.Name) { $_.Name } else { $_ }
  $isSchema = $_.Type -eq 'schema'

  $ScriptFullPaths = $ModelCreateScripts[$componentName] | ForEach-Object { "$PSScriptRoot\..\Model\$_.sql" }

  & "$PSScriptRoot\ModelCreateRoledSchema.ps1" `
      -sqlServerInstance $Server `
      -databaseName $Database `
      -componentName $componentName `
      -componentIsASchema:$isSchema `
      -dbRoleGeneratorFolder $PSScriptRoot\DbRoleGenerator `
      -createDatabaseObjectsScripts $ScriptFullPaths

  $Users | Foreach-Object {
    $user = $_
    $user.roles[$componentName] | Where-Object { $_ -ne $null } | Foreach-Object {
      if($_ -eq 'Creator' -and -not $isSchema){
        throw "Creator role is only valid for schema components"
      }

      $fullRoleName = "$($componentName)_$_"
      $roleParams = "user=$($user.userName)", "role=$fullRoleName", "databaseName=$Database"

      Write-Verbose "Invoke-Sqlcmd -InputFile $userRoleAddScript -ServerInstance $Server -QueryTimeout 120 -ConnectionTimeout 60 -Variable $roleParams"
      Invoke-Sqlcmd -InputFile $userRoleAddScript -ServerInstance $Server -QueryTimeout 120 -ConnectionTimeout 60 -Variable $roleParams
    }
  }
}
