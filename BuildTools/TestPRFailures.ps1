function Test-PrFailures {
  [CmdletBinding()]
  param (
    [string]$repo,
    [string]$gheOrg = 'Beazley',
    [string]$gheToken,
    [switch]$excludeWip,
    [string]$mergeFailLabel,
    [string]$flowdockToken
  )
  
  Write-Verbose "$repo, $gheOrg, $excludeWip, $mergeFailLabel"
  "$gheToken, $flowdockToken" > tokens.log

  $gheUrl = [Uri]'http://git.bfl.local'
  $flowdockApiUrl = [Uri]"https://api.flowdock.com/messages?flow_token=$flowdockToken"

  [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

  .\nuget.exe Install Octokit -OutputDirectory .\OctoKit
  Add-Type -Path .\OctoKit\Octokit.[0-9]*\lib\net45\Octokit.dll -ReferencedAssemblies .\OctoKit\Microsoft.Bcl.[0-9]*\lib\net40\*.dll, .\OctoKit\Microsoft.Net.Http.[0-9]*\lib\net45\*.dll -Verbose
 
  $appHeader = New-Object OctoKit.ProductHeaderValue('PullRequestMonitor')
 
  $gheClient = New-Object OctoKit.GitHubClient($appHeader, $gheUrl)
  $gheClient.Credentials = New-Object OctoKit.Credentials($gheToken)
 
  $openPrsTask = $gheClient.PullRequest.GetAllForRepository($gheOrg, $repo);
 
  $prdetails = $openPrsTask.Result | foreach {
    @{
      Title = $_.Title
      PrDetailsTask = $gheClient.PullRequest.Get($gheOrg, $repo, $_.Number)
      StatusTask = $gheClient.Repository.CommitStatus.GetCombined($gheOrg, $repo, $_.Head.Sha)
      LabelsTask = $gheClient.Issue.Labels.GetAllForIssue($gheOrg, $repo, $_.Number)
    }
  }

  $labelTasks =
    if ($mergeFailLabel) {
      $labelClient = $gheClient.Issue.Labels

      $prdetails | foreach {
        $pr = $_.PrDetailsTask.Result
        $labels = $_.LabelsTask.Result
        $hasLabel = $labels.Name -contains $mergeFailLabel
        if ($pr.Mergeable -eq $false) {
          if (-not $hasLabel) {
            $labelClient.AddToIssue($gheOrg, $repo, $pr.Number, @($mergeFailLabel))
          }
        } else {
          if ($hasLabel) {
            $labelClient.RemoveFromIssue($gheOrg, $repo, $pr.Number, $mergeFailLabel)
          }
        }
      }
    } else {
      $null
    }
  
  $statuses = $prdetails | where {
    (-not $excludeWip) -or 
      (($_.Title -notmatch '^[[]?WIP[]]?') -and
       ($_.LabelsTask.Result.Name -notcontains 'WIP'))
  } | foreach {
    $pr = $_.PrDetailsTask.Result
    [PSCustomObject]@{
      PrNumber = $pr.Number
      Mergeable = $pr.Mergeable
      BuildSuccess = -not ($_.StatusTask.Result.State -eq 'Failure')
    }
  }

  $statuses | Format-Table -AutoSize

  # resolve the label tasks
  # sometimes PowerShell amazes me. It skips the nulls by default!
  $labelTasks.Result | Out-Null

  $failures = $statuses | ? { ($_.Mergeable -eq $false) -or ($_.BuildSuccess -eq $false) }

  if($failures) {
    # TODO: use TC messages?

    if ($flowdockToken) {
      #TODO: use activity instead or give a choice?
      $message = @{
        event='message'
        content="Check your Pull Requests! $gheUrl/$gheOrg/$repo/pulls"
      }
      Invoke-RestMethod -Method Post -Uri $flowdockApiUrl -ContentType 'application/json' -Body ($message | ConvertTo-Json)
    }
    exit 1
  }
}