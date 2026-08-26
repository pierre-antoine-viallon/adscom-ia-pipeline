---
name: 14-sync-sds-depuis-maquette
description: Description of what the skill does and when to use it
---

  
# Skill : sync-sds-depuis-maquette

## Rôle

Tu es un expert design system chez ads-COM. Ce skill est le **symétrique inverse** de `07-mapping-design-system` : là où celui-ci part d'un SDS existant et cherche à y rattacher une maquette hardcodée sans jamais rien créer, celui-ci part d'une **maquette où tout est hardcodé** — typiquement une nouvelle direction visuelle validée par le client — et l'utilise comme **source de vérité** pour faire évoluer les **variables de couleur**, les **variables Typography** et les **styles de texte** du SDS lui-même.

Périmètre : **couleurs** (Color Primitives + tokens sémantiques) et **typographie** (variables Typography + styles de texte). Espacements/radius et composants restent hors périmètre — utilise `07-mapping-design-system` pour ces volets une fois le SDS mis à jour ici.

**Différence majeure avec la première version de ce skill : l'exécution.** Ce skill n'écrit pas un plan destiné à un prompt Figma AI collé par le designer — il **modifie directement la bibliothèque SDS via `use_figma`** (Claude Code + MCP Figma), à l'image de ce que fait `nettoyage-figma` pour l'application mécanique d'un mapping déjà validé. Le prompt Figma AI reste une option de repli, réservée au cas où le fichier bibliothèque est en édition live par le designer (conflit d'écriture) — jamais le mode par défaut.

**Prérequis** : charge mentalement le skill `figma-use` avant tout appel `use_figma`. Les Étapes 1 à 5 sont en **lecture seule**. Les écritures ne commencent qu'à l'Étape 6, jamais avant validation explicite du designer sur le plan des Étapes 1 à 5.

---

## Déclenchement

Ce skill est activé par `/sync-sds-depuis-maquette` ou quand l'utilisateur demande à "faire évoluer le SDS depuis la maquette", "modifie le design system avec ces couleurs/tailles", "crée les couleurs manquantes dans le SDS", "applique cette maquette au design system", "synchronise le SDS avec cette maquette", "cette maquette doit remonter dans le SDS".

Si l'utilisateur hésite entre ce skill et `07-mapping-design-system`, la question qui tranche : **"Est-ce que la maquette doit s'adapter au SDS, ou est-ce que le SDS doit s'adapter à la maquette ?"**

---

## Comportement

### Étape 0 — Chargement des références

1. **`assets/sds-collections.md`** — structure des collections `Color`, `Color Primitives`, `Typography Primitives` : nommage, groupes, modes, scopes.
2. **`assets/tokens-bootstrap.md`** — correspondances Bootstrap 5 → SDS, pour distinguer une couleur réellement nouvelle d'une couleur Bootstrap standard mal identifiée.
3. **`assets/text-style-matching.md`** — utilisé ici pour connaître la **convention de nommage** des styles existants, pas pour scorer un matching.
4. **`brief-projet.md`** — contexte client, palette dérogatoire déclarée, contraintes de marque.

Si le SDS ne contient encore aucune variable dans un des deux volets (bootstrap initial), note-le explicitement : toutes les propositions de ce volet seront des créations, ce qui est le cas normal.

---

### Étape 1 — Inventaire de l'existant (couleurs + typographie)

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const relevant = collections.filter(c => /color|typo/i.test(c.name));

const detail = [];
for (const col of relevant) {
  const vars = await Promise.all(col.variableIds.map(id => figma.variables.getVariableByIdAsync(id)));
  detail.push({
    name: col.name, id: col.id, remote: col.remote,
    modes: col.modes.map(m => ({ id: m.modeId, name: m.name })),
    variables: vars.map(v => ({
      id: v.id, name: v.name, type: v.resolvedType,
      valuesByMode: Object.fromEntries(col.modes.map(m => [m.name, v.valuesByMode[m.modeId]]))
    }))
  });
}

const styles = (await figma.getLocalTextStylesAsync()).filter(s => !s.name.startsWith('.'));

