# PowerShell to see issues and pull requests from watched repositories
param(
  $labels = @(),
  $orderBy = "created", # created, updated, etc https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-issues-and-pull-requests
  $orderDirection = "desc", # asc, desc
  $itemsPerPage = 100, # Max 100
  $state = "open" # open, closed
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

$queryTemplate = "/search/issues?q=$urlEncodedQuery+type:{0}+state:$state&sort=$orderBy&order=$orderDirection&per_page=$itemsPerPage"

$itemTypes = @(
  @{
    name = "Issues"
    query = [string]::Format($queryTemplate, "issue")
  },
  @{
    name = "Pull Requests"
    query = [string]::Format($queryTemplate, "pr")
  }
)

foreach($itemType in $itemTypes) {
  $items = ConvertFrom-Json $(gh api "$($itemType.query)")

  Write-Host ""
  Write-Host $itemType.name -ForegroundColor DarkBlue
  Write-Host "------" -ForegroundColor DarkBlue
  if($items.items.Count -eq 0) {
    Write-Host "No $($itemType.name) found. Happy days!" -ForegroundColor Green
    Write-Host ""
  } else {
    $items.items | Format-Table -Property html_url, created_at, @{ Label = "created_by"; Expression = {$_.user.login} }, title, @{ Label = "assigned_to"; Expression = {$_.assignee.login} } -AutoSize
  }
}
