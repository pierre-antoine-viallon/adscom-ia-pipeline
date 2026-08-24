# CLAUDE.md

Ce fichier guide Claude Code (claude.ai/code) lors du travail dans ce repo.

## Objet du projet

Pipeline de production agentique ads-COM pour des sites WordPress (Drupal en second temps), organisé en 4 dossiers de phase : `00-setup`, `01-design`, `02-passation-design-dev`, `03-developpement`. Successeur de `figma-mcp-claude-skills` pour les nouveaux projets — voir `PIPELINE-AGENTIQUE.md` pour l'architecture complète et l'historique des décisions.

**Ce repo lui-même n'est pas un projet WordPress.** Il héberge des modèles de référence (skills Claude Code, agents Copilot) installés dans un projet consommateur via `scripts/install.ps1`/`.sh` — jamais exécutés directement depuis ce repo.

## Structure

- `01-design/<nn-nom>/SKILL.md` — 16 skills Claude Code, identiques à `figma-mcp-claude-skills`, invoqués via `/<nn-nom>` une fois installés à plat dans `.claude/skills/` d'un projet. **Ne jamais imbriquer davantage** : la découverte Claude Code n'est pas récursive.
- `02-passation-design-dev/agents/spec.md` et `03-developpement/agents/*.md` — modèles d'agents GitHub Copilot (frontmatter YAML `name`/`description`/`prompt`/`tools`/`mcpServers`), installés dans `.github/agents/` d'un projet.
- `scripts/install.ps1`, `scripts/install.sh` — mécanisme d'installation (clone temporaire + copie/aplatissement + marqueur `.source-version`, voir `README.md`).

## Règle absolue : ne jamais modifier `figma-mcp-claude-skills`

Ce repo est un successeur, pas un remplacement rétroactif. `figma-mcp-claude-skills` reste la source de vérité pour les projets déjà installés dessus (RJAC, CC4V, Neoville, TPbCCI45) — aucune action dessus depuis ce repo, jamais.

## Authoring — Skills (`01-design/`)

Un `SKILL.md` est un fichier prompt Markdown chargé à l'invocation de la slash command. Structure attendue :
1. **Rôle** — une phrase définissant ce que fait le skill et ce qu'il ne fait pas
2. **Déclenchement** — quelles phrases ou commandes l'activent
3. **Comportement** — étapes numérotées avec scripts `use_figma` si applicable
4. **Format de sortie** — template Markdown du rapport ou fichier produit
5. **Règles de conduite** — garde-fous (lecture seule, confirmation, limites de lot)

Tous lisent `brief-projet.md` à la racine du projet consommateur comme source de vérité partagée.

## Authoring — Agents Copilot (`02-passation-design-dev/agents/`, `03-developpement/agents/`)

Fichier Markdown avec frontmatter YAML : `name`, `description` (utilisée pour la sélection automatique par l'agent parent), `prompt` (prompt système), `tools` (liste, `null`/omis = tous), `mcpServers` (serveurs MCP propres à cet agent). Contexte d'exécution isolé par agent — voir `PIPELINE-AGENTIQUE.md` §1 et §9 pour le rôle de chacun.

**État actuel : les 6 fichiers sont des stubs.** Ne pas inventer de contenu comportemental (prompt système détaillé, restrictions d'outils précises) sans validation explicite — même règle que celle qui a retardé leur rédaction lors de la conception initiale.

## Conventions de classification

| Propriété | Valeurs |
|---|---|
| **Mode Figma / navigateur** | Lecture seule / Écriture (canvas ou WordPress) / Aucun |
| **Sortie** | Rapport Markdown / Fichier SCSS / Assets WebP / Modifications canvas ou code |
| **Confirmation requise** | Oui pour toute écriture canvas/code (skills 08/10, tous les agents Copilot en Développement) |
| **Source de vérité consommée** | `brief-projet.md` (tous) + Design Manifest (agents Copilot) + rapports des skills précédents |
