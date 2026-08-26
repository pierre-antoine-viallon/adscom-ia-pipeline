---
name: 15-annotations-dev-mode
description: Prépare la phase de développement en posant des annotations Dev Mode Figma sur les nœuds, visibles par le développeur dans l'onglet Dev Mode.
---


# Skill : annotations-dev-mode

## Rôle

Prépare la phase de développement en posant des **annotations Dev Mode Figma** (attachées aux nœuds, visibles par le développeur dans l'onglet Dev Mode) sur trois volets :

1. **Correspondance CMS** — comment cette section s'implémente dans le CMS du projet (**WordPress** ou **Drupal**, détecté automatiquement depuis `brief-projet.md` — voir méthode de décision dédiée à chaque stack ci-dessous)
2. **Contrôleur JS Bootstrap** — quel composant JS Bootstrap 5 (`data-bs-*`) pilote le comportement interactif du nœud (volet commun aux deux stacks)
3. **Rappel RGAA** — points d'attention accessibilité propres au nœud (alt text, ARIA, focus, formulaires)

Ce skill n'écrit **aucune modification visuelle** du design (pas de fill, style, layout) — uniquement la propriété `annotations` des nœuds. C'est un complément à la doc technique (`12-documentation`), pas un remplacement : l'annotation vit au plus près du nœud pendant le développement, la doc technique reste le livrable de référence pour la passation.

**Prérequis obligatoire** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. Applique toutes ses règles sans exception, en particulier : retourner tous les IDs mutés, travailler par petits lots (max 15 nœuds par appel), arrêter sur erreur sans retry immédiat.

---

## Déclenchement

Ce skill est activé par `/annotations-dev-mode` ou quand l'utilisateur demande à "préparer les annotations pour le dev", "annoter pour Gutenberg/ACF", "annoter pour Paragraphs/Views", "documenter les blocks ACF sur la maquette", "documenter les types de Paragraph sur la maquette", "annoter les contrôleurs Bootstrap".

---

## Comportement

### Étape 0 — Repérage (lecture seule, produit un rapport avant toute écriture)

1. **Lis `brief-projet.md`** pour la stack et les conventions de nommage. **Détermine la stack CMS depuis la ligne `Stack` du tableau "Source de vérité"** :
   - contient `WordPress` → branche **WordPress** (blocs Gutenberg / ACF)
   - contient `Drupal` → branche **Drupal** (Paragraphs / Views)
   - ni l'un ni l'autre, ou ambigu → demande explicitement à l'utilisateur avant de continuer (ne jamais deviner la stack CMS)

   Toute la suite de cette étape (bibliothèque existante, méthode de décision, gabarit d'annotation) applique la branche déterminée ici. Les volets Bootstrap JS et RGAA sont **communs aux deux stacks**, aucune détection nécessaire pour eux.

2. **Lis les rapports disponibles** pour ne pas re-dériver ce qui est déjà tranché : `inspection-figma.md` (structure), `check-cdc-*.md` / `mapping-ds-*.md` (contenu des pages), `audit-rgaa-*.md` (points RGAA déjà identifiés). Réutilise leurs conclusions plutôt que de refaire un audit RGAA complet.
3. **Si un chemin vers le code réel du projet est connu ou fourni par l'utilisateur, inspecte-le avant d'annoter** — ne pas se contenter de deviner l'architecture depuis la maquette seule.
   - **Branche WordPress** : le thème actif (classique/PHP vs FSE/block-based — change tout le sens de "Template Part"), les plugins installés (`wp-content/plugins/`, en particulier `alpha-block` s'il est présent — voir bibliothèque de blocks ci-dessous), les `template-parts/` existants (header, footer, breadcrumb...), et si les CPT/taxonomies visés existent déjà (`register_post_type`/`register_taxonomy` dans `functions.php` ou un plugin dédié).
   - **Branche Drupal** : le thème actif (custom Bootstrap 5 vs sous-thème d'un thème contrib), les modules activés (en particulier `Paragraphs`, `Views`, `Layout Builder`), les types de Paragraph déjà définis (`config/sync/paragraphs.paragraphs_type.*.yml` ou Structure > Types de paragraphes dans l'admin), les surcharges Twig existantes (`web/themes/custom/<theme>/templates/paragraphs/`, `.../views/`), et si les types de contenu (Content Types) / vocabulaires de taxonomie visés existent déjà (`config/sync/node.type.*.yml`, `taxonomy.vocabulary.*.yml`).

   Une annotation ancrée dans le vrai code (nom de fichier, machine name déjà utilisé, bug réel repéré) vaut largement mieux qu'une hypothèse générique.
4. **Demande la ou les frame(s) cible(s)** si non précisée(s) (une page à la fois recommandé — le volume d'annotations peut être important).
5. **Parcours la frame** (`use_figma`, lecture) et identifie trois listes de candidats :
   - **Correspondance CMS** : chaque section de premier niveau (frame top-level dans la page, ex. "Hero", "Chiffres clés", "Startups accompagnées") est un candidat. Applique la méthode de décision de la branche détectée à l'étape 0.1 (**WordPress** : Bibliothèque existante → Natif → Composition → ACF, ci-dessous ; **Drupal** : Composant existant → Natif → Paragraph composé → Vue → Paragraph custom, ci-dessous) plutôt que de partir du principe que tout nécessite un champ/bloc custom.
   - **Contrôleurs Bootstrap** : repère les patterns d'interaction (voir catalogue ci-dessous) par le nom des calques et leur structure (ex. plusieurs slides de même dimension empilées = carousel candidat, bloc question/réponse répété = accordéon candidat). Si un composant de la bibliothèque existante (WordPress : `alpha-block` ; Drupal : Paragraph type déjà câblé) couvre déjà le pattern, le comportement Bootstrap est déjà câblé dedans — le signaler plutôt que de le prescrire comme un ajout séparé.
   - **Rappels RGAA** : un rappel par nœud seulement quand il y a une **action développeur non déductible du visuel seul** (attribut `alt`, ordre de focus non-linéaire, `aria-*` sur un composant custom, message d'erreur de formulaire). Ne pas dupliquer un point déjà couvert par un style/composant SDS générique déjà documenté ailleurs.

6. **Produis le rapport** `annotations-dev-<page>-<date>.md` (format ci-dessous) et **demande confirmation** avant d'écrire quoi que ce soit dans Figma.

---

## Branche WordPress

### Bibliothèque de blocks existante — thème Alpha (`alpha-bs-5` + plugin `alpha-block`)

Sur les projets utilisant le thème ads-COM **Alpha** (`alpha-bs-5` + thème enfant `alpha-bs-5-child`, Bootstrap 5), le plugin **`alpha-block`** fournit déjà une bibliothèque de blocks Gutenberg **natifs custom** (namespace `cgb/`, enregistrés via `registerBlockType`/`create-guten-block` — ce ne sont **pas** des ACF Blocks) qui couvrent la plupart des patterns d'interaction courants. **Toujours vérifier cette bibliothèque avant de proposer `core/details`, une composition manuelle, ou un ACF Block** — si un block existe déjà et correspond, c'est lui la bonne réponse (niveau 0, avant même les blocs `core/*`) :

| Pattern Figma | Block(s) `alpha-block` | Ce qu'il faut savoir |
|---|---|---|
| Accordéon / FAQ | `cgb/accordeon` + `cgb/accordeon-item` | Rend le markup Bootstrap Accordion natif (`.accordion`/`.accordion-collapse.collapse`). Chaque item = `core/heading` (niveau 3) + `core/group` contenant `core/paragraph`, imposé par `templateLock="all"`. |
| Carousel | `cgb/carousel` + `cgb/carousel-item` | Rend le markup Bootstrap Carousel natif (`data-bs-ride="carousel"`, flèches prev/next déjà câblées). Chaque slide = `core/group` > `core/cover` (image + légende). |
| Témoignage | `cgb/temoignage` (+ `cgb/temoignage-slider` si plusieurs témoignages doivent tourner) | Utilise `core/pullquote` en interne — citation + attribution nativement supportées, pas besoin de champ dédié. Le slider imbrique plusieurs `cgb/temoignage` dans un conteneur carousel. |
| Onglets (Tab) | `cgb/tab` + `cgb/tab-item` | Rend le markup Bootstrap Tab natif. Chaque item = `core/heading` (classe `tab-title`) + contenu. |
| Équipe | `cgb/team` + `cgb/team-item` | Chaque membre = `core/image` (rond, 100×100) + `core/paragraph` (nom) + `core/paragraph` (fonction), rendu en slider avec nav prev/next. |
| Chiffres clés | `cgb/key-figures` + `cgb/key-figures-item` | Chaque chiffre = `core/heading` (niveau 3) + `core/paragraph`. **Rendu en slider avec nav prev/next par défaut** (`<ul>`/`<nav>`), pas une grille statique — à vérifier auprès du designer si la maquette montre une grille fixe. |
| Formulaire | `cgb/formulaire` | ⚠️ Existant mais lié à une liste de formulaires (`SelectControl`) qui semble spécifique à un ancien projet (`TextForm`/`SelectForm`/`OscarForm`/`HereGeoForm`) — ne pas réutiliser tel quel sans vérifier avec le développeur si c'est étendu pour ce projet ou si le plugin **Contact Form 7** (généralement installé à côté) est utilisé directement via son propre block. |

**Comment vérifier si applicable à un autre projet** : chercher `wp-content/plugins/alpha-block/src/Block/` dans le code du projet — chaque sous-dossier est un block `cgb/<nom>` avec son `block.js`. Si le plugin n'est pas installé sur un projet donné, retomber sur la méthode Natif → Composition → ACF classique ci-dessous.

### Méthode de décision — Bibliothèque existante → Natif → Composition → ACF

**Priorité imposée par défaut sur les projets ads-COM WordPress** : toujours chercher la solution la plus native/déjà-construite possible avant de proposer un block custom. Applique cet ordre à chaque section candidate, dans l'ordre, et arrête-toi au premier niveau qui convient :

**0. Block déjà existant dans le code du projet** (ex. bibliothèque `alpha-block` du thème Alpha, voir ci-dessus) — s'il y a une correspondance, c'est la réponse : plus rapide, déjà testé, déjà câblé au JS Bootstrap si besoin. **Vérifier le vrai code plutôt que de deviner** (cf. Étape 0.3 ci-dessus).

**1. Bloc(s) natif(s) Gutenberg** — le contenu est un assemblage de texte, image, bouton, liste, citation, embed, sans champ structuré propre à valider ni logique métier. Couvert par les blocs `core/*` standards : `paragraph`, `heading`, `image`, `gallery`, `buttons`/`button`, `list`, `quote`, `embed` (YouTube/Vimeo via oEmbed — inclut la lecture inline, pas besoin de lightbox custom), `columns`/`group` pour la mise en page, `cover` pour un hero simple, **`details`** (natif depuis WP 6.1, `<details>/<summary>` — voir cas accordéon/FAQ plus bas). **Annotation** : liste des blocs natifs à assembler, aucun champ à créer.

**2. Composition / pattern Gutenberg** — même cas que 1, mais l'assemblage de blocs natifs se répète identique (structure + styles) à plusieurs endroits du site, ou constitue une section suffisamment complexe pour valoir la peine d'être industrialisée. Sauvegarder comme **pattern** (bloc réutilisable classique, ou pattern synchronisé si la structure doit rester identique partout). **Annotation** : nom du pattern proposé, toujours aucun champ ACF.

**Règle par défaut — contenu édité une seule fois quelque part = Composition, jamais un champ.** Avant de songer à un champ structuré (ACF Field Group, Options Page), pose systématiquement la question : *cette donnée est-elle affichée à plusieurs endroits différents (plusieurs templates, ou dans une Query Loop ET une fiche détail) et doit-elle rester synchronisée ?* Si la réponse est non — un témoignage unique, les chiffres clés d'une page d'accueil, la liste de l'équipe sur une fiche produit, les coordonnées d'une page Contact — alors même si le contenu "a l'air structuré" (plusieurs sous-valeurs, une liste), il reste au niveau 1 ou 2 : blocs natifs saisis en dur par l'éditeur, éventuellement en pattern pour la mise en page. Un champ (ACF ou Options Page) ne se justifie que si la donnée doit être **interrogée par du code à plusieurs endroits** (typiquement : affichée à la fois dans une carte de Query Loop et dans la fiche détail du même post — cf. `tagline`/`site_web`/`annee_entree` sur le CPT `startup`, réutilisés entre `Card/Startup` et `Startup/fiche`).

**Cas accordéon/FAQ** : d'abord vérifier `cgb/accordeon`/`cgb/accordeon-item` (niveau 0, thème Alpha). À défaut de cette bibliothèque, le bloc natif `core/details` (niveau 1) suffit pour un accordéon accessible sans JS. Ne basculer sur Bootstrap Collapse + ACF Block que si aucun des deux ne couvre le besoin.

**Cas carousel** : d'abord vérifier `cgb/carousel`/`cgb/carousel-item` (niveau 0, thème Alpha — rend déjà le markup Bootstrap Carousel complet). À défaut, le stockage des données (images, légendes, liens) reste un bloc **natif** `core/gallery` — le carousel est une présentation, pas une structure de données différente ; le comportement Bootstrap Carousel s'ajoute alors côté thème (variation de style de bloc + habillage du rendu), sans champ ACF dédié.

**3. Query Loop natif (cas des contenus répétés issus d'un CPT)** — dès que le contenu répété correspond à un Custom Post Type dédié (articles, startups...), c'est le bloc core **Query Loop** (`core/query`) qui s'en charge, filtré sur le CPT et/ou la taxonomie — **jamais un Repeater ACF** pour ce cas, même si le rendu visuel ressemble à une liste de cartes. Nécessite que le CPT/la taxonomie existent (cf. mini spec dédiée si elle n'est pas encore faite). **Annotation** : "Query Loop natif — CPT `<nom>`, taxonomie `<nom>` si filtrage".

**Cas filtres sur une liste (pills secteur, statut, type...)** — préférer les **pages catégorie/taxonomie natives WordPress** à un filtrage JS/AJAX : chaque pill est un simple lien (`get_term_link()`) vers l'archive du terme de taxonomie correspondant (page rechargée, requête native gérée par WP), pas un bouton de bascule avec appel JS. Implique deux conséquences à vérifier avec le développeur : (1) tout critère de filtre visible en pill (y compris un "statut" du type en cours/sorti) doit être modélisé en **taxonomie**, pas en simple champ meta, pour bénéficier de l'archive native ; (2) si plusieurs dimensions de filtre doivent pouvoir se combiner en même temps (ex. secteur ET statut), ça reste "natif" tant que ça passe par des paramètres de requête sur un template d'archive custom (`tax_query` dans `pre_get_posts`), sans JS de filtrage live. **Annotation** : "Filtres = liens vers archives de taxonomie natives, pas de JS de filtrage".

**4. Block ACF custom ou champs ACF sur CPT/Options Page (dernier recours)** — seulement si rien ci-dessus ne convient, **et** que le test de réutilisation multi-endroits ci-dessus est positif : comportement interactif non standard qu'aucun bloc natif ne couvre (`core/details` et `core/gallery` écartés en premier), champs structurés avec contrainte de saisie réutilisés dans plusieurs templates (ex. `tagline`/`site_web`/`annee_entree` du CPT `startup`), formulaire avec logique de soumission (→ plutôt un plugin de formulaire qu'un ACF Block, cf. catalogue), ou logique métier qui dépasse l'édition de contenu simple. Dans ce cas seulement, déduis les champs ACF depuis le contenu visible :

| Contenu visuel | Champ ACF suggéré |
|---|---|
| Image / photo / logo | Image |
| Titre court (H1-H3) | Text |
| Paragraphe / description | Textarea ou WYSIWYG |
| Date | Date Picker |
| Lien / CTA | Link ou Page Link |
| Choix fermé (catégorie, secteur, statut) | Select ou Taxonomy |
| Nombre (chiffre clé, année) | Number |
| Élément qui se répète en dur (Repeater légitime uniquement si ce n'est PAS un CPT, cf. niveau 3) | Repeater |
| Icône parmi un set fermé | Select (mappé à un set d'icônes SVG côté thème) |

Nomme chaque block ACF `<slug-projet>/<slug-section>` (namespace = slug du projet, cohérent avec le nom du thème WordPress). Si une section a déjà un composant Figma nommé (`Card Actu`, `StartupCard`...), reprends ce nom en kebab-case pour le slug.

**Dans le rapport, indique toujours le niveau retenu (Natif / Composition / Query Loop / ACF) et pourquoi** — ne saute jamais directement à ACF sans avoir écarté les niveaux précédents. Un cas limite (ex. "un Repeater ACF serait plus simple mais une Query Loop est possible") se signale "à confirmer avec le développeur", ne se tranche pas unilatéralement dans l'annotation.

---

## Branche Drupal

### Composants Paragraphs déjà existants — vérification code obligatoire

Contrairement à WordPress où une bibliothèque de blocks ads-COM cataloguée (`alpha-block`) existe, **il n'y a pas encore de catalogue générique équivalent côté Drupal** : chaque projet peut avoir défini ses propres types de Paragraph. **Ne jamais deviner — toujours inspecter le code avant d'annoter** (cf. Étape 0.3) :

- Liste des types de Paragraph déjà définis : `config/sync/paragraphs.paragraphs_type.*.yml`, ou Structure > Types de paragraphes dans l'admin Drupal.
- Champs de chaque type déjà défini : `config/sync/field.field.paragraph.<type>.*.yml`.
- Surcharges Twig existantes côté thème : `web/themes/custom/<theme>/templates/paragraphs/paragraph--<type>.html.twig` (indique qu'un rendu spécifique est déjà câblé, potentiellement déjà avec les attributs `data-bs-*` du contrôleur Bootstrap).
- Vues déjà définies pour du contenu répété : `config/sync/views.view.*.yml`.

Si un type de Paragraph correspond déjà visuellement à la section candidate, c'est la réponse (niveau 0, avant même le niveau "Natif") : plus rapide, déjà testé, potentiellement déjà câblé au JS Bootstrap si le `.html.twig` existe.

### Méthode de décision — Composant existant → Natif → Paragraph composé → Vue → Paragraph custom

**Priorité imposée par défaut sur les projets ads-COM Drupal** : toujours chercher la solution la plus native/déjà-construite possible avant de proposer un nouveau type de Paragraph avec ses propres champs. Applique cet ordre à chaque section candidate, dans l'ordre, et arrête-toi au premier niveau qui convient :

**0. Composant déjà existant dans le code du projet** (type de Paragraph déjà défini + éventuelle surcharge Twig, voir ci-dessus) — s'il y a une correspondance, c'est la réponse. **Vérifier le vrai code plutôt que de deviner** (cf. Étape 0.3 ci-dessus).

**1. Natif Twig / Bootstrap (pas de structuration de contenu)** — le contenu est un assemblage fixe de texte/image/bouton sans variation multi-instance à saisir par un éditeur (ex. un footer figé, une mise en page purement présentationnelle du thème), ou du texte riche ponctuel couvert par un champ **Text long (WYSIWYG/CKEditor)** existant sur le node. Couvert directement par le template Twig du thème (`page.html.twig`, `block--*.html.twig`) sans nouveau champ à créer. **Annotation** : "Natif Twig — pas de champ" ou "champ Text long (WYSIWYG) existant".

**2. Paragraph composé (type de Paragraph avec champs simples)** — l'assemblage se répète identique (structure + styles) à plusieurs endroits du site, ou constitue une section suffisamment complexe pour valoir la peine d'être industrialisée et réutilisée dans plusieurs `node`/`paragraph` parents via un champ Entity Reference Revisions. **Annotation** : machine name proposé (snake_case, ex. `hero_section`), liste des champs.

**Règle par défaut — contenu édité une seule fois quelque part = Paragraph composé avec champs saisis une fois, jamais besoin de le rendre "interrogeable" ailleurs.** Avant de songer à un champ porté par le **type de contenu (Content Type)** du node plutôt que par le Paragraph lui-même, pose systématiquement la question : *cette donnée est-elle affichée à plusieurs endroits différents (une Vue ET une page de détail du même contenu) et doit-elle rester synchronisée ?* Si la réponse est non — un témoignage unique, les chiffres clés d'une page d'accueil, la liste de l'équipe sur une fiche produit, les coordonnées d'une page Contact — alors même si le contenu "a l'air structuré" (plusieurs sous-valeurs, une liste), un type de Paragraph avec ses propres champs suffit. Un champ porté par le Content Type (donc interrogeable par une Vue) ne se justifie que si la donnée doit être **affichée à la fois dans une Vue (liste) et dans la fiche détail du même contenu** (équivalent Drupal du cas `tagline`/`site_web`/`annee_entree` sur le CPT `startup`).

**Cas accordéon/FAQ** : type de Paragraph "Accordéon" avec un champ Entity Reference Revisions multi-valué vers un Paragraph "Item accordéon" (titre + texte long), rendu via Twig avec markup Bootstrap Collapse natif — pas de champ structuré supplémentaire nécessaire.

**Cas carousel** : le stockage des données (images, légendes, liens) reste un champ **Image** multi-valué (ou Entity Reference Revisions vers un Paragraph "Slide" si légende/lien par image) — le carousel est une présentation, pas une structure de données différente ; le comportement Bootstrap Carousel s'ajoute côté Twig/thème (attributs `data-bs-ride`), sans logique métier supplémentaire.

**3. Vue (Views) pour contenu répété issu d'un type de contenu** — dès que le contenu répété correspond à un **type de contenu (Content Type)** dédié (articles, startups, formations...), c'est une **Vue** (bloc de vue ou page de vue), filtrée sur ce Content Type et/ou un vocabulaire de taxonomie, qui s'en charge — **jamais un champ Entity Reference Revisions multi-valué codé à la main** pour ce cas, même si le rendu visuel ressemble à une liste de cartes gérée "à la main" dans un Paragraph. Nécessite que le Content Type / vocabulaire existent (cf. mini spec dédiée si elle n'est pas encore faite). **Annotation** : "Vue — Content Type `<nom>`, taxonomie `<nom>` si filtrage".

**Cas filtres sur une liste (pills secteur, statut, type...)** — préférer les **filtres exposés natifs d'une Vue** (Views exposed filters) ou les pages de terme de taxonomie natives (`/taxonomy/term/%`) à un filtrage JS/AJAX custom : chaque pill est soit un filtre exposé de la Vue (requête rechargée ou AJAX natif Views, géré par le module), soit un simple lien vers la page de terme correspondante. Implique de vérifier avec le développeur : (1) tout critère de filtre visible en pill (y compris un "statut" du type en cours/terminé) doit être modélisé en **champ de taxonomie (vocabulaire)**, pas en simple champ texte libre, pour bénéficier du filtre natif ; (2) si plusieurs dimensions de filtre doivent se combiner (ex. secteur ET statut), ça reste "natif" tant que ça passe par des filtres exposés combinables de la Vue, sans JS de filtrage live custom. **Annotation** : "Filtres = filtres exposés Views ou liens vers pages de taxonomie natives, pas de JS de filtrage".

**4. Type de Paragraph custom avec champs de contrainte (dernier recours)** — seulement si rien ci-dessus ne convient, **et** que le test de réutilisation multi-endroits ci-dessus est positif : comportement interactif non standard, champs structurés avec contrainte de saisie réutilisés dans plusieurs templates, formulaire avec logique de soumission (→ Webform plutôt qu'un Paragraph, cf. module `Webform`), ou logique métier qui dépasse l'édition de contenu simple. Dans ce cas seulement, déduis les champs depuis le contenu visible :

| Contenu visuel | Type de champ Drupal suggéré |
|---|---|
| Image / photo / logo | Image |
| Titre court (H1-H3) | Text (plain) |
| Paragraphe / description | Text long (format filtré) ou Text (formaté, WYSIWYG) |
| Date | Date |
| Lien / CTA | Link |
| Choix fermé (catégorie, secteur, statut) | List (text) ou Entity reference (taxonomy) |
| Nombre (chiffre clé, année) | Number (integer/decimal) |
| Élément qui se répète en dur (multi-valué légitime uniquement si ce n'est PAS un Content Type dédié, cf. niveau 3) | Entity Reference Revisions (Paragraph imbriqué) multi-valué |
| Icône parmi un set fermé | List (text) (mappé à un set d'icônes SVG côté thème) |

Nomme chaque type de Paragraph `<slug_projet>_<slug_section>` (machine name Drupal en snake_case, préfixé par le slug du projet). Si une section a déjà un composant Figma nommé (`Card Actu`, `StartupCard`...), reprends ce nom en snake_case pour le slug.

**Dans le rapport, indique toujours le niveau retenu (Natif / Paragraph composé / Vue / Paragraph custom) et pourquoi** — ne saute jamais directement à un Paragraph custom sans avoir écarté les niveaux précédents. Un cas limite (ex. "un champ multi-valué serait plus simple mais une Vue est possible") se signale "à confirmer avec le développeur", ne se tranche pas unilatéralement dans l'annotation.

---

## Catalogue — Contrôleurs JS Bootstrap 5 (commun WordPress / Drupal)

| Pattern visuel / nommage Figma | Composant Bootstrap | Attributs `data-bs-*` clés |
|---|---|---|
| Slides/images empilées avec indicateurs ou flèches | **Carousel** | `data-bs-ride="carousel"`, `data-bs-slide` |
| Menu burger / nav mobile qui se déploie | **Collapse** (navbar) ou **Offcanvas** | `data-bs-toggle="collapse"` / `data-bs-toggle="offcanvas"` |
| Question/réponse repliable, FAQ, section "voir plus" | **Collapse** (accordéon) | `data-bs-toggle="collapse"`, `data-bs-parent` |
| Groupe d'onglets avec panneaux de contenu | **Tab** | `data-bs-toggle="tab"` |
| Fenêtre de confirmation, formulaire en overlay | **Modal** | `data-bs-toggle="modal"` |
| Info-bulle courte sur icône/élément | **Tooltip** | `data-bs-toggle="tooltip"` |
| Info-bulle riche (texte + actions) | **Popover** | `data-bs-toggle="popover"` |
| Menu déroulant (filtres, sélecteur, langue) | **Dropdown** | `data-bs-toggle="dropdown"` |
| Notification temporaire (succès formulaire, ajout panier) | **Toast** | `data-bs-autohide` |
| Bandeau fermable (alerte, message RGPD hors Tarte au Citron) | **Alert** dismissible | `data-bs-dismiss="alert"` |
| Barre de progression (étapes formulaire multi-pages) | **Progress** (pas de JS, CSS pur) | — |

Ne propose un contrôleur que si le comportement interactif est réel (visible dans le nommage des calques, les variantes de composant type "ouvert/fermé", ou explicitement décrit dans le cahier des charges) — ne pas inventer d'interactivité absente de la maquette.

---

### Étape 1 — Écriture des annotations (après confirmation)

**Script 1 — Récupérer les catégories d'annotation disponibles** (ne jamais coder en dur un `categoryId` — les libellés/ids peuvent varier selon le plan Figma)

```javascript
const categories = await figma.annotations.getAnnotationCategoriesAsync();
const catByLabel = {};
for (const c of categories) catByLabel[c.label.toLowerCase()] = c.id;

// Résout au mieux, retombe sur undefined (annotation sans catégorie) si rien ne correspond.
// Catégories par défaut Figma observées (2026-08-20, projet TPbCCI45) : Development, Interaction, Accessibility, Content.
const categoryIds = {
  cms: catByLabel['development'] ?? catByLabel['developer notes'] ?? catByLabel['dev'] ?? catByLabel['custom'],
  bootstrap: catByLabel['interaction'] ?? catByLabel['developer notes'] ?? catByLabel['dev'] ?? catByLabel['custom'],
  rgaa: catByLabel['accessibility'] ?? catByLabel['custom']
};
return { available: categories.map(c => ({ id: c.id, label: c.label })), resolved: categoryIds };
```

**Script 2 — Poser une annotation sur un nœud** (un nœud à la fois, `labelMarkdown` supporte le Markdown pour structurer plusieurs volets sur un même nœud)

```javascript
// nodeId : id du nœud cible
// markdown : contenu structuré (voir gabarit ci-dessous)
// categoryId : résolu à l'étape précédente, peut être undefined

const nodeId = '<NODE_ID>';
const markdown = '<MARKDOWN>';
const categoryId = '<CATEGORY_ID_OU_UNDEFINED>';

const node = await figma.getNodeByIdAsync(nodeId);
if (!node) return { error: `Nœud ${nodeId} introuvable` };

const existing = node.annotations ?? [];
node.annotations = [
  ...existing,
  { labelMarkdown: markdown, ...(categoryId ? { categoryId } : {}) }
];

return { mutatedNodeId: nodeId, annotationCount: node.annotations.length };
```

**Gabarit `labelMarkdown` par nœud — branche WordPress** (n'inclure que les sections pertinentes pour ce nœud, ne pas forcer les trois volets à chaque fois) :

```markdown
**Gutenberg — Natif** : `core/heading` + `core/paragraph` + `core/image` + `core/buttons`

**Gutenberg — Composition** : pattern `<nom-du-pattern>` (blocs natifs : ...)

**Gutenberg — Query Loop** : CPT `<nom>`, taxonomie `<nom>` (filtrage si applicable)

**Gutenberg — Block ACF** `<slug-projet>/<slug-section>` *(uniquement si aucun niveau natif ne convient — justifier pourquoi)*
- `<champ>` (Type ACF) — <ce que ça contient>
- `<champ>` (Type ACF) — <ce que ça contient>

**Bootstrap JS** — <Composant> (`data-bs-toggle="<valeur>"`)

**RGAA** — <point d'attention précis, ex. "alt requis : nom + rôle de l'entreprise, pas 'logo entreprise'">
```

**Gabarit `labelMarkdown` par nœud — branche Drupal** (n'inclure que les sections pertinentes pour ce nœud, ne pas forcer les trois volets à chaque fois) :

```markdown
**Drupal — Natif** : template Twig direct, pas de champ (ou champ Text long/WYSIWYG existant)

**Drupal — Paragraph composé** : type `<machine_name>` (champs : ...)

**Drupal — Vue** : Content Type `<nom>`, taxonomie `<nom>` (filtrage si applicable)

**Drupal — Paragraph custom** `<slug_projet>_<slug_section>` *(uniquement si aucun niveau natif ne convient — justifier pourquoi)*
- `<champ>` (Type de champ Drupal) — <ce que ça contient>
- `<champ>` (Type de champ Drupal) — <ce que ça contient>

**Bootstrap JS** — <Composant> (`data-bs-toggle="<valeur>"`)

**RGAA** — <point d'attention précis, ex. "alt requis : nom + rôle de l'entreprise, pas 'logo entreprise'">
```

*(n'inclure qu'une seule ligne de correspondance CMS par nœud — celle du niveau retenu dans la branche détectée — pas toutes les possibilités à chaque fois)*

**Répète pour chaque nœud du rapport confirmé, par lot de 15 maximum, en validant entre chaque lot** (relire `node.annotations.length` sur un échantillon pour confirmer que rien n'a été écrasé).

---

## Format du rapport de repérage

```markdown
## Annotations Dev Mode — Repérage <page> — <date>

Stack détectée : <WordPress|Drupal> (depuis brief-projet.md)

### Correspondance CMS candidate
| Nœud (nom / id) | Niveau | Détail |
|---|---|---|
| `text bloc/Notre positionnement` (`123:40`) | Natif | *(WordPress)* `core/heading` + `core/paragraph` — *(Drupal)* template Twig direct |
| `section/hero` (`123:45`) | Custom *(justif. : composant réutilisé, champs surchargeables par page)* | *(WordPress)* `tpbcci45/hero` — image, titre, chapo, cta_texte, cta_lien — *(Drupal)* `tpbcci45_hero` — mêmes champs |
| `Card Actu` (`123:78`, ×6 instances) | Query Loop / Vue | *(WordPress)* CPT `actu` — *(Drupal)* Content Type `actu` (à confirmer si taxonomie de filtrage) |

### Contrôleurs Bootstrap candidats
| Nœud (nom / id) | Composant Bootstrap | Justification |
|---|---|---|
| `Carousel/images` (`123:90`) | Carousel | 5 slides même format + flèches/indicateurs visibles |

### Rappels RGAA
| Nœud (nom / id) | Point d'attention |
|---|---|
| `img/logo-startup` (`123:12`) | Alt text = nom + secteur startup, pas "logo" |

### À confirmer avec le développeur
<Cas ambigus : multi-valué vs Vue/Query Loop, contrôleur Bootstrap incertain, etc.>

Confirmes-tu l'écriture de ces annotations dans Figma ? (oui / non / ajuster)
```

---

## Règles de conduite

- **Détecter la stack avant toute analyse** : lire la ligne `Stack` de `brief-projet.md` (WordPress ou Drupal) et appliquer la branche correspondante — ne jamais mélanger le vocabulaire des deux stacks dans un même rapport, et ne jamais deviner la stack si elle n'est pas déterminable (demander à l'utilisateur).
- **Rapport avant écriture** : toujours produire et faire valider le rapport de repérage avant le moindre appel d'écriture — les annotations sont plus rapides à corriger qu'un binding de variable, mais elles doivent rester fiables pour le développeur qui s'y fie sans revalider.
- **Ne jamais écraser les annotations existantes** : toujours lire `node.annotations` avant de réassigner, et concaténer.
- **Ne jamais coder en dur un `categoryId`** : le résoudre dynamiquement via `getAnnotationCategoriesAsync()` à chaque session (peut différer selon le plan Figma/l'organisation).
- **Ne pas inventer d'interactivité** : un contrôleur Bootstrap ne se propose que si le comportement est visible dans la maquette (variantes ouvert/fermé, nommage explicite) ou mentionné au cahier des charges.
- **Réutiliser les rapports existants** (`audit-rgaa-*.md`, `mapping-ds-*.md`, `check-cdc-*.md`) plutôt que de refaire l'analyse — ce skill assemble et projette dans les annotations, il ne ré-audite pas RGAA depuis zéro.
- **Un cas ambigu (multi-valué vs Vue/Query Loop, contrôleur incertain) se signale "à confirmer avec le développeur"** dans le rapport — ne jamais trancher une décision d'architecture backend à la place du développeur.
- Propose à la fin de sauvegarder le rapport dans `annotations-dev-<page>-<date>.md`.
