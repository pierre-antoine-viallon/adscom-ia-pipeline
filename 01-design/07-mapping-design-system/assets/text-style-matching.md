# Matching des styles de texte — formule et heuristiques

> Utilisé par `07-mapping-design-system` (Étape 6) pour rapprocher un texte hardcodé (famille, graisse, taille) du style de texte nommé le plus proche déjà défini dans le SDS du fichier Figma.
> Ne jamais créer de nouveau style — toujours rapprocher vers l'existant, quitte à signaler un écart au designer.

---

## Pourquoi une formule plutôt qu'un jugement au cas par cas

Un fichier Figma peut contenir des dizaines de combinaisons non stylées, souvent dues à :
- des imports bruts (HTML-to-Figma, copier-coller depuis un autre fichier),
- des duplications à différentes échelles responsive (mobile/tablette/desktop),
- des micro-écarts d'arrondi (`57.599998474121094` au lieu de `57.6`, `15.998852...` au lieu de `16`).

Une formule reproductible évite de traiter chaque cas au doigt mouillé et rend le résultat auditable.

---

## Étape 1 — Convertir la graisse en rang numérique

| Style de police | Rang |
|---|---|
| Regular / Italic | 1 |
| Medium | 2 |
| SemiBold | 3 |
| Bold | 4 |
| ExtraBold | 5 |
| Black | 6 |

`Italic` partage le rang de `Regular` — la casse italique est traitée séparément comme un attribut de décoration (voir Étape 4), pas comme une graisse.

---

## Étape 2 — Contrainte dure : la famille de police

**Ne jamais matcher entre deux familles différentes** (ex. un texte en Poppins ne doit jamais être lié à un style Roboto), sauf si :
- aucun style de la même famille n'existe dans le SDS à une taille raisonnable, **et**
- l'écart de taille/graisse avec un style d'une autre famille est quasi nul (signe probable d'une erreur de saisie plutôt que d'une intention).

Dans ce cas de figure, **ne jamais trancher seul** : présenter le cas au designer avec les deux options (laisser hardcodé vs. lier en traversant la famille) et attendre sa décision.

---

## Étape 3 — Score de distance

Pour chaque style candidat de la même famille :

```
score = |tailleNœud - tailleStyle| × 2 + |rangGraisseNœud - rangGraisseStyle| × 3
```

Le style au score le plus bas est retenu. Pondération :
- La **graisse** pèse plus que la **taille** (×3 vs ×2) car un changement de graisse est visuellement plus perceptible qu'un écart de quelques pixels.
- Les deux facteurs sont volontairement combinés dans une seule formule plutôt que priorisés en cascade, pour éviter de choisir un style à la bonne taille mais à une graisse aberrante (ou l'inverse).

### Départage en cas d'égalité de score

1. **Line-height** : comparer le pourcentage de line-height réel du nœud à celui de chaque style candidat ex-aequo — retenir le plus proche.
2. **Contexte du calque parent** : un parent nommé `Button`, un texte très court (label, tag, chiffre isolé) ou un besoin visuel "une seule ligne" oriente vers une variante *single line* du SDS si elle existe (ex. une collection `Single Line/*` à line-height 100%, dédiée aux composants UI compacts).
3. **Nom du parent en `Heading N`** : si le fichier utilise une convention de nommage `Heading 1`/`Heading 2`/`Heading 3` sur les calques parents, elle reflète une hiérarchie éditoriale — un `Heading 3` doit être matché à un style visuellement inférieur ou égal à celui utilisé pour les `Heading 2` du même fichier, même si la distance numérique brute suggérerait un autre style.

---

## Étape 4 — Propriétés non couvertes par le score

Certaines propriétés du nœud ne participent pas au score mais doivent être vérifiées après avoir choisi le style le plus proche :

| Propriété du nœud | Le style cible la couvre ? | Action |
|---|---|---|
| `textCase: UPPER` | Non (la plupart des styles sont `ORIGINAL`) | Appliquer le style puis réappliquer `textCase = 'UPPER'` en override local sur le nœud |
| `textDecoration: UNDERLINE` | Seulement si un style dédié existe (ex. `Body Link`) | Préférer ce style dédié s'il est de taille/graisse proche ; sinon, appliquer le style le plus proche puis réappliquer la décoration |
| `fontStyle: Italic` | Seulement si un style dédié existe (ex. `Body Emphasis`) | Idem — préférer le style dédié à taille égale |

**Toujours signaler ces cas dans le rapport** (colonne "Note" ou section dédiée) : appliquer un style puis le modifier localement crée un override visible dans l'UI Figma ("style + modifications"), ce qui est normal mais doit être compris du designer.

---

## Étape 5 — Regrouper les duplications à échelle variable

Avant de figer les matchings, comparer le contenu textuel (`characters`, tronqué à ~40 caractères) entre combinaisons différentes. Si deux combinaisons ou plus partagent un contenu identique/quasi identique mais des tailles différentes, elles représentent presque toujours **le même élément dupliqué à une autre échelle** (responsive, plusieurs gabarits d'un même produit, export à différentes largeurs de conteneur).

**Dans ce cas, unifier tout le groupe vers un seul style cible** — choisi par vote majoritaire parmi les matchings individuels du groupe, ou par cohérence sémantique (ex. un texte utilisé comme "sous-titre sous un grand titre" doit rester un style de sous-titre même si sa taille isolée le rapprocherait numériquement d'un autre style). Ne pas laisser deux instances du même contenu éditorial finir sur deux styles différents.

---

## Exemple de calcul

Nœud détecté : `Roboto`, `Bold`, taille `18`, line-height `150%`.

Styles candidats (même famille `Roboto`) :
- `Body Large` : Regular (rang 1), taille 18, line-height 145%
  → score = `|18-18|×2 + |4-1|×3` = `0 + 9` = **9**
- `Body Large Strong` : ExtraBold (rang 5), taille 20, line-height 140%
  → score = `|18-20|×2 + |4-5|×3` = `4 + 3` = **7**
- `Subheading` : Bold (rang 4), taille 24, line-height 120%
  → score = `|18-24|×2 + |4-4|×3` = `12 + 0` = **12**

**Résultat : `Body Large Strong` retenu (score 7, le plus bas)** malgré une graisse et une taille non exactement identiques — c'est le meilleur compromis disponible dans le SDS.
