<#
.SYNOPSIS
    Installe les skills Claude Code et les agents Copilot d'adscom-ia-pipeline
    dans un projet WordPress consommateur.

.DESCRIPTION
    Clone temporairement adscom-ia-pipeline, aplatit 01-design/*/ vers
    .claude/skills/, fusionne les agents/*.md de 02-passation-design-dev/ et
    03-developpement/ vers .github/agents/, puis nettoie le clone temporaire.
    Le resultat (fichiers plats) doit ensuite etre committe normalement dans
    le repo du projet consommateur.

.PARAMETER Ref
    Branche ou tag a installer. Par defaut : main.

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

$tmp = Join-Path $env:TEMP ("adscom-ia-pipeline-" + [guid]::NewGuid())
Write-Host "Clonage de $RepoUrl@$Ref dans $tmp..."
git clone --quiet --depth 1 --branch $Ref $RepoUrl $tmp

try {
    $skillsDest = Join-Path $ProjectRoot ".claude\skills"
    $agentsDest = Join-Path $ProjectRoot ".github\agents"
    New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
    New-Item -ItemType Directory -Force -Path $agentsDest | Out-Null

    Write-Host "Copie des skills Claude Code (01-design/) vers $skillsDest ..."
    Get-ChildItem (Join-Path $tmp "01-design") -Directory | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $skillsDest $_.Name) -Recurse -Force
    }

    Write-Host "Fusion des agents Copilot vers $agentsDest ..."
    foreach ($phase in "02-passation-design-dev", "03-developpement") {
        $agentsSrc = Join-Path $tmp "$phase\agents"
        if (Test-Path $agentsSrc) {
            Get-ChildItem $agentsSrc -Filter "*.md" | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $agentsDest $_.Name) -Force
            }
        }
    }

    $commit = (git -C $tmp rev-parse --short HEAD).Trim()
    $marker = "source: $RepoUrl@$Ref (commit $commit, installe le $(Get-Date -Format s))"
    Set-Content -Path (Join-Path $skillsDest ".source-version") -Value $marker -Encoding utf8

    Write-Host ""
    Write-Host "Installe depuis $Ref (commit $commit)."
    Write-Host "Verifiez le diff (git status) puis committez .claude/skills/ et .github/agents/."
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
