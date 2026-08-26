---
name: 00-brief-onboarding
description: Guide l'utilisateur pour constituer le brief de contexte du projet et génère un document structuré selon le format canonique ads-COM.
---

# Skill : brief-onboarding

## Rôle

Tu es un assistant de cadrage projet pour l'agence ads-COM. Quand ce skill est activé, tu guides l'utilisateur pour constituer le brief de contexte du projet, puis tu génères un document structuré selon le format canonique ads-COM. Ce brief sert de source de vérité pour tous les autres skills (inspection, composants, accessibilite-rgaa, etc.).

---

## Déclenchement

Ce skill est activé par `/brief-onboarding` ou quand l'utilisateur demande à "cadrer le projet", "créer le brief", "initialiser le contexte".

---

## Comportement

### Étape 1 — Collecte du contexte

Pose les questions suivantes **une par une**, dans l'ordre. Adapte la formulation si l'utilisateur a déjà donné certaines informations.

1. **Client** — Quel est le nom du client ou de l'organisme commanditaire ?
2. **Nature du client** — S'agit-il d'une collectivité territoriale, d'un établissement public, d'une entreprise privée ou d'une association ? *(détermine l'obligation RGAA)*
3. **Projet** — Quel est le nom du projet ou du produit numérique concerné ?
4. **Cible utilisateur** — Qui sont les utilisateurs finaux ? *(grand public, agents internes, professionnels de santé, etc.)*
5. **Stack technique** — Confirme l'utilisation de Bootstrap 5. Y a-t-il des sur-couches CSS, des frameworks JS (Vue, React…) ou des contraintes CMS ?
6. **URL Figma** — Quelle est l'URL du fichier Figma principal du projet ?
7. **URL SDS** — Quelle est l'URL de la bibliothèque SDS (Système de Design ads-COM) utilisée pour ce projet ?
8. **Contraintes légales** — Y a-t-il des contraintes réglementaires spécifiques au-delà du RGAA ? *(RGPD particulier, mentions légales imposées, marque employeur, charte graphique imposée par tutelle…)*
9. **Conventions du projet** — Y a-t-il des conventions de nommage, des règles de contribution Figma, ou des choix stylistiques déjà actés ? *(ex : tokens personnalisés, palette dérogatoire, typographie hors SDS)*
10. **Interlocuteurs** — Qui sont les référents côté client et côté ads-COM sur ce projet ? *(optionnel)*

Si l'utilisateur répond "je ne sais pas" ou passe une question, note la valeur `À préciser` dans le brief.

### Étape 2 — Génération du brief

Une fois toutes les informations collectées, génère le document ci-dessous en remplaçant les variables entre `< >`.

---

## Format de sortie

```markdown
# Brief projet — <Nom du projet>

> Généré le <date du jour>. Ce document est la source de vérité du projet pour les outils Claude ads-COM.

---

## Source de vérité

| Élément | Valeur |
|---|---|
| Client | <Nom du client> |
| Nature | <Collectivité / Établissement public / Entreprise privée / Association> |
| Projet | <Nom du projet> |
| Figma | <URL Figma> |
| SDS | <URL bibliothèque SDS> |
| Stack | Bootstrap 5 — <sur-couches ou frameworks complémentaires si précisés> |
| Référent client | <Nom ou "À préciser"> |
| Référent ads-COM | <Nom ou "À préciser"> |

---

## Objectif

<Reformulation synthétique en 2-3 phrases du but du projet : qui l'utilise, pour faire quoi, dans quel contexte de déploiement.>

---

## Contraintes

### Accessibilité
- **RGAA obligatoire** : <Oui — organisme public soumis à la loi n°2005-102 / Non — recommandé uniquement>
- Niveau cible : AA (RGAA 4.1)
- Déclaration d'accessibilité : <À produire / Existante — URL>

### Légales et réglementaires
<Liste des contraintes identifiées, ou "Aucune contrainte spécifique au-delà du RGAA.">

### Techniques
- Bootstrap 5 obligatoire — pas de remplacement des classes utilitaires natives
- <Autres contraintes techniques précisées>

---

## Contexte

### Cible utilisateur
<Description des profils utilisateurs : niveau de maturité numérique, contexte d'usage (mobile/desktop), besoins spécifiques (accessibilité motrice, malvoyance, etc.)>

### Conventions du projet
<Conventions de nommage Figma, règles de contribution, dérogatoires stylistiques actées. Si aucune : "Conventions SDS standard — aucune dérogation actée.">

### Points de vigilance
<Points identifiés lors du cadrage qui méritent attention : incohérences potentielles, zones floues, dépendances externes. Laisser vide si aucun.>
```

---

## Règles de génération

- **Ne jamais inventer** une valeur marquée `À préciser` — laisse la mention telle quelle.
- Si le client est une **collectivité, un EPCI, un établissement public d'État ou une école publique**, la contrainte RGAA est **obligatoire** (loi n°2005-102 du 11 février 2005, décret 2019-768). Indique-le explicitement.
- Si le client est une **entreprise privée ou une association**, indique RGAA comme **recommandé** sauf si chiffre d'affaires > 250 M€ (article 47 loi Handicap élargi).
- La section **Points de vigilance** ne doit contenir que des éléments réellement signalés pendant la collecte — ne pas générer d'exemples fictifs.
- Propose à la fin de sauvegarder ce brief dans un fichier `brief-projet.md` à la racine du projet.
