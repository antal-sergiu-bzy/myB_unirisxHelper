if (     ! (Get-Module -Name SqlPs) `
    -And ! (Get-PSSnapin -Name SqlServer*Snapin100 -ErrorAction SilentlyContinue)) {
  if(Get-Module -ListAvailable -Name SqlPs) {
    # importing SqlPs sometimes changes the path to SQLSERVER:\
    $currDir = Get-Location
    Import-Module SqlPs
    Set-Location $currDir
  } else {
    Add-PSSnapin SqlServer*Snapin100
  }
}
