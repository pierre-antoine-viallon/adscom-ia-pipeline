# reference-blocks/

Exemples de blocs **déjà codés et validés sur des projets ads-COM réellement livrés** (pas des gabarits génériques, pas des exemples synthétiques) — chargés systématiquement par l'agent `dev` à l'étape 5 du process d'intégration SCSS (voir `agents/dev.md`, section "Comportement (Theming) — itération 1") comme modèle de style de code : nommage BEM, nesting, organisation mobile-first ou desktop-first.

## Provenance

Le contenu de ce dossier doit être copié manuellement depuis des projets déjà réalisés (le repo `figma-mcp-claude-skills` ne doit **jamais** être modifié — voir `CLAUDE.md` — mais rien n'empêche d'en copier des exemples ici en lecture). Ce repo (`adscom-ia-pipeline`) ne génère et ne fabrique aucun exemple lui-même : ce serait contraire à l'objectif (`dev` doit s'appuyer sur du code réel, pas sur une invention plausible).

## Format attendu

Un sous-dossier par bloc, nommé de façon descriptive (ex. `card-actualite/`, `hero-simple/`, `footer-complexe/`), contenant au minimum :

- le markup HTML final du bloc (tel que généré par `contrib` sur le projet source) ;
- le SCSS correspondant, déjà validé par `reviewer` sur ce projet.

## Diversité attendue (2-3 blocs)

- **un bloc simple** — structure basique, pas de variante ;
- **un bloc avec variantes/états** — modificateurs BEM, hover/actif/vide ;
- **un bloc avec responsive complexe** — plusieurs breakpoints, réarrangement de la grille.

## Si ce dossier est vide ou incomplet

`dev` ne bloque pas dessus : à défaut d'exemple exploitable, il retombe sur les conventions BEM/nesting standard documentées dans `brief-projet.md` du projet consommateur (voir `dev.md`, étape 5). Alimenter ce dossier reste toutefois la meilleure garantie de cohérence de style entre blocs.
