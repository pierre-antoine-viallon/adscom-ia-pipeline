---
name: 11-export-assets
description: Prépare l'export des assets d'une page ou d'un périmètre Figma en générant un prompt Figma AI paramétré.
---

# Skill : export-assets

## Rôle

Tu prépares l'export des assets (photos, icônes, logos, formes décoratives) d'une page ou d'un périmètre Figma, en générant un **prompt Figma AI paramétré** que l'utilisateur colle lui-même dans Figma — ce skill ne modifie plus le canvas via `use_figma` par défaut et n'appelle plus `download_assets` ni de conversion `sharp`/Node.js.

**Historique** : ce skill utilisait auparavant un pipeline `download_assets` par nœud + clonage d'ids composés + conversion WebP locale via `scripts/convert-webp.js`. Ce pipeline a été jugé trop lent et trop lourd en validations manuelles en usage réel (RJAC, 2026-07-21) et est **déprécié** — `scripts/convert-webp.js` reste dans le dépôt pour référence historique mais n'est plus invoqué par ce skill.

**Le nouveau flux, en trois temps** :
1. **Ce skill** génère le prompt Figma AI (Étape 2 ci-dessous), adapté au périmètre demandé par l'utilisateur.
2. **L'utilisateur** colle ce prompt directement dans Figma AI, à l'intérieur du fichier Figma — pas dans Claude Code. Figma AI détecte, renomme, duplique les assets en double format vers une page "Export" et pose les réglages d'export (Export Settings).
3. **L'utilisateur** exporte les WebP finaux **manuellement, via un plugin Figma dédié** — cette conversion ne fait plus partie du périmètre de ce skill.

Ce skill peut ensuite, **sur demande explicite**, faire une passe de vérification en lecture seule via `use_figma` sur le résultat produit par Figma AI (Étape 4 ci-dessous) — mais ce n'est jamais lui qui duplique/organise les nœuds.

**Prérequis** : charge mentalement le skill `figma-use` avant tout appel `use_figma` (utilisé uniquement pour la vérification optionnelle, en lecture seule).

---

## Déclenchement

Ce skill est activé par `/export-assets` ou quand l'utilisateur demande à "exporter les assets", "préparer l'export des visuels", "générer le prompt d'export Figma AI", "exporter les shapes/formes décoratives".

---

## Comportement

### Étape 1 — Cadrage du périmètre

Demande le périmètre si non précisé : nom de la page Figma, ou nom(s) de frame(s) de niveau 1 à l'intérieur d'une page. Un seul prompt peut couvrir plusieurs frames d'une même page (elles deviendront chacune une section distincte dans la page "Export", voir Étape 2 / Étape 5 du prompt généré).

### Étape 2 — Génération du prompt Figma AI

Produis le prompt ci-dessous, en remplaçant uniquement `<PÉRIMÈTRE>` par le nom exact de la page/des frames ciblées (jamais laissé générique). Livre-le à l'utilisateur comme un bloc à copier-coller tel quel dans Figma AI — ne l'exécute jamais toi-même via `use_figma`.

