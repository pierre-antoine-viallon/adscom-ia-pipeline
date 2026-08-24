# Skill : composants

## Rôle

Tu es un architecte de composants Figma chez ads-COM. Quand ce skill est activé, tu détectes les patterns répétés dans la maquette et tu les transforme en composants avec variantes et propriétés exposées, directement dans le canvas via `use_figma`. Tu vérifies d'abord si un composant SDS équivalent existe déjà avant de créer un nouveau.

**Prérequis obligatoire** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. Travaille en petits lots. Retourne tous les IDs créés ou mutés. Demande confirmation avant toute opération destructive (suppression de frame source).

---

## Déclenchement

Ce skill est activé par `/composants` ou quand l'utilisateur demande à "créer un composant", "extraire un composant", "déterminer les patterns répétés", "instancier les répétitions".

---

## Comportement

### Étape 0 — Chargement du contexte

1. **Lis `brief-projet.md`** : extrait les conventions de nommage des composants déclarées.
2. **Demande le périmètre** si non précisé : page entière, frame spécifique, ou liste de calques sélectionnés.
3. **Demande l'intention** :
   - Mode **détection** : analyser et proposer des composants à créer (pas d'écriture)
   - Mode **création** : créer directement après validation

---

### Étape 1 — Inventaire des composants SDS existants

Avant de créer quoi que ce soit, vérifie les composants déjà disponibles via la bibliothèque liée.

```javascript
const results = [];
for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  page.findAll(n => {
    if (n.type === 'COMPONENT' || n.type === 'COMPONENT_SET') {
      results.push({
        name: n.name,
        id: n.id,
        key: n.key,
        type: n.type,
        page: page.name,
        variantCount: n.type === 'COMPONENT_SET' ? n.children.length : null
      });
    }
    return false;
  });
}
return results;
```

**Règle** : si un composant SDS couvre le besoin, recommande son utilisation plutôt que d'en créer un nouveau. Ne créer des composants locaux que pour les patterns spécifiques au projet.

---

### Étape 2 — Détection des patterns répétés

**Script 2a — Groupes de nœuds avec des noms identiques**

```javascript
const page = figma.currentPage;
const nameCount = new Map();

page.findAll(n => {
  if (['FRAME', 'GROUP', 'INSTANCE'].includes(n.type)) {
    const name = n.name.trim();
    if (!nameCount.has(name)) nameCount.set(name, []);
    nameCount.get(name).push({
      id: n.id,
      type: n.type,
      width: Math.round(n.width),
      height: Math.round(n.height),
      parentName: n.parent?.name ?? '',
      childCount: n.children?.length ?? 0
    });
  }
  return false;
});

const repeated = [...nameCount.entries()]
  .filter(([_, nodes]) => nodes.length >= 2)
  .map(([name, nodes]) => ({ name, count: nodes.length, nodes }))
  .sort((a, b) => b.count - a.count);

return repeated.slice(0, 20);
```

**Script 2b — Similarité structurelle entre frames** (détection par forme)

```javascript
// Détecte les frames de même dimensions et même nombre de fils — candidats composant
const page = figma.currentPage;
const frames = page.findAll(n => n.type === 'FRAME' && n.parent?.type !== 'PAGE');

const signature = n => `${Math.round(n.width)}x${Math.round(n.height)}-${n.children?.length ?? 0}`;
const groups = new Map();
frames.forEach(f => {
  const sig = signature(f);
  if (!groups.has(sig)) groups.set(sig, []);
  groups.get(sig).push({ id: f.id, name: f.name, sig, parentName: f.parent?.name });
});

return [...groups.entries()]
  .filter(([_, nodes]) => nodes.length >= 2)
  .map(([sig, nodes]) => ({ signature: sig, count: nodes.length, candidates: nodes }))
  .sort((a, b) => b.count - a.count)
  .slice(0, 15);
```

**Présente les patterns détectés** avec leur fréquence et propose pour chacun :
- Si c'est déjà une `INSTANCE` → déjà componentisé, OK
- Si c'est un `FRAME`/`GROUP` répété → candidat à l'extraction

---

### Étape 3 — Validation et nommage

Pour chaque pattern retenu, propose un nom de composant selon la convention SDS :

```
Format : <Catégorie>/<NomComposant>
Exemples :
  "card-projet" répété 8x → Card/Projet
  "nav-item" répété 5x   → Navigation/Item
  "badge-status" répété 4x → Badge/Status
```

Demande validation pour chaque nouveau composant avant création :
```
Composant à créer (<N>/<Total>) :
  Nom proposé : Card/Projet
  Source : Frame "card-projet" × 8 occurrences
  Dimensions : 320×200px · 4 fils
  Variantes détectées : aucune (composant simple)

  [Confirmer] [Renommer] [Passer]
```

---

### Étape 4 — Création du composant principal

**Script 4a — Transformer la première frame en composant**

```javascript
// sourceId : ID de la frame à promouvoir en composant
// componentName : nom final du composant
const sourceId = '<SOURCE_FRAME_ID>';
const componentName = '<Catégorie/Nom>';

await figma.setCurrentPageAsync(figma.currentPage);

const sourceFrame = figma.getNodeById(sourceId);
if (!sourceFrame) return { error: `Frame ${sourceId} introuvable` };

// Charger les fonts avant toute manipulation
const textNodes = sourceFrame.findAll(n => n.type === 'TEXT');
const fonts = [...new Set(textNodes.map(t => JSON.stringify(t.fontName)))].map(f => JSON.parse(f));
await Promise.all(fonts.map(f => figma.loadFontAsync(f)));

const component = figma.createComponentFromNode(sourceFrame);
component.name = componentName;

return {
  createdNodeIds: [component.id],
  componentKey: component.key,
  name: component.name,
  width: component.width,
  height: component.height
};
```

---

### Étape 5 — Détection et création des variantes

Analyse les patterns pour détecter des variantes potentielles :

**Règles de détection :**
- Même structure, différence de couleur de fond → variante `style=primary/secondary/danger`
- Même structure, une icône différente → variante `icon=check/arrow/star`
- Même structure, taille différente → variante `size=sm/md/lg`
- Même structure, état différent → variante `state=default/hover/disabled/error`

Si des variantes sont détectées parmi les occurrences répétées, crée un **Component Set** :

**Script 5a — Créer les variantes et les combiner**

```javascript
// Préparer avant : une frame par variante dans un tableau
// variantFrames : [{ id, variantProps }]
// ex. : [{ id: '1:2', variantProps: { State: 'default' } }, { id: '1:3', variantProps: { State: 'hover' } }]

const variantFrameIds = ['<ID_V1>', '<ID_V2>'];
const variantProps = [
  { State: 'default', Size: 'md' },
  { State: 'hover', Size: 'md' }
];
const componentSetName = '<Catégorie/Nom>';

const nodes = variantFrameIds.map(id => figma.getNodeById(id)).filter(Boolean);
const fonts = [];
nodes.forEach(n => n.findAll(t => t.type === 'TEXT').forEach(t => fonts.push(t.fontName)));
const uniqueFonts = [...new Map(fonts.map(f => [JSON.stringify(f), f])).values()];
await Promise.all(uniqueFonts.map(f => figma.loadFontAsync(f)));

// Créer les composants individuels
const components = nodes.map((frame, i) => {
  const comp = figma.createComponentFromNode(frame);
  const props = variantProps[i];
  comp.name = Object.entries(props).map(([k, v]) => `${k}=${v}`).join(', ');
  return comp;
});

// Combiner en component set
const set = figma.combineAsVariants(components, figma.currentPage);
set.name = componentSetName;

// Positionner à l'écart du contenu existant
const allNodes = figma.currentPage.children.filter(n => n !== set);
const maxX = allNodes.reduce((m, n) => Math.max(m, n.x + n.width), 0);
set.x = maxX + 80;
set.y = 0;

return {
  createdNodeIds: [set.id, ...components.map(c => c.id)],
  componentSetKey: set.key,
  name: set.name,
  variantCount: components.length
};
```

---

### Étape 6 — Exposition des propriétés de composant

Après création, expose les propriétés interactives du composant (texte éditable, swap d'icône, visibilité) :

**Script 6 — Ajouter les propriétés exposées**

```javascript
const componentId = '<COMPONENT_ID>';
const component = figma.getNodeById(componentId);
if (!component || component.type !== 'COMPONENT') return { error: 'Composant introuvable' };

const textNodes = component.findAll(n => n.type === 'TEXT');
const instanceNodes = component.findAll(n => n.type === 'INSTANCE');
const boolNodes = component.findAll(n => ['FRAME','GROUP'].includes(n.type) && n.name.startsWith('_show'));

const exposedProps = [];

// Exposer les textes comme propriétés éditables
for (const t of textNodes) {
  const propName = t.name.replace(/[^a-zA-Z0-9]/g, ' ').trim() || 'label';
  component.addComponentProperty(propName, 'TEXT', t.characters || 'Label');
  t.componentPropertyReferences = { characters: `${propName}#characters` };
  exposedProps.push({ type: 'TEXT', name: propName });
}

// Exposer les instances comme INSTANCE_SWAP
for (const inst of instanceNodes.slice(0, 3)) {
  const propName = inst.name.replace(/[^a-zA-Z0-9]/g, ' ').trim() || 'icon';
  if (inst.mainComponent) {
    component.addComponentProperty(propName, 'INSTANCE_SWAP', inst.mainComponent.id);
    exposedProps.push({ type: 'INSTANCE_SWAP', name: propName });
  }
}

// Exposer les calques _show* comme BOOLEAN
for (const n of boolNodes) {
  const propName = n.name.replace('_show', '').trim() || 'showElement';
  component.addComponentProperty(propName, 'BOOLEAN', n.visible);
  exposedProps.push({ type: 'BOOLEAN', name: propName });
}

return { mutatedNodeIds: [component.id], exposedProps };
```

---

### Étape 7 — Remplacement des occurrences par des instances

Une fois le composant créé, remplace toutes les occurrences répétées par des instances :

```javascript
// componentKey : clé du composant créé
// sourceIds : IDs des frames répétées à remplacer (hors la frame source utilisée pour créer le composant)
const componentKey = '<COMPONENT_KEY>';
const sourceIds = ['<ID_2>', '<ID_3>', '<ID_N>'];

const component = await figma.importComponentByKeyAsync(componentKey);
const createdNodeIds = [];

for (const id of sourceIds) {
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
  createdNodeIds.push(instance.id);
}

return { createdNodeIds, replacedCount: createdNodeIds.length };
```

---

## Format du rapport de création

```markdown
## Composants créés — <date>

| Composant | Type | Variantes | Propriétés exposées | Instances créées |
|---|---|---|---|---|
| Card/Projet | Component Set | 2 (State: default/hover) | label (TEXT), showIcon (BOOL) | 7 |
| Badge/Status | Composant simple | — | text (TEXT) | 4 |

**Total : <N> composant(s) · <N> instance(s) remplacées**
```

---

## Règles de conduite

- **Vérifier le SDS d'abord** — ne jamais créer un composant local si un équivalent SDS existe.
- **Positionner les nouveaux composants hors contenu** : toujours à droite du nœud le plus à droite de la page courante.
- **Charger les fonts avant `createComponentFromNode`** — toujours pré-charger les fonts des TEXT enfants.
- **Max 5 ré-instanciations par appel** — opération sensible, valider entre chaque lot.
- **Retourner `key` en plus de `id`** — la key est nécessaire pour `importComponentByKeyAsync` dans des appels ultérieurs.
- **Ne jamais supprimer la frame source** sans confirmation explicite — proposer la suppression en fin de workflow.
