# GitHub Relevant Issues and Pull Requests

A PowerShell script to output relevant GitHub Issues and Pull Requests. This is useful if you are the maintainer of multiple GitHub repositories and struggle to see what you need in the GitHub UI.

It uses the GitHub API to search for issues and pull requests in repositories you are watching.

## Prequisites

1. Install the GitHub CLI (gh) from https://cli.github.com/
1. Login to GitHub using `gh auth login`
1. Head over to https://github.com/watching and make sure you are only watching the repositories you are responsible for. Must be set to `All activity` at this time.

## Usage

1. Clone this repository to your local machine.
1. Open a PowerShell prompt in the repo path.
1. Run the script with the following command:

  ```powershell
  ./Get-GitHubIssuesAndPullRequests.ps1
  ```
  
  To filter by one or more labels, use the `-label` parameter:
  
  ```pwsh  
  ./Get-GitHubIssuesAndPullRequests.ps1 -labels "bug","enhancement"
  ```

  ```pwsh  
  $labels = @("Needs: Triage :mag:")
  ./Get-GitHubIssuesAndPullRequests.ps1 -labels $labels
  ```
  
  To order by created or updated dates, use the `-orderBy` parameter:
  
  ```pwsh
  ./Get-GitHubIssuesAndPullRequests.ps1 -orderBy "created"
  ```
  
  ```pwsh
  ./Get-GitHubIssuesAndPullRequests.ps1 -orderBy "updated"
  ```