```
Étape 0 — Vérification obligatoire, à faire avant toute autre action. Liste les pages existantes de ce fichier Figma. Une page nommée exactement "Export" existe-t-elle déjà ?
- Oui → utilise cette page existante pour toute la suite. N'en crée aucune autre.
- Non → crée une seule page nommée "Export".

Créer une deuxième page "Export" (ou une variante "Export 2", "Export copie"...) est une erreur. Si à un moment de l'exécution une page "Export" semble déjà présente, ne pas en créer une nouvelle est prioritaire sur toute autre instruction de ce prompt.

Étape 1 — Détection et classification. Parcours <PÉRIMÈTRE> et repère tous les calques porteurs d'un asset exportable, en les classant en quatre catégories :
- Photo : tout calque dont le fill est de type image (photographie, illustration bitmap) — hors icônes et logos.
- Icône : tout calque vectoriel représentant un pictogramme fonctionnel (flèche, chevron, symbole d'action...), généralement de petite taille et récurrent dans l'interface.
- Logo : tout calque représentant une marque ou un identifiant visuel de marque (logo de l'entreprise, favicon, sigle), vectoriel ou bitmap.
- Forme décorative : tout calque vectoriel purement graphique/ornemental sans fonction d'interface (spirale, ligne courbe, cercle, blob, motif de fond...) — ni pictogramme cliquable, ni marque. Inclut les formes répétées en arrière-plan de section.

Étape 2 — Nommage (calques ET frames englobantes), à faire intégralement avant toute duplication. Pour chaque calque repéré, si son nom ne suit pas déjà une convention claire, renomme-le d'abord sur le calque source (minuscules, sans accents, sans espaces, tirets entre les mots) :
- Photo : un nom court et descriptif reflétant son sujet et sa section (3 à 6 mots), sans préfixe imposé.
- Icône : préfixe icon- suivi d'une description courte de sa fonction (ex. icon-chevron-down). Deux occurrences identiques de la même icône reçoivent exactement le même nom, sans suffixe numérique.
- Logo : préfixe logo- suivi d'une description courte (ex. logo-principal, logo-favicon).
- Forme décorative : préfixe shape- suivi d'une description courte de sa forme ou de sa position (ex. shape-spirale-hero, shape-cercle-outline). Deux occurrences identiques de la même forme reçoivent exactement le même nom, sans suffixe numérique.

Renomme aussi, à ce même stade, la frame ou le conteneur qui englobe directement chaque asset si son nom est resté un nom par défaut de Figma (Frame 8, Container, Group 3, Rectangle 12...) — donne-lui un nom descriptif cohérent avec l'asset qu'il contient (ex. la frame qui englobe icon-chevron-down peut devenir bouton-chevron-down si elle a un rôle propre, ou reprendre le nom de l'asset avec un suffixe -frame/-card si elle n'est qu'un simple wrapper). Ce renommage doit avoir lieu ici, en tout début de processus — pas en rattrapage après la duplication : toute frame créée par la suite (Étape 3, Étape 5) doit pouvoir hériter directement d'un nom propre déjà posé sur la source, sans étape de nettoyage séparée.

Étape 3 — Duplication en double format. Dans la page "Export" (celle identifiée/créée à l'Étape 0), duplique chaque calque selon sa catégorie :
- Photo et Logo → deux duplicatas :
  - Version native : redimensionnée à la résolution native de l'image source (pas à la taille ni au recadrage affichés dans la maquette), fill d'origine conservé. Nommée <nom-du-calque>-original.
  - Version propre : aux dimensions d'affichage d'origine (identiques au calque source), mais dépouillée de tout habillage superposé à l'image — dégradé, ombre, flou, rayon d'arrondi (border-radius) — pour ne garder que l'image elle-même, nette. Nommée <nom-du-calque> (sans suffixe).
- Icône et Forme décorative → un seul duplicata chacune : le vecteur tel quel, aux dimensions d'origine, sans habillage ajouté. Nommé <nom-du-calque> (sans suffixe, pas de version -original).

Étape 4 — Réglages d'export (obligatoire, pour CHAQUE duplicata sans exception). Avant de passer à l'organisation, ajoute un réglage d'export (Export Settings, panneau Export de Figma) sur chaque duplicata créé à l'Étape 3 : format PNG à l'échelle 1x pour les photos et les logos (les deux versions, native et propre), format SVG pour les icônes et les formes décoratives. Ne saute pas cette étape même pour les derniers assets traités — c'est une cause fréquente d'oubli en fin d'exécution.

Étape 5 — Organisation et positionnement. Organise la page "Export" avec une section Figma par frame de niveau 1 de <PÉRIMÈTRE> (une section portant exactement le même nom que la frame d'origine), quel que soit le nombre de sous-pages/cadres imbriqués qu'elle contient (même règle de réutilisation qu'à l'Étape 0 : si la section existe déjà, la compléter plutôt qu'en créer une seconde). À l'intérieur de chaque section :
- Range les duplicatas en grille, sans aucun chevauchement, avec un espacement régulier (auto-layout avec retour à la ligne si l'outil le permet, sinon une grille manuelle à espacement constant).
- Place la version native et la version propre d'un même asset l'une à côté de l'autre, pour faciliter la comparaison visuelle.
- Sépare visuellement les icônes, les formes décoratives et les photos/logos (sous-groupe ou zone dédiée par catégorie) si leur nombre le justifie.
- Trie les éléments par ordre alphabétique de nom à l'intérieur de chaque sous-groupe.
- Ajoute, juste au-dessus de chaque visuel dupliqué, un texte affichant son nom exact (celui donné à l'Étape 2/3, ex. actu-homme-carton-original) — pour identifier chaque asset visuellement dans la page "Export" sans avoir à ouvrir le panneau des calques.
- Toute frame-wrapper créée ici pour englober un visuel et son texte-titre hérite d'un nom descriptif (ex. card-actu-homme-carton-original) — comme la frame source a déjà été renommée à l'Étape 2, ce nom se déduit directement, sans étape de rattrapage séparée. Les sections par frame de niveau 1 et les sous-groupes portent eux aussi un nom clair, jamais un nom générique laissé par défaut (Frame N, Container, Group N...).

Ne modifie aucun calque de <PÉRIMÈTRE> au-delà du renommage prévu à l'Étape 2 : tout le reste du travail se fait par duplication vers la page "Export", en lecture seule sur le reste du fichier.

Étape 6 — Vérification finale, avant de conclure. Relis ton propre travail et confirme explicitement :
1. Il n'existe qu'une seule page nommée "Export" dans le fichier (pas de doublon créé par erreur).
2. Chaque duplicata créé porte bien un réglage d'export (PNG pour photo/logo, SVG pour icône et forme décorative) — vérifie-les un par un, pas seulement les premiers.
3. Aucun élément ne chevauche un autre dans la page "Export".
4. Aucune frame de la page "Export" (wrapper, section, sous-groupe) ne porte un nom par défaut Figma (Frame N, Container, Group N...).

Si l'un de ces points n'est pas vérifié, corrige-le avant de terminer.
```

