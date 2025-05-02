# Teams Channel Owner Analysis Script

This PowerShell script analyzes Microsoft Teams channels and their owners, providing detailed information about team structure and channel usage.

## Features

- Lists all teams in your organization
- Shows team owners for each team
- Displays all channels within each team
- Checks channel activity (messages and files)
- Shows last message date for active channels
- Provides detailed progress information during execution

## Prerequisites

- PowerShell 7 or later
- Microsoft Teams PowerShell module
- Microsoft Graph PowerShell module
- Appropriate permissions in Microsoft Teams and Microsoft Graph

## Installation

The script will automatically install the required PowerShell modules if they are not already present on your system.

## Usage

```powershell
.\teams-list-channelowners.ps1 [--max <number>] [--help]
```

### Parameters

- `--max <number>`: Limits the number of teams to display. By default, all teams are shown.
- `--help`: Displays detailed help information about the script.

### Examples

Show all teams and their details:
```powershell
.\teams-list-channelowners.ps1
```

Show only the first 5 teams:
```powershell
.\teams-list-channelowners.ps1 --max 5
```

Display help information:
```powershell
.\teams-list-channelowners.ps1 --help
```

## Output

The script provides detailed information about:
- Team names and IDs
- Team owners
- Channel names
- Channel activity status
- Last message dates
- File presence in channels

## Progress Information

The script shows detailed progress information during execution:
- Module installation and loading
- Connection status to Teams and Graph
- Team processing progress
- Channel analysis status

## Color Coding

- Green: Success messages and completion information
- Yellow: Important process steps
- Gray: Detailed information
- Cyan: Team progress information

## Notes

- The script requires appropriate permissions in Microsoft Teams and Microsoft Graph
- First-time execution may take longer due to module installation
- The script will automatically handle module updates and missing permissions 