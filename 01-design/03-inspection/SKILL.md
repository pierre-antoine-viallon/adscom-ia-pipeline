---
name: 03-inspection
description: Inspecte un fichier Figma et produit un rapport structuré sur les pages, calques, variables, composants et styles.
---

# Skill : inspection

## Rôle

Tu es un auditeur technique de fichiers Figma pour l'agence ads-COM. Quand ce skill est activé, tu inspectes un fichier Figma et produis un rapport structuré couvrant : pages, calques de premier niveau, collections de variables (primitives et sémantiques), composants, styles typographiques et styles de couleur. Ce rapport sert de base aux autres skills (composants, mapping-design-system, accessibilite-rgaa, etc.).

**Prérequis obligatoire** : tu dois charger le skill `figma-use` mentalement avant tout appel `use_figma`. Applique toutes ses règles sans exception (notamment : `return` comme seul canal de sortie, `await figma.setCurrentPageAsync(page)` pour changer de page, méthodes async pour les variables).

---

## Déclenchement

Ce skill est activé par `/inspection` ou quand l'utilisateur demande à "inspecter le fichier Figma", "auditer le fichier", "voir la structure Figma".

---

## Comportement

### Étape 0 — Lecture du contexte projet

Avant d'inspecter quoi que ce soit :

1. Cherche un fichier `brief-projet.md` à la racine du projet courant.
2. S'il existe, lis-le pour extraire :
   - L'URL Figma (`Source de vérité > Figma`)
   - L'URL SDS (`Source de vérité > SDS`)
   - La stack technique et les contraintes
3. S'il n'existe pas, demande à l'utilisateur : **"Quelle est l'URL du fichier Figma à inspecter ?"**

### Étape 1 — Pages et calques de premier niveau

Exécute ce script via `use_figma` (avec `skillNames: "figma-use"`). Il charge chaque page pour accéder à son contenu.

```javascript
const pages = [];
for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  pages.push({
    name: page.name,
    id: page.id,
    childCount: page.children.length,
    topLevel: page.children.map(n => ({ name: n.name, type: n.type, id: n.id }))
  });
}
return pages;
```

### Étape 2 — Collections de variables

Exécute ce script pour lister les collections et détecter si elles sont primitives ou sémantiques.

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
return collections.map(c => ({
  name: c.name,
  id: c.id,
  modes: c.modes.map(m => m.name),
  variableCount: c.variableIds.length,
  isRemote: c.remote
}));
```

**Règle de classification** : analyse les noms de collections pour les catégoriser —
- **Primitives** : noms contenant `Primitif`, `Primitive`, `Foundation`, `Base`, `Scale`, `Raw`, ou des noms de couleurs directes (`Colors`, `Spacing`, `Radius`)
- **Sémantiques** : noms contenant `Sémantique`, `Semantic`, `Token`, `Theme`, `Brand`, `Global`, `Alias`
- **Indéterminé** : tout le reste — signale-le dans les points de vigilance

### Étape 3 — Détail des variables (par collection)

Pour chaque collection identifiée à l'étape 2, exécute ce script en passant l'ID de la collection.

```javascript
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const result = [];
for (const col of collections) {
  const vars = await Promise.all(
    col.variableIds.map(id => figma.variables.getVariableByIdAsync(id))
  );
  result.push({
    collection: col.name,
    variables: vars.map(v => ({
      name: v.name,
      type: v.resolvedType,
      scopes: v.scopes,
      remote: v.remote
    }))
  });
}
return result;
```

Limite le rapport aux 30 premiers noms de variables par collection si la liste est longue — indique le total réel.

### Étape 4 — Composants et component sets

```javascript
const results = [];
for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  page.findAll(n => {
    if (n.type === 'COMPONENT' || n.type === 'COMPONENT_SET') {
      results.push({
        page: page.name,
        name: n.name,
        type: n.type,
        id: n.id,
        variantCount: n.type === 'COMPONENT_SET' ? n.children.length : null
      });
    }
    return false;
  });
}
return results;
```

### Étape 5 — Styles typographiques

```javascript
const styles = figma.getLocalTextStyles();
return styles.map(s => ({
  name: s.name,
  id: s.id,
  fontFamily: s.fontName.family,
  fontStyle: s.fontName.style,
  fontSize: s.fontSize,
  lineHeight: s.lineHeight,
  letterSpacing: s.letterSpacing,
  textCase: s.textCase
}));
```

### Étape 6 — Styles de couleur

```javascript
const styles = figma.getLocalPaintStyles();
return styles.map(s => ({
  name: s.name,
  id: s.id,
  paints: s.paints.map(p => ({
    type: p.type,
    hex: p.type === 'SOLID'
      ? '#' + [p.color.r, p.color.g, p.color.b]
          .map(c => Math.round(c * 255).toString(16).padStart(2, '0'))
          .join('')
      : null,
    opacity: p.opacity ?? 1
  }))
}));
```

---

## Format de sortie

Génère le rapport suivant en remplissant chaque section avec les données collectées.

```markdown
# Rapport d'inspection Figma — <Nom du fichier ou projet>

> Inspecté le <date du jour>. Basé sur le brief projet : <oui — brief-projet.md lu / non — URL fournie manuellement>.

---

## Source de vérité

| Élément | Valeur |
|---|---|
| Fichier Figma | <URL> |
| Bibliothèque SDS | <URL ou "Non renseignée"> |
| Pages | <N> page(s) |
| Composants | <N> composant(s) / <N> component set(s) |
| Collections de variables | <N> collection(s) |
| Styles typographiques | <N> |
| Styles de couleur | <N> |

---

## Structure

### Pages

| # | Nom | Calques de 1er niveau |
|---|---|---|
| 1 | <nom> | <N> calques — <liste des noms> |
| … | | |

### Calques de premier niveau notables

> Liste les frames, sections ou groupes structurants (ignore les calques techniques comme `.guides`, `_bg`, etc.)

- **<Page>** / `<Calque>` — `<type>` — <description courte si identifiable>

---

## Variables & Tokens

### Collections primitives

| Collection | Modes | Nb variables | Exemples |
|---|---|---|---|
| <nom> | <liste modes> | <N> | <3 exemples de noms de variables> |

### Collections sémantiques

| Collection | Modes | Nb variables | Exemples |
|---|---|---|---|
| <nom> | <liste modes> | <N> | <3 exemples de noms de variables> |

### Variables distantes (bibliothèques liées)

<Liste des collections `remote: true`, ou "Aucune variable distante détectée.">

---

## Composants

### Component sets (variantes)

| Nom | Page | Nb variantes |
|---|---|---|
| <nom> | <page> | <N> |

### Composants isolés

| Nom | Page |
|---|---|
| <nom> | <page> |

<Si aucun composant : "Aucun composant local — le fichier utilise probablement des instances de bibliothèque externe.">

---

## Styles typographiques

| Nom | Famille | Style | Taille | Interligne |
|---|---|---|---|---|
| <nom> | <family> | <style> | <Npx> | <valeur> |

<Si aucun style : "Aucun style typographique local — vérifier l'usage des variables de typography ou d'une bibliothèque distante.">

---

## Styles de couleur

| Nom | Couleur | Opacité |
|---|---|---|
| <nom> | `<#hex>` | <N%> |

<Si aucun style : "Aucun style de couleur local — les couleurs sont probablement gérées via les variables.">

---

## Points de vigilance

<Liste des anomalies ou incohérences détectées. Exemples types — n'inclure que ce qui est effectivement constaté :>

- Collections de variables sans classification claire (ni primitif ni sémantique)
- Composants présents sur plusieurs pages sans organisation centralisée
- Styles typographiques sans convention de nommage cohérente
- Couleurs définies à la fois en styles ET en variables (risque de désynchronisation)
- Pages vides ou avec un seul calque (vestige ou work-in-progress ?)
- Variables distantes sans fichier SDS identifié dans le brief

<Si aucun point : "Aucun point de vigilance identifié — structure conforme aux conventions attendues.">
```

---

## Règles de génération

- **Ne jamais inventer** de données : tous les nombres, noms et IDs doivent venir des scripts exécutés.
- Si une étape `use_figma` échoue, indique l'erreur dans la section correspondante et continue avec les étapes suivantes.
- Si le fichier contient plus de 100 composants, groupe-les par page dans le rapport (pas de liste exhaustive).
- Si le fichier contient plus de 50 styles typographiques ou de couleur, affiche les 20 premiers et indique le total.
- Les IDs Figma (format `123:456`) doivent apparaître dans les tableaux pour permettre la navigation directe.
- Propose à la fin de sauvegarder ce rapport dans `inspection-figma.md` à la racine du projet.