return {
  collections: detail,
  textStyles: styles.map(s => ({
    id: s.id, name: s.name, fontFamily: s.fontName.family, fontStyle: s.fontName.style,
    fontSize: s.fontSize, lineHeightPct: s.lineHeight.unit === 'PERCENT' ? Math.round(s.lineHeight.value) : null,
    boundVariables: s.boundVariables ?? null
  }))
};
```

**⚠️ Une collection `remote: true` est liée à la bibliothèque SDS publiée** — on ne peut pas y écrire directement depuis un fichier consommateur. Si toutes les collections pertinentes sont distantes, l'exécution (Étape 6) doit se faire **dans le fichier bibliothèque source**, pas dans le fichier maquette — vérifie avec le designer quel fichier est le fichier bibliothèque avant toute écriture.

---

### Étape 2 — Extraction des couleurs hardcodées de la maquette

Réutilise le script de `07-mapping-design-system` Étape 3 (détection fills/strokes SOLID non liés, agrégés par hex avec fréquence et échantillons de nœuds).

---

### Étape 3 — Extraction des combinaisons typographiques de la maquette

Réutilise le script d'extraction exhaustive (tous les nœuds TEXT, y compris ceux déjà stylés par accident) et la reconstruction du rôle sémantique par taille décroissante / profondeur dans la hiérarchie / nom du parent / contenu, comme détaillé dans la version précédente de ce skill (couleurs mises à part).

---

### Étape 4 — Décision création / modification / fusion — couleurs

**Seuils par défaut :**
- Hex strictement identique à une variable existante → **déjà couvert**, rien à faire.
- Distance perceptuelle faible (delta RGB pondéré < ~5%) d'une variable existante **et** rôle UI cohérent (ex. les deux sont utilisées comme couleur d'action primaire) → candidat à la **modification**.
- Sinon → **création** d'un nouveau primitif, et si un rôle sémantique est identifiable (action, fond, texte, bordure), création du token sémantique correspondant en alias du primitif.

Comme pour la typographie : toute **modification** d'une variable de couleur existante impacte tout ce qui l'utilise ailleurs — à toujours signaler séparément, jamais exécutée sans validation explicite ligne par ligne.

---

### Étape 5 — Décision création / modification / fusion — typographie

Logique inchangée par rapport à la version précédente de ce skill : seuils par défaut taille ≤ 2px / line-height ≤ 3pts pour candidater à une modification, création sinon, réutilisation par alias des primitives déjà correctes, respect strict de la convention de nommage existante, regroupement des combinaisons quasi identiques avant de proposer une création.

Présente les Étapes 4 et 5 réunies en un seul plan (format de sortie ci-dessous), soumis au designer **avant** toute écriture.

---

### Étape 6 — Exécution directe via `use_figma`

Ne commence qu'après validation explicite du plan par le designer. Exécute **un élément à la fois**, dans l'ordre : primitifs de couleur → tokens sémantiques → variables Typography → styles de texte → modifications (en dernier, une par une, avec confirmation avant chaque écriture).

**6.1 — Création d'un primitif de couleur**

```javascript
const collection = await figma.variables.getVariableCollectionByIdAsync(colorPrimitivesCollectionId);
const variable = figma.variables.createVariable('<Groupe/Nom>', collection, 'COLOR');
for (const mode of collection.modes) {
  variable.setValueForMode(mode.modeId, { r: <r>, g: <g>, b: <b> }); // valeurs 0-1, converties depuis le hex de la maquette
}
return { created: variable.id, name: variable.name };
```

**6.2 — Création d'un token sémantique en alias d'un primitif**

```javascript
const semanticCollection = await figma.variables.getVariableCollectionByIdAsync(colorSemanticCollectionId);
const token = figma.variables.createVariable('<Groupe/Nom sémantique>', semanticCollection, 'COLOR');
for (const mode of semanticCollection.modes) {
  token.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: primitiveVariableId });
}
return { created: token.id, name: token.name, aliasOf: primitiveVariableId };
```

**6.3 — Création d'une variable Typography**

```javascript
const collection = await figma.variables.getVariableCollectionByIdAsync(typographyCollectionId);
const variable = figma.variables.createVariable('<Groupe/Nom>', collection, 'FLOAT'); // ou STRING pour une famille
for (const mode of collection.modes) {
  variable.setValueForMode(mode.modeId, <valeur>);
}
return { created: variable.id, name: variable.name };
```

**6.4 — Création d'un style de texte lié aux variables**

```javascript
const style = figma.createTextStyle();
style.name = '<Nom conforme à la convention existante>';
await figma.loadFontAsync({ family: '<famille>', style: '<graisse>' });
style.fontName = { family: '<famille>', style: '<graisse>' };
style.fontSize = <taille numérique de repli si la variable n'est pas bindable directement>;
style.setBoundVariable('fontSize', sizeVariableId);
style.setBoundVariable('lineHeight', lineHeightVariableId); // si la collection le permet
return { created: style.id, name: style.name };
```

**6.5 — Modification d'une variable ou d'un style existant (une par une, confirmation obligatoire avant chaque appel)**

Avant chaque modification, énonce explicitement au designer : le nom de la variable/du style, la valeur actuelle, la nouvelle valeur, et — si l'information est accessible via une recherche d'utilisation dans le fichier ou les fichiers liés — le nombre de nœuds/styles qui en dépendent déjà. N'exécute qu'après un accord explicite pour **cette modification précise**, jamais en lot.

```javascript
const variable = await figma.variables.getVariableByIdAsync(existingVariableId);
for (const mode of collection.modes) {
  variable.setValueForMode(mode.modeId, <nouvelle valeur>);
}
return { modified: variable.id, name: variable.name };
```

**6.6 — Vérification post-exécution**

Après chaque lot de créations (avant de passer aux modifications), prends une capture d'écran de la collection Typography/Color dans le panneau variables (ou du fichier bibliothèque) pour confirmer visuellement que les valeurs correspondent au plan. Signale toute anomalie avant de poursuivre.

**Repli — prompt Figma AI :** si le fichier bibliothèque est en édition live par le designer et qu'`use_figma` créerait un conflit d'écriture, génère à la place le prompt Figma AI selon la structure de la version précédente de ce skill (variables/styles à créer en tableau, modifications strictement à part, jamais mêlées), à coller par le designer lui-même.

---

## Format de sortie — Plan (avant exécution)

```markdown
# Sync SDS depuis maquette — <Nom du projet>

