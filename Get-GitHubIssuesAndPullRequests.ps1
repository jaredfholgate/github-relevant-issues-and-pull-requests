# PowerShell to see issues and pull requests from watched repositories
param(
  $labels = @(),
  $orderBy = "created" # created, updated, etc https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-issues-and-pull-requests
)

$watchedRepos = ConvertFrom-Json $(gh api "/user/subscriptions")

$query = ""

foreach($repo in $watchedRepos) {
  $query += "repo:$($repo.owner.login)/$($repo.name) "
}

if($labels.Count -gt 0) {
  foreach($label in $labels) {
    $query = "$query label:`"$($label)`""
  }
}

$urlEncodedQuery = [System.Web.HttpUtility]::UrlEncode($query)

$issues = ConvertFrom-Json $(gh api "/search/issues?q=$urlEncodedQuery+type:issue+state:open&sort=$orderBy&order=desc&per_page=100")
$pullRequests = ConvertFrom-Json $(gh api "/search/issues?q=$urlEncodedQuery+type:pr+state:open&sort=$orderBy&order=desc&per_page=100")

Write-Host "Issues"
if($issues.items.Count -eq 0) {
  Write-Host "No issues found. Happy days!" -ForegroundColor Green
  Write-Host ""
} else {
  $issues.items | Format-Table -Property html_url, created_at, @{ Label = "created_by"; Expression = {$_.user.login} }, title, @{ Label = "assigned_to"; Expression = {$_.assignee.login} } -AutoSize
}

Write-Host "Pull Requests"
if($pullRequests.items.Count -eq 0) {
  Write-Host "No pull requests found. Happy days!" -ForegroundColor Green
  Write-Host ""
} else {
  $pullRequests.items | Format-Table -Property html_url, created_at, @{ Label = "created_by"; Expression = {$_.user.login} }, title, @{ Label = "assigned_to"; Expression = {$_.assignee.login} } -AutoSize
}
