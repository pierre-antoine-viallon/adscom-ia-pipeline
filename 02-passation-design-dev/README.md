# Passation design-dev

Bascule entre la phase Design (Claude, `01-design/`) et la phase Développement (Copilot, `03-developpement/`).

## `agents/spec.md` — IA Spec

Agent Copilot qui génère le **Design Manifest** : artefact structuré (`index.json` + `pages/<slug>.json` + `tokens.json`) servant de source de vérité figée (write-once) pour toute la phase Développement — pages, sections, contenu complet, ordre de mise en page, tokens de design.

Voir `PIPELINE-AGENTIQUE.md` §2 et §9 à la racine du repo pour le détail (décision Option A write-once, séparation avec le journal d'exécution de l'Orchestrator).

**État actuel : stub, contenu comportemental pas encore rédigé.**
