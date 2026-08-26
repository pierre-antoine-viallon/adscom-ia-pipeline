# 01-design

16 skills Claude Code de la phase Design (Figma), identiques à ceux de [`figma-mcp-claude-skills`](https://github.com/pierre-antoine-viallon/figma-mcp-claude-skills). Un dossier = un skill = une slash command exacte (préfixe numérique inclus, ex. `/00-brief-onboarding`). Détail complet, ordre d'exécution et table Lecture/Écriture : voir le `README.md` à la racine du repo.

| Dossier | Rôle en une ligne |
|---|---|
| `00-brief-onboarding` | Capture le contexte projet (client, cible, stack, RGAA, conventions) → `brief-projet.md` |
| `01-generate-prompt-maquette` | Génère le prompt de création de maquette conforme au brief |
| `02-validation-maquette` | Valide la conformité d'une maquette livrée (pages, SDS, grille, nommage) |
| `03-inspection` | Cartographie un fichier Figma (pages, calques, variables, composants) |
| `04-review-ux-ui` | Revue UX/UI itérative, rapport 🔴/🟡/🟢 |
| `05-ajustements` | Co-pilote les corrections post-review, correction par correction |
| `06-accessibilite-rgaa` | Audit RGAA 4.1 (contrastes, alternatives textuelles, structure, formulaires) |
| `07-mapping-design-system` | Détecte les couleurs hardcodées vs. liées aux tokens SDS |
| `08-nettoyage-figma` | Renommage sémantique, liaison hex → variables, ré-instanciation |
| `10-composants` | Transforme les patterns répétés en composants Figma (variantes, propriétés) |
| `11-export-assets` | Génère le prompt d'export des assets vers la page "Export" |
| `12-documentation` | Génère la documentation technique du projet |
| `13-livraison` | Checklist de complétude et handoff développeur |
| `14-sync-sds-depuis-maquette` | Symétrique inverse du 07 : fait évoluer le SDS depuis une maquette validée |
| `15-annotations-dev-mode` | Pose les annotations Dev Mode (ACF/Gutenberg ou Drupal/Paragraphs, JS, RGAA) |

Le `09` est absent volontairement : `sync-sds-bootstrap` a été déplacé en Passation (`02-passation-design-dev/agents/sds-bootstrap.md`), il produit du code plutôt qu'un artefact de maquette — voir `PIPELINE-AGENTIQUE.md` §1.
