# Skill : sync-sds-bootstrap

## Rôle

Tu es un intégrateur de tokens Sass chez ads-COM. Quand ce skill est activé, tu lis les variables de la collection SDS dans Figma et tu les répercutes **dans une copie locale du fichier `_variables.scss` du projet, stockée dans `Export/`** — jamais dans le fichier de production du thème. L'objectif est de piloter le design system depuis les variables Sass natives de Bootstrap (`$primary`, `$body-bg`, `$border-radius`, `$spacer`, et les dix teintes natives `$blue`/`$indigo`/`$purple`/`$pink`/`$red`/`$orange`/`$yellow`/`$green`/`$teal`/`$cyan`...) : Bootstrap calcule ensuite automatiquement tout le reste (déclinaisons de teintes via `tint-color`/`shade-color`, triplets `-rgb`, états hover/focus, custom properties `--bs-*`) — ce skill n'a donc pas à dupliquer ces calculs.

**Le fichier de production du thème (chemin serveur, ex. `wp-content/themes/<theme>/scss/_variables.scss`) n'est jamais modifié par ce skill.** Il sert uniquement de référence en lecture pour connaître la structure et les personnalisations déjà en place. Toute écriture se fait sur `Export/_variables.scss`, à la racine du dossier projet — un livrable que l'intégrateur relit et applique lui-même côté thème.

Créer une nouvelle variable (`$sds-*`) est une **exception**, réservée aux tokens SDS qui n'ont réellement aucun équivalent dans la nomenclature Bootstrap — y compris parmi les dix teintes natives. Ce n'est jamais le comportement par défaut : avant de créer quoi que ce soit, vérifie si une teinte Bootstrap native inutilisée par le projet (ex. `$teal`, `$cyan`, `$indigo`, `$purple`) peut porter la couleur de marque à la place.

> Un mode alternatif « custom properties CSS runtime » (génération d'un fichier `--sds-*` séparé, pour un theming dynamique sans recompilation Sass) reste possible mais uniquement sur demande explicite de l'utilisateur — ce n'est plus le comportement par défaut de ce skill.

**Prérequis** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. La lecture Figma est en **lecture seule** — ce skill ne modifie pas le canvas Figma. L'écriture se fait uniquement sur `Export/_variables.scss`, en modifiant les lignes existantes (jamais de réécriture complète du fichier).

---

## Déclenchement

Ce skill est activé par `/sync-sds-bootstrap` ou quand l'utilisateur demande à "générer les tokens SCSS", "synchroniser les variables Figma", "mettre à jour les variables Bootstrap", "aligner _variables.scss sur le SDS".

---

## Comportement

### Étape 0 — Lecture du contexte

1. **Lis `brief-projet.md`** : stack technique, conventions de nommage dérogatoires, URL SDS, le **chemin de référence du fichier `_variables.scss` de production** (champ `Chemin fichier variables Bootstrap`) et le **chemin du livrable** (`Export/_variables.scss` à la racine du dossier projet, par défaut — pas besoin de le demander sauf si le projet utilise déjà une autre convention de dossier de livrables).
2. Si le chemin de référence production n'est pas renseigné dans `brief-projet.md`, demande-le à l'utilisateur puis propose de l'ajouter au brief pour les prochaines synchronisations — le chemin est spécifique à chaque thème/projet (ex. `wp-content/themes/<theme>/scss/_variables.scss` pour un thème WordPress) et ne doit pas être deviné par convention générique.
3. Ne demande le mode light/dark que si le fichier cible contient déjà un mécanisme de mode sombre propre au projet (variables `$primary-bg-subtle` de Bootstrap ≥5.3, ou `[data-bs-theme="dark"]` déjà présent). **Ne crée jamais un mécanisme de dark mode qui n'existe pas déjà dans le projet.**

---

### Étape 1 — Préparation et lecture du fichier `_variables.scss`

1. **Si `Export/_variables.scss` n'existe pas encore** dans le dossier projet, crée-le en copiant intégralement le fichier de référence production (chemin lu à l'Étape 0) — c'est l'état de départ, avant toute synchronisation SDS.
2. **Si `Export/_variables.scss` existe déjà** (une synchronisation précédente a eu lieu), travaille sur cette copie directement — ne réinitialise pas depuis la production, sous peine d'écraser des ajustements déjà validés dans le livrable. Si l'utilisateur veut repartir de zéro depuis la production, il doit le demander explicitement.
3. Lis le fichier `Export/_variables.scss` en entier (`Read`, avec pagination si nécessaire) et repère :
   - Les variables déjà présentes (motif `^\$[\w-]+:\s*.+;`), leur valeur actuelle, et si elles portent `!default` ou non.
   - **Les lignes sans `!default`** : dans la convention ads-COM, l'absence de `!default` signale une valeur déjà pilotée manuellement (personnalisation de marque, ex. `$blue`, `$primary`, `$spacer` sur un projet déjà entamé). Note-les pour ne jamais les écraser silencieusement — si le token SDS correspondant diverge de la valeur actuelle, signale le conflit à l'utilisateur avant d'écraser.
   - Les maps existantes (`$theme-colors`, `$colors`, `$grays`, `$spacers`, `$container-max-widths`...) et leurs clés actuelles — pour étendre plutôt que remplacer.
   - La version de Bootstrap déduite de la structure du fichier (présence ou non de `$body-secondary-bg`, `$primary-bg-subtle`, etc. → Bootstrap ≥5.2/5.3) : la disponibilité de certaines variables natives dépend de la version.
   - **Les dix teintes natives Bootstrap** (`$blue`, `$indigo`, `$purple`, `$pink`, `$red`, `$orange`, `$yellow`, `$green`, `$teal`, `$cyan`) et lesquelles sont réellement référencées ailleurs dans le fichier (`$theme-colors`, `$colors`, ou une variable de composant) — une teinte non référencée est un candidat naturel pour porter une couleur de marque SDS qui n'a pas d'équivalent Bootstrap direct (voir Étape 3, règle 2bis).

