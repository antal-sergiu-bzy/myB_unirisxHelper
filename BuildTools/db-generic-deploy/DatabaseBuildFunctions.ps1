function Set-BuildUsers {
    param ($Users, $Database, $Server)
    Write-Host "Generating Users" -foregroundcolor "cyan"
    $Users | Foreach-Object {
        $user = $_
        $userArgs = @{
            SqlServerInstance = $Server
            DatabaseName      = $Database
            LoginDomain       = $user.domain
            LoginName         = $user.userName
            SuffixStyle       = $user.suffixStyle
        }
        & "$scriptRoot\ModelUserCreate.ps1" @userArgs

        $userName = $user.userName
        Write-Host "  User Created: $($user.domain)/$userName" -foregroundcolor "yellow"

        Write-Host "  Generating User Roles" -foregroundcolor "cyan"

        if(-not $user.roles){
          throw "User $userName must have at least one role"
        }

        $user.roles | Foreach-Object {
            $roleParams = "user=$userName", "role=$_", "databaseName=$Database"
            Invoke-Sqlcmd -InputFile $userRoleAddScript -ServerInstance $Server -QueryTimeout 120 -ConnectionTimeout 60 -Variable $roleParams
            Write-Host "    Role Created: $_" -foregroundcolor "yellow"
        }

        if($user.grants) {
          Write-Host "  Generating User Roles" -foregroundcolor "cyan"
          $user.grants | Foreach-Object {
              Invoke-Sqlcmd -Query "GRANT $_ TO [$userName]" -ServerInstance $Server -Database $Database -QueryTimeout 120 -ConnectionTimeout 60
              Write-Host "    Grant Created: $_" -foregroundcolor "yellow"
          }
        }
    }
}
