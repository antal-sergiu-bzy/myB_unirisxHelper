# for PS 2.0 support
if (-not $SCRIPT:PSScriptRoot) {
  $SCRIPT:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$SCRIPT:DbGhostConfigDir = "$PSScriptRoot\DbGhostConfiguration"

$SCRIPT:OriginalDirectory = (Get-Location -PSProvider "FileSystem").ProviderPath
$SCRIPT:OriginalSystemDirectory = [System.IO.Directory]::GetCurrentDirectory()

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) LoadSqlModule.ps1)

function Copy-ItemWrapper ([string] $Path, [string] $Destination) {
  if (!(Test-Path -Path $Destination -PathType "Container")) {
    New-Item -Path $Destination -ItemType "Directory" -confirm:$false -force | Out-Null
  }
  Copy-Item -Path $Path -Destination $Destination -confirm:$false -force
}

function Set-ContentWrapper (
    [Parameter(ValueFromPipeline=$true, Position=2)]
    [object[]] $Value,
    [Parameter(Position=1)]
    [string] $Path) {
  $dir = Split-Path $Path
  if ( ! (Test-Path -Path $dir -PathType "Container")) {
    New-Item -Path $dir -ItemType "Directory" | Out-Null
  }
  if ($input) {
    $input | Set-Content -Path $Path
  } else {
    Set-Content @PSBoundParameters
  }
}

function Get-Parameters(
  [string]$environment,
  [string]$database = $(throw "missing parameter 'SSDB Database Name'"),
  [string]$server = $(throw "missing parameter 'SSDB Server'"),
  [string]$rollbackParams,
  [string[]]$instances,
  [string]$requestId,
  [boolean]$createPackageScripts
) {
  # if we got just a number, convert to Request_111111 format
  if ($requestId -match '^[0-9]*$') {
    $requestId = 'Request_{0:000000}' -f [int]$req
  }

  if ($requestId -inotmatch '^Request_[0-9]{6}$') {
    throw "$requestId invalid parameter 'Request Id'"
  }

  $environment = $environment.ToUpper()
  if ('DEV','INT','SYS','UAT','PKG','PRD' -notcontains $environment) {
    throw "$environment invalid 'Environment' parameter [dev | int | sys | uat | pkg | prd]"
  }

  # account for condition where instances are passed in via "-File" argument to PowerShell.exe
  if ( ! $instances) {
    $instances = @($server)
  } elseif ($instances -match ' ') {
    $instances = $instances -split ' '
  }

  $dbSettingsFile = Join-Path (Split-Path $PSScriptRoot) DbSettings.psd1
  $dbSettings = Get-Content $dbSettingsFile | Out-String | Invoke-Expression

  return @{
    requestId = $requestId
    env = $environment
    templateDatabase = "$($database)_dbgbuild"
    database = $database
    server = $server
    instances = $instances
    components = $dbSettings.components
    users = $dbSettings.users
    createScripts = $dbSettings.createScripts
    doRollback = $rollbackParams -ne '/norollback'
    createPackageScripts = $createPackageScripts
    deploymentSettings = $dbSettings.deploymentSettings
  }
}

function Test-EnvironmentName(
  [string[]]$Instances,
  [string]$Env
) {
  $instances | Foreach-Object {
    Invoke-Sqlcmd -InputFile $PSScriptRoot\SqlCmdScripts\EnsureEnvironmentName.sql `
                  -ServerInstance $_ `
                  -QueryTimeout 120 -ConnectionTimeout 60 `
                  -Variable "env=$env"
  }
}

function Set-Logins(
  [string[]]$instances,
  [hashtable[]]$users
) {
  $instances | Foreach-Object {
    $instance = $_
    $users | Foreach-Object {
      & "$PSScriptRoot\ModelLoginCreate.ps1" `
          -sqlServerInstance $instance `
          -loginCreationScript $PSScriptRoot\SqlCmdScripts\CreateSqlLogin.sql `
          -loginDomain $_.domain `
          -loginName $_.userName `
          -suffixStyle $_.suffixStyle
    }
  }
}

function Initialize-BuildDb(
  [string]$server,
  [string]$database,
  $components,
  [hashtable]$createScripts,
  [hashtable[]]$users,
  [hashtable]$deploymentSettings
) {
  # TODO: could we just use $PSBoundParameters?
  $args = @{
    Server=$server
    Database=$database
    Components=$components
    ModelCreateScripts=$createScripts
    Users=$users
    DeploymentSettings=$deploymentSettings
  }
  
  #TODO: use CmdletBinding attribute across project so verbose gets automatically passed
  & (GetBuildScriptName($deploymentSettings)) @args -Verbose
}

