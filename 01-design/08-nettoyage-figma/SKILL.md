---
name: 08-nettoyage-figma
description: Exécute des opérations de nettoyage destructives directement dans un fichier Figma, en suivant les rapports de mapping du design system SDS.
---


# Skill : nettoyage-figma

## Rôle

Tu es un automaticien de fichiers Figma chez ads-COM. Quand ce skill est activé, tu exécutes des opérations de nettoyage **destructives** directement dans le canvas via `use_figma` : renommage sémantique des calques, liaison des couleurs hardcodées aux variables SDS, liaison des nœuds de texte aux styles SDS, liaison des paddings/gaps/radius aux variables `Size`, et détachement/ré-instanciation des composants (boutons et assimilés). Tu lis le rapport `mapping-ds-*.md` pour cibler les priorités de chaque volet. Toute écriture dans Figma est **irréversible sans Ctrl+Z** — tu demandes une confirmation globale avant d'exécuter. La ré-instanciation de composants (Opération F) restructure la hiérarchie et est plus risquée qu'un simple binding de propriété — vérifie toujours visuellement (`get_screenshot`) après chaque remplacement.

**Prérequis obligatoire** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. Applique toutes ses règles sans exception, en particulier : retourner tous les IDs mutés, travailler par petits lots (max 10 opérations par appel), arrêter sur erreur sans retry immédiat.

---

## Déclenchement

Ce skill est activé par `/nettoyage-figma` ou quand l'utilisateur demande à "nettoyer le fichier Figma", "renommer les calques", "lier les couleurs SDS", "lier les styles de texte", "lier les espacements", "corriger les radius", "instancier les composants", "remplacer les boutons bruts".

---

## Comportement

### Étape 0 — Chargement du contexte et confirmation

1. **Cherche `mapping-ds-*.md`** à la racine du projet (prends le plus récent). Extrait :
   - La liste des couleurs à lier (section "À lier — correspondance SDS exacte") avec leurs hex et tokens SDS cibles
   - Les primitifs à créer si nécessaire
   - La liste des styles de texte à lier (section "Mapping des styles de texte") avec les combinaisons famille/graisse/taille et le style SDS cible
   - La liste des espacements/radius à lier (section "Mapping des espacements et radius") avec les valeurs et variables `Size` cibles, ainsi que les correctifs "pilule cassée" suggérés
   - Les correspondances de composants proposées (section "Audit des composants") avec le composant/variante cible
   - Les cas signalés comme "à confirmer avec le designer" ou "aucune correspondance disponible" — ne jamais les traiter sans validation explicite de l'utilisateur

2. **Lis `brief-projet.md`** pour les conventions de nommage déclarées.

3. **Demande le périmètre du nettoyage** si non précisé :
   ```
   Six opérations disponibles :
   A — Renommage sémantique des calques
   B — Liaison des couleurs hardcodées → variables SDS
   C — Ré-instanciation des frames brutes en composants
   D — Liaison des nœuds de texte → styles SDS
   E — Liaison des paddings/gaps/radius → variables Size
   F — Remplacement des boutons/composants bruts par des instances SDS

   Quelles opérations lancer ? (ex. "A et B", "tout", "seulement B")
   ```

4. **Annonce le plan et demande confirmation** avant toute écriture :
   ```
   ⚠️  Ces opérations modifient directement le fichier Figma.
   Assure-toi d'avoir une version sauvegardée (Figma sauvegarde automatiquement,
   mais un Ctrl+Z peut être limité après de nombreuses opérations).

   Plan :
   - Renommage : ~<N> calques génériques détectés
   - Liaison couleurs : <N> hex uniques → <N> tokens SDS
   - Ré-instanciation : <N> frames candidates
   - Liaison styles de texte : <N> combinaisons → <N> styles SDS (<N> cas à confirmer avant liaison)
   - Liaison espacements/radius : <N> valeurs → <N> variables Size (<N> correctifs "pilule cassée")
   - Remplacement composants : <N> nœuds bruts → instances SDS (<N> sans correspondance, non traités)

   Confirmes-tu le lancement ? (oui / non)
   ```

---

### Opération A — Renommage sémantique des calques

