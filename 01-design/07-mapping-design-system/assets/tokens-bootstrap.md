# Bootstrap 5 — Tokens et correspondances SDS

> **Référence : Bootstrap 5.3.x** (variables CSS + Sass).
> Ce document mappe les tokens Bootstrap 5 vers les variables SDS sémantiques.
> Les valeurs hex sont les défauts Bootstrap — elles peuvent être surchargées par la charte client.
>
> ⚠️ **Version cible du projet** : sur une version antérieure à 5.3, certaines variables listées ici
> n'existent pas encore. Introduites après 5.0 (à ne pas écrire sur une 5.0.x / 5.1.x sans vérifier) :
> le système de custom properties `--bs-*` de couleurs (5.1→5.3), `$body-secondary-color` /
> `$body-tertiary-color` / `$body-secondary-bg` / `$body-tertiary-bg` (5.3),
> `$focus-ring-width` / `$focus-ring-color` (5.3), les variables de mode sombre.
> `sds-bootstrap` doit lire la version réelle (`tokens.json._meta.bootstrap_target`) et n'écrire que
> les variables disponibles — cf. `02-passation-design-dev/agents/sds-bootstrap.md` étape 2.

---

## Couleurs thématiques (Theme Colors)

Ces couleurs sont les `$theme-colors` Sass et leurs équivalents CSS `--bs-*`.

| Token Bootstrap | Variable CSS | Valeur défaut | Token SDS sémantique | Primitif SDS |
|---|---|---|---|---|
| `$primary` | `--bs-primary` | `#0d6efd` | `Action/primary` | `Blue/600` |
| `$primary-rgb` | `--bs-primary-rgb` | `13, 110, 253` | — | — |
| `$secondary` | `--bs-secondary` | `#6c757d` | `Text/secondary` | `Neutral/500` |
| `$success` | `--bs-success` | `#198754` | `Status/positive` | `Green/700` |
| `$info` | `--bs-info` | `#0dcaf0` | `Status/informative` | `Teal/400` |
| `$warning` | `--bs-warning` | `#ffc107` | `Status/warning` | `Yellow/500` |
| `$danger` | `--bs-danger` | `#dc3545` | `Status/negative` | `Red/600` |
| `$light` | `--bs-light` | `#f8f9fa` | `Background/secondary` | `Neutral/50` |
| `$dark` | `--bs-dark` | `#212529` | `Text/primary` | `Neutral/900` |

---

## Primitifs de teinte (Hue) → variables Sass Bootstrap

Bootstrap ne stocke qu'**une seule variable par teinte** (`$blue`, `$red`, `$green`...) ; les déclinaisons `$blue-100` à `$blue-900` sont calculées automatiquement via `tint-color()` / `shade-color()` à partir de cette base. **Ne surcharge donc que la variable de base** — jamais la série `-100`…`-900` complète — sauf si un primitif Figma précis diverge visiblement de la valeur que Bootstrap calculerait.

| Primitif Figma (référence ~500/600) | Variable Sass Bootstrap |
|---|---|
| `Neutral/0` | `$white` |
| `Neutral/100`…`Neutral/900` | `$gray-100`…`$gray-900` |
| `Neutral/1000` (ou noir) | `$black` |
| `Blue/*` | `$blue` |
| `Indigo/*` | `$indigo` |
| `Purple/*` | `$purple` |
| `Pink/*` | `$pink` |
| `Red/*` | `$red` |
| `Orange/*` | `$orange` |
| `Yellow/*` | `$yellow` |
| `Green/*` | `$green` |
| `Teal/*` | `$teal` |
| `Cyan/*` | `$cyan` |

---

## Couleurs de corps (Body)

| Token Bootstrap | Variable CSS | Valeur défaut | Token SDS sémantique |
|---|---|---|---|
| `$body-bg` | `--bs-body-bg` | `#ffffff` | `Background/default` |
| `$body-color` | `--bs-body-color` | `#212529` | `Text/primary` |
| `$body-secondary-color` | `--bs-secondary-color` | `rgba(33,37,41,.75)` | `Text/secondary` |
| `$body-tertiary-color` | `--bs-tertiary-color` | `rgba(33,37,41,.5)` | `Text/disabled` |
| `$body-tertiary-bg` | `--bs-tertiary-bg` | `#f8f9fa` | `Background/secondary` |
| `$body-secondary-bg` | `--bs-secondary-bg` | `#e9ecef` | `Background/tertiary` |
| `$link-color` | `--bs-link-color` | `#0d6efd` | `Text/link` |
| `$link-hover-color` | `--bs-link-hover-color` | `#0a58ca` | `Text/link/hover` |