function GetBuildScriptName(
  [hashtable]$deploymentSettings)
{
  if($deploymentSettings) {
    $deploymentType = $deploymentSettings.type
  }

  switch($deploymentType){
    SSDT { "$PSScriptRoot\SSDT\DatabaseBuild.ps1"; Write-Host "Using SSDT"; break }
    EntityFramework { "$PSScriptRoot\EntityFramework\DatabaseBuild.ps1"; Write-Host "Using EF"; break }
    DbGhost { "$PSScriptRoot\DbGhostBuild\DatabaseBuild.ps1"; Write-Host "Using DbGhost Build"; break }
    default { "$PSScriptRoot\DatabaseBuild.ps1"; Write-Host "Using Schemaster (default)"; break }
  }
}

function Initialize-TargetDb(
  [string[]]$instances,
  [string]$database
) {
  $instances | Foreach-Object {
    Invoke-Sqlcmd -InputFile $PSScriptRoot\SqlCmdScripts\CreateDatabase.sql `
                  -ServerInstance $_ `
                  -QueryTimeout 120 -ConnectionTimeout 60 `
                  -Variable "DatabaseName=$database"
  }
}

function Invoke-DbGhost(
  [string]$server,
  [string]$sourceDb,
  [string]$targetDb,
  [string]$script,
  [string[]]$otherArgs = @()
) {
  $args = @("""$script""")
  $args += "/targetserver", """$server""",
           "/sourceserver", """$server""",
           "/buildserver", """$server""",
           "/targetdatabase", """$targetDb""",
           "/sourcedatabase", """$sourceDb""",
           "/builddatabase", """$sourceDb"""
  $args += $otherArgs

  $dbGhostExec = Get-DbGhostExec

  Write-Host "$dbGhostExec $($args -join ' ')"
  & $dbGhostExec @args
  if ( ! $?) {
    # output of exception will be in DBGhost messages
    throw
  }
}

function Get-DbGhostExec() {
  $dbGhostExec = $env:ProgramFiles, ${env:ProgramFiles(x86)} |
    Foreach-Object { "$_\DB Ghost\ChangeManagerCMD.exe" } |
    Where-Object { Test-Path -Path $_ } |
    Select-Object -First 1

  if (-not $dbGhostExec) { throw "ChangeManagerCMD.exe program not found" }

  $dbGhostExec
}

function Create-PackageScripts(
  [string] $Database,
  [hashtable[]] $Users,
  [switch] $IncludeRollback,
  [string] $Suffix
) {
  $deployDir = "$PSScriptRoot\..\Deploy"
  $dbDir = "$deployDir\Databases\$DatabaseName"
  $loginDir = "$deployDir\Security\Logins"

  $rollforwardHeader = Convert-SqlCmd -Path "$DbGhostConfigDir\DBGhostChangeManagerTemplate_rollforward.txt" `
                                      -Variables @{Database=$Database}

  $rollforwardHeader +
    (Get-Content $DbGhostConfigDir\DBGhost_DeltaRollforward.sql,
                 $DbGhostConfigDir\DBGhostChangeManagerTemplate.txt) |
    Set-ContentWrapper $dbDir\Rollforward\DeltaRollforwardToExecute$Suffix.sql

  if ($IncludeRollback) {
    $rollbackHeader = Convert-SqlCmd -Path $DbGhostConfigDir\DBGhostChangeManagerTemplate_rollback.txt `
                                     -Variables @{Database=$Database}

    $rollbackHeader +
      (Get-Content $DbGhostConfigDir\DBGhost_DeltaRollback.sql,
                   $DbGhostConfigDir\DBGhostChangeManagerTemplate.txt) |
      Set-ContentWrapper $dbDir\Rollback\DeltaRollbackToExecute$Suffix.sql
  }

  Copy-ItemWrapper -Path $DbGhostConfigDir\DBGhost_Process.log `
                   -Destination $dbDir

  Convert-SqlCmd -Path $PSScriptRoot\SqlCmdScripts\CreateDatabase.sql `
                 -Variables @{DatabaseName=$database} |
    Set-ContentWrapper $dbDir\CreateDB.sql

  $Users | Foreach-Object {
    Convert-SqlCmd -Path $PSScriptRoot\SqlCmdScripts\CreateSqlLogin.sql `
                   -Variables @{login_domain=$_.domain; user_name=$_.userName} |
      Set-ContentWrapper "$loginDir\$($_.domain)-$($_.userName).sql"
  }
}

function Convert-SqlCmd(
  [string] $Path,
  [hashtable] $Variables
) {
  $sqlCmdContent = Get-Content $Path
  $Variables.Keys | Foreach-Object {
    $varToReplace = [regex]::escape("`$($_)")
    $sqlCmdContent = $sqlCmdContent -replace $varToReplace,$Variables[$_]
  }
  $sqlCmdContent
}

##################################################################################################
# From PowerShell Community Extensions                                                           #
# http://pscx.codeplex.com/SourceControl/latest#Trunk/Src/Pscx/Modules/Utility/Pscx.Utility.psm1 #
##################################################################################################

Set-Alias ??    Invoke-NullCoalescing  -Description "PSCX alias"
Set-Alias ?:    Invoke-Ternary         -Description "PSCX alias"

<#
.SYNOPSIS
    Similar to the C# ? : operator e.g. name = (value != null) ? String.Empty : value
.DESCRIPTION
    Similar to the C# ? : operator e.g. name = (value != null) ? String.Empty : value.
    The first script block is tested. If it evaluates to $true then the second scripblock
    is evaluated and its results are returned otherwise the third scriptblock is evaluated
    and its results are returned.
.PARAMETER Condition
    The condition that determines whether the TrueBlock scriptblock is used or the FalseBlock
    is used.
.PARAMETER TrueBlock
    This block gets evaluated and its contents are returned from the function if the Conditon
    scriptblock evaluates to $true.
.PARAMETER FalseBlock
    This block gets evaluated and its contents are returned from the function if the Conditon
    scriptblock evaluates to $false.
.PARAMETER InputObject
    Specifies the input object. Invoke-Ternary injects the InputObject into each scriptblock
    provided via the Condition, TrueBlock and FalseBlock parameters.
.EXAMPLE
    C:\PS> $toolPath = ?: {[IntPtr]::Size -eq 4} {"$env:ProgramFiles(x86)\Tools"} {"$env:ProgramFiles\Tools"}}
    Each input number is evaluated to see if it is > 5.  If it is then "Greater than 5" is
    displayed otherwise "Less than or equal to 5" is displayed.
