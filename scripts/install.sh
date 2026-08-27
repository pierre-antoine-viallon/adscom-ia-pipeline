#!/usr/bin/env bash
# Installe ou met a jour le submodule agents/_pipeline-repo, puis aplatit
# les skills Claude Code et les agents Copilot dans un projet WordPress
# consommateur.
#
# Ajoute (ou synchronise) adscom-ia-pipeline comme submodule Git en
# agents/_pipeline-repo, aplatit 01-design/*/ vers .claude/skills/,
# fusionne les agents/*.md de 02-passation-design-dev/ et
# 03-developpement/ vers .github/agents/, cree agents/design-manifest/
# et agents/journal.ndjson s'ils n'existent pas encore, et copie
# 03-developpement/reference-blocks/ vers agents/reference-blocks/ lors
# de la toute premiere installation (jamais ecrase ensuite).
# Le resultat (submodule + fichiers plats) doit ensuite etre committe
# normalement dans le repo du projet consommateur.
#
# Usage :
#   ./install.sh
#   ./install.sh --ref v1.2.0
#   ./install.sh --ref main --project-root /chemin/vers/projet

set -euo pipefail

REF="main"
REPO_URL="https://github.com/pierre-antoine-viallon/adscom-ia-pipeline.git"
PROJECT_ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --repo-url) REPO_URL="$2"; shift 2 ;;
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    *) echo "Argument inconnu : $1" >&2; exit 1 ;;
  esac
done

# git refuse d'operer sur un depot dont il ne "possede" pas le dossier
# (partages reseau, //wsl$/, volumes montes...). Exception ciblee plutot
# que de laisser le script echouer a mi-parcours.
add_git_safe_directory() {
  local abs
  abs="$(cd "$1" 2>/dev/null && pwd)" || return 0
  if ! git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$abs"; then
    git config --global --add safe.directory "$abs" 2>/dev/null || true
  fi
}

add_git_safe_directory "$PROJECT_ROOT"

PIPELINE_REPO="$PROJECT_ROOT/agents/_pipeline-repo"

if [[ -d "$PIPELINE_REPO/.git" ]]; then
  echo "Submodule agents/_pipeline-repo existant, mise a jour vers $REF..."
  add_git_safe_directory "$PIPELINE_REPO"
  git -C "$PIPELINE_REPO" fetch --quiet origin "$REF"
  git -C "$PIPELINE_REPO" checkout --quiet FETCH_HEAD
else
  echo "Ajout du submodule agents/_pipeline-repo ($REPO_URL@$REF)..."
  mkdir -p "$PROJECT_ROOT/agents"
  git -C "$PROJECT_ROOT" submodule add --quiet "$REPO_URL" "agents/_pipeline-repo"
  add_git_safe_directory "$PIPELINE_REPO"
  git -C "$PIPELINE_REPO" fetch --quiet origin "$REF"
  git -C "$PIPELINE_REPO" checkout --quiet FETCH_HEAD
fi

SKILLS_DEST="$PROJECT_ROOT/.claude/skills"
AGENTS_DEST="$PROJECT_ROOT/.github/agents"
mkdir -p "$SKILLS_DEST" "$AGENTS_DEST"

echo "Copie des skills Claude Code (01-design/) vers $SKILLS_DEST ..."
for skill_dir in "$PIPELINE_REPO"/01-design/*/; do
  name="$(basename "$skill_dir")"
  # Purge prealable pour une resync propre (parite avec install.ps1, ou
  # Copy-Item -Recurse imbriquerait XX/XX au 2e passage).
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -r "$skill_dir" "$SKILLS_DEST/$name"
done

echo "Fusion des agents Copilot vers $AGENTS_DEST ..."
for phase in "02-passation-design-dev" "03-developpement"; do
  agents_src="$PIPELINE_REPO/$phase/agents"
  if [[ -d "$agents_src" ]]; then
    cp "$agents_src"/*.md "$AGENTS_DEST/" 2>/dev/null || true
  fi
done

echo "Preparation de agents/design-manifest/ et agents/journal.ndjson ..."
MANIFEST_DEST="$PROJECT_ROOT/agents/design-manifest"
mkdir -p "$MANIFEST_DEST"
[[ -f "$MANIFEST_DEST/.gitkeep" ]] || touch "$MANIFEST_DEST/.gitkeep"
JOURNAL_PATH="$PROJECT_ROOT/agents/journal.ndjson"
[[ -f "$JOURNAL_PATH" ]] || touch "$JOURNAL_PATH"

# Le projet consommateur est generalement servi sous Linux : forcer LF pour
# eviter d'introduire des CRLF dans le SCSS/PHP/JS depuis un poste Windows.
GITATTRIBUTES="$PROJECT_ROOT/.gitattributes"
if [[ ! -f "$GITATTRIBUTES" ]]; then
  printf '* text=auto eol=lf\n' > "$GITATTRIBUTES"
  echo "Cree .gitattributes (eol=lf)."
fi

REFBLOCKS_SRC="$PIPELINE_REPO/03-developpement/reference-blocks"
REFBLOCKS_DEST="$PROJECT_ROOT/agents/reference-blocks"
if [[ -d "$REFBLOCKS_SRC" && ! -d "$REFBLOCKS_DEST" ]]; then
  echo "Copie initiale de reference-blocks/ vers $REFBLOCKS_DEST ..."
  cp -r "$REFBLOCKS_SRC" "$REFBLOCKS_DEST"
else
  echo "agents/reference-blocks/ deja present, non ecrase (alimente le contenu manuellement)."
fi

COMMIT="$(git -C "$PIPELINE_REPO" rev-parse --short HEAD 2>/dev/null || true)"
echo ""
if [[ -z "$COMMIT" ]]; then
  COMMIT="inconnu"
  echo "AVERTISSEMENT : impossible de lire le commit du submodule (git -C a echoue)." >&2
  echo "Si le message parlait de 'dubious ownership', lancer :" >&2
  echo "  git config --global --add safe.directory <chemin-absolu-du-projet>" >&2
fi
echo "Installe depuis $REF (commit $COMMIT)."
echo "Verifiez le diff (git status) puis committez agents/, .claude/skills/, .github/agents/, .gitattributes et .gitmodules."
