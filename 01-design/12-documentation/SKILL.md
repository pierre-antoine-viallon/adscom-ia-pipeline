---
name: 12-documentation
description: Génère la documentation technique du projet à partir des rapports produits par les skills précédents.
---


# Skill — documentation

## Rôle

Génère la documentation technique du projet à partir des rapports produits par les skills précédents : composants, tokens, assets, décisions d'accessibilité. Ne modifie pas les fichiers Figma.

## Déclenchement

- `/documentation`
- « génère la documentation »
- « documente le projet »

## Comportement

1. Lire `brief-projet.md`, `inspection-figma.md`, `mapping-ds-*.md` et `audit-rgaa-*.md` disponibles
2. Inventorier les livrables produits (rapports, SCSS, assets WebP)
3. Générer la documentation en sections :
   - **Vue d'ensemble** : client, périmètre, stack, URLs Figma et SDS
   - **Design system** : collections de variables, tokens SCSS générés, correspondances Bootstrap
   - **Composants** : liste, variantes, propriétés exposées, statut (natif Figma / créé par `/composants`)
   - **Assets** : inventaire WebP, dimensions, emplacement dans l'arborescence Bootstrap
   - **Accessibilité** : niveau RGAA atteint, points ouverts, critères validés
   - **Décisions techniques** : conventions de nommage, choix d'implémentation notables

## Format de sortie

Fichier `documentation-projet-<date>.md` à la racine du projet consommateur.

## Règles de conduite

- Lecture seule : agrège les rapports existants, ne génère pas de nouveau contenu Figma
- Si des rapports sont manquants, lister les skills à relancer pour les obtenir
- Adapter le niveau de détail RGAA selon la nature du client (collectivité vs. privé)
