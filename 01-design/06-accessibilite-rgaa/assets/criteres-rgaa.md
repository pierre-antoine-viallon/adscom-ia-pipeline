# Référence RGAA 4.1 — Critères auditables depuis Figma

> Source : RGAA 4.1 (décret n°2019-768 du 24 juillet 2019, mis à jour 2021).
> Ce document liste uniquement les critères vérifiables à partir d'une maquette Figma.
> Les critères purement techniques (HTML, ARIA, JS) ne figurent pas ici.

---

## Thématique 1 — Images

### Critère 1.1 — Niveau A
**Images porteuses d'information**
Chaque image (bitmap, SVG, icône) qui transmet une information doit avoir une alternative textuelle.

Audit Figma :
- Les frames/groups contenant des images informatives ont-ils un nom descriptif (et non "Image", "Rectangle", "Frame 42") ?
- Les icônes porteuses de sens sont-elles nommées avec leur signification ("Icône téléphone", "Flèche vers la droite") ?
- Les images qui contiennent du texte incrusté sont-elles identifiées ?

Conformité : Conforme si chaque image informative a un nom de calque explicite ou une annotation alt.

### Critère 1.2 — Niveau A
**Images de décoration**
Les images purement décoratives doivent être ignorées par les lecteurs d'écran.

Audit Figma :
- Les éléments décoratifs (fonds, séparateurs, illustrations sans sens) sont-ils marqués comme tels ?
- Convention ads-COM : les calques décoratifs commencent par `_` ou sont nommés `décoration`, `bg`, `pattern`.

### Critère 1.3 — Niveau A
**Images textes**
Les images contenant du texte (sauf logos) ne sont pas conformes — le texte doit être réel.

Audit Figma :
- Y a-t-il des captures d'écran, bannières, ou visuels avec texte incrusté non éditables ?
- Exception : les logos et marques peuvent être des images textes.

---

## Thématique 3 — Couleurs

### Critère 3.2 — Niveau AA ⚠️ Critique
**Contraste du texte**

| Type de texte | Ratio minimum |
|---|---|
| Texte normal (< 18pt ou < 14pt gras) | **4,5:1** |
| Grand texte (≥ 18pt ou ≥ 14pt gras) | **3:1** |
| Texte de logo / marque | Non applicable |

Correspondance Bootstrap 5 / px :
- 18pt = 24px
- 14pt bold = 18,67px en gras

Audit Figma :
- Calculer le ratio entre la couleur du texte et la couleur de fond directe.
- Cas particuliers à vérifier manuellement : texte sur image, texte sur dégradé, texte sur fond semi-transparent.

### Critère 3.3 — Niveau AA ⚠️ Critique
**Contraste des composants d'interface**

Les éléments graphiques porteurs d'information (icônes actives, bordures de champ, indicateurs d'état, focus) doivent avoir un ratio de **3:1** minimum avec leur fond.

Audit Figma :
- Bordures des champs de formulaire vs. fond du formulaire
- Icônes standalone non accompagnées de texte
- Indicateur de focus (outline) vs. fond environnant
- Checkboxes et radio buttons non cochés

---

## Thématique 9 — Structure de l'information

### Critère 9.1 — Niveau A ⚠️ Important
**Hiérarchie des titres**

La page doit avoir un H1 unique et une hiérarchie logique sans saut (H1 → H2 → H3, pas H1 → H3).

Audit Figma :
- Le texte le plus important de la page est-il le plus grand ? Est-il unique par écran ?
- La hiérarchie taille → importance est-elle cohérente et sans rupture ?
- Les styles typographiques du SDS correspondent-ils à des niveaux sémantiques (Display = H1, Titre 1 = H2, etc.) ?

Correspondance recommandée ads-COM / Bootstrap 5 :
- H1 : 32px+ (display ou titre principal)
- H2 : 24–28px
- H3 : 20–22px
- H4 : 18px
- H5–H6 : 16px avec graisse

---

## Thématique 10 — Présentation de l'information

### Critère 10.9 — Niveau AA
**Texte non justifié**
Le texte ne doit pas être aligné à gauche ET à droite simultanément (justification pleine).

Audit Figma :
- Vérifier que `textAlignHorizontal` n'est pas `JUSTIFIED` sur les blocs de texte courant.
- La justification est autorisée pour des éléments très courts (titres, labels courts).

### Critère 10.12 — Niveau AA
**Espacement des caractères**
L'utilisateur doit pouvoir modifier l'espacement sans perte d'information.

Audit Figma :
- Les blocs de texte ont-ils une hauteur fixe qui pourrait tronquer le contenu si l'espacement augmente ?
- Préférer les conteneurs en auto-layout (HUG) aux hauteurs fixes sur les blocs textuels.

---

## Thématique 11 — Formulaires

### Critère 11.1 — Niveau A ⚠️ Critique
**Étiquettes des champs**
Chaque champ de formulaire doit avoir une étiquette visible et explicite. Le placeholder seul ne suffit pas.

Audit Figma :
- Chaque champ input a-t-il un label visible au-dessus ou à gauche ?
- Le label disparaît-il quand le champ est rempli (floating label) ? Si oui, y a-t-il un label fixe visible aussi ?
- Les champs obligatoires sont-ils identifiés visuellement ET textuellement (pas seulement par un astérisque rouge) ?

### Critère 11.2 — Niveau A
**Pertinence des étiquettes**
Les labels doivent décrire précisément la donnée attendue.

Audit Figma :
- Labels vagues à corriger : "Nom" → "Nom de famille", "Email" → "Adresse électronique professionnelle"
- Le label doit être compréhensible hors contexte.

### Critère 11.9 — Niveau A
**Libellé des boutons de formulaire**
Les boutons de soumission doivent avoir un libellé explicite.

Audit Figma :
- Boutons non conformes : "OK", "Valider", "Envoyer" sans contexte
- Boutons conformes : "Envoyer le formulaire de contact", "Télécharger le document PDF"

### Critère 11.10 — Niveau AA ⚠️ Important
**Messages d'erreur**
Les erreurs de saisie doivent être identifiées et décrites textuellement, et le champ en erreur doit être identifiable.

Audit Figma :
- L'état `error` du composant champ est-il designé ?
- Le message d'erreur est-il un texte visible (pas seulement une couleur rouge) ?
- Le message d'erreur décrit-il le problème ET la correction attendue ?
- Exemple conforme : "Le format de l'adresse e-mail est incorrect. Ex. : prenom.nom@exemple.fr"
- Exemple non conforme : "Champ invalide" ou seulement une bordure rouge

---

## Thématique 13 — Consultation

### Critère 13.11 — Niveau AA
**Taille des zones cliquables**
Les zones d'interaction doivent être suffisamment grandes.

Seuils :
- RGAA / WCAG 2.2 AA : **24×24px minimum**
- Recommandation forte (WCAG 2.5.8 AA) : **44×44px** pour les éléments tactiles
- Exception : si l'élément est en ligne dans du texte (lien dans un paragraphe)

Audit Figma :
- Boutons icône (sans texte)
- Liens de navigation
- Cases à cocher et boutons radio
- Puces de pagination
- Contrôles de formulaire personnalisés