Détecte les calques avec des noms génériques Figma (auto-générés ou non significatifs) et les renomme selon la convention `type/role` ou `composant/variante`.

**Script 1 — Détection des noms génériques**

```javascript
const page = figma.currentPage;
const genericPatterns = [
  /^(frame|group|rectangle|ellipse|vector|polygon|star|line|image)\s*\d*$/i,
  /^(frame|group|rectangle|ellipse|vector)\s+\d+$/i,
  /^\d+:\d+$/,  // IDs bruts
  /^(layer|calque)\s*\d*$/i
];

const generics = [];
page.findAll(n => {
  const name = n.name?.trim() ?? '';
  if (genericPatterns.some(p => p.test(name))) {
    generics.push({
      id: n.id,
      name,
      type: n.type,
      parentName: n.parent?.name ?? '',
      childCount: n.children?.length ?? 0,
      width: Math.round(n.width),
      height: Math.round(n.height)
    });
  }
  return false;
});
return { count: generics.length, nodes: generics.slice(0, 40) };
```

**Script 2 — Renommage par lot** (max 15 nœuds par appel)

Pour chaque nœud détecté, génère un nom selon ces règles :
- `FRAME` contenant des éléments → `section/<rôle-déduit-du-contenu>`
- `FRAME` vide ou fond → `_bg` ou `_layout/<position>`
- `RECTANGLE` avec fill image → `img/<sujet-si-déductible>`
- `RECTANGLE` aplat → `shape/<couleur-ou-rôle>`
- `GROUP` → `group/<rôle>` ou décomposer si possible
- `VECTOR/ELLIPSE` dans un bouton → garder le nom parent, nommer `icon` ou `dot`

```javascript
// Passe les IDs et nouveaux noms depuis l'analyse précédente
const renames = [
  { id: '<NODE_ID_1>', newName: '<nom-sémantique-1>' },
  { id: '<NODE_ID_2>', newName: '<nom-sémantique-2>' }
  // ... max 15 par appel
];

const mutatedNodeIds = [];
for (const { id, newName } of renames) {
  const node = figma.getNodeById(id);
  if (!node) continue;
  node.name = newName;
  mutatedNodeIds.push(id);
}
return { mutatedNodeIds, count: mutatedNodeIds.length };
```

---

### Opération B — Liaison des couleurs hardcodées → variables SDS

Utilise les données du rapport `mapping-ds-*.md` : liste de hex → token SDS avec IDs de collection.

**Script 1 — Récupérer les IDs de variables SDS cibles**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const targetNames = [
  'Action/primary',
  'Text/primary',
  'Border/default'
  // Compléter depuis le rapport mapping
];

const varMap = {};
for (const col of collections) {
  const vars = await Promise.all(
    col.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
  );
  for (const v of vars) {
    if (targetNames.includes(v.name)) {
      varMap[v.name] = v.id;
    }
  }
}
return varMap;
```

**Script 2 — Liaison fill par couleur hex cible** (un hex à la fois, max 30 nœuds par appel)

```javascript
// Paramètres à injecter depuis le rapport :
// targetHex : ex. '#0d6efd'
// variableId : ID de la variable SDS cible
// property : 'fills' ou 'strokes'

const targetHex = '<HEX>';
const variableId = '<VARIABLE_ID>';
const property = 'fills'; // ou 'strokes'

function toHex(c) {
  return '#' + [c.r, c.g, c.b]
    .map(v => Math.round(v * 255).toString(16).padStart(2, '0')).join('');
}

const variable = await figma.variables.getVariableByIdAsync(variableId);
if (!variable) return { error: `Variable ${variableId} introuvable` };

const page = figma.currentPage;
const mutatedNodeIds = [];
let processedCount = 0;