.EXAMPLE
    C:\PS> 1..10 | ?: {$_ -gt 5} {"Greater than 5";$_} {"Less than or equal to 5";$_}
    Each input number is evaluated to see if it is > 5.  If it is then "Greater than 5" is
    displayed otherwise "Less than or equal to 5" is displayed.
.NOTES
    Aliases:  ?:
    Author:   Karl Prosser
#>
function Invoke-Ternary {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [scriptblock]
        $Condition,

        [Parameter(Mandatory=$true, Position=1)]
        [scriptblock]
        $TrueBlock,

        [Parameter(Mandatory=$true, Position=2)]
        [scriptblock]
        $FalseBlock,

        [Parameter(ValueFromPipeline=$true, ParameterSetName='InputObject')]
        [psobject]
        $InputObject
    )

    Process {
        if ($pscmdlet.ParameterSetName -eq 'InputObject') {
            Foreach-Object $Condition -input $InputObject | Foreach {
                if ($_) {
                    Foreach-Object $TrueBlock -InputObject $InputObject
                }
                else {
                    Foreach-Object $FalseBlock -InputObject $InputObject
                }
            }
        }
        elseif (&$Condition) {
            &$TrueBlock
        }
        else {
            &$FalseBlock
        }
    }
}

<#
.SYNOPSIS
    Similar to the C# ?? operator e.g. name = value ?? String.Empty
.DESCRIPTION
    Similar to the C# ?? operator e.g. name = value ?? String.Empty;
    where value would be a Nullable&lt;T&gt; in C#.  Even though PowerShell
    doesn't support nullables yet we can approximate this behavior.
    In the example below, $LogDir will be assigned the value of $env:LogDir
    if it exists and it's not null, otherwise it get's assigned the
    result of the second script block (C:\Windows\System32\LogFiles).
    This behavior is also analogous to Korn shell assignments of this form:
    LogDir = ${$LogDir:-$WinDir/System32/LogFiles}
.PARAMETER PrimaryExpr
    The condition that determines whether the TrueBlock scriptblock is used or the FalseBlock
    is used.
.PARAMETER AlternateExpr
    This block gets evaluated and its contents are returned from the function if the Conditon
    scriptblock evaluates to $true.
.PARAMETER InputObject
    Specifies the input object. Invoke-NullCoalescing injects the InputObject into each
    scriptblock provided via the PrimaryExpr and AlternateExpr parameters.
.EXAMPLE
    C:\PS> $LogDir = ?? {$env:LogDir} {"$env:windir\System32\LogFiles"}
    $LogDir is set to the value of $env:LogDir unless it doesn't exist, in which case it
    will then default to "$env:windir\System32\LogFiles".
.NOTES
    Aliases:  ??
    Author:   Keith Hill
#>
function Invoke-NullCoalescing {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [scriptblock]
        $PrimaryExpr,

        [Parameter(Mandatory=$true, Position=1)]
        [scriptblock]
        $AlternateExpr,

        [Parameter(ValueFromPipeline=$true, ParameterSetName='InputObject')]
        [psobject]
        $InputObject
    )

    Process {
        if ($pscmdlet.ParameterSetName -eq 'InputObject') {
            if ($PrimaryExpr -eq $null) {
                Foreach-Object $AlternateExpr -InputObject $InputObject
            }
            else {
                $result = Foreach-Object $PrimaryExpr -input $InputObject
                if ($result -eq $null) {
                    Foreach-Object $AlternateExpr -InputObject $InputObject
                }
                else {
                    $result
                }
            }
        }
        else {
            if ($PrimaryExpr -eq $null) {
                &$AlternateExpr
            }
            else {
                $result = &$PrimaryExpr
                if ($result -eq $null) {
                    &$AlternateExpr
                }
                else {
                    $result
                }
            }
        }
    }
}
