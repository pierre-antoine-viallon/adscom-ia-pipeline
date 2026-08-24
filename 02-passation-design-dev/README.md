# Passation design-dev

Bascule entre la phase Design (Claude, `01-design/`) et la phase Développement (Copilot, `03-developpement/`). **Autonome vis-à-vis de `01-design`** : `spec` n'exige aucun skill Claude en amont, seulement un accès Figma via MCP — voir `spec.md`.

## `agents/spec.md` — IA Spec

Agent Copilot qui génère le **Design Manifest** : artefact structuré (`index.json` + `pages/<slug>.json` + `tokens.json`) servant de source de vérité figée (write-once) pour toute la phase Développement — pages, sections, contenu complet, ordre de mise en page, correspondance des tokens de design (dérivée directement de Figma, pas d'un skill Claude en amont).

Voir `PIPELINE-AGENTIQUE.md` §2 et §9 à la racine du repo pour le détail (décision Option A write-once, séparation avec le journal d'exécution de l'Orchestrator).

## `agents/sds-bootstrap.md`

Agent Copilot qui applique `tokens.json` aux variables Sass natives de Bootstrap 5 et produit `design-manifest/_variables.scss` — un livrable préparé, appliqué au vrai thème seulement plus tard par `init` (Développement) : il produit du code (pas un artefact de maquette), donc relève de la Passation par le même principe que le reste de la répartition Claude/Copilot (voir `PIPELINE-AGENTIQUE.md` §1).

**État actuel : rédigé (2026-08-24), pas encore validé sur un vrai projet.** Contenu écrit en autonomie à partir des décisions de `PIPELINE-AGENTIQUE.md` — à relire et ajuster à l'usage, en particulier le format exact `tools`/`mcpServers` (identifiants d'outils Copilot non confirmés précisément à la rédaction).
