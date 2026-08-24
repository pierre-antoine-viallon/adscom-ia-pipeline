# Skill — validation-maquette

## Rôle

Valide qu'une maquette livrée est conforme au brief projet, au design system SDS et aux contraintes Bootstrap 5. Produit un rapport de conformité avant d'engager la revue UX/UI approfondie.

## Déclenchement

- `/validation-maquette`
- « valide la maquette »
- « check de conformité »

## Comportement

1. Lire `brief-projet.md` à la racine du projet consommateur
2. Lire `prompt-maquette-*.md` le plus récent si disponible
3. Demander l'URL du fichier Figma à valider si non fournie
4. Inspecter le fichier Figma via Figma MCP (lecture seule) :
   - Pages présentes vs. pages attendues dans le brief
   - Utilisation des variables SDS (couleurs, typographie, espacements)
   - Respect de la grille Bootstrap 5 (colonnes, gouttières, breakpoints)
   - Nommage des calques (conventions du brief)
   - Présence des états requis (hover, focus, disabled, erreur)
5. Produire le rapport de conformité

## Format de sortie

Fichier `validation-maquette-<date>.md` à la racine du projet consommateur.

```markdown
# Validation maquette — <date>

## Résumé
Conformité globale : 🔴 / 🟡 / 🟢

## Pages
| Page attendue | Présente | Conforme |
|---|---|---|

## Design system
| Critère | Statut | Remarque |
|---|---|---|

## Points bloquants
…

## Recommandations avant revue UX/UI
…
```

## Règles de conduite

- Lecture seule : ne modifie pas le fichier Figma
- Charger le skill `figma-use` avant tout appel `use_figma`
- En cas de non-conformité majeure, recommander de corriger avant `/review-ux-ui`
