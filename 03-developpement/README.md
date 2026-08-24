# Développement

Init → Contribution → Theming, piloté par l'Orchestrator (agent Copilot, routeur déterministe). Voir `PIPELINE-AGENTIQUE.md` à la racine du repo pour l'architecture complète (§1, §3, §4, §7, §8, §9).

## `agents/`

| Fichier | Rôle |
|---|---|
| `orchestrator.md` | Lance le bon agent selon l'étape courante, gère les boucles (plafond 4 itérations/unité, non-convergence), journalise les actions, décide quand solliciter l'humain |
| `init.md` | Initialise le socle WordPress (starterkit, CPT, plugins) |
| `contrib.md` | Contribution Gutenberg par page, priorité aux blocs natifs |
| `reviewer.md` | Vérifie la conformité (Contribution : cohérence/zoning ; Theming : fidélité maquette, responsive, RGAA, perf) — verdict classé `APPROVED`/`DEV_FIX`/`CONTRIB_FIX`/`HUMAN_REVIEW` |
| `dev.md` | Theming bloc par bloc en itération avec la maquette (MCP Figma) |

**État actuel : rédigé (2026-08-24), pas encore validé sur un vrai projet.** Décision prise en autonomie pendant la rédaction : `reviewer` est **un seul agent à deux modes** (Contribution/Theming, checklist choisie selon la phase transmise par l'Orchestrator) plutôt que deux agents séparés — à confirmer ou revoir à l'usage. Format exact `tools`/`mcpServers` à ajuster (identifiants d'outils Copilot non confirmés précisément à la rédaction).
