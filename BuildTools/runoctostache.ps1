param (
    $Path, 
    $JsonFile = '.\Variables.json'
)

[IO.Directory]::SetCurrentDirectory($PWD)

Add-Type -Path .\lib\Calamari.exe\Newtonsoft.Json.dll
Add-Type -Path .\lib\Calamari.exe\Sprache.dll
Add-Type -Path .\lib\Calamari.exe\Octostache.dll

try{
    $variables = New-Object -TypeName Octostache.VariableDictionary -ArgumentList $JsonFile

    # stolen from https://github.com/OctopusDeploy/Calamari/blob/755501eda21d63861022f1a2d87c98d5e7f9f23b/source/Calamari/Integration/Substitutions/FileSubstituter.cs#L23-L35
    $source = [IO.File]::ReadAllText($Path)
    $evalError = $null
    $result = $variables.Evaluate($source, [ref]$evalError)
}
catch [Exception]
{
    echo $_.Exception|format-list -force
}

if (-not [String]::IsNullOrEmpty($evalError)) {
  Write-Output "Parsing file '$Path' with Octostache returned the following error: '$evalError'"
}

[IO.File]::WriteAllText($Path, $result);
