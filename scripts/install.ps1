<#
.SYNOPSIS
    Installe ou met a jour le submodule agents/_pipeline-repo, puis aplatit
    les skills Claude Code et les agents Copilot dans un projet WordPress
    consommateur.

.DESCRIPTION
    Ajoute (ou synchronise) adscom-ia-pipeline comme submodule Git en
    agents/_pipeline-repo, aplatit 01-design/*/ vers .claude/skills/,
    fusionne les agents/*.md de 02-passation-design-dev/ et
    03-developpement/ vers .github/agents/, cree agents/design-manifest/
    et agents/journal.ndjson s'ils n'existent pas encore, et copie
    03-developpement/reference-blocks/ vers agents/reference-blocks/ lors
    de la toute premiere installation (jamais ecrase ensuite).
    Le resultat (submodule + fichiers plats) doit ensuite etre committe
    normalement dans le repo du projet consommateur.

.PARAMETER Ref
    Branche, tag ou commit a installer. Par defaut : main.

.PARAMETER RepoUrl
    URL du repo source. Par defaut : adscom-ia-pipeline sur GitHub.

.PARAMETER ProjectRoot
    Racine du projet consommateur. Par defaut : repertoire courant.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Ref v1.2.0
#>

param(
    [string]$Ref = "main",
    [string]$RepoUrl = "https://github.com/pierre-antoine-viallon/adscom-ia-pipeline.git",
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

$pipelineRepo = Join-Path $ProjectRoot "agents\_pipeline-repo"

if (Test-Path (Join-Path $pipelineRepo ".git")) {
    Write-Host "Submodule agents/_pipeline-repo existant, mise a jour vers $Ref..."
    git -C $pipelineRepo fetch --quiet origin $Ref
    git -C $pipelineRepo checkout --quiet FETCH_HEAD
}
else {
    Write-Host "Ajout du submodule agents/_pipeline-repo ($RepoUrl@$Ref)..."
    New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot "agents") | Out-Null
    git -C $ProjectRoot submodule add --quiet $RepoUrl "agents/_pipeline-repo"
    git -C $pipelineRepo fetch --quiet origin $Ref
    git -C $pipelineRepo checkout --quiet FETCH_HEAD
}

$skillsDest = Join-Path $ProjectRoot ".claude\skills"
$agentsDest = Join-Path $ProjectRoot ".github\agents"
New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
New-Item -ItemType Directory -Force -Path $agentsDest | Out-Null

Write-Host "Copie des skills Claude Code (01-design/) vers $skillsDest ..."
Get-ChildItem (Join-Path $pipelineRepo "01-design") -Directory | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $skillsDest $_.Name) -Recurse -Force
}

Write-Host "Fusion des agents Copilot vers $agentsDest ..."
foreach ($phase in "02-passation-design-dev", "03-developpement") {
    $agentsSrc = Join-Path $pipelineRepo "$phase\agents"
    if (Test-Path $agentsSrc) {
        Get-ChildItem $agentsSrc -Filter "*.md" | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $agentsDest $_.Name) -Force
        }
    }
}

Write-Host "Preparation de agents/design-manifest/ et agents/journal.ndjson ..."
$manifestDest = Join-Path $ProjectRoot "agents\design-manifest"
New-Item -ItemType Directory -Force -Path $manifestDest | Out-Null
$manifestKeep = Join-Path $manifestDest ".gitkeep"
if (-not (Test-Path $manifestKeep)) {
    New-Item -ItemType File -Path $manifestKeep | Out-Null
}
$journalPath = Join-Path $ProjectRoot "agents\journal.ndjson"
if (-not (Test-Path $journalPath)) {
    New-Item -ItemType File -Path $journalPath | Out-Null
}

$refBlocksSrc = Join-Path $pipelineRepo "03-developpement\reference-blocks"
$refBlocksDest = Join-Path $ProjectRoot "agents\reference-blocks"
if ((Test-Path $refBlocksSrc) -and -not (Test-Path $refBlocksDest)) {
    Write-Host "Copie initiale de reference-blocks/ vers $refBlocksDest ..."
    Copy-Item $refBlocksSrc $refBlocksDest -Recurse
}
else {
    Write-Host "agents/reference-blocks/ deja present, non ecrase (alimente le contenu manuellement)."
}

$commit = (git -C $pipelineRepo rev-parse --short HEAD).Trim()
Write-Host ""
Write-Host "Installe depuis $Ref (commit $commit)."
Write-Host "Verifiez le diff (git status) puis committez agents/, .claude/skills/, .github/agents/ et .gitmodules."
