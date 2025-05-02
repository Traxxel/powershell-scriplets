<#
.SYNOPSIS
    Listet Teams, deren Kanäle und Owner auf und zeigt die Kanälnutzung an.

.DESCRIPTION
    Dieses Skript verbindet sich mit Microsoft Teams und listet alle Teams in der Organisation auf.
    Für jedes Team werden die Owner und Kanäle angezeigt, sowie die Aktivität der Kanäle überprüft.

.PARAMETER max
    Maximale Anzahl der anzuzeigenden Teams. Standardmäßig werden alle Teams angezeigt.

.PARAMETER help
    Zeigt diese Hilfe an.

.EXAMPLE
    .\teams-list-channelowners.ps1
    Zeigt alle Teams und deren Details an.

.EXAMPLE
    .\teams-list-channelowners.ps1 --max 5
    Zeigt nur die ersten 5 Teams an.

.EXAMPLE
    .\teams-list-channelowners.ps1 --help
    Zeigt diese Hilfe an.
#>

param(
    [Parameter()]
    [int]$max = 0,  # Standardwert 0 bedeutet alle Teams
    
    [Parameter()]
    [switch]$help
)

# Hilfe anzeigen, wenn --help angegeben wurde
if ($help) {
    Get-Help $PSCommandPath -Detailed
    exit
}

Write-Host "Teams-Kanal-Analyse wird gestartet..." -ForegroundColor Green

# Prüfen, ob die benötigten Module installiert sind
Write-Host "`nPrüfe benötigte Module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Write-Host "Microsoft Teams PowerShell-Modul wird installiert..." -ForegroundColor Yellow
    Install-Module -Name MicrosoftTeams -Force -AllowClobber
    Write-Host "Microsoft Teams PowerShell-Modul wurde installiert." -ForegroundColor Green
} else {
    Write-Host "Microsoft Teams PowerShell-Modul ist bereits installiert." -ForegroundColor Green
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft Graph PowerShell-Modul wird installiert..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
    Write-Host "Microsoft Graph PowerShell-Modul wurde installiert." -ForegroundColor Green
} else {
    Write-Host "Microsoft Graph PowerShell-Modul ist bereits installiert." -ForegroundColor Green
}

# Module importieren
Write-Host "`nImportiere Module..." -ForegroundColor Yellow
if (-not (Get-Module -Name MicrosoftTeams)) {
    Write-Host "Lade Microsoft Teams PowerShell-Modul..." -ForegroundColor Gray
    Import-Module MicrosoftTeams -DisableNameChecking
    Write-Host "Microsoft Teams PowerShell-Modul wurde geladen." -ForegroundColor Green
} else {
    Write-Host "Microsoft Teams PowerShell-Modul ist bereits geladen." -ForegroundColor Green
}

if (-not (Get-Module -Name Microsoft.Graph)) {
    Write-Host "Lade Microsoft Graph PowerShell-Modul..." -ForegroundColor Gray
    Import-Module Microsoft.Graph -DisableNameChecking
    Write-Host "Microsoft Graph PowerShell-Modul wurde geladen." -ForegroundColor Green
} else {
    Write-Host "Microsoft Graph PowerShell-Modul ist bereits geladen." -ForegroundColor Green
}

# Verbindung zu Teams und Graph herstellen
Write-Host "`nStelle Verbindung zu Teams und Graph her..." -ForegroundColor Yellow

# Prüfe Teams-Verbindung
try {
    $teamsContext = Get-Team
    Write-Host "Bestehende Teams-Verbindung gefunden." -ForegroundColor Green
} catch {
    Write-Host "Stelle neue Teams-Verbindung her..." -ForegroundColor Yellow
    Connect-MicrosoftTeams
    Write-Host "Verbindung zu Teams hergestellt." -ForegroundColor Green
}

# Prüfe Graph-Verbindung
try {
    $graphContext = Get-MgContext
    if ($graphContext) {
        Write-Host "Bestehende Graph-Verbindung gefunden." -ForegroundColor Green
        # Prüfe, ob alle benötigten Scopes vorhanden sind
        $requiredScopes = @("User.Read.All", "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All")
        $missingScopes = $requiredScopes | Where-Object { $_ -notin $graphContext.Scopes }
        if ($missingScopes) {
            Write-Host "Ergänze fehlende Berechtigungen..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes $requiredScopes
        }
    } else {
        Write-Host "Stelle neue Graph-Verbindung her..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "User.Read.All", "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All"
    }
    Write-Host "Graph-Verbindung ist bereit." -ForegroundColor Green
} catch {
    Write-Host "Stelle neue Graph-Verbindung her..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "User.Read.All", "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All"
    Write-Host "Verbindung zu Graph hergestellt." -ForegroundColor Green
}

# Alle Teams abrufen
Write-Host "`nRufe Teams-Informationen ab..." -ForegroundColor Yellow
$teams = Get-Team

# Begrenze die Anzahl der Teams, falls gewünscht
if ($max -gt 0) {
    Write-Host "Zeige nur die ersten $max Teams an..." -ForegroundColor Yellow
    $teams = $teams | Select-Object -First $max
}

$teamCount = $teams.Count
Write-Host "`nVerarbeite $teamCount Teams..." -ForegroundColor Green

# Für jedes Team die Kanäle abrufen
$currentTeam = 0
foreach ($team in $teams) {
    $currentTeam++
    Write-Host "`nVerarbeite Team $currentTeam von $teamCount" -ForegroundColor Cyan
    Write-Host "Team: $($team.DisplayName)"
    Write-Host "Team ID: $($team.GroupId)"
    
    # Team-Owner abrufen
    Write-Host "Rufe Team-Owner ab..." -ForegroundColor Gray
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
    Write-Host "Team-Owner:"
    foreach ($owner in $owners) {
        Write-Host "  - $($owner.User)"
    }
    
    Write-Host "Rufe Kanäle ab..." -ForegroundColor Gray
    $channels = Get-TeamChannel -GroupId $team.GroupId
    Write-Host "Kanäle:"
    foreach ($channel in $channels) {
        Write-Host "  - $($channel.DisplayName)"
        
        # Kanälnutzung überprüfen
        try {
            Write-Host "    Prüfe Kanälnutzung..." -ForegroundColor Gray
            $messages = Get-MgTeamChannelMessage -TeamId $team.GroupId -ChannelId $channel.Id -Top 1
            $files = Get-MgTeamChannelFileFolder -TeamId $team.GroupId -ChannelId $channel.Id
            
            if ($messages -or $files) {
                Write-Host "    * Aktiv: Ja"
                if ($messages) { 
                    $lastMessage = $messages[0]
                    Write-Host "      - Letzte Nachricht: $($lastMessage.CreatedDateTime)"
                }
                if ($files) { 
                    Write-Host "      - Enthält Dateien"
                }
            } else {
                Write-Host "    * Aktiv: Nein"
            }
        } catch {
            Write-Host "    * Aktiv: Unbekannt (Fehler beim Abrufen der Daten)"
        }
    }
}

Write-Host "`nVerbindung wird getrennt..." -ForegroundColor Yellow
# Verbindung trennen
Disconnect-MicrosoftTeams
Disconnect-MgGraph

Write-Host "`nAnalyse abgeschlossen!" -ForegroundColor Green