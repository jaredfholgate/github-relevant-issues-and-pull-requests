    Write-Host "Getting Open Issues and Pull Requests Requiring Triage or Attention"
    $labels = @("Needs: Triage :mag:", "Needs: Attention :wave:", "Needs: Immediate Attention :bangbang:")
    /Users/myuser/Code/github-relevant-issues-and-pull-requests/Get-GitHubIssuesAndPullRequests.ps1 -labels $labels
    Read-Host -Prompt "Press any key to exit"