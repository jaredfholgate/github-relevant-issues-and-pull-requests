# GitHub Relevant Issues and Pull Requests

A PowerShell script to output relevant GitHub Issues and Pull Requests. This is useful if you are the maintainer of multiple GitHub repositories and struggle to see what you need in the GitHub UI.

It uses the GitHub API to search for issues and pull requests in repositories you are watching.

## Prequisites

1. Install the GitHub CLI (gh) from <https://cli.github.com/>
1. Login to GitHub using `gh auth login`
1. Head over to <https://github.com/watching> and make sure you are only watching the repositories you are responsible for. Must be set to `All activity` at this time.

## Usage

1. Clone this repository to your local machine.
1. Open a PowerShell prompt in the repo path.
1. Run the script with the following command:

  ```powershell
  ./Get-GitHubIssuesAndPullRequests.ps1
  ```
  
  To filter by one or more labels, use the `-labels` parameter:
  
  ```pwsh  
  ./Get-GitHubIssuesAndPullRequests.ps1 -labels "bug","enhancement"
  ```

  ```pwsh  
  $labels = @("Needs: Triage :mag:", "Needs: Attention :wave:", "Needs: Immediate Attention :bangbang:")
  ./Get-GitHubIssuesAndPullRequests.ps1 -labels $labels
  ```
  
  To order by created or updated dates, use the `-orderBy` parameter:
  
  ```pwsh
  ./Get-GitHubIssuesAndPullRequests.ps1 -orderBy "created"
  ```
  
  ```pwsh
  ./Get-GitHubIssuesAndPullRequests.ps1 -orderBy "updated"
  ```

  To add additional repositories not in the watch list and only see issues and pull requests assigned to you, use the `-repositories` and `-repositoriesToFilterIssuesByAssigned` parameters:

  ```pwsh
  $labels = @("Needs: Triage :mag:", "Needs: Attention :wave:", "Needs: Immediate Attention :bangbang:")
  $additionalRepositories = @("Azure/bicep-registry-modules")  # Additional repositories to include in the output
  $repositoriesToFilterIssuesByAssigned = @("Azure/bicep-registry-modules")  # Repositories to filter issues and pull requests by assigned to me
  ./Get-GitHubIssuesAndPullRequests.ps1 `
    -labels $labels `
    -repositories $additionalRepositories `
    -repositoriesToFilterIssuesByAssigned $repositoriesToFilterIssuesByAssigned
  ```

## Create a shortcut to run the script directly (Windows)

1. Create scripts that generates the output you need. See the examples in the `examples` folder.

    Examples:
  
    ```pwsh
    Write-Host "Getting All Open Issues and Pull Requests"
    /Users/myuser/Code/github-relevant-issues-and-pull-requests/Get-GitHubIssuesAndPullRequests.ps1
    Read-Host -Prompt "Press any key to exit"
    ```
  
    ```powershell
    Write-Host "Getting Open Issues and Pull Requests Requiring Triage or Attention"
    $labels = @("Needs: Triage :mag:", "Needs: Attention :wave:", "Needs: Immediate Attention :bangbang:")
    /Users/myuser/Code/github-relevant-issues-and-pull-requests/Get-GitHubIssuesAndPullRequests.ps1 -labels $labels
    Read-Host -Prompt "Press any key to exit"
    ```
  
1. Create a shortcut that executes the PowerShell. Right-click on the desktop and select `New` -> `Shortcut`.
1. Enter a target that looks like the following:

    ```text
    pwsh -command "& 'C:\Users\myuser\Code\Get-IssuesAndPullRequestsNeedingTriage.ps1'"
    ```

1. Give the shortcut a name and click `Finish`.
1. Now you can double-click the shortcut to run the script or add it to your taskbar.
