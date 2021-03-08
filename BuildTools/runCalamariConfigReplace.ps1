param (
    $Path,
    $JsonFile = '.\Variables.json'
)

[IO.Directory]::SetCurrentDirectory($PWD)

Add-Type -Path .\lib\Calamari.exe\Octostache.dll
#cannot use -Add-Type for executables
[Reflection.Assembly]::LoadFile("$PWD\lib\Calamari.exe\Calamari.exe")

try{
    $variables = New-Object -TypeName Octostache.VariableDictionary -ArgumentList $JsonFile
    $replacer = New-Object -TypeName Calamari.Integration.ConfigurationVariables.ConfigurationVariablesReplacer -ArgumentList $false

    $result = $replacer.ModifyConfigurationFile($Path, $variables)
}
catch [Exception]
{
    Write-Output $_.Exception|format-list -force
}