---

### Étape 2 — Extraction des tokens SDS depuis Figma

**Script 2a — Collections et modes disponibles**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
return collections.map(c => ({
  name: c.name,
  id: c.id,
  remote: c.remote,
  modes: c.modes,
  variableCount: c.variableIds.length
}));
```

Identifie :
- La collection **Color Primitives** (ou équivalent) — valeurs hex brutes
- La collection **Color** sémantique — alias avec modes Light/Dark
- La collection **Number**/**Size** — espacements, rayons
- La collection **Typography Primitives**/**Type** (ou équivalent) — familles de police, échelle de tailles, poids (souvent avec des modes par device : Desktop/Mobile/Tablet)
- La collection **Typography**/**Type Styles** (ou équivalent) — styles sémantiques (Heading, Title, Body, Code...) qui aliasent la collection primitive ci-dessus

**Script 2b — Variables Color Primitives avec leurs valeurs hex**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const primitiveCol = collections.find(c =>
  c.name.toLowerCase().includes('primitive') ||
  c.name.toLowerCase().includes('primitif') ||
  c.name.toLowerCase().includes('foundation') ||
  c.name.toLowerCase().includes('base')
);
if (!primitiveCol) return { error: 'Collection primitives introuvable', available: collections.map(c => c.name) };

const vars = await Promise.all(
  primitiveCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
);
const modeId = primitiveCol.modes[0].modeId;

return vars
  .filter(v => v.resolvedType === 'COLOR')
  .map(v => {
    const val = v.valuesByMode[modeId];
    const isAlias = val && 'type' in val && val.type === 'VARIABLE_ALIAS';
    const hex = !isAlias && val && 'r' in val
      ? '#' + ['r','g','b'].map(k => Math.round(val[k] * 255).toString(16).padStart(2,'0')).join('')
      : null;
    return { name: v.name, id: v.id, hex, isAlias };
  });
```

**Script 2c — Variables sémantiques avec résolution des alias**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const semanticCol = collections.find(c =>
  !c.name.toLowerCase().includes('primitive') &&
  !c.name.toLowerCase().includes('primitif') &&
  !c.name.toLowerCase().includes('foundation') &&
  !c.name.toLowerCase().includes('number') &&
  !c.name.toLowerCase().includes('boolean') &&
  c.variableIds.length > 0
) ?? collections.find(c => c.modes.length > 1); // fallback : collection avec plusieurs modes

if (!semanticCol) return { error: 'Collection sémantique introuvable' };

const lightMode = semanticCol.modes.find(m => m.name.toLowerCase().includes('light') || m.name.toLowerCase() === 'default') ?? semanticCol.modes[0];
const darkMode = semanticCol.modes.find(m => m.name.toLowerCase().includes('dark')) ?? null;

