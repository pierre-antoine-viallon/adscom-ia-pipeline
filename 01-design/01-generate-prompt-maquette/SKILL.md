# Skill — generate-prompt-maquette

## Rôle

Génère un prompt structuré (brief créatif) à destination d'un designer ou d'un outil IA pour créer une maquette conforme au brief projet. Ne modifie aucun fichier Figma.

## Déclenchement

- `/generate-prompt-maquette`
- « génère un prompt pour la maquette »
- « crée le brief créatif »

## Comportement

1. Lire `brief-projet.md` à la racine du projet consommateur
2. Extraire : client, cible utilisateur, stack (Bootstrap 5), URLs SDS, contraintes RGAA, conventions de nommage
3. Identifier la page ou le composant cible (demander à l'utilisateur si non précisé)
4. Générer un prompt structuré en sections :
   - **Contexte** : client, cible, objectif de la page
   - **Contraintes techniques** : Bootstrap 5, grille, breakpoints
   - **Design system** : palette SDS, typographie, espacements
   - **Accessibilité** : niveau RGAA requis, contrastes minimaux
   - **Livrables attendus** : format, pages Figma, nommage des calques

## Format de sortie

Fichier `prompt-maquette-<composant>-<date>.md` à la racine du projet consommateur.

```markdown
# Prompt maquette — <composant> — <date>

## Contexte
…

## Contraintes techniques
…

## Design system
…

## Accessibilité
…

## Livrables attendus
…
```

## Règles de conduite

- Lecture seule : ne touche pas aux fichiers Figma
- Si `brief-projet.md` est absent, lancer `/brief-onboarding` d'abord
- Adapter le niveau RGAA (obligatoire / recommandé) selon la nature du client