page.findAll(n => {
  if (processedCount >= 30) return false;
  const fills = n[property];
  if (!Array.isArray(fills)) return false;
  const bv = n.boundVariables ?? {};
  const boundArr = Array.isArray(bv[property]) ? bv[property] : [];

  let changed = false;
  const newFills = fills.map((fill, i) => {
    if (fill.type !== 'SOLID' || fill.visible === false) return fill;
    if (boundArr[i]?.id) return fill; // deja lie a une variable (meme si meme hex qu'une autre) -> ne jamais reassigner
    if (toHex(fill.color) !== targetHex) return fill;
    const boundPaint = figma.variables.setBoundVariableForPaint(fill, 'color', variable);
    changed = true;
    return boundPaint;
  });

  if (changed) {
    n[property] = newFills;
    mutatedNodeIds.push(n.id);
    processedCount++;
  }
  return false;
});

return { mutatedNodeIds, processedCount, targetHex, variableId };
```

**⚠️ Piège vérifié en pratique (incident réel du 2026-07-22, projet Neocampus) :** sans la vérification `boundArr[i]?.id` ci-dessus, un nœud déjà lié à un token SDS différent (ex. `Background/Brand/Default`) qui partage la même valeur hex que le token ciblé (ex. `Icon/Brand/Default`, même bleu de marque) est silencieusement réassigné vers le mauvais rôle sémantique. Aucune régression visuelle n'est détectable au screenshot — seul un contrôle explicite de `boundVariables` avant/après le révèle. Cela s'est produit sur des instances de composants partagés (header/footer) où la plupart des couleurs étaient déjà correctement liées : une correspondance par simple valeur hex, sans ce garde-fou, a reclassé des dizaines de nœuds vers un token incorrect. **Ne jamais retirer cette vérification, même pour aller plus vite.**

**Répète ce script pour chaque hex de la liste "À lier — correspondance exacte" du rapport mapping.** Traite un hex à la fois, valide entre chaque lot.

---

### Opération C — Ré-instanciation des frames brutes en composants

Détecte les frames qui sont des duplications de composants existants (même structure, même nom de fils) et les remplace par des instances.

**Script 1 — Identifier les composants locaux disponibles**

```javascript
const components = [];
for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  page.findAll(n => {
    if (n.type === 'COMPONENT' || n.type === 'COMPONENT_SET') {
      components.push({ name: n.name, id: n.id, key: n.key, page: page.name, type: n.type });
    }
    return false;
  });
}
return components;
```

**Script 2 — Détecter les frames candidates (même structure qu'un composant connu)**

```javascript
// Injecter componentName et componentChildNames depuis le script précédent
const componentName = '<NOM_COMPOSANT>';
const page = figma.currentPage;
const candidates = [];

page.findAll(n => {
  if (n.type !== 'FRAME' && n.type !== 'GROUP') return false;
  if (n.name !== componentName) return false; // même nom de calque
  candidates.push({
    id: n.id,
    name: n.name,
    parentId: n.parent?.id,
    x: Math.round(n.x),
    y: Math.round(n.y),
    width: Math.round(n.width),
    height: Math.round(n.height),
    childNames: n.children?.map(c => c.name) ?? []
  });
  return false;
});
return candidates;
```

**Script 3 — Ré-instanciation** (max 5 nœuds par appel — opération sensible)

```javascript
// componentKey : clé du composant source
// candidateIds : IDs des frames à remplacer (max 5)
const componentKey = '<COMPONENT_KEY>';
const candidateIds = ['<ID_1>', '<ID_2>'];

const component = await figma.importComponentByKeyAsync(componentKey);
const mutatedNodeIds = [];

for (const id of candidateIds) {
  const frame = figma.getNodeById(id);
  if (!frame || !frame.parent) continue;

  const parent = frame.parent;
  const index = parent.children.indexOf(frame);
  const { x, y, width, height } = frame;

  const instance = component.createInstance();
  parent.insertChild(index, instance);
  instance.x = x;
  instance.y = y;
  instance.resize(width, height);

  frame.remove();
  mutatedNodeIds.push(instance.id);
}

return { mutatedNodeIds, replacedCount: mutatedNodeIds.length };
```

---

### Opération D — Liaison des nœuds de texte → styles SDS

Utilise les données de la section "Mapping des styles de texte" du rapport `mapping-ds-*.md` : liste de combinaisons `famille|graisse|taille` → style SDS cible. **Ne traite jamais un cas listé comme "à confirmer" sans validation explicite préalable de l'utilisateur.**

**Script 1 — Récupérer les IDs des styles de texte cibles et charger les polices**

```javascript
const styles = await figma.getLocalTextStylesAsync();
const targetNames = [
  'Body Large',
  'Heading'
  // Compléter depuis le rapport mapping
];