const allVars = await figma.variables.getLocalVariablesAsync();
const varById = Object.fromEntries(allVars.map(v => [v.id, v]));

const vars = await Promise.all(
  semanticCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
);

function resolveValue(val, varById) {
  if (!val) return null;
  if ('type' in val && val.type === 'VARIABLE_ALIAS') {
    const aliased = varById[val.id];
    if (!aliased) return { alias: val.id, unresolved: true };
    const modeId = Object.keys(aliased.valuesByMode)[0];
    return { alias: aliased.name, hex: resolveHex(aliased.valuesByMode[modeId], varById) };
  }
  return { hex: 'r' in val ? '#' + ['r','g','b'].map(k => Math.round(val[k] * 255).toString(16).padStart(2,'0')).join('') : null };
}

function resolveHex(val, varById) {
  if (!val) return null;
  if ('type' in val && val.type === 'VARIABLE_ALIAS') {
    const aliased = varById[val.id];
    if (!aliased) return null;
    const modeId = Object.keys(aliased.valuesByMode)[0];
    return resolveHex(aliased.valuesByMode[modeId], varById);
  }
  return 'r' in val ? '#' + ['r','g','b'].map(k => Math.round(val[k] * 255).toString(16).padStart(2,'0')).join('') : null;
}

return vars
  .filter(v => v.resolvedType === 'COLOR')
  .map(v => ({
    name: v.name,
    id: v.id,
    light: resolveValue(v.valuesByMode[lightMode.modeId], varById),
    dark: darkMode ? resolveValue(v.valuesByMode[darkMode.modeId], varById) : null
  }));
```

**Script 2d — Variables Number (espacements, rayons)**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const numberCol = collections.find(c =>
  c.name.toLowerCase().includes('number') ||
  c.name.toLowerCase().includes('spacing') ||
  c.name.toLowerCase().includes('size')
);
if (!numberCol) return { notFound: true };

const vars = await Promise.all(
  numberCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
);
const modeId = numberCol.modes[0].modeId;
return vars
  .filter(v => v.resolvedType === 'FLOAT')
  .map(v => ({ name: v.name, value: v.valuesByMode[modeId] }));
```

**Script 2e — Typography Primitives (familles, échelle, poids)**

Si les modes de la collection incluent des devices (`Desktop`/`Mobile`/`Tablet`), utilise **toujours le mode `Desktop`** comme référence pour `_variables.scss` — Bootstrap n'a pas de mécanisme de variable Sass responsive par breakpoint ; l'adaptation mobile passe par le RFS natif de Bootstrap (`$enable-rfs`), pas par une seconde valeur de variable (voir Étape 3, règle 6).

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const typoCol = collections.find(c =>
  c.name.toLowerCase().includes('typography primitive') ||
  c.name.toLowerCase().includes('type primitive') ||
  (c.name.toLowerCase().includes('typo') && c.name.toLowerCase().includes('primitiv'))
);
if (!typoCol) return { notFound: true, available: collections.map(c => c.name) };

const desktopMode = typoCol.modes.find(m => m.name.toLowerCase().includes('desktop')) ?? typoCol.modes[0];
const vars = await Promise.all(typoCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id)));

return vars.map(v => ({
  name: v.name,
  type: v.resolvedType,
  value: v.valuesByMode[desktopMode.modeId]
}));
```

**Script 2f — Typography sémantique (styles de type, avec résolution des alias vers les primitives)**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const typoStyleCol = collections.find(c =>
  c.name.toLowerCase() === 'typography' ||
  c.name.toLowerCase().includes('type style') ||
  c.name.toLowerCase().includes('type ramp')
);
if (!typoStyleCol) return { notFound: true };

const allVars = await figma.variables.getLocalVariablesAsync();
const varById = Object.fromEntries(allVars.map(v => [v.id, v]));

function resolve(val) {
  if (!val) return null;
  if ('type' in val && val.type === 'VARIABLE_ALIAS') {
    const aliased = varById[val.id];
    if (!aliased) return { unresolved: true, id: val.id };
    // Préfère le mode Desktop si la primitive résolue en a un
    const modeEntry = Object.entries(aliased.valuesByMode).find(([, m]) =>
      false // placeholder, remplacé ci-dessous pour lisibilité
    );
    const modeId = aliased.valuesByMode['9:2'] !== undefined ? '9:2' : Object.keys(aliased.valuesByMode)[0];
    return { resolvedFrom: aliased.name, value: aliased.valuesByMode[modeId] };
  }
  return { value: val };
}

const modeId = typoStyleCol.modes[0].modeId; // généralement un seul mode ("Mode 1")
const vars = await Promise.all(typoStyleCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id)));

return vars.map(v => ({
  name: v.name, // ex. "Title Hero/Size", "Heading/Font Weight", "Body/Font Family"
  resolved: resolve(v.valuesByMode[modeId])
}));
```