---

## Bordures

| Token Bootstrap | Variable CSS | Valeur défaut | Token SDS sémantique |
|---|---|---|---|
| `$border-color` | `--bs-border-color` | `#dee2e6` | `Border/default` |
| `$border-color-translucent` | `--bs-border-color-translucent` | `rgba(0,0,0,.175)` | `Border/default` |
| `$border-radius` | `--bs-border-radius` | `0.375rem` (6px) | `Radius/md` |
| `$border-radius-sm` | `--bs-border-radius-sm` | `0.25rem` (4px) | `Radius/sm` |
| `$border-radius-lg` | `--bs-border-radius-lg` | `0.5rem` (8px) | `Radius/lg` |
| `$border-radius-xl` | `--bs-border-radius-xl` | `1rem` (16px) | `Radius/xl` |
| `$border-radius-xxl` | `--bs-border-radius-xxl` | `2rem` (32px) | — |
| `$border-radius-pill` | `--bs-border-radius-pill` | `50rem` | `Radius/full` |

---

## États des composants

| Contexte Bootstrap | Valeur hex | Token SDS |
|---|---|---|
| Focus ring color | `#0d6efd` (primary) | `Border/focus` |
| Focus ring opacity | 0.25 | — |
| Input border (default) | `#ced4da` | `Border/default` |
| Input border (focus) | `#86b7fe` | `Border/focus` |
| Input border (invalid) | `#dc3545` | `Border/error` |
| Input placeholder | `rgba(33,37,41,.5)` | `Text/placeholder` |
| Disabled background | `#e9ecef` | `Background/tertiary` |
| Disabled color | `#6c757d` | `Text/disabled` |
| Disabled border | `#dee2e6` | `Border/default` |

---

## Typographie

### Familles de police

| Token Bootstrap | Rôle | Correspondance SDS typique |
|---|---|---|
| `$font-family-sans-serif` | Pile sans-serif par défaut (préfixer, ne pas remplacer les fallbacks) | `Typography Primitives/Family Sans` |
| `$font-family-base` | Police effective du body (souvent = `$font-family-sans-serif` via `var(--#{$prefix}font-sans-serif)`) | idem |
| `$headings-font-family` | Police des titres si distincte du body (`null` par défaut = hérite du body) | `Typography Primitives/Family Heading` |
| `$font-family-monospace` | Pile monospace (code, `<kbd>`, `<pre>`) | `Typography Primitives/Family Mono` |
| — (pas de variable native) | Police serif dédiée | `Typography Primitives/Family Serif` — laisser en note si non utilisée par le projet |

### Échelle de tailles