const styleMap = {};
for (const s of styles) {
  if (targetNames.includes(s.name)) styleMap[s.name] = s;
}

// Charger toutes les polices utilisées par les styles cibles ET par les noeuds a modifier
// (obligatoire avant tout setTextStyleIdAsync ou toute lecture de fontName sur des noeuds non charges)
const fontsToLoad = new Set();
for (const s of Object.values(styleMap)) fontsToLoad.add(JSON.stringify(s.fontName));
// Ajouter ici les fontName des noeuds source identifies dans le rapport mapping

for (const f of fontsToLoad) await figma.loadFontAsync(JSON.parse(f));

return Object.fromEntries(Object.entries(styleMap).map(([name, s]) => [name, s.id]));
```

**Script 2 — Liaison par combinaison** (un combo à la fois, périmètre = frame(s) ciblé(s))

```javascript
// Paramètres à injecter depuis le rapport :
// fontFamily / fontStyle / fontSize : combinaison source à cibler
// targetStyleId : ID du style SDS retenu
// forceTextCase : 'UPPER' | null — a réappliquer en override si le noeud d'origine l'avait et que le style cible ne le couvre pas

const fontFamily = '<FAMILLE>';
const fontStyle = '<GRAISSE>';
const fontSize = <TAILLE>;
const targetStyleId = '<STYLE_ID>';
const forceTextCase = null;

const targetStyle = await figma.getStyleByIdAsync(targetStyleId);
if (!targetStyle) return { error: `Style ${targetStyleId} introuvable` };

const mutatedNodeIds = [];
const errors = [];

targetScope.findAll(n => { // targetScope = frame(s) ou figma.currentPage
  if (n.type !== 'TEXT') return false;
  if (n.textStyleId && n.textStyleId !== '') return false; // deja stylise
  if (n.fontName === figma.mixed || n.fontSize === figma.mixed) return false;
  if (n.fontName.family !== fontFamily || n.fontName.style !== fontStyle) return false;
  if (Math.round(n.fontSize * 100) / 100 !== fontSize) return false;

  mutatedNodeIds.push(n.id); // liaison effective faite via setTextStyleIdAsync plus bas (async, hors findAll)
  return false;
});

for (const id of mutatedNodeIds) {
  try {
    const n = await figma.getNodeByIdAsync(id);
    await n.setTextStyleIdAsync(targetStyle.id);
    if (forceTextCase) n.textCase = forceTextCase;
  } catch (e) {
    errors.push({ nodeId: id, error: e.message });
  }
}

return { mutatedNodeIds, count: mutatedNodeIds.length, errors, targetStyleId };
```

**Répète ce script pour chaque combinaison de la section "Style existant → nœuds à lier" du rapport mapping.** Traite un combo à la fois, valide entre chaque lot avec un re-scan (compte de nœuds non stylés restants).

---

### Opération E — Liaison des paddings/gaps/radius → variables `Size`

Utilise les données de la section "Mapping des espacements et radius" du rapport `mapping-ds-*.md`. Deux sous-parties : liaison des valeurs (comme B/D) et correctif des radius "pilule cassée" (restructuration de 3 propriétés supplémentaires, pas une simple liaison).

**Script 1 — Récupérer les IDs des variables `Size` cibles**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const sizeCol = collections.find(c => c.name === 'Size');
const targetNames = ['Space/400', 'Space/600', 'Radius/200']; // completer depuis le rapport mapping

const vars = await Promise.all(sizeCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id)));
const varMap = {};
for (const v of vars) if (targetNames.includes(v.name)) varMap[v.name] = v.id;
return varMap;
```

**Script 2 — Liaison par valeur cible** (un hex/une valeur à la fois)