> Le mode id `9:2` codé en dur dans le script ci-dessus est un raccourci illustratif (mode "Desktop" observé sur RJAC) — en pratique, résous dynamiquement le mode Desktop de la collection Typography Primitives à l'Étape 2e plutôt que de coder un id en dur, puis réutilise ce `modeId` ici.

---

### Étape 3 — Mapping Figma → variables Sass natives

Consulte `assets/tokens-bootstrap.md` du skill `mapping-design-system` : la colonne **« Token Bootstrap »** (`$primary`, `$body-bg`, `$border-radius`...) est la cible d'écriture — **jamais** la colonne « Variable CSS » (`--bs-*`), que Bootstrap génère automatiquement depuis les variables Sass au moment de la compilation.

Règles de mapping, dans l'ordre de priorité :

1. **Cherche d'abord une variable Bootstrap native.** Un token sémantique SDS (`Action/primary`, `Status/positive`, `Background/default`...) correspond quasi toujours à une variable Sass existante (`$primary`, `$success`, `$body-bg`...) — voir la table de `tokens-bootstrap.md`. Utilise cette variable.
2. **Primitifs de teinte (hue) → variable de base uniquement.** Une famille de couleurs Figma (`Blue/50` à `Blue/900`) ne doit **pas** être recopiée shade par shade : Bootstrap calcule déjà `$blue-100`…`$blue-900` via `tint-color($blue, …)` / `shade-color($blue, …)` à partir de la seule variable `$blue` (voir la table « Primitifs de teinte » de `tokens-bootstrap.md`). Écris uniquement la variable de base, à partir du primitif Figma le plus proche de la teinte de référence (~500/600). Ne surcharge une shade individuelle (`$blue-600`, etc.) que si sa valeur Figma diverge visiblement de la valeur que Bootstrap calculerait automatiquement — dans ce cas seulement, documente l'écart en commentaire.
2bis. **Une couleur de marque (`$primary`, `$secondary`...) sans variable Bootstrap dédiée doit d'abord chercher une teinte native inutilisée avant d'écrire un hex brut.** Si un token sémantique SDS (ex. `Background/Brand/Default`) n'a pas de correspondance directe (`$primary` n'a pas d'équivalent "brand" propre — c'est déjà la variable la plus proche), et que la famille primitive Figma d'origine (ex. `Brand`, `Teal`) ne porte pas le même nom qu'une teinte Bootstrap : choisis, parmi les dix teintes natives repérées à l'Étape 1 comme non référencées ailleurs dans le fichier, celle dont l'apparence se rapproche le plus (ex. une couleur bleu-vert → `$teal` plutôt que `$blue` si `$blue` est déjà utilisé pour autre chose ou n'a pas de rapport). Écris la valeur exacte du token sémantique dans cette teinte, puis fais pointer l'alias existant vers elle (`$primary: $blue;` → `$primary: $teal;`) — **ne remplace jamais `$primary`/`$secondary` par un hex littéral** tant qu'une teinte native est disponible pour porter la valeur : cela préserve la structure d'alias déjà en place dans le fichier et garde `$primary`/`$secondary` lisibles comme des références, pas des valeurs figées.
2ter. **Variantes d'une couleur de marque déjà mappée (`Default Dark`, `Secondary Hover`, `Tertiary`...) → variables de rôle en hex direct, regroupées dans le bloc `theme-color-variables`, jamais dispersées dans le fichier.** Un SDS expose souvent plusieurs paliers pour une même couleur de marque (ex. `Background/Brand/Default`, `Default Dark`, `Default Darker`, `Default Light`, `Default Lighter`, `Hover`). Ces paliers n'ont pas d'équivalent Bootstrap natif (pas de convention `-dark`/`-light` pour les theme colors) : c'est une extension de nomenclature propre au projet, à faire confirmer par l'utilisateur avant de créer (comme toute exception de la règle 6) — une fois validée pour un rôle (`-dark`), applique le même principe aux autres marques (`$secondary-dark`, `$tertiary-dark`...) sans redemander à chaque fois.
   - **Utilise un hex littéral, pas un alias vers l'échelle de teinte (`$teal-900` etc.).** Deux raisons : (1) ça évite la contrainte d'ordre Sass — le fichier s'évalue de haut en bas, et l'échelle de teinte (`$teal-100`…`$teal-900`) n'est définie que dans le bloc `fusv-disable`/`fusv-enable`, *après* `theme-color-variables` ; aliasing forcerait à séparer physiquement la déclaration de rôle de sa couleur de base. (2) l'utilisateur préfère voir toute la gamme d'une marque groupée au même endroit, immédiatement après la variable de base, plutôt qu'éclatée entre le haut et le bas du fichier.
   - **Regroupe par marque, dans l'ordre `$primary` → variantes → ligne vide → `$secondary` → variantes → ligne vide → `$tertiary` → variantes**, le tout à l'intérieur du bloc `// scss-docs-start theme-color-variables` … `// scss-docs-end theme-color-variables`, juste après (ou à la place de) la ligne de la couleur de base. Exemple observé sur RJAC :
     ```scss
     $primary:         $teal; // SDS Figma — Background/Brand/Default (Brand/800)
     $primary-dark:    #0e4953; // SDS Figma — Background/Brand/Default Dark (Brand/900)
     $primary-darker:  #093239; // SDS Figma — Background/Brand/Default Darker (Brand/1000)
     $primary-light:   #61cde0; // SDS Figma — Background/Brand/Default Light (Brand/400)
     $primary-lighter: #ceedf3; // SDS Figma — Background/Brand/Default Lighter (Brand/200)
     $primary-hover:   #0e4953; // SDS Figma — Background/Brand/Hover (Brand/900)
     ```
   - La couleur de base elle-même (`$primary`, `$secondary`, `$tertiary`) reste sur le principe de la règle 2bis (alias vers une teinte native) — seules ses *variantes* (`-dark`, `-light`...) passent en hex direct.
   - Pour une couleur de marque qui réutilise une teinte déjà mappée par ailleurs sans besoin de palier différent (ex. `Background/Brand/Tertiary` = la même teinte que `$green` déjà en place), pas besoin de toucher l'échelle : alias directement la teinte de base (`$tertiary: $green;`), cohérent avec la règle 1.
   - Ne modifie **pas** l'échelle de teinte native (`$teal-900` etc.) pour ce cas d'usage — elle reste sur ses valeurs Bootstrap par défaut (`shade-color()`/`tint-color()`, `!default`), sauf besoin explicite ailleurs dans le projet (règle 2).
3. **Ne duplique jamais une valeur déjà calculée par une formule Bootstrap.** États hover/active (`shade-color($primary, $btn-hover-bg-shade-amount)`), triplets `-rgb`, `rgba()` de focus ring : laisse la formule native produire la valeur. N'écris une valeur brute que si Figma fournit une valeur *différente* de ce que la formule donnerait — et dans ce cas, indique en commentaire que c'est un écart volontaire par rapport au calcul Bootstrap standard.
4. **Espacements → étends la map existante, ne la remplace pas.** Si le projet a déjà personnalisé `$spacer`/`$spacers` (échelle et clés propres au projet), aligne les nouvelles valeurs Figma sur cette échelle existante (trouve la clé la plus proche) plutôt que d'introduire un système `--sds-spacing-*` séparé. N'ajoute une nouvelle clé à `$spacers` que si aucune clé existante ne correspond à la valeur Figma.
5. **Rayons et propriétés de composant → variables `$<composant>-<propriété>` existantes.** `$border-radius*` pour l'échelle générale ; variables spécifiques (`$btn-border-radius`, `$card-border-radius`, `$input-border-radius`, `$modal-content-border-radius`, `$btn-padding-y`, `$card-spacer-x`...) uniquement si un token Figma nomme explicitement ce composant (ex. `Radius/Card Radius`) **ou** si la ligne est déjà personnalisée séparément (sans `!default`) — sinon laisse-les hériter de la variable générale (`$border-radius`, `$spacer`...) par défaut, comme le fait Bootstrap nativement. Cette règle s'applique à toute propriété de composant, pas seulement aux rayons : un token Figma `Button/Padding` chercherait `$btn-padding-y`/`$btn-padding-x`, un token `Input/Border Width` chercherait `$input-border-width`, etc. — **cherche toujours le nom du composant Figma dans le préfixe des variables Bootstrap** (`$btn-*`, `$card-*`, `$input-*`, `$nav-*`, `$modal-*`, `$dropdown-*`...) avant de conclure qu'aucune variable native n'existe.
6. **Familles de police → `$font-family-*`, en complétant la pile de fallback, jamais en la remplaçant.** `Family Sans`/`Family Body` → `$font-family-sans-serif` (ou `$font-family-base` s'il est déjà littéral) : préfixe la police Figma devant la pile de fallback système existante (`"Nom Figma", system-ui, -apple-system, ...`), ne supprime pas les fallbacks. `Family Heading` (si distincte de la police body) → `$headings-font-family`. `Family Mono`/`Family Code` → `$font-family-monospace`, même logique de préfixe. Une famille sans variable Bootstrap native correspondante (ex. `Family Serif` quand le projet n'utilise pas de `$font-family-serif`) reste non mappée — signale-la dans le résumé plutôt que d'inventer une variable, sauf besoin explicite confirmé par l'utilisateur.
7. **Tailles de police → résoudre le mode Desktop, puis mapper par intention sémantique, pas par ordre alphabétique.** Les noms Figma (`Title Hero`, `Title Page`, `Heading`, `Subheading`, `Subtitle`, `Body`, `Code`) ne correspondent pas terme à terme à `$h1`…`$h6` : propose un mapping raisonné et **demande confirmation avant d'écrire**, par exemple :
   - `Title Hero` (le plus grand, souvent hors du flux `h1`-`h6`) → une entrée de la map `$display-font-sizes` (`display-1` etc.) plutôt qu'un `$h1-font-size` détourné — Bootstrap a déjà cette fonctionnalité pour les gros titres hero, prévue pour ce cas précis.
   - `Title Page` → `$h1-font-size`
   - `Heading` → `$h2-font-size`/`$h3-font-size` selon le nombre de niveaux `Heading`/`Subheading` distincts dans le SDS
   - `Body` (taille "Medium"/"Base") → `$font-size-base` ; ses variantes Small/Large → `$font-size-sm`/`$font-size-lg`
   - `Subtitle` → `$lead-font-size` si son usage correspond à un chapeau/intro, sinon laisse en note
   - `Code` → `$code-font-size`
   Si le SDS a plus ou moins de niveaux que Bootstrap n'en propose nativement (6 titres + display), signale l'écart dans le résumé plutôt que de forcer un mapping approximatif.
8. **Poids de police → `$font-weight-*` uniquement pour les paliers nommés par Bootstrap** (`$font-weight-light` = 300, `$font-weight-normal` = 400, `$font-weight-bold` = 700 : mappe directement `Weight Light`/`Weight Regular`/`Weight Bold` si les valeurs numériques correspondent). Pour un poids intermédiaire sans variable Bootstrap dédiée (`Weight Medium` = 500, `Weight Semibold` = 600), **n'invente pas de variable** : la plupart des variables de composant Bootstrap (`$headings-font-weight`, `$btn-font-weight`...) acceptent déjà un nombre littéral — vérifie si la ligne existante porte déjà cette valeur exacte (ex. `$headings-font-weight: 500` correspond déjà à `Weight Medium`) avant de la modifier ; sinon mets à jour le littéral avec un commentaire de source, sans créer de variable.
9. **Exception — création de variable.** Si un token sémantique SDS n'a réellement aucun équivalent Bootstrap, même en élargissant la recherche aux préfixes de composant (règle 5) et aux fallbacks de police (règle 6) (cas rare : token de marque très spécifique, ex. `Illustration/accent`, `Family Serif` sans usage prévu), crée une variable `$sds-<nom>` avec `!default`, dans une nouvelle section en fin de fichier intitulée `// Variables custom SDS (hors nomenclature Bootstrap)`, avec un commentaire expliquant pourquoi aucune variable native ne convient. **Demande confirmation avant de créer une telle variable.**

---

### Étape 4 — Application des modifications

Pour chaque variable Bootstrap native concernée :

1. Localise sa ligne exacte dans **`Export/_variables.scss`** (`Grep`, ou relecture de l'Étape 1) — **jamais dans le fichier de production**.
2. Modifie la valeur avec l'outil `Edit` (`old_string`/`new_string` sur la ligne complète), en conservant l'alignement et les commentaires existants du fichier.
3. **Retire `!default`** sur toute ligne modifiée par ce skill — c'est la convention ads-COM pour signaler qu'une valeur est pilotée par le SDS Figma (cohérent avec les personnalisations déjà présentes dans les fichiers ads-COM). Une ligne qui garde `!default` signifie qu'elle n'a jamais été alignée sur le SDS. Ajoute un commentaire court `// SDS Figma — <nom du token>` en fin de ligne pour tracer la source.
4. **Ne réécris jamais le fichier entier** avec `Write` (sauf pour l'amorce de l'Étape 1.1, la copie initiale depuis la production) — préserve la structure Bootstrap standard (sections `scss-docs-start/end`, commentaires, ordre des variables) et les personnalisations non liées au SDS repérées à l'Étape 1.
5. Si une valeur Figma ne peut pas être résolue (alias manquant, variable introuvable), **laisse la ligne existante inchangée** et signale-le dans le résumé — n'insère jamais de valeur `null`/`TODO` dans le SCSS : le fichier doit rester compilable à tout moment.
6. **Le fichier de production n'est jamais ouvert en écriture par ce skill**, à aucune étape. C'est à l'intégrateur de reporter manuellement le contenu de `Export/_variables.scss` vers le thème, quand il le juge prêt.

---

### Étape 5 — Résumé

Affiche un tableau récapitulatif avant/après :

| Variable Sass | Ancienne valeur | Nouvelle valeur | Source Figma |
|---|---|---|---|
| `$primary` | `#0d6efd` | `#0b1a4d` | `Action/primary` |
| `$border-radius` | `.25rem` | `.375rem` | `Radius/md` |
| ... | | | |

Liste séparément :
- Les tokens SDS sans équivalent Bootstrap trouvé — proposer soit de les ignorer, soit de créer une variable `$sds-*` (demander confirmation avant de créer).
- Les lignes qui portaient déjà une personnalisation manuelle (sans `!default`) et qui divergent du SDS — **demander confirmation avant d'écraser**.

---

## Règles de conduite

- **Ne jamais écrire dans le fichier de production du thème.** Toute écriture cible exclusivement `Export/_variables.scss` à la racine du dossier projet — le fichier de production n'est lu qu'une fois, comme référence pour amorcer la copie initiale.
- **Toujours chercher une variable Bootstrap native avant d'envisager une variable custom** — y compris une des dix teintes natives inutilisées (`$blue`/`$indigo`/`$purple`/`$pink`/`$red`/`$orange`/`$yellow`/`$green`/`$teal`/`$cyan`) pour porter une couleur de marque sans variable dédiée. La création de `$sds-*` est l'exception, jamais la norme.
- **Ne jamais écrire un hex littéral dans `$primary`/`$secondary`/`$success`/etc. si une teinte native peut porter la valeur à leur place** — préserve la structure d'alias déjà présente dans le fichier (`$primary: $teal;` plutôt que `$primary: #156a79;`).
- **Ne jamais dupliquer une valeur que Bootstrap calcule déjà nativement** (déclinaisons de teintes, triplets `-rgb`, états hover/focus dérivés par les fonctions Sass de Bootstrap).
- **Modifier le fichier en place** (`Edit`), jamais de réécriture complète (`Write`) — `_variables.scss` appartient au thème et contient des personnalisations non liées au SDS.
- **Retirer `!default`** sur les lignes modifiées, pour signaler qu'elles sont désormais pilotées par le SDS Figma.
- **Ne jamais écraser silencieusement** une ligne déjà personnalisée manuellement (sans `!default`) sans le signaler et demander confirmation.
- **Ne jamais inventer un mécanisme (dark mode, prefix de custom properties CSS) qui n'existe pas déjà dans le projet.**
- Propose à la fin un résumé avant/après et la liste des tokens non mappés — n'écris rien tant qu'un conflit détecté à l'Étape 1 n'a pas été validé explicitement par l'utilisateur.
