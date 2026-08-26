---
name: 07-mapping-design-system
description: Analyse un fichier Figma et produit un plan de mise à jour priorisé pour le design system SDS
---


# Skill : mapping-design-system

## Rôle

Tu es un expert design system chez ads-COM. Quand ce skill est activé, tu analyses un fichier Figma et produis un **plan de mise à jour priorisé** couvrant quatre volets, indépendants les uns des autres :
- **Couleurs** : quelles couleurs sont déjà liées au SDS, lesquelles sont hardcodées à lier, et quels primitifs manquent à créer (Étapes 1 à 5).
- **Styles de texte** : quels nœuds TEXT n'ont aucun style SDS appliqué, et quel style nommé existant leur correspond le mieux (Étape 6).
- **Espacements et radius** : quels paddings/gaps/rayons ne sont pas liés aux collections `Size` (`Space/*`, `Radius/*`), et quelle variable existante leur correspond le mieux (Étape 7).
- **Composants (boutons et assimilés)** : quels éléments répétés ressemblent à un composant SDS existant sans en être une instance, et lequel/laquelle leur correspond le mieux — ou l'absence de correspondance à signaler (Étape 8).

Tu ne modifies **jamais** le fichier Figma directement — tu guides, le designer exécute via le skill `nettoyage-figma` (Opération B couleurs, D styles de texte, E espacements/radius, F composants), ou via un **prompt Figma AI personnalisé** que tu génères à partir de l'analyse (Étape 9) et que le designer colle lui-même dans Figma — utile quand `use_figma` n'est pas souhaitable (fichier en cours d'édition live, préférence du designer). La correspondance couleurs/typo vers Sass n'est plus automatisée par un skill Claude à ce stade — voir l'agent Copilot `sds-bootstrap` en Passation (`02-passation-design-dev/agents/sds-bootstrap.md`).

**Règle commune à tous les volets : ne jamais proposer la création d'un nouveau token/style/composant.** Toujours rapprocher vers l'élément existant le plus proche (couleur, style de texte, variable `Size`, ou composant déjà défini dans le SDS), quitte à signaler un écart — ou une absence de correspondance — au designer plutôt que d'inventer une nouvelle valeur ou de forcer un mauvais matching.

**Prérequis** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. Tous les appels sont en **lecture seule**.

---

## Déclenchement

Ce skill est activé par `/mapping-design-system` ou quand l'utilisateur demande à "mapper les tokens", "vérifier les variables SDS", "analyser les couleurs hardcodées", "préparer la synchronisation SDS", "mapper les styles de texte", "vérifier les text styles", "analyser les tailles de police hardcodées", "mapper les espacements", "vérifier les paddings/gaps", "analyser les radius", "auditer les boutons", "détecter les composants bruts", "générer un prompt Figma AI", "prompt d'ajustement SDS", "prompt pour aligner au design system".

Les quatre volets (couleurs / styles de texte / espacements-radius / composants) peuvent être demandés ensemble ou séparément — n'exécute que ce qui est demandé.

---

## Comportement

### Étape 0 — Chargement des références

Lis dans cet ordre avant toute inspection Figma :

1. **`assets/sds-collections.md`** (chemin relatif au répertoire du skill) — structure des collections SDS : nommage, groupes de teintes, scopes, tokens sémantiques.
2. **`assets/tokens-bootstrap.md`** — correspondances Bootstrap 5 → SDS : hex par défaut, CSS variables, tokens par composant.
3. **`assets/text-style-matching.md`** — uniquement si le mapping des styles de texte (Étape 6) est demandé : formule de scoring famille/graisse/taille pour matcher un texte hardcodé au style nommé le plus proche.
4. **`brief-projet.md`** (à la racine du projet) — contexte client, URL SDS, conventions dérogatoires.

Aucun asset dédié n'est nécessaire pour les Étapes 7 (espacements/radius) et 8 (composants) — leurs règles de matching sont directement décrites dans ces étapes.

Si `brief-projet.md` n'existe pas, demande : **"Y a-t-il une palette dérogatoire (couleurs hors Bootstrap/SDS standards) pour ce projet ?"** et note la réponse.

Constitue mentalement une **table de référence hex→token** à partir des deux fichiers d'assets. Elle sera utilisée à l'étape 3 pour matcher les couleurs hardcodées.

---

### Étape 1 — Inventaire des collections présentes dans la maquette

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const detail = [];
for (const col of collections) {
  const vars = await Promise.all(
    col.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
  );
  const firstModeId = col.modes[0]?.modeId;
  detail.push({
    name: col.name,
    id: col.id,
    remote: col.remote,
    modes: col.modes.map(m => m.name),
    variableCount: col.variableIds.length,
    sample: vars.slice(0, 8).map(v => {
      const val = firstModeId ? v.valuesByMode[firstModeId] : null;
      const isAlias = val && typeof val === 'object' && 'type' in val && val.type === 'VARIABLE_ALIAS';
      const isColor = val && typeof val === 'object' && 'r' in val;
      return {
        name: v.name,
        type: v.resolvedType,
        remote: v.remote,
        valueKind: isAlias ? 'alias' : isColor ? 'hex' : typeof val,
        hex: isColor
          ? '#' + ['r','g','b'].map(k => Math.round(val[k] * 255).toString(16).padStart(2,'0')).join('')
          : null
      };
    })
  });
}
return detail;
```

**Analyse des résultats :**
- Identifie quelles collections correspondent aux rôles SDS (`Color Primitives`, `Color` sémantique)
- Détecte les collections distantes (`remote: true`) — elles viennent de la bibliothèque SDS liée
- Signale les collections dont le nommage ne correspond pas à la convention SDS

---

### Étape 2 — Inventaire des nœuds avec variables liées

```javascript
const page = figma.currentPage;
const linked = new Map();

page.findAll(n => {
  const bv = n.boundVariables;
  if (!bv) return false;

  for (const [prop, binding] of Object.entries(bv)) {
    const entries = Array.isArray(binding) ? binding : [binding];
    for (const b of entries) {
      if (!b?.id) continue;
      const key = b.id;
      if (!linked.has(key)) linked.set(key, { variableId: key, count: 0, properties: new Set(), nodeNames: [] });
      const entry = linked.get(key);
      entry.count++;
      entry.properties.add(prop);
      if (entry.nodeNames.length < 3) entry.nodeNames.push(n.name);
    }
  }
  return false;
});

const result = [...linked.values()].map(e => ({
  ...e,
  properties: [...e.properties]
}));
return { totalLinkedBindings: result.reduce((s, e) => s + e.count, 0), uniqueVariables: result.length, variables: result.slice(0, 40) };
```

**Interprétation :** compare `uniqueVariables` avec le nombre total de variables dans les collections. Un ratio élevé = bonne couverture. Un ratio faible = beaucoup de hardcoding.

---

### Étape 3 — Détection des couleurs hardcodées

Ce script détecte tous les aplats solides non liés à une variable, et les agrège par valeur hex pour prioriser les plus fréquents.

```javascript
function toHex(c) {
  return '#' + [c.r, c.g, c.b]
    .map(v => Math.round(v * 255).toString(16).padStart(2, '0')).join('');
}

const page = figma.currentPage;
const hardcodedMap = new Map();

function register(hex, nodeName, nodeType, property) {
  if (!hardcodedMap.has(hex)) {
    hardcodedMap.set(hex, { hex, count: 0, properties: new Set(), nodeTypes: new Set(), nodes: [] });
  }
  const entry = hardcodedMap.get(hex);
  entry.count++;
  entry.properties.add(property);
  entry.nodeTypes.add(nodeType);
  if (entry.nodes.length < 4) entry.nodes.push(nodeName);
}

page.findAll(n => {
  const bv = n.boundVariables ?? {};

  // Fills
  if (Array.isArray(n.fills)) {
    n.fills.forEach((fill, i) => {
      if (fill.type !== 'SOLID' || fill.visible === false) return;
      const bound = Array.isArray(bv.fills) ? bv.fills[i]?.id : null;
      if (!bound) register(toHex(fill.color), n.name, n.type, 'fill');
    });
  }

  // Strokes
  if (Array.isArray(n.strokes)) {
    n.strokes.forEach((stroke, i) => {
      if (stroke.type !== 'SOLID' || stroke.visible === false) return;
      const bound = Array.isArray(bv.strokes) ? bv.strokes[i]?.id : null;
      if (!bound) register(toHex(stroke.color), n.name, n.type, 'stroke');
    });
  }

  return false;
});

const sorted = [...hardcodedMap.values()]
  .sort((a, b) => b.count - a.count)
  .map(e => ({ ...e, properties: [...e.properties], nodeTypes: [...e.nodeTypes] }));

return {
  uniqueHardcodedColors: sorted.length,
  totalOccurrences: sorted.reduce((s, e) => s + e.count, 0),
  colors: sorted.slice(0, 35)
};
```

---

### Étape 4 — Matching hex → token SDS/Bootstrap

Pour chaque couleur hardcodée retournée à l'étape 3, effectue le matching suivant **en utilisant les tables de référence chargées à l'étape 0** :

**Algorithme de matching :**

1. **Correspondance exacte** — le hex est dans `tokens-bootstrap.md` ou dans un primitif SDS connu → colonne `Mapping` = token SDS exact
2. **Proximité Bootstrap** — le hex est proche (< 10% de différence perceptuelle) d'un token Bootstrap → noter comme "probable `$primary` surchargé" ou similaire
3. **Hors palette** — la couleur ne correspond à aucune valeur référencée → classer comme "primitif à créer"
4. **Couleurs blanc/noir** — `#ffffff`, `#000000`, `#212529` → systématiquement des primitifs SDS (`Neutral/0`, `Neutral/1000`, `Neutral/900`)

Pour les couleurs de la **charte dérogatoire** déclarées dans le brief : les noter comme "primitif projet" (accepté, à documenter).

---

### Étape 5 — Analyse de la cohérence des collections existantes

Si des collections de variables existent dans la maquette, vérifie leur cohérence avec le SDS de référence :

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const issues = [];

for (const col of collections) {
  if (col.remote) continue; // collections distantes = SDS lié, OK

  const vars = await Promise.all(
    col.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
  );

  // Vérifie le nommage (convention SDS : Groupe/Nom)
  const badNames = vars.filter(v => !v.name.includes('/'));
  if (badNames.length > 0) {
    issues.push({
      collection: col.name,
      issue: 'nommage_sans_groupe',
      count: badNames.length,
      examples: badNames.slice(0, 4).map(v => v.name)
    });
  }

  // Vérifie les scopes (ALL_SCOPES sur des primitifs = trop permissif)
  const primitiveKeywords = ['primitive', 'primitif', 'base', 'foundation', 'raw', 'scale'];
  const isPrimitiveCollection = primitiveKeywords.some(kw => col.name.toLowerCase().includes(kw));
  if (isPrimitiveCollection) {
    const withAllScopes = vars.filter(v => v.scopes.includes('ALL_SCOPES'));
    if (withAllScopes.length > 0) {
      issues.push({
        collection: col.name,
        issue: 'primitifs_avec_ALL_SCOPES',
        count: withAllScopes.length,
        note: 'Les primitifs ne devraient pas être exposés dans les property pickers'
      });
    }
  }
}

return issues;
```

---

### Étape 6 — Mapping des styles de texte

Volet indépendant des Étapes 1-5 (couleurs) — peut être exécuté seul. Charge `assets/text-style-matching.md` avant de commencer.

**Script 1 — Inventaire des styles de texte locaux**

```javascript
const styles = await figma.getLocalTextStylesAsync();
return styles
  .filter(s => !s.name.startsWith('.')) // exclut les styles internes (convention `.Utilities/...`)
  .map(s => ({
    id: s.id, name: s.name,
    fontFamily: s.fontName.family, fontStyle: s.fontName.style, fontSize: s.fontSize,
    lineHeightPct: s.lineHeight.unit === 'PERCENT' ? Math.round(s.lineHeight.value) : null,
    letterSpacing: s.letterSpacing, textCase: s.textCase, textDecoration: s.textDecoration
  }));
```

**Script 2 — Détection des nœuds TEXT sans style appliqué**

Regroupe par combinaison `famille|graisse|taille` (arrondie) pour prioriser par volume, et capture le nom du calque parent comme indice sémantique (un parent `Heading 2`, `Button`, `Category Tag`... oriente vers le style correspondant).

```javascript
const unstyled = new Map();

targetScope.findAll(n => { // targetScope = frame(s) ciblé(s) ou figma.currentPage
  if (n.type !== 'TEXT') return false;
  if (n.textStyleId && n.textStyleId !== '') return false; // déjà stylé
  if (n.fontName === figma.mixed || n.fontSize === figma.mixed) return false; // style mixte — à traiter nœud par nœud si nécessaire

  const lh = n.lineHeight;
  const lhPct = lh.unit === 'PERCENT' ? Math.round(lh.value)
    : lh.unit === 'PIXELS' ? Math.round((lh.value / n.fontSize) * 100) : null;

  const key = `${n.fontName.family}|${n.fontName.style}|${Math.round(n.fontSize * 100) / 100}`;
  if (!unstyled.has(key)) {
    unstyled.set(key, {
      fontFamily: n.fontName.family, fontStyle: n.fontName.style, fontSize: n.fontSize,
      textCase: n.textCase, textDecoration: n.textDecoration,
      count: 0, lhSamples: [], parentNames: new Set(), sampleNodes: []
    });
  }
  const e = unstyled.get(key);
  e.count++;
  e.lhSamples.push(lhPct);
  e.parentNames.add(n.parent?.name ?? '');
  if (e.sampleNodes.length < 3) e.sampleNodes.push({ id: n.id, name: n.name, chars: n.characters.slice(0, 40) });
  return false;
});

return [...unstyled.values()]
  .map(e => ({ ...e, parentNames: [...e.parentNames], avgLhPct: Math.round(e.lhSamples.reduce((a,b)=>a+b,0) / e.lhSamples.length) }))
  .sort((a,b) => b.count - a.count);
```

**Étape 6.1 — Scoring et matching**

Pour chaque combinaison détectée, calcule le style existant le plus proche selon la formule détaillée dans `assets/text-style-matching.md` :
- **Contrainte dure** : ne jamais matcher entre deux familles de police différentes (ex. Roboto ≠ Poppins), sauf absence totale d'alternative dans la même famille — dans ce cas, signale-le comme cas à confirmer plutôt que de trancher seul.
- **Score** = `|Δtaille| × 2 + |Δgraisse| × 3` (graisse convertie en rang numérique : Regular/Italic=1, Medium=2, SemiBold=3, Bold=4, ExtraBold=5, Black=6). Le style au score le plus bas est retenu.
- **Départage** (score ex-aequo) : compare la proximité de line-height, puis le nom du calque parent (un parent `Button` ou un texte très court oriente vers une variante "single line" si le SDS en propose une).

**Étape 6.2 — Détection des doublons à échelle variable**

Avant de figer les matchings, regroupe les combinaisons qui partagent un contenu textuel identique ou très proche (`sampleNodes[].chars`) mais des tailles différentes — signe fréquent d'un même élément dupliqué à plusieurs échelles (breakpoints responsive, plusieurs instances d'un même gabarit, exports à des largeurs de conteneur différentes). **Unifie ces groupes vers un seul style cible** plutôt que de suivre la distance numérique frame par frame : la cohérence du rôle sémantique prime sur la proximité pixel-perfect d'une instance isolée.

**Étape 6.3 — Cas à signaler systématiquement au designer avant liaison**
- Tout matching nécessitant de traverser une famille de police (aucune alternative dans la même famille).
- Tout matching où le style trouvé n'a pas le même `textCase` (`UPPER`) ou `textDecoration` (`UNDERLINE`/`ITALIC`) que le nœud d'origine — préciser qu'il faudra réappliquer cette propriété en override local après liaison, le style ne la restaure pas automatiquement.
- Tout écart de taille important entre le nœud et le style trouvé (signale un vrai manque dans l'échelle du SDS plutôt qu'une correspondance fiable).
- Tout texte identifiable comme logo/wordmark de marque — ne jamais le lier à un style de contenu générique, le signaler comme "à laisser hardcodé".

---

### Étape 7 — Mapping des espacements et radius

Volet indépendant des précédents — peut être exécuté seul. Couvre les collections `Size` (`Space/*` pour padding/gap, `Radius/*` pour les rayons).

**Script 1 — Inventaire de la collection `Size`**

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const sizeCol = collections.find(c => c.name === 'Size');
const modeId = sizeCol.modes[0].modeId;

const vars = await Promise.all(sizeCol.variableIds.map(id => figma.variables.getVariableByIdAsync(id)));
return vars
  .map(v => ({ name: v.name, id: v.id, value: v.valuesByMode[modeId] }))
  .filter(v => typeof v.value === 'number') // exclut les alias non resolus
  .sort((a, b) => a.value - b.value);
```

Construit deux échelles triées à partir du résultat : une pour `Space/*` (padding, gap, `itemSpacing`, `counterAxisSpacing`, y compris les valeurs négatives type `Space/Negative *`), une pour `Radius/*` (`topLeftRadius`, `topRightRadius`, `bottomLeftRadius`, `bottomRightRadius`).

**Script 2 — Détection des paddings/gaps et radius non liés**

```javascript
const spacingProps = ['paddingLeft','paddingRight','paddingTop','paddingBottom','itemSpacing','counterAxisSpacing'];
const radiusProps = ['topLeftRadius','topRightRadius','bottomLeftRadius','bottomRightRadius'];

const unboundSpacing = new Map();
const unboundRadius = new Map();

function register(map, value, prop, nodeName, nodeType) {
  const key = Math.round(value * 100) / 100; // arrondit le bruit d'echelle (34.69 -> 34.69, reste identifiable)
  if (!map.has(key)) map.set(key, { value: key, count: 0, props: new Set(), nodes: [] });
  const e = map.get(key);
  e.count++;
  e.props.add(prop);
  if (e.nodes.length < 4) e.nodes.push(nodeName);
}

targetScope.findAll(n => { // targetScope = frame(s) cible(s) ou figma.currentPage
  const bv = n.boundVariables ?? {};

  if (n.layoutMode && n.layoutMode !== 'NONE') {
    for (const prop of spacingProps) {
      if (typeof n[prop] !== 'number' || bv[prop]) continue;
      if (Math.abs(n[prop]) < 0.05) continue; // bruit sub-pixel negligeable
      register(unboundSpacing, n[prop], prop, n.name, n.type);
    }
  }

  if ('cornerRadius' in n) {
    for (const prop of radiusProps) {
      if (typeof n[prop] !== 'number' || bv[prop] || n[prop] < 0.5) continue;
      register(unboundRadius, n[prop], prop, n.name, n.type);
    }
  }
  return false;
});

return { unboundSpacing: [...unboundSpacing.values()], unboundRadius: [...unboundRadius.values()] };
```

**Étape 7.1 — Règle de matching des espacements**

- **Arrondis les valeurs bruitées** (artefacts d'échelle type `34.69`, `15.99`, `691.36`) puis cherche la variable `Space/*` la plus proche par distance absolue (aucune tolérance de famille à respecter ici, contrairement aux styles de texte).
- **Signale plutôt que de forcer** les valeurs dont l'écart à la variable la plus proche dépasse ~50 % de leur propre valeur (ex. un padding de 655px vs la variable `Space/8000`=320px) — ce sont presque toujours des marges de centrage de conteneur calculées, pas des choix de design, et les forcer casserait visuellement la mise en page. Les classer "hors palette — probable marge structurelle" plutôt que de choisir la variable la plus proche par défaut.

**Étape 7.2 — Règle de matching des radius (cercles et pilules)**

- Si la valeur du radius est **≥ la moitié de la plus petite dimension du nœud** (`n.width`/`n.height`), le nœud est visuellement un cercle ou une pilule complète — lier à `Radius/Full` (ou équivalent), **jamais** à la valeur numérique la plus proche de l'échelle classique. Le résultat visuel serait identique mais l'intention ("totalement arrondi", robuste si la taille change) est mieux exprimée par le token dédié.
- Sinon, cherche la variable `Radius/*` la plus proche par distance absolue.

**Étape 7.3 — Détection d'un défaut d'import fréquent : "pilule cassée"**

Sur les fichiers issus d'un import HTML→Figma, il est fréquent qu'un `border-radius` uniforme n'ait été capturé que sur **un seul coin** (les 3 autres restent à 0), rendant l'élément visuellement carré sur 3 côtés au lieu d'être une pilule/cercle complet. Détecte ce cas :

```javascript
// Sur les noeuds a cornerRadius mixte (n.cornerRadius === figma.mixed) :
// un seul des 4 props topLeft/topRight/bottomLeft/bottomRightRadius est non-nul.
const values = radiusProps.map(p => n[p]);
const nonZero = values.filter(v => v >= 0.5);
if (nonZero.length === 1) {
  const minDim = Math.min(n.width, n.height);
  const looksLikePillBug = nonZero[0] * 2 >= minDim - 1;
  // looksLikePillBug === true -> defaut d'import probable, proposer de lier les 4 coins a Radius/Full
  // looksLikePillBug === false -> coin arrondi isole intentionnel (design), ne pas toucher
}
```

Signale les cas `looksLikePillBug: true` comme "correctif suggéré" distinct du reste du mapping — ce n'est pas un simple token à lier, c'est un défaut visuel à corriger (les 4 coins doivent recevoir la même variable, pas seulement celui déjà renseigné).

---

### Étape 8 — Audit des composants (boutons et assimilés)

Volet indépendant des précédents. Contrairement aux Étapes 1-7 (valeurs → variable la plus proche), ici on compare des **nœuds bruts** (frames non instanciées) à des **composants existants** pour proposer un remplacement — une opération plus risquée (elle restructure la hiérarchie) que le simple binding de propriété.

**Script 1 — Inventaire des composants candidats dans le fichier**

```javascript
const namePattern = /button|btn|cta/i; // adapter selon la cible (ex. /card|badge/i pour d'autres familles)
const results = [];
for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  page.findAll(n => {
    if (n.type !== 'COMPONENT' && n.type !== 'COMPONENT_SET') return false;
    if (!namePattern.test(n.name)) return false;
    let variantOptions = null;
    if (n.type === 'COMPONENT_SET') {
      try {
        variantOptions = {};
        for (const [k, def] of Object.entries(n.componentPropertyDefinitions)) {
          // Omettre les props INSTANCE_SWAP (listes d'icones potentiellement enormes) du rapport
          variantOptions[k] = def.type === 'INSTANCE_SWAP' ? '(instance swap, omis)' : def;
        }
      } catch (e) { variantOptions = `ERROR: ${e.message}`; }
    }
    results.push({ page: page.name, name: n.name, type: n.type, id: n.id, key: n.key, variantOptions });
    return false;
  });
}
return results;
```

**⚠️ Piège fréquent :** les propriétés `INSTANCE_SWAP` (ex. un slot "Icon") retournent des listes de `preferredValues` pouvant contenir des centaines d'entrées — toujours les filtrer/omettre du rapport comme ci-dessus pour ne pas saturer le contexte.

**Script 2 — Détection des instances vs nœuds bruts dans le périmètre cible**

```javascript
const instances = [];
const rawNodes = [];

targetScope.findAll(n => {
  if (!namePattern.test(n.name ?? '')) return false;
  if (n.type === 'INSTANCE') {
    instances.push({ id: n.id, name: n.name, mainComponentName: n.mainComponent?.name ?? null,
      mainComponentSetName: n.mainComponent?.parent?.type === 'COMPONENT_SET' ? n.mainComponent.parent.name : null });
  } else if (n.type === 'FRAME' || n.type === 'GROUP') {
    rawNodes.push({ id: n.id, name: n.name, width: Math.round(n.width), height: Math.round(n.height),
      parent: n.parent?.name, childNames: n.children?.map(c => c.name) ?? [] });
  }
  return false;
});

return { instanceCount: instances.length, rawCount: rawNodes.length, rawNodes };
```

**Étape 8.1 — Matching structure/taille**

Pour chaque groupe de nœuds bruts similaires (même nom, taille proche), compare aux variantes du composant candidat le plus pertinent :
- Compare les tailles par défaut des variantes (`width`/`height`) à celles des nœuds bruts.
- Vérifie que les enfants requis par le composant (ex. une icône obligatoire) existent bien dans le nœud brut — si le composant impose un élément absent du nœud brut (ex. une icône, un slot obligatoire), **ne force pas le matching** : signale "pas de correspondance disponible" plutôt que d'instancier un composant visuellement différent.
- Utilise `get_screenshot` pour comparer visuellement le nœud brut au rendu attendu du composant avant de conclure à une correspondance, surtout si le nom seul ne suffit pas à trancher (ex. plusieurs composants "Button"/"Button Secondary"/"Button Danger" possibles).

**Étape 8.2 — Signalement des cas sans correspondance**

Si aucun composant existant ne correspond raisonnablement (tailles incompatibles, éléments requis manquants, rôle différent), **ne propose pas de créer un nouveau composant dans ce skill** — c'est le rôle du skill `10-composants`. Se contenter de signaler le pattern répété comme candidat pour `10-composants`.

**Étape 8.3 — Note d'exécution (pour `nettoyage-figma` Opération F)**

Un piège vérifié en pratique : après `component.createInstance()` puis `parent.insertChild(...)`, une instance peut hériter d'un `layoutSizingHorizontal`/`layoutSizingVertical` `FIXED` par défaut au lieu de `HUG`/`FILL`. Si le libellé (`Label` override) est plus long que la valeur par défaut du composant, le texte déborde visuellement du nœud sans erreur levée. **Toujours vérifier par capture d'écran après remplacement**, et corriger explicitement le sizing :
- `HUG` si le nœud d'origine s'ajustait à son contenu.
- `FILL` si le nœud d'origine occupait toute la largeur de son conteneur parent (cas fréquent des CTA pleine largeur dans une carte).

---

### Étape 9 — Génération d'un prompt Figma AI personnalisé (alternative à `nettoyage-figma`)

Volet transversal, déclenché sur demande ("génère un prompt Figma AI", "prompt d'ajustement SDS") une fois les volets 1 à 3 analysés (couleurs / styles de texte / espacements-radius — le volet composants, Étape 8, ne se prête pas à un prompt Figma AI et reste piloté par `/composants`). C'est une **alternative** à `/nettoyage-figma` : au lieu de guider une exécution `use_figma`, on transforme l'analyse en un prompt que le designer colle lui-même dans Figma AI — utile quand le fichier est en cours d'édition live par le designer (conflit d'écriture avec `use_figma`) ou quand il préfère exécuter dans l'app plutôt que de valider un pipeline d'appels `use_figma`.

**Ne jamais inclure dans le prompt généré :**
- Les cas listés "à confirmer avec le designer" ou "aucune correspondance disponible" dans l'analyse — seuls les matchings déjà tranchés sont transmis à Figma AI.
- Les couleurs de marque tierces (réseaux sociaux, logos partenaires) signalées "à laisser hardcodées".
- Toute référence à un id de nœud Figma (`4716:16852`...) — Figma AI ne peut pas les résoudre ; seuls les **noms de calque et leur position/hiérarchie** sont actionnables pour lui. Si un nom de calque n'est pas unique dans le périmètre (`Container`, `Text`...), ajoute un indice de désambiguïsation (texte visible du calque, calque parent, position dans une liste) plutôt que de risquer une application au mauvais doublon.

**Règle de sécurité obligatoire — incident réel vérifié (2026-07-22, projet Neocampus) :** si le périmètre analysé contient des **instances de composants partagés** (header, footer, cartes réutilisées ailleurs dans le fichier), le prompt doit explicitement interdire à Figma AI de toucher à leur intérieur. Une correspondance couleur par simple valeur hex affichée, sans vérifier qu'un calque n'est pas déjà lié à une variable, a réassigné silencieusement des dizaines de nœuds déjà correctement liés vers un mauvais token sémantique (deux tokens SDS différents partagent souvent la même valeur hex — ex. `Background/Brand/Default` et `Icon/Brand/Default` peuvent être le même bleu). Le rendu visuel ne change pas : l'erreur est invisible sans vérification champ par champ. **Toujours faire précéder le prompt d'une consigne explicite en Étape 0, jamais en fin de prompt.**

**Structure du prompt généré :**

```
> Étape 0 — Périmètre et garde-fous, à respecter avant toute autre action.
> Travaille uniquement sur la page/le cadre "<nom de la page ou du cadre>".
> Ne modifie **jamais** un calque à l'intérieur d'une instance des composants suivants, même si sa couleur correspond à la liste ci-dessous : <liste des composants partagés détectés — ex. "Header Neocampus", "Footer Campus">. Ce sont des composants utilisés sur d'autres pages : les modifier ici les modifierait partout.
> Avant de lier une couleur, un style de texte ou un espacement à une variable/un style, vérifie toujours que le calque n'est **pas déjà lié** à une variable ou un style — dans ce cas, ignore-le et passe au suivant. Une couleur visuellement identique peut déjà être liée au bon token via une variable différente de celle que tu t'apprêtes à appliquer : ne te fie jamais à la seule couleur affichée.
>
> Étape 1 — Couleurs à lier (uniquement les calques listés ci-dessous) :
> | Calque (nom exact / repère) | Couleur actuelle | Variable à lier |
> |---|---|---|
> | <nom de calque> | <hex> | <Groupe/Nom> |
>
> Étape 2 — Styles de texte à appliquer :
> | Calque(s) (nom exact / repère) | Style à appliquer |
> |---|---|
> | <nom/description> | <Nom du style> |
>
> Étape 3 — Espacements et rayons à lier :
> | Calque (nom exact / repère) | Propriété | Variable à lier |
> |---|---|---|
> | <nom de calque> | <padding/gap/radius> | <Groupe/Nom> |
>
> Étape 4 — Vérification finale, avant de conclure.
> 1. Confirme qu'aucun calque à l'intérieur d'une instance de <liste des composants partagés> n'a été modifié.
> 2. Confirme que chaque liaison des Étapes 1 à 3 a bien été appliquée sur variable/style (pas une recopie de valeur brute qui ressemble juste à la bonne couleur).
> 3. Prends une capture d'écran de la page/du cadre modifié et signale tout texte tronqué ou élément qui se chevauche.
```

Remplis ce gabarit avec les données réelles de l'analyse (Étapes 1 à 7) : un seul tableau par volet effectivement concerné (omets l'Étape du gabarit dont le volet correspondant n'a rien à lier — par exemple si les couleurs ont déjà été traitées par ailleurs). Affiche le prompt final dans un bloc de citation prêt à copier-coller, et propose de le sauvegarder dans `prompt-sds-<page>-<date>.md`.

---

## Format de sortie

```markdown
# Mapping Design System — <Nom du projet>

> Analysé le <date du jour>
> Référence SDS : <URL depuis brief-projet.md ou "Non renseignée">
> Palette dérogatoire : <Oui — couleurs X, Y / Non>

---

## État actuel des collections

| Collection | Type | Lien | Modes | Variables |
|---|---|---|---|---|
| <nom> | Primitive / Sémantique / Inconnue | Distante ✅ / Locale | <liste> | <N> |

**Diagnostic global :**
- Collections SDS correctement liées : <N> ✅
- Collections locales à aligner : <N> ⚠️
- Aucune collection de variables : <si applicable> 🔴

---

## Couleurs hardcodées — classement par impact

### ✅ Déjà liées à des variables SDS
*Ces nœuds n'apparaissent pas dans la liste hardcodée — bonne pratique confirmée.*
> Total de bindings variables actifs : <N>

---

### 🔴 À lier — correspondance SDS exacte trouvée

> Ces couleurs ont un token SDS direct. Priorité haute : chaque occurrence peut être liée sans créer de nouveau primitif.

| Hex hardcodé | Occurrences | Propriétés | Token SDS à lier | Token Bootstrap équivalent |
|---|---|---|---|---|
| `#0d6efd` | 23 | fill, stroke | `Action/primary` → alias `Blue/600` | `$primary` |
| `#212529` | 18 | fill (TEXT) | `Text/primary` → alias `Neutral/900` | `$body-color` |
| `#dee2e6` | 11 | stroke | `Border/default` → alias `Neutral/200` | `$border-color` |
| … | | | | |

**Nœuds représentatifs :** <liste des 3 premiers noms de nœuds pour chaque couleur>

---

### 🟡 À lier — correspondance Bootstrap probable (valeur surchargée)

> Ces couleurs sont proches des tokens Bootstrap mais ne correspondent pas exactement. Probable surcharge de `$primary` ou charte client.

| Hex hardcodé | Occurrences | Proximité Bootstrap | Action recommandée |
|---|---|---|---|
| `#1a72ff` | 7 | Proche `$primary` (#0d6efd) | Confirmer si c'est la couleur de marque client → créer `Brand/primary` dans Color Primitives |

---

### 🟠 Primitifs à créer — couleurs hors palette SDS/Bootstrap

> Ces couleurs n'ont pas de correspondance dans le SDS ou Bootstrap. Elles nécessitent la création d'un nouveau primitif avant de pouvoir être liées.

| Hex | Occurrences | Propriétés | Primitif suggéré | Groupe SDS |
|---|---|---|---|---|
| `#f4a261` | 4 | fill | `Orange/400` | Color Primitives |
| `#2d6a4f` | 2 | fill | `Green/800` | Color Primitives |

---

### ⚪ Couleurs décoratives (faible priorité)

> Couleurs très peu utilisées (1–2 occurrences) ou purement décoratives. À traiter après les autres phases.

| Hex | Occurrences | Nœuds |
|---|---|---|
| `#f1f3f5` | 1 | `bg-footer` |

---

## Problèmes de cohérence des collections

<Si des problèmes ont été détectés à l'étape 5 :>

| Collection | Problème | Nb de variables | Action |
|---|---|---|---|
| `Primitives` | Nommage sans groupe (`/`) | 12 | Renommer selon convention `Hue/Shade` |
| `Primitives` | Scope `ALL_SCOPES` sur primitifs | 8 | Restreindre les scopes — les primitifs ne doivent pas apparaître dans les property pickers |

---

## Plan de mise à jour — 3 phases

### Phase 1 — Lier les correspondances exactes (🔴 haute priorité)
*Peut être fait sans créer de nouvelles variables. Impact immédiat sur la maintenabilité.*

1. Lier les `<N>` occurrences de `#0d6efd` → `Action/primary`
2. Lier les `<N>` occurrences de `#212529` → `Text/primary`
3. Lier les `<N>` occurrences de `#dee2e6` → `Border/default`
4. …

> Cette correspondance couleurs → Sass n'est plus automatisée par un skill Claude ici — elle est reprise en Passation par l'agent Copilot `sds-bootstrap` (`02-passation-design-dev/agents/sds-bootstrap.md`), à partir du `tokens.json` du Design Manifest.

### Phase 2 — Créer les primitifs manquants (🟠 moyenne priorité)
*À faire avant de lier — le token cible doit exister.*

1. Créer `Orange/400` (#f4a261) dans la collection `Color Primitives`
2. Créer `Green/800` (#2d6a4f) dans la collection `Color Primitives`
3. Créer les tokens sémantiques correspondants dans `Color` si ces couleurs ont un rôle UI

### Phase 3 — Aligner les collections et les scopes (🟡 qualité)
*Ne bloque pas la livraison mais est nécessaire avant de publier la bibliothèque.*

1. Renommer les variables sans groupe dans la collection `Primitives`
2. Restreindre les scopes des primitifs
3. Documenter les couleurs dérogatoires dans `brief-projet.md`

---

## Récapitulatif chiffré

| Catégorie | Nb de couleurs uniques | Nb d'occurrences |
|---|---|---|
| Liées à des variables SDS | — | <N> bindings actifs |
| À lier (correspondance exacte) | <N> | <N> |
| À lier (correspondance Bootstrap probable) | <N> | <N> |
| Primitifs à créer | <N> | <N> |
| Décoratives (faible priorité) | <N> | <N> |
```

---

## Format de sortie — Mapping des styles de texte (si Étape 6 exécutée)

```markdown
## Mapping des styles de texte

> <N> nœuds déjà stylés, <N> non stylés (<N> combinaisons famille/graisse/taille uniques)

### Style existant → nœuds à lier

| Style SDS | Famille/Graisse/Taille cible | Nœuds | Écart | Note |
|---|---|---|---|---|
| `Heading` | Poppins SemiBold 24 | 35 | taille +4px | Regroupe plusieurs tailles proches (20-24px) |
| `Body Large` | Roboto Regular 18 | 65 | exact | — |
| … | | | | |

### Cas à confirmer avec le designer

| Combinaison détectée | Occurrences | Nœuds représentatifs | Pourquoi ça bloque |
|---|---|---|---|
| Poppins Regular 16 | 1 | "Tous les événements" | Seul texte de ce type dans cette famille — tous les autres liens équivalents sont en Roboto |
| … | | | |

### À laisser hardcodé

| Nœud | Pourquoi |
|---|---|
| Wordmark logo | Typographie de marque figée, ne doit pas dépendre d'un style de contenu |

### Plan de liaison
> Utiliser le skill `/nettoyage-figma` (Opération D) pour exécuter, après validation des cas à confirmer.
```

---

## Format de sortie — Espacements et radius (si Étape 7 exécutée)

```markdown
## Mapping des espacements et radius

> <N> bindings d'espacement déjà actifs / <N> non liés (<N> valeurs uniques)
> <N> bindings de radius déjà actifs / <N> non liés (<N> valeurs uniques)

### Espacements à lier

| Valeur détectée | Variable `Space/*` cible | Occurrences |
|---|---|---|
| 15 | `Space/400` (16) | 41 |
| 30 | `Space/800` (32) | 17 |
| … | | |

### Radius à lier

| Valeur détectée | Variable cible | Occurrences | Note |
|---|---|---|---|
| 50 (sur boîte 40×40) | `Radius/Full` | 1 | Cercle/pilule détecté (radius ≥ moitié dimension) |
| 30 | `Radius/500` (32) | 22 | — |

### Correctif suggéré — "pilule cassée" (défaut d'import probable)

| Nœud | Coins actuels | Correctif | Occurrences |
|---|---|---|---|
| `Link` (148×56) | `[9999,0,0,0]` | Lier les 4 coins à `Radius/Full` | 26 |

### Hors palette — probable marge structurelle (non lié)

| Nœud | Propriété | Valeur | Raison |
|---|---|---|---|
| `Container` | paddingTop | 655 | >2× la plus grande variable `Space/*` — offset de centrage calculé, pas un espacement de composant |

### Plan de liaison
> Utiliser le skill `/nettoyage-figma` (Opération E) pour exécuter.
```

---

## Format de sortie — Composants (si Étape 8 exécutée)

```markdown
## Audit des composants — <famille, ex. Boutons>

> <N> instances déjà correctes / <N> nœuds bruts détectés

### Correspondances proposées

| Nœud brut | Composant SDS cible | Variante | Occurrences |
|---|---|---|---|
| CTA "Nous contacter" (175×40) | `Button Danger` | Primary/Default/Medium/Default | 3 |
| Card CTA "Candidater à cette formation" (316×48) | `Button` | Primary/Default/Medium/Default | 1 |

### Aucune correspondance disponible

| Nœud brut | Occurrences | Pourquoi aucun composant ne convient |
|---|---|---|
| Items de nav ("Ma mairie"...) | 13 | `Navigation Button` impose une icône et des tailles fixes incompatibles avec ces libellés |

> Candidats pour le skill `/composants` (création d'un nouveau composant local) — décision à prendre avec le designer, hors périmètre de ce skill.

### Plan de remplacement
> Utiliser le skill `/nettoyage-figma` (Opération F) pour exécuter, un groupe de nœuds à la fois, avec vérification visuelle après chaque remplacement.
```

---

## Règles de conduite

- **Ne jamais inventer de valeurs hex ni créer de nouveau token/style** non retournés par les scripts — toujours rapprocher vers l'élément existant le plus proche, y compris pour les styles de texte (Étape 6).
- **Priorité au réel** : si une couleur dérogatoire client est déclarée dans le brief, la classer comme "primitif projet accepté" — pas comme une erreur.
- **Chiffrer chaque action** : chaque ligne du plan doit indiquer le nombre d'occurrences impactées pour que le designer puisse estimer l'effort.
- **Ne pas lister exhaustivement** les nœuds : utiliser les 3–4 premiers comme exemples représentatifs, indiquer le total.
- **Styles de texte** : ne jamais trancher seul un matching qui traverse les familles de police ou qui perd une propriété (`UPPER`/`UNDERLINE`/`ITALIC`) sans la signaler — remonter ces cas au designer avant liaison.
- **Espacements/radius** : ne jamais forcer une valeur clairement hors échelle (marge structurelle) vers la variable la plus proche si l'écart dépasse ~50 % — la signaler plutôt que de risquer une régression visuelle. Toujours vérifier si un radius correspond à un cercle/pilule (≥ moitié de la plus petite dimension) avant de choisir une valeur numérique de l'échelle classique.
- **Composants** : ne jamais forcer une instanciation si un élément requis par le composant (icône, slot) est absent du nœud brut, ou si les tailles sont trop différentes — signaler l'absence de correspondance plutôt que de dégrader visuellement l'élément. Ce skill ne crée jamais de nouveau composant — c'est le rôle de `/composants`.
- Ce skill produit un **plan** — l'exécution du binding Figma est assurée par `/nettoyage-figma` (Opération B couleurs, D styles de texte, E espacements/radius, F composants), par le designer manuellement, ou par un **prompt Figma AI personnalisé** (Étape 9) que le designer colle lui-même dans Figma. La correspondance couleurs → Sass (côté code, pas côté Figma) est prise en charge séparément, en Passation, par l'agent Copilot `sds-bootstrap`.
- **Prompt Figma AI (Étape 9)** : ne jamais le générer sans le garde-fou d'exclusion des composants partagés et la consigne "vérifie que ce n'est pas déjà lié" en Étape 0 — un incident réel (2026-07-22, projet Neocampus) a montré qu'une liaison par simple valeur hex affichée peut silencieusement casser des bindings corrects ailleurs dans le fichier, sans régression visuelle détectable.
- Propose à la fin de sauvegarder le plan dans `mapping-ds-<date>.md`, ou le prompt généré dans `prompt-sds-<page>-<date>.md` si l'Étape 9 a été produite.