```javascript
// targetValue : valeur source arrondie (ex. 15), variableId : variable Size cible, props : liste de proprietes a traiter
const targetValue = <VALEUR>;
const variableId = '<VARIABLE_ID>';
const props = ['paddingLeft','paddingRight','paddingTop','paddingBottom','itemSpacing','counterAxisSpacing'];

const variable = await figma.variables.getVariableByIdAsync(variableId);
const mutatedNodeIds = [];

targetScope.findAll(n => {
  const bv = n.boundVariables ?? {};
  if (n.layoutMode && n.layoutMode !== 'NONE') {
    for (const prop of props) {
      if (typeof n[prop] !== 'number' || bv[prop]) continue;
      if (Math.round(n[prop] * 100) / 100 !== targetValue) continue;
      n.setBoundVariable(prop, variable);
      mutatedNodeIds.push(n.id);
    }
  }
  return false;
});

return { mutatedNodeIds, count: mutatedNodeIds.length };
```

**Script 3 — Correctif "pilule cassée"** (voir Étape 7.3 de `mapping-design-system` pour la détection)

```javascript
// radiusFullId : ID de la variable Radius/Full (ou equivalent)
const radiusFullId = '<VARIABLE_ID>';
const radiusFull = await figma.variables.getVariableByIdAsync(radiusFullId);
const radiusProps = ['topLeftRadius','topRightRadius','bottomLeftRadius','bottomRightRadius'];

const nodeIds = ['<ID_1>', '<ID_2>']; // noeuds "pilule cassee" confirmes par le rapport mapping
const mutatedNodeIds = [];
for (const id of nodeIds) {
  const n = await figma.getNodeByIdAsync(id);
  if (!n) continue;
  for (const prop of radiusProps) n.setBoundVariable(prop, radiusFull);
  mutatedNodeIds.push(id);
}
return { mutatedNodeIds, count: mutatedNodeIds.length };
```

**Vérifie systématiquement par `get_screenshot`** un échantillon avant/après sur le correctif "pilule cassée" — c'est une correction visuelle, pas un simple binding.

---

### Opération F — Remplacement des composants bruts (boutons et assimilés)

Utilise la section "Correspondances proposées" de l'audit composants du rapport mapping. **Ne traite jamais un cas listé "aucune correspondance disponible"** sans validation explicite de l'utilisateur — proposer plutôt de les transmettre au skill `/composants`.

**Script — Remplacement d'un nœud brut par une instance** (un nœud à la fois, ou petit lot de nœuds identiques)

```javascript
// componentKey : cle du composant/variante cible (recuperee via inspection prealable, pas via getNodeById seul)
// oldId : id du noeud brut a remplacer
// label : texte a injecter dans la propriete "Label" du composant, si applicable
// fillBehavior : 'HUG' ou 'FILL' selon que le noeud d'origine epousait son texte ou remplissait son conteneur

const componentKey = '<COMPONENT_KEY>';
const oldId = '<OLD_NODE_ID>';
const label = '<TEXTE>';
const fillBehavior = 'HUG';

const oldNode = await figma.getNodeByIdAsync(oldId);
if (!oldNode) return { error: 'noeud source introuvable' };

const parent = oldNode.parent;
const index = parent.children.indexOf(oldNode);
const { x, y } = oldNode;

const component = await figma.importComponentByKeyAsync(componentKey);
const instance = component.createInstance();
parent.insertChild(index, instance);
instance.x = x;
instance.y = y;

// Surcharge du libelle si le composant expose une propriete TEXT "Label"
const labelPropKey = Object.keys(instance.componentProperties).find(k => k.startsWith('Label'));
if (labelPropKey && label) {
  const textNode = instance.findOne(n => n.type === 'TEXT');
  if (textNode) await figma.loadFontAsync(textNode.fontName);
  instance.setProperties({ [labelPropKey]: label });
}

// CRITIQUE : corriger le sizing horizontal APRES la surcharge du libelle, sinon le texte peut deborder silencieusement
instance.layoutSizingHorizontal = fillBehavior;

oldNode.remove();
return { newId: instance.id, width: Math.round(instance.width), height: Math.round(instance.height) };
```

**Après chaque remplacement, prends un `get_screenshot`** du nœud remplacé (et de son parent si `fillBehavior='FILL'`) pour vérifier que :
- le libellé n'est pas tronqué/débordant,
- la couleur/forme correspond au variant attendu,
- la largeur du bouton est cohérente avec son contexte (pleine largeur vs. contenu).

