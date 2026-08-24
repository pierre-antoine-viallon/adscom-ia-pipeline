#!/usr/bin/env bash
# Installe les skills Claude Code et les agents Copilot d'adscom-ia-pipeline
# dans un projet WordPress consommateur.
#
# Clone temporairement adscom-ia-pipeline, aplatit 01-design/*/ vers
# .claude/skills/, fusionne les agents/*.md de 02-passation-design-dev/ et
# 03-developpement/ vers .github/agents/, puis nettoie le clone temporaire.
# Le resultat (fichiers plats) doit ensuite etre committe normalement dans
# le repo du projet consommateur.
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

TMP_DIR="$(mktemp -d -t adscom-ia-pipeline-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Clonage de $REPO_URL@$REF dans $TMP_DIR..."
git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$TMP_DIR"

SKILLS_DEST="$PROJECT_ROOT/.claude/skills"
AGENTS_DEST="$PROJECT_ROOT/.github/agents"
mkdir -p "$SKILLS_DEST" "$AGENTS_DEST"

echo "Copie des skills Claude Code (01-design/) vers $SKILLS_DEST ..."
for skill_dir in "$TMP_DIR"/01-design/*/; do
  name="$(basename "$skill_dir")"
  cp -r "$skill_dir" "$SKILLS_DEST/$name"
done

echo "Fusion des agents Copilot vers $AGENTS_DEST ..."
for phase in "02-passation-design-dev" "03-developpement"; do
  agents_src="$TMP_DIR/$phase/agents"
  if [[ -d "$agents_src" ]]; then
    cp "$agents_src"/*.md "$AGENTS_DEST/" 2>/dev/null || true
  fi
done

COMMIT="$(git -C "$TMP_DIR" rev-parse --short HEAD)"
echo "source: $REPO_URL@$REF (commit $COMMIT, installe le $(date -Iseconds))" > "$SKILLS_DEST/.source-version"

echo ""
echo "Installe depuis $REF (commit $COMMIT)."
echo "Verifiez le diff (git status) puis committez .claude/skills/ et .github/agents/."
