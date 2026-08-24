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

**État actuel : tous en stub, contenu comportemental (prompt système, `tools`, `mcpServers`) pas encore rédigé.**
