# PowerShell to see issues and pull requests from watched repositories
param(
  $labels = @(),
  $labelsLogic = "or", # or, and
  $orderBy = "created", # created, updated, etc https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-issues-and-pull-requests
  $orderDirection = "desc", # asc, desc
  $itemsPerPage = 100, # Max 100
  $state = "open", # open, closed
  $emojiListFileName = "emoji-list-short.csv",
  $repositories = @(), # Extra repositories to include in the search (e.g. "organization/repo")
  $includeWatchedRepositories = $true, # Include watched repositories in the search
  $repositoriesToFilterByAssigned = @() # Repositories where issues should be filtered based on the assigned_to (e.g. "organization/repo")
)

function Get-EmojiList {
  param(
    [string] $listFileName = "emoji-list-short.csv"
  )
  $emojiCsvPath = "$PSScriptRoot/$listFileName"
  $emojiCsv = Import-Csv $emojiCsvPath

  $emojiHashTable = @{}

  foreach($emoji in $emojiCsv) {
    $emojiHashTable[$emoji.key] = $emoji.symbol
  }

  return $emojiHashTable
}

function Format-Hyperlink {
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Uri] $Uri,

    [Parameter(Mandatory=$false, Position = 1)]
    [string] $Label
  )

  if ($Label) {
    return "`e]8;;$Uri`e\$Label`e]8;;`e\"
  }

  return "$Uri"
}

function Format-Emoji {
  param(
    [string] $originalString,
    [hashtable] $emojiList
  )

  if(!$originalString.Contains(":")) {
    return $originalString
  }

  $regex = ':([a-z_]*?):'
  $emojiMatches = $originalString | Select-String -Pattern $regex -AllMatches

  foreach($match in $emojiMatches.Matches) {
    if($emojiList.ContainsKey($match.Value)) {
      $originalString = $originalString.Replace($match.Value, $emojiList[$match.Value])
    }
  }

  return $originalString
}

$emojiList = Get-EmojiList -listFileName $emojiListFileName

$query = ""

if($includeWatchedRepositories) {
  $watchedRepos = ConvertFrom-Json $(gh api "/user/subscriptions")

  foreach($repo in $watchedRepos) {
    $query += "repo:$($repo.owner.login)/$($repo.name) "
  }
}

foreach($repo in $repositories) {
  $query += "repo:$repo "
}

if($labels.Count -gt 0) {
  if($labelsLogic -eq "or") {
    $query = "$query label:"
    $isFirst = $true
    foreach($label in $labels) {
      if($isFirst) {
        $isFirst = $false
        $query = "$query`"$($label)`""
      } else {
        $query = "$query,`"$($label)`""
      }
    }
  } else {
    foreach($label in $labels) {
      $query = "$query label:`"$($label)`""
    }
  }
}

$username = (ConvertFrom-Json $(gh api "/user")).login
#$teams = (ConvertFrom-Json $(gh api "/user/teams"))  #TODO: Filter pull requests by team assigned reviewers? Does not appear in search results, so would require extra API calls

$urlEncodedQuery = [System.Web.HttpUtility]::UrlEncode($query)

$queryTemplate = "/search/issues?q=$urlEncodedQuery+type:{0}+state:$state&sort=$orderBy&order=$orderDirection&per_page=$itemsPerPage"

Write-Verbose "Query: $queryTemplate"

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
  $page = 1
  $items = @()
  $incompleteResults = $true

  # Get the paged results
  while($incompleteResults) {
    $response = ConvertFrom-Json $(gh api "$($itemType.query)&page=$page")
    $items += $response.items
    $incompleteResults = $page * $itemsPerPage -lt $response.total_count
    $page++
  }

  $formattedItems = @()
  foreach($item in $items) {
    # Format the output
    $assignedTo = $null -eq $item.assignee.login -or $item.assignee.login -eq "" ? "unassigned" : $item.assignee.login
    $htmlUrl = $item.html_url
    $orgRepoSplit = $htmlUrl -split "/"
    $organization = $orgRepoSplit[3]
    $repository = $orgRepoSplit[4]
    $organizationRepository = "$organization/$repository"
    
    if($repositoriesToFilterByAssigned -contains $organizationRepository -and $assignedTo -ne $username) {
      continue
    }

    $number = $item.number
    $title = $item.title
    $createdBy = $item.user.login
    $created = $item.created_at.ToString("yyyy-MM-dd HH:mm")
    $updated = $item.updated_at.ToString("yyyy-MM-dd HH:mm")
    $label = ""
    foreach($labelObect in $item.labels) {
      if($labels -contains $labelObect.name) {
        $label = Format-Emoji -originalString $labelObect.name -emojiList $emojiList
        break
      }
    }

    #Add to the array
    $formattedItems += @{
      id = Format-Hyperlink -Uri $htmlUrl -Label $number
      title = $title
      organizationRepository = Format-Hyperlink -Uri $htmlUrl -Label $organizationRepository
      createdBy = Format-Hyperlink -Uri $htmlUrl -Label $createdBy
      created = Format-Hyperlink -Uri $htmlUrl -Label $created
      updated = Format-Hyperlink -Uri $htmlUrl -Label $updated
      assignedTo = Format-Hyperlink -Uri $htmlUrl -Label $assignedTo
      label = Format-Hyperlink -Uri $htmlUrl -Label $label
    }
  }

  Write-Host ""
  $title = "$($itemType.name) ($($formattedItems.Count))"
  Write-Host $title -ForegroundColor DarkBlue
  Write-Host ("-" * $title.Length) -ForegroundColor DarkBlue
  if($formattedItems.Count -eq 0) {
    Write-Host "No $($itemType.name) found. Happy days!" -ForegroundColor Green
    Write-Host ""
  } else {
    if($labels.Count -gt 0) {
      $formattedItems | ForEach-Object {[PSCustomObject]$_} | Format-Table -Property id, label, @{ Label = "repo"; Expression = {$_.organizationRepository} }, created, createdBy, updated, assignedTo, title -AutoSize -Wrap
    } else {
      $formattedItems | ForEach-Object {[PSCustomObject]$_} | Format-Table -Property id, @{ Label = "repo"; Expression = {$_.organizationRepository} }, created, createdBy, updated, assignedTo, title -AutoSize -Wrap
    }
  }
}
