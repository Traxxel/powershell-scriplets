<#
.SYNOPSIS
    Lists Teams, their channels and owners and shows channel usage.

.DESCRIPTION
    This script connects to Microsoft Teams and lists all teams in the organization.
    For each team, it displays the owners and channels, and checks channel activity.

.PARAMETER max
    Maximum number of teams to display. By default, all teams are shown.

.PARAMETER help
    Shows this help information.

.EXAMPLE
    .\teams-list-channelowners.ps1
    Shows all teams and their details.

.EXAMPLE
    .\teams-list-channelowners.ps1 --max 5
    Shows only the first 5 teams.

.EXAMPLE
    .\teams-list-channelowners.ps1 --help
    Shows this help information.
#>

param(
    [Parameter()]
    [int]$max = 0,  # Default value 0 means all teams
    
    [Parameter()]
    [switch]$help
)

# Show help if --help was specified
if ($help) {
    Get-Help $PSCommandPath -Detailed
    exit
}

Write-Host "Starting Teams Channel Analysis..." -ForegroundColor Green

# Check if required modules are installed
Write-Host "`nChecking required modules..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Write-Host "Installing Microsoft Teams PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name MicrosoftTeams -Force -AllowClobber
    Write-Host "Microsoft Teams PowerShell module installed." -ForegroundColor Green
} else {
    Write-Host "Microsoft Teams PowerShell module already installed." -ForegroundColor Green
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft Graph PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
    Write-Host "Microsoft Graph PowerShell module installed." -ForegroundColor Green
} else {
    Write-Host "Microsoft Graph PowerShell module already installed." -ForegroundColor Green
}

# Import modules
Write-Host "`nImporting modules..." -ForegroundColor Yellow
if (-not (Get-Module -Name MicrosoftTeams)) {
    Write-Host "Loading Microsoft Teams PowerShell module..." -ForegroundColor Gray
    Import-Module MicrosoftTeams -DisableNameChecking
    Write-Host "Microsoft Teams PowerShell module loaded." -ForegroundColor Green
} else {
    Write-Host "Microsoft Teams PowerShell module already loaded." -ForegroundColor Green
}

# Connect to Teams
Write-Host "`nEstablishing connection to Teams..." -ForegroundColor Yellow
try {
    $teamsContext = Get-Team
    Write-Host "Existing Teams connection found." -ForegroundColor Green
} catch {
    Write-Host "Establishing new Teams connection..." -ForegroundColor Yellow
    Connect-MicrosoftTeams
    Write-Host "Connected to Teams." -ForegroundColor Green
}

# Connect to Graph only when needed
Write-Host "`nEstablishing Graph connection..." -ForegroundColor Yellow
try {
    $graphContext = Get-MgContext
    if (-not $graphContext) {
        Write-Host "Establishing new Graph connection..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "User.Read.All", "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All"
    }
    Write-Host "Graph connection ready." -ForegroundColor Green
} catch {
    Write-Host "Establishing new Graph connection..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "User.Read.All", "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All"
    Write-Host "Connected to Graph." -ForegroundColor Green
}

# Get all teams
Write-Host "`nRetrieving team information..." -ForegroundColor Yellow
$teams = Get-Team

# Limit number of teams if requested
if ($max -gt 0) {
    Write-Host "Showing only the first $max teams..." -ForegroundColor Yellow
    $teams = $teams | Select-Object -First $max
}

$teamCount = $teams.Count
Write-Host "`nProcessing $teamCount teams..." -ForegroundColor Green

# Process teams in parallel
$teams | ForEach-Object -Parallel {
    $team = $_
    $teamCount = $using:teamCount
    $teamIndex = [array]::IndexOf($using:teams, $team) + 1
    
    Write-Host "`nProcessing Team $teamIndex of $teamCount" -ForegroundColor Cyan
    Write-Host "Team: $($team.DisplayName)"
    Write-Host "Team ID: $($team.GroupId)"
    
    # Get team owners
    Write-Host "Retrieving team owners..." -ForegroundColor Gray
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
    Write-Host "Team Owners:"
    foreach ($owner in $owners) {
        Write-Host "  - $($owner.User)"
    }
    
    Write-Host "Retrieving channels..." -ForegroundColor Gray
    $channels = Get-TeamChannel -GroupId $team.GroupId
    Write-Host "Channels:"
    foreach ($channel in $channels) {
        Write-Host "  - $($channel.DisplayName)"
        
        # Check channel usage
        try {
            Write-Host "    Checking channel usage..." -ForegroundColor Gray
            try {
                $messages = Get-MgTeamChannelMessage -TeamId $team.GroupId -ChannelId $channel.Id -Top 1 -ErrorAction SilentlyContinue
            } catch {
                $messages = $null
            }
            try {
                $files = Get-MgTeamChannelFileFolder -TeamId $team.GroupId -ChannelId $channel.Id -ErrorAction SilentlyContinue
            } catch {
                $files = $null
            }
            
            if ($messages -or $files) {
                Write-Host "    * Active: Yes"
                if ($messages) { 
                    $lastMessage = $messages[0]
                    Write-Host "      - Last message: $($lastMessage.CreatedDateTime)"
                }
                if ($files) { 
                    Write-Host "      - Contains files"
                }
            } else {
                Write-Host "    * Active: No"
            }
        } catch {
            Write-Host "    * Active: Unknown (Error retrieving data)"
        }
    }
} -ThrottleLimit 5

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
# Disconnect
Disconnect-MicrosoftTeams
Disconnect-MgGraph

Write-Host "`nAnalysis completed!" -ForegroundColor Green