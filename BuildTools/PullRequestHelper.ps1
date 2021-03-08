# Get all PRs that have been closed in the last x hours
function Get-RecentlyClosedPRs
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $repo,
        [string] $owner = "Beazley",
        [int] $closedWithinLastHours = 1
    )
    $closedCutoffTime = [datetime]::Now.AddHours($closedWithinLastHours * -1)
    Write-Verbose $closedCutoffTime
    $closedPullRequests = Invoke-WebRequest -Uri "http://git.bfl.local/api/v3/repos/$owner/$repo/pulls?state=closed" -UseDefaultCredentials -UseBasicParsing -Method Get | ConvertFrom-JSON
    $targetPRs = $closedPullRequests | Where-Object { [datetime]$_.closed_at -gt $closedCutoffTime } | ForEach-Object { "$($_.number)" }
    if($targetPRs -eq $null){
        Write-Verbose "No PR's found that were closed since $closedCutoffTime"
        return $null
    }

    [string]::Join(',', $targetPRs)
}

# Run the Octopus Deploy PR clean up project with PR details
function Run-OctopusDeploy-PR-CleanUp-Project
{
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$deploymentName,
        [Parameter(Mandatory=$true)]
        [int] $pullRequestNumber
    )
    $octopusDeployExe = "$(Get-Location)\lib\OctopusTools\tools\octo.exe"
    $octopusDeployServer = $env:Octopus_Server
    $octopusDeployApiKey = $env:Octopus_API_Key

    $command = "$octopusDeployExe " `
             + "deploy-release " `
             + "--project=""$deploymentName"" " `
             + "--version=latest " `
             + "--deployTo=""Integration"" " `
             + "--waitfordeployment " `
             + "--deploymenttimeout=01:00:00 " `
             + "--server=$octopusDeployServer " `
             + "--apiKey=""$octopusDeployApiKey"" " `
             + "--variable=PullRequest_Number:$pullRequestNumber"
    $command

    if($PSCmdlet.ShouldProcess($octopusDeployServer,$command)) {
        Invoke-Expression $command
    }
}

# Main entry-point
function CleanUp-PR-Environment
{
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string] $repo,
        [Parameter(Mandatory=$true)]
        [string] $octopusCleanUpProjectName,
        [ValidatePattern("(^$|(\d{3}[,])*\d{3}$)")]
        [string] $ClosedPRs,
        [int] $closedWithinLastHours = 1
    )

    if ([String]::IsNullOrEmpty($closedPRs)) 
    {
        $closedPRs = Get-RecentlyClosedPRs -repo $repo -closedWithinLastHours $closedWithinLastHours
        if ([String]::IsNullOrEmpty($closedPRs)) 
        {
            Write-Output "No PRs to close in the last $closedWithinLastHours-hours."
            return
        }
    } else {
        Write-Output "Forced PRs for clean up : $ClosedPRs"
    }

    foreach ($PRToCleanUp in $closedPRs.Split(','))
    {
        try
        {
            Write-Output "Cleaning up PR: $PRToCleanUp"
            Run-OctopusDeploy-PR-CleanUp-Project -deploymentName $octopusCleanUpProjectName -pullRequestNumber $PRToCleanUp
        }
        catch
        {
            Write-Warning "Failed to clean up PR with error: $($_.Exception.Message)"
        }
    }
}