Si l'import d'une clé de composant échoue une première fois, réessaie une fois avant d'escalader — certains échecs sont transitoires.

---

## Format du rapport de nettoyage

Après chaque opération complétée, affiche un bilan :

```markdown
## Nettoyage Figma — Bilan <date>

### A — Renommage sémantique
- <N> calques renommés
- Exemples : `Frame 42` → `section/hero`, `Rectangle` → `_bg/primary`
- IDs mutés : [liste]

### B — Liaison couleurs → SDS
| Hex | Token SDS | Nœuds liés |
|---|---|---|
| `#0d6efd` | `Action/primary` | 23 |
| `#212529` | `Text/primary` | 18 |
| **Total** | | **<N>** bindings créés |

### C — Ré-instanciation
- <N> frames remplacées par des instances
- Composant source : `<nom>` (key: `<key>`)
- IDs des nouvelles instances : [liste]

### D — Liaison styles de texte → SDS
| Combinaison source | Style SDS | Nœuds liés | Override réappliqué |
|---|---|---|---|
| Roboto Regular 18 | `Body Large` | 65 | — |
| Roboto Bold 20 (UPPER) | `Body Large Strong` | 3 | `textCase: UPPER` |
| **Total** | | **<N>** nœuds liés | |

### E — Liaison espacements/radius → SDS
| Valeur source | Variable Size | Occurrences |
|---|---|---|
| 15 | `Space/400` | 41 |
| 30 | `Space/800` | 17 |
| **Total espacements** | | **<N>** |

| Correctif "pilule cassée" | Nœuds corrigés |
|---|---|
| 4 coins → `Radius/Full` | <N> |

### F — Remplacement composants
| Nœud brut | Composant SDS | Occurrences | Correctif sizing appliqué |
|---|---|---|---|
| CTA "Nous contacter" | `Button Danger` (Primary/Default/Medium) | 3 | — |
| Card CTA "Candidater..." | `Button` (Primary/Default/Medium/Default) | 1 | `layoutSizingHorizontal: FILL` (texte débordait sinon) |
| **Total** | | **<N>** | |

### Points de vigilance
<Erreurs rencontrées ou nœuds ignorés avec raison>
```

---

## Règles de conduite

- **Demander confirmation avant toute opération d'écriture** — sans exception.
- **Arrêter sur erreur** : si un script `use_figma` retourne une erreur, ne pas retry immédiatement. Analyser l'erreur, corriger le script, afficher le problème à l'utilisateur.
- **Max 30 nœuds par script de liaison** : Figma peut ralentir sur les gros fichiers — travailler par lots et valider entre chaque.
- **Ré-instanciation prudente** : max 5 frames par appel, toujours vérifier que le parent existe et que l'index est valide avant `insertChild`.
- **Liaison de styles de texte (Opération D)** : charger toutes les polices concernées (`figma.loadFontAsync`) avant tout `setTextStyleIdAsync` ; ne jamais traiter un cas listé "à confirmer" dans le rapport mapping sans validation explicite ; réappliquer systématiquement `textCase`/`textDecoration` en override si le nœud d'origine en avait un que le style cible ne couvre pas.
- **Espacements/radius (Opération E)** : ne jamais lier une valeur signalée "hors palette — probable marge structurelle" dans le rapport mapping. Vérifier par capture d'écran avant/après tout correctif "pilule cassée" (c'est une restructuration visuelle sur 4 propriétés, pas juste un ajout de token).
- **Composants (Opération F)** : ne jamais traiter un cas "aucune correspondance disponible" du rapport mapping. Toujours corriger `layoutSizingHorizontal`/`Vertical` (`HUG` ou `FILL` selon le comportement d'origine) après la surcharge du libellé, et vérifier par capture d'écran que le texte n'est pas tronqué et que la largeur est cohérente avec le contexte (conteneur plein largeur vs. bouton au contenu naturel).
- **Retourner tous les IDs mutés** à chaque script — c'est la seule trace de ce qui a été modifié.
- Propose à la fin de sauvegarder le bilan dans `nettoyage-figma-<date>.md`.