Le SDS Figma nomme ses tailles par intention (`Title Hero`, `Title Page`, `Heading`, `Subheading`, `Subtitle`, `Body`, `Code`), pas par niveau `h1`-`h6` — voir `02-passation-design-dev/agents/sds-bootstrap.md` (successeur de l'ancien skill Claude `09-sync-sds-bootstrap`, retiré de `01-design/` — même méthode de mapping raisonné, à confirmer avec l'utilisateur, pas d'auto-mapping par ordre alphabétique/numérique).

| Token Bootstrap | Valeur défaut | Note |
|---|---|---|
| `$display-font-sizes` (map `display-1`…`display-6`) | `5rem`…`2.5rem` | Titres hero hors flux `h1`-`h6` — cible naturelle pour `Title Hero` SDS |
| `$h1-font-size` | `2.5rem` (40px) | `Title Page` SDS |
| `$h2-font-size` | `2rem` (32px) | `Heading` SDS |
| `$h3-font-size` | `1.75rem` (28px) | `Subheading` SDS |
| `$h4-font-size` | `1.5rem` (24px) | — |
| `$h5-font-size` | `1.25rem` (20px) | — |
| `$h6-font-size` | `1rem` (16px) | — |
| `$lead-font-size` | `1.25rem` (20px) | `Subtitle` SDS, si usage chapeau/intro |
| `$font-size-base` | `1rem` (16px) | `Body/Size Medium` (ou "Base") SDS |
| `$font-size-sm` | `0.875rem` (14px) | `Body/Size Small` SDS, `.small`, `.form-text` |
| `$font-size-lg` | `1.125rem` (18px) | `Body/Size Large` SDS, `.fs-5` |
| `$code-font-size` | `.875em` | `Code/Size Base` SDS |

### Poids et interlignage

| Token Bootstrap | Valeur défaut | Note |
|---|---|---|
| `$font-weight-light` | 300 | `Weight Light` SDS |
| `$font-weight-normal` | 400 | `Weight Regular` SDS |
| `$font-weight-bold` | 700 | `Weight Bold` SDS |
| `$headings-font-weight` | 500 (souvent surchargé en littéral, pas via variable dédiée) | `Weight Medium` SDS — vérifier si déjà aligné avant d'écrire |
| — (pas de variable dédiée dans Bootstrap 5 de base) | 500/600 | `Weight Medium`/`Weight Semibold` SDS — n'existent pas nativement comme `$font-weight-medium`/`$font-weight-semibold` dans toutes les versions de Bootstrap 5 ; vérifier la présence réelle dans `_variables.scss` avant de s'appuyer dessus (sinon utiliser le littéral numérique sur la variable de composant concernée, ex. `$headings-font-weight: 500`) |
| `$line-height-base` | 1.5 | — |
| `$line-height-sm` | 1.25 | — |
| `$line-height-lg` | 2 | — |

---

## Espacement

Bootstrap 5 calcule les espacements comme multiples de `$spacer` (variable Sass — défaut `1rem`/16px, peut être personnalisée par projet). L'échelle est portée par la map Sass `$spacers` : étendre ses clés existantes plutôt que créer un système séparé.

| Classe Bootstrap | Valeur | Token SDS |
|---|---|---|
| `p-0`, `m-0` | 0 | `Spacing/0` |
| `p-1`, `m-1` | `0.25rem` (4px) | `Spacing/1` |
| `p-2`, `m-2` | `0.5rem` (8px) | `Spacing/2` |
| `p-3`, `m-3` | `1rem` (16px) | `Spacing/4` |
| `p-4`, `m-4` | `1.5rem` (24px) | `Spacing/6` |
| `p-5`, `m-5` | `3rem` (48px) | `Spacing/12` |

---

## Correspondance Bootstrap → SDS pour les composants clés

### Boutons

| État bouton Bootstrap | Propriété CSS | Token SDS attendu |
|---|---|---|
| `.btn-primary` fond | `background-color` | `Action/primary` |
| `.btn-primary` fond hover | `background-color` | `Action/primary/hover` |
| `.btn-primary` texte | `color` | `Action/primary/text` |
| `.btn-secondary` fond | `background-color` | `Action/secondary` |
| `.btn-danger` fond | `background-color` | `Action/destructive` |
| `.btn` focus ring | `box-shadow` | `Border/focus` |
| `.btn:disabled` fond | `background-color` | `Background/tertiary` |
| `.btn:disabled` texte | `color` | `Text/disabled` |

### Formulaires

| État champ Bootstrap | Propriété CSS | Token SDS attendu |
|---|---|---|
| `.form-control` bordure | `border-color` | `Border/default` |
| `.form-control:focus` bordure | `border-color` | `Border/focus` |
| `.form-control.is-invalid` bordure | `border-color` | `Border/error` |
| `.form-control` fond | `background-color` | `Background/default` |
| `.form-control:disabled` fond | `background-color` | `Background/tertiary` |
| `.form-label` couleur | `color` | `Text/primary` |
| `.form-text` couleur | `color` | `Text/secondary` |
| `.invalid-feedback` couleur | `color` | `Status/negative` |
| `.valid-feedback` couleur | `color` | `Status/positive` |

### Alertes

| Variante Bootstrap | Fond | Texte | Bordure |
|---|---|---|---|
| `.alert-success` | `Status/positive/background` | `Status/positive` | `Status/positive` |
| `.alert-danger` | `Status/negative/background` | `Status/negative` | `Status/negative` |
| `.alert-warning` | `Status/warning/background` | `Status/warning` | `Status/warning` |
| `.alert-info` | `Status/informative/background` | `Status/informative` | `Status/informative` |

---

## Breakpoints Bootstrap 5 (pour information)

| Nom | Préfixe classe | Largeur min | Container max |
|---|---|---|---|
| xs | *(aucun)* | < 576px | 100% |
| sm | `sm:` | ≥ 576px | 540px |
| md | `md:` | ≥ 768px | 720px |
| lg | `lg:` | ≥ 992px | 960px |
| xl | `xl:` | ≥ 1200px | 1140px |
| xxl | `xxl:` | ≥ 1400px | 1320px |
