---
name: 13-livraison
description: Prépare et vérifie le dossier de livraison final, en suivant une checklist de complétude et de cohérence des livrables.
---


# Skill — livraison

## Rôle

Prépare et vérifie le dossier de livraison final : checklist de complétude, cohérence des livrables, handoff développeur. Étape terminale du parcours — ne modifie pas les fichiers Figma.

## Déclenchement

- `/livraison`
- « prépare la livraison »
- « checklist de livraison »
- « handoff »

## Comportement

1. Lire `brief-projet.md` et `documentation-projet-*.md` le plus récent
2. Parcourir les livrables attendus selon le type de projet :
   - Assets WebP dans `assets/img/` générés par `/export-assets`
   - Rapports de revue et d'audit (`review-ux-ui-*.md`, `audit-rgaa-*.md`)
   - Documentation projet (`documentation-projet-*.md`)
3. Vérifier la cohérence :
   - Tokens SCSS alignés avec les variables Figma SDS
   - Assets correspondant aux composants documentés
   - Niveau RGAA atteint vs. requis dans le brief
4. Produire la checklist de livraison et le résumé handoff

## Format de sortie

Fichier `livraison-<date>.md` à la racine du projet consommateur.

```markdown
# Livraison — <client> — <date>

## Statut global : 🔴 / 🟡 / 🟢

## Checklist livrables
- [ ] brief-projet.md
- [ ] _sds-tokens.scss
- [ ] assets/img/ (WebP)
- [ ] documentation-projet-<date>.md
- [ ] audit-rgaa-<date>.md

## Points ouverts
…

## Instructions handoff développeur
…
```

## Règles de conduite

- Lecture seule : ne modifie aucun fichier source ni Figma
- Si des livrables sont manquants, indiquer le skill à relancer
- Ne pas valider la livraison si des points RGAA bloquants sont ouverts (pour les clients collectivités)