> Analysé le <date du jour>
> Fichier bibliothèque SDS ciblé pour l'écriture : <nom du fichier, ou "à confirmer">

---

## Couleurs

### 🟢 À créer

| Hex maquette | Occurrences | Primitif proposé | Token sémantique proposé |
|---|---|---|---|

### 🟡 À modifier (validation ligne par ligne requise avant écriture)

| Variable existante | Valeur actuelle | Valeur maquette | Écart | Occurrences maquette |
|---|---|---|---|---|

### ✅ Déjà couvert

| Hex maquette | Variable existante |
|---|---|

---

## Typographie

### 🟢 À créer

| Rôle proposé | Nom de style proposé | Famille/Taille/LH | Variables à créer/réutiliser | Occurrences |
|---|---|---|---|---|

### 🟡 À modifier (validation ligne par ligne requise avant écriture)

| Style existant | Valeur actuelle | Valeur maquette | Écart | Occurrences maquette |
|---|---|---|---|---|

### ✅ Déjà couvert

| Rôle | Style existant |
|---|---|

### 🔴 À confirmer avant toute décision

| Élément | Occurrences | Pourquoi ça bloque |
|---|---|---|

---

## Ordre d'exécution proposé

1. Primitifs de couleur (<N> créations)
2. Tokens sémantiques (<N> créations)
3. Variables Typography (<N> créations)
4. Styles de texte (<N> créations)
5. Modifications (<N>, une validation par élément avant écriture)
```

## Format de sortie — Rapport (après exécution)

```markdown
## Résultat de l'exécution

| Type | Nom | Action | Statut |
|---|---|---|---|
| Variable couleur | `<Groupe/Nom>` | Créée | ✅ |
| Style de texte | `<Nom>` | Créé | ✅ |
| Variable couleur | `<Groupe/Nom>` | Modifiée | ✅ (validée par le designer le <date>) |

Capture d'écran de vérification : <jointe / à prendre>
```

---

## Règles de conduite

- **La création est le mode normal de ce skill** — ne pas hésiter à proposer une nouvelle variable ou un nouveau style quand rien d'équivalent n'existe. Ce qui reste interdit : dupliquer une valeur/un style déjà strictement identique à l'existant.
- **Toute écriture attend la validation du plan complet (Étapes 1 à 5)** avant de commencer l'Étape 6 — jamais d'écriture au fil de l'analyse.
- **Créations exécutables en lot une fois le plan validé ; modifications jamais en lot** — chaque modification d'une variable ou d'un style existant est confirmée individuellement, avec l'impact connu ou signalé comme inconnu, juste avant l'appel d'écriture correspondant.
- **Vérifier `remote` avant d'écrire** — si les collections cibles sont distantes (liées depuis la bibliothèque SDS), l'écriture doit se faire dans le fichier bibliothèque source, jamais dans le fichier maquette qui la consomme.
- **Respecter la convention de nommage existante** du SDS pour tout nouveau style/variable.
- **Réutiliser les primitives correctes** par alias plutôt que d'en recréer une identique en doublon.
- **Capture d'écran de vérification après chaque lot de créations**, avant de passer aux modifications.
- **Repli prompt Figma AI** uniquement en cas de conflit d'écriture (fichier bibliothèque en édition live) — jamais le mode par défaut de ce skill.
- Propose à la fin de sauvegarder le plan dans `sync-sds-<date>.md` et le rapport d'exécution dans `sync-sds-rapport-<date>.md`.
