# SDS — Structure des collections de variables

> Source : Figma Simple Design System — github.com/figma/sds
> Ce document décrit la structure canonique des collections SDS à utiliser comme référence de mapping.
> Les valeurs hex exactes sont à lire depuis le fichier SDS Figma du projet (URL dans brief-projet.md).

---

## Collections présentes dans le SDS

| Collection | Rôle | Modes |
|---|---|---|
| **Color Primitives** | Valeurs brutes — hex directs, échelle de teintes | aucun mode (valeurs fixes) |
| **Color** | Tokens sémantiques — rôles UI, thème clair/sombre | `Light` · `Dark` |
| **Number** | Espacements, rayons, opacités | aucun mode |
| **Boolean** | Flags (show/hide) | aucun mode |

---

## Collection : Color Primitives

Convention de nommage : `<Hue>/<Shade>` (ex. `Blue/600`, `Neutral/100`)

### Groupes de teintes

| Groupe | Rôle typique | Shades disponibles |
|---|---|---|
| `Neutral` | Textes, fonds, bordures | 0 · 50 · 100 · 200 · 300 · 400 · 500 · 600 · 700 · 800 · 900 · 1000 |
| `Blue` | Action primaire, liens | 50 · 100 · 200 · 300 · 400 · 500 · 600 · 700 · 800 · 900 |
| `Red` | Danger, erreur, destructif | 50 · 100 · 200 · 300 · 400 · 500 · 600 · 700 · 800 · 900 |
| `Green` | Succès, positif, validation | 50 · 100 · 200 · 300 · 400 · 500 · 600 · 700 · 800 · 900 |
| `Yellow` | Avertissement, attention | 50 · 100 · 200 · 300 · 400 · 500 · 600 · 700 · 800 · 900 |
| `Orange` | Avertissement alternatif | 50 · 100 · … · 900 |
| `Purple` | Accent, marque | 50 · 100 · … · 900 |
| `Teal` | Informatif, secondaire | 50 · 100 · … · 900 |

**Règle de shade :** Plus le chiffre est élevé, plus la couleur est foncée. `Neutral/0` = blanc, `Neutral/1000` = noir.

### Scopes attendus pour les primitifs

Les variables primitives ne doivent **pas** être utilisées directement sur les nœuds — elles sont réservées aux alias sémantiques.
- Scope recommandé : `ALL_SCOPES` restreint aux collections internes, ou scope vide si les primitifs ne doivent pas apparaître dans les property pickers des composants.

---

## Collection : Color (sémantique)

Convention de nommage : `<Catégorie>/<Rôle>` ou `<Catégorie>/<Rôle>/<Variante>`

### Groupe `Background`

| Token | Rôle | Alias primitif (Light) | Alias primitif (Dark) |
|---|---|---|---|
| `Background/default` | Fond de page principal | `Neutral/0` | `Neutral/950` |
| `Background/secondary` | Fond de section, sidebar | `Neutral/50` | `Neutral/900` |
| `Background/tertiary` | Fond de carte imbriquée | `Neutral/100` | `Neutral/800` |
| `Background/overlay` | Fond de modal/drawer | `Neutral/0` | `Neutral/900` |
| `Background/inverse` | Fond sur dark | `Neutral/900` | `Neutral/0` |

### Groupe `Text`

| Token | Rôle | Alias (Light) | Alias (Dark) |
|---|---|---|---|
| `Text/primary` | Corps de texte principal | `Neutral/900` | `Neutral/50` |
| `Text/secondary` | Texte d'aide, légendes | `Neutral/600` | `Neutral/400` |
| `Text/disabled` | Texte désactivé | `Neutral/400` | `Neutral/600` |
| `Text/inverse` | Texte sur fond coloré | `Neutral/0` | `Neutral/900` |
| `Text/placeholder` | Placeholder de champ | `Neutral/400` | `Neutral/500` |
| `Text/link` | Lien hypertexte | `Blue/600` | `Blue/400` |
| `Text/link/hover` | Lien au survol | `Blue/700` | `Blue/300` |

### Groupe `Border`

| Token | Rôle | Alias (Light) | Alias (Dark) |
|---|---|---|---|
| `Border/default` | Séparateur, contour léger | `Neutral/200` | `Neutral/800` |
| `Border/strong` | Contour de champ actif | `Neutral/400` | `Neutral/600` |
| `Border/focus` | Outline de focus | `Blue/500` | `Blue/400` |
| `Border/error` | Contour de champ en erreur | `Red/500` | `Red/400` |

### Groupe `Action`

| Token | Rôle | Alias (Light) | Alias (Dark) |
|---|---|---|---|
| `Action/primary` | Bouton primaire fond | `Blue/600` | `Blue/500` |
| `Action/primary/hover` | Bouton primaire survol | `Blue/700` | `Blue/400` |
| `Action/primary/text` | Texte sur bouton primaire | `Neutral/0` | `Neutral/0` |
| `Action/secondary` | Bouton secondaire fond | `Neutral/100` | `Neutral/800` |
| `Action/secondary/hover` | Bouton secondaire survol | `Neutral/200` | `Neutral/700` |
| `Action/destructive` | Bouton danger fond | `Red/600` | `Red/500` |
| `Action/destructive/hover` | Bouton danger survol | `Red/700` | `Red/400` |

### Groupe `Status`

| Token | Rôle | Alias (Light) | Alias (Dark) |
|---|---|---|---|
| `Status/positive` | Succès, validation | `Green/600` | `Green/400` |
| `Status/positive/background` | Fond badge succès | `Green/50` | `Green/950` |
| `Status/negative` | Erreur, danger | `Red/600` | `Red/400` |
| `Status/negative/background` | Fond badge erreur | `Red/50` | `Red/950` |
| `Status/warning` | Avertissement | `Yellow/600` | `Yellow/400` |
| `Status/warning/background` | Fond badge avertissement | `Yellow/50` | `Yellow/950` |
| `Status/informative` | Information | `Blue/600` | `Blue/400` |
| `Status/informative/background` | Fond badge info | `Blue/50` | `Blue/950` |

---

## Collection : Number

Convention de nommage : `<Catégorie>/<Valeur>` (ex. `Spacing/4`, `Radius/md`)

### Spacing (en px)

| Token | Valeur | Usage Bootstrap 5 |
|---|---|---|
| `Spacing/0` | 0 | — |
| `Spacing/1` | 4px | `$spacer * 0.25` |
| `Spacing/2` | 8px | `$spacer * 0.5` |
| `Spacing/3` | 12px | — |
| `Spacing/4` | 16px | `$spacer * 1` (base) |
| `Spacing/5` | 20px | — |
| `Spacing/6` | 24px | `$spacer * 1.5` |
| `Spacing/8` | 32px | — |
| `Spacing/10` | 40px | — |
| `Spacing/12` | 48px | `$spacer * 3` |
| `Spacing/16` | 64px | — |

### Border Radius

| Token | Valeur | Usage Bootstrap 5 |
|---|---|---|
| `Radius/none` | 0 | `$border-radius: 0` |
| `Radius/sm` | 4px | `$border-radius-sm` |
| `Radius/md` | 6px | `$border-radius` (défaut) |
| `Radius/lg` | 8px | `$border-radius-lg` |
| `Radius/xl` | 12px | `$border-radius-xl` |
| `Radius/full` | 9999px | `$border-radius-pill` |