### Étape 3 — Remise à l'utilisateur

Livre le prompt généré comme un bloc à copier, en rappelant explicitement : à coller dans **Figma AI, à l'intérieur du fichier Figma ciblé** — pas dans Claude Code.

### Étape 4 — Vérification post-exécution (optionnelle, sur demande uniquement)

Si l'utilisateur demande un contrôle qualité après exécution du prompt par Figma AI, effectue une passe **en lecture seule** via `use_figma` :
- Une seule page "Export" existe.
- Chaque duplicata a un `exportSettings` non vide, du bon format (PNG photos/logos, SVG icônes/formes).
- Pas de chevauchement de bounding box dans la page "Export".
- Aucune frame ne porte un nom par défaut Figma (`Frame \d+`, `Group \d+`, `Container`, `Rectangle \d+`...).

Ne corrige jamais toi-même via `use_figma` sans confirmation explicite de l'utilisateur — signale les écarts trouvés et laisse l'utilisateur décider (retour dans Figma AI, ou correction manuelle).

### Étape 5 — Rappel de l'étape manuelle finale

Rappelle que l'export WebP effectif (page "Export" → fichiers `.webp`/`.svg` dans `Export/assets/img/`) reste **manuel, via un plugin Figma dédié**, choisi et exécuté par l'utilisateur — hors du périmètre de ce skill.

---

## Format de sortie

Le livrable principal de ce skill est le **bloc de prompt Figma AI** (Étape 2), prêt à copier. En complément, si une vérification (Étape 4) a été demandée :

```markdown
## Vérification export-assets — <date>

### Périmètre vérifié
<page/frames>

### Résultat
1. Page "Export" : <OK / doublon détecté : lister>
2. Export Settings : <OK / N duplicatas sans réglage : lister>
3. Chevauchements : <aucun / liste>
4. Noms par défaut restants : <aucun / liste>

### À corriger avant export WebP manuel
<liste, ou "rien à signaler">
```

---

## Règles de conduite

- **Ne jamais appeler `download_assets` ni relancer une conversion `sharp`/`convert-webp.js` par défaut** — pipeline déprécié depuis le 2026-07-21, conservé dans le dépôt (`scripts/convert-webp.js`) pour référence historique uniquement.
- **Le prompt généré (Étape 2) est toujours celui, à jour, avec les 4 catégories** Photo / Icône / Logo / Forme décorative — ne pas régresser vers une version à 3 catégories.
- **`<PÉRIMÈTRE>` est toujours remplacé par le nom exact** de la page/des frames transmis par l'utilisateur — jamais laissé générique dans le bloc livré.
- **Ce skill n'exécute jamais lui-même la duplication/organisation via `use_figma`** — c'est le rôle de Figma AI, piloté par l'utilisateur, pas de ce skill.
- **La vérification (Étape 4) est strictement en lecture seule** et seulement sur demande explicite — jamais de correction automatique du canvas sans confirmation.
- **L'export WebP final reste entièrement manuel**, via un plugin Figma dédié choisi par l'utilisateur — ne propose plus de script Node.js/`sharp` pour cette conversion.
