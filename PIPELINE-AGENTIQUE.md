# Pipeline de production agentique — WordPress (première cible)

Ce document décrit l'architecture cible du repo `adscom-ia-pipeline` : un **pipeline de production complet**, du cadrage projet à la livraison développeur, avec un premier périmètre WordPress (Drupal en second temps, cf. `01-design/15-annotations-dev-mode` déjà multi-CMS).

Le repo est organisé en dossiers de phase — **`00-setup` → `01-design` → `02-passation-design-dev` → `03-developpement`** — miroir direct des 4 phases du pipeline : Setup → Design → Passation design-dev → Développement. `01-design` reprend intégralement les 16 skills Claude Code précédemment maintenus dans `figma-mcp-claude-skills` (repo historique, laissé inchangé — voir note en fin de section). Ce document formalise les décisions prises pour couvrir le reste du pipeline, en particulier toute la phase Développement.

**Ce repo remplace `figma-mcp-claude-skills` pour les futurs projets uniquement.** L'ancien repo continue de servir tel quel les projets déjà en cours (installés par clone/submodule direct) — aucune migration rétroactive prévue. Voir `README.md` pour le mécanisme d'installation (script, plus de clone/submodule direct — nécessaire du fait de l'organisation par dossier de phase, cf. §9).

---

## 1. Rôles et outillage

**Décision actée (revue après comparaison Claude Code / GitHub Copilot)** : les deux plateformes ont été comparées sur ce workflow précis (orchestration multiagent, contexte isolé par sous-agent, accès MCP par agent, pilotage navigateur). Capacité équivalente confirmée des deux côtés — le choix ci-dessous n'est pas motivé par une incapacité de l'un ou l'autre, mais par la répartition retenue :

| Rôle | Plateforme | Portée | Pilotage |
|---|---|---|---|
| Claude Research | Claude | Design — cadrage, benchmark | Humain (CP) |
| Claude UX | Claude Code | Design — prompt maquette | Humain (Designer) |
| **IA Orchestrator** | **GitHub Copilot** | Coordination — Développement uniquement | Autonome (routeur déterministe) |
| **IA Spec** | **GitHub Copilot** | Coordination — génère le Design Manifest (Passation) | Humain (CP) |
| **IA dev** | **GitHub Copilot** | Développement — Init, CPT, blocs custom, theming | Orchestrator |
| **IA Contrib** | **GitHub Copilot** | Développement — contribution Gutenberg | Orchestrator |
| **IA reviewer** | **GitHub Copilot** | Développement — conformité maquette / cohérence / RGAA / perf | Orchestrator |
| ads-COM Humain CP | Humain | Design + validations finales + fiches Mantis | — |
| ads-COM Humain designer | Humain | Exécution des prompts maquette, ajustements | — |
| ads-COM Humain dev/IW | Humain | Contrôle conformité, autorise les commits Git, ajustements ciblés | — |

Répartition : la frontière outillage n'est **pas** alignée strictement sur les 4 phases, mais sur la nature du travail. **Création et nettoyage de la maquette dans Figma reste 100% Claude** (`01-design/00` à `01-design/15`, format `SKILL.md`, testé sur projets réels — aucune raison de migrer une brique qui fonctionne : brief, prompt maquette, validation, inspection, review UX/UI, ajustements, RGAA visuel, mapping/nettoyage design system, composants, sync SDS). **Tout ce qui produit ou consomme un artefact structuré destiné au code passe sur GitHub Copilot** : le Design Manifest (§2) et l'ensemble du Développement (Orchestrator + dev + Contrib + reviewer), en s'appuyant sur les *custom agents* (contexte isolé, prompt système propre, restrictions d'outils, serveurs MCP propres par agent — vérifié sur la doc GitHub) — terrain neuf, pas de skill existant à migrer, et repos GitHub-natifs pour la partie code (CPT, theming).

**Tension assumée, pas encore tranchée définitivement** : avec l'Orchestrator, l'IA Spec et tout le Développement déjà côté Copilot, il ne reste que Research/UX côté Claude — la tentation du "tout Copilot" est réelle. Choix explicite de l'utilisateur : on reste sur ce découpage pour l'instant (Claude conserve la création/nettoyage de maquette, terrain où les skills existants sont éprouvés), à rouvrir plus tard si besoin plutôt qu'à trancher maintenant par principe.

L'Orchestrator reste un **routeur déterministe** : séquence Init → Contribution → Theming fixe, verdict du reviewer classé en 4 états (`APPROVED`, `DEV_FIX`, `CONTRIB_FIX`, `HUMAN_REVIEW`) qui pilote le routage. Responsabilités actées : lancer le bon agent selon l'étape courante, gérer les boucles (plafond, non-convergence), **journaliser les actions** (voir §8), décider quand solliciter l'humain.

---

## 2. Le Design Manifest — nouvel artefact de passation (agent IA Spec, Copilot)

**Constat** : un prototype de manifest existe déjà (`design-manifest/` sur The Place by CCI 45) mais a été **reconstruit a posteriori**, après contribution/theming déjà faits à la main. Il mélange donc deux choses à séparer :

| Contenu | Nature | Où ça doit vivre |
|---|---|---|
| `index.json` (pages, refs Figma/WordPress), `pages/<slug>.json` (sections, contenu complet, `layout_order`), `tokens.json` | **Spec figée**, générée une fois en fin de Passation | **Agent IA Spec** (Copilot custom agent, write-once) |
| `bugs_found`, champs `gap`/`status`, `theming-notes.md` | **Journal d'exécution** des boucles Contribution/Theming | Journal de l'Orchestrator (§8), produit *pendant* le Développement |

**Décision actée (Option A)** : le Design Manifest produit par IA Spec est **write-once** — généré une fois, jamais retouché par les agents en aval. Respecte l'invariant déjà en place dans toute la bibliothèque Claude (un skill = un producteur, plusieurs consommateurs en lecture), étendu tel quel au monde Copilot. Une révision Figma en cours de Développement devient un événement explicite (nouvelle version versionnée du manifest, régénérée par IA Spec), jamais une mutation silencieuse.

**Révision (2026-08-24)** : `09-sync-sds-bootstrap` (Claude, `01-design/`) a été retiré de ce repo et remplacé par l'agent Copilot `sds-bootstrap` (`02-passation-design-dev/agents/sds-bootstrap.md`) — même nature de travail que le reste de la Passation/Développement (produit du code, pas un artefact de maquette, cf. §1). IA Spec dérive donc lui-même la correspondance des tokens directement depuis Figma (variables `Color`/`Typography`/`Size`, via les fichiers de référence partagés `.claude/skills/07-mapping-design-system/assets/`), sans dépendre d'aucune sortie Claude en amont — `spec` fonctionne désormais sans que `01-design` ait été exécuté du tout, seul un accès Figma MCP est requis. `sds-bootstrap` consomme ensuite `tokens.json` pour produire `design-manifest/_variables.scss`, appliqué au vrai thème par `init` (Développement) une fois celui-ci instancié.

IA Spec ajoute aussi, par section, un champ `layout_order` pour capturer l'ordre des enfants/positions relatives — évite un appel MCP live en boucle de Theming pour ce genre de vérification (cas réel rencontré : réordonnancement d'une galerie, trouvé initialement seulement via `get_metadata`).

**IA Spec est un agent Copilot** (contexte isolé, son propre serveur MCP Figma) plutôt qu'un skill Claude : il produit l'artefact d'entrée consommé exclusivement par des agents Copilot (Init, Contribution, Theming), donc le tenir dans le même écosystème évite une bascule Claude→Copilot au milieu du pipeline pour ce seul artefact. Il continue de lire sans problème les fichiers déjà produits par les skills Claude du projet (`mapping-ds-*.md`, `_sds-tokens.scss`, `export-assets/`, `annotations-dev-*.md`) — ce sont de simples fichiers sur disque, aucune dépendance à l'écosystème qui les a produits.

Son modèle de référence vit dans `02-passation-design-dev/agents/spec.md` (§9) — copié dans le `.github/agents/` du projet WordPress par le script d'installation, pas exécuté depuis ce repo.

---

## 3. Boucles Contribution et Theming — gestion des itérations

Les deux boucles (`Contrib ↔ Reviewer`, `Theming ↔ Reviewer`) sont gérées par l'Orchestrator :

- **Plafond par unité de boucle**, pas global au projet : par page pour Contribution, par bloc pour Theming. Le compteur repart à zéro à chaque nouvelle unité.
- **Plafond : 4 itérations**, paramétrable dans `brief-projet.md` (même principe que le flag RGAA-obligatoire). **Un seul compteur par unité, quel que soit le verdict** (`DEV_FIX` ou `CONTRIB_FIX`) — une page qui fait des allers-retours dev↔contrib sans jamais approuver compte comme non-convergente, peu importe vers qui l'Orchestrator route le correctif.
- **Verdict du reviewer classé en 4 états** : `APPROVED` (fin de boucle), `DEV_FIX` (renvoi vers IA dev), `CONTRIB_FIX` (renvoi vers IA Contrib), `HUMAN_REVIEW` (escalade directe, 0 retry — ex. donnée absente de la maquette elle-même, jamais résolvable par itération).
- **Escalade anticipée** si le reviewer remonte deux fois de suite exactement le même écart non résolu (pas de progrès entre deux itérations) — avant même d'atteindre le plafond.
- Si le plafond est dépassé sur une unité : l'Orchestrator informe `[Humain dev]` et suspend la boucle sur cette unité.

**Commit Git — toujours déclenché par un humain**, jamais automatique en fin de boucle : `[Humain dev]` informe l'Orchestrator qu'il peut lancer le commit, à la fin de la Contribution (toutes pages) et à la fin du Theming (toutes pages). Le journal enregistre qui a autorisé chaque commit et son hash.

**Intégration Mantis** : en fin de Theming, `[CP Dev]` crée les fiches Mantis correspondant aux écarts/points ouverts. Traitement (automatisation éventuelle depuis le journal) volontairement différé — le journal doit au minimum marquer l'événement (`external_ticket_created`) pour ne pas fermer la porte à une automatisation future.

---

## 4. Source de vérité pendant la boucle Theming

Trois natures de données, trois sources différentes :

1. **Valeurs de tokens** (couleurs, typo, spacing/radius) : toujours depuis `tokens.json` figé (généré par l'agent `spec`, Passation), jamais re-dérivées ni par MCP live ni par lecture visuelle d'un PNG pendant la boucle.
2. **Fidélité structurelle/visuelle** (bloc présent, ordre, responsive) : **MCP Figma live**, dès l'itération 1 — c'est la source principale. Le Design Manifest (PNG + `layout_order` figés) ne suffit pas seul pour un theming fidèle (pas assez de détail exploitable : espacements exacts, valeurs précises, hiérarchie fine) ; il reste consulté comme repère visuel rapide en complément, jamais comme substitut au MCP.
3. **Épuisement du quota MCP en cours de boucle** : traité comme un déclencheur d'escalade humaine explicite — jamais un repli silencieux vers le PNG. Risque accru par rapport à la version précédente de cette section (le MCP est maintenant sollicité dès la première itération de chaque unité, plus seulement en cas de rejet) : accepté comme compromis délibéré, la fidélité prime sur l'économie de quota.

**Révision (2026-08-24)** : la répartition PNG-d'abord/MCP-en-second-recours a été abandonnée — un PNG seul a été jugé insuffisant pour que `dev` applique un theming fidèle (pas de valeurs exactes, pas de détail fin exploitable). Le MCP Figma live devient la source principale dès l'itération 1 dans `dev.md` et `reviewer.md` ; le PNG reste un repère visuel rapide, jamais la source de comparaison faisant foi.

Le pilotage navigateur (vérification visuelle, responsive, RGAA) côté Copilot s'appuie sur un serveur MCP de type Playwright (arbre d'accessibilité natif, émulation d'appareil, screenshots) — capacité confirmée équivalente à l'outillage navigateur utilisé côté Claude.

---

## 5. Granularité des skills/agents

Même principe que l'existant côté Claude : **un skill = une responsabilité étroite = un livrable daté**. Côté Copilot, même logique transposée aux *custom agents* : un agent = un rôle isolé (dev / Contrib / reviewer), pas d'agent fourre-tout.

---

## 6. Setup (périmètre minimal pour l'instant)

- Notre Infra crée la BDD
- Le Git Projet
- Installation des skills/agents au sein du projet (script `scripts/install.ps1`/`.sh` de ce repo — plus de clone/submodule direct, cf. §9 et `README.md`)

Volontairement léger à ce stade — pas de skill dédié, contenu de `00-setup/` réservé à cette documentation.

---

## 7. Init WordPress

`[IA dev]` (Copilot) initialise le socle sur la base du starterkit ads-COM, sous `wordpress/` (racine du site, isolée du reste du repo — cf. §9) : récupération des sources Git, récupération des infos base (fournies par Setup), renommage du thème, instanciation WordPress. Applique ensuite `agents/design-manifest/_variables.scss` (produit par `sds-bootstrap` en Passation) au thème réellement instancié, si ce livrable existe. Puis, sur la base de la documentation, des maquettes Figma, des annotations et des specs éventuelles : création des CPT, installation des plugins nécessaires. Fin de passe → Orchestrator informe `[Humain dev]` → `[contrôle dev/IW]` / `[ajustement dev/IW]`.

---

## 8. Journal d'exécution de l'Orchestrator

Complément **mutable** (append-only) au Design Manifest **figé** (§2) — sépare la spec (ce qui était demandé) de l'historique (ce qui s'est passé), cohérent avec l'invariant un-producteur du reste de la bibliothèque.

Chemin concret dans le repo projet : `agents/journal.ndjson` (voir §9) — seul l'Orchestrator y écrit, les sous-agents lui rapportent leur résultat.

**Grain d'une entrée** = un événement, jamais réécrit.

| Champ | Rôle |
|---|---|
| `ts` | Horodatage |
| `run_id` | Identifiant de session Orchestrator (traçabilité multi-passes dans le temps) |
| `phase` | `Init` \| `Contribution` \| `Theming` |
| `unit` | Clé de portée de boucle — `page:<slug>` (Contribution), `block:<page-slug>/<block-id>` (Theming), `page:<slug>:full` (check de page complète) |
| `iteration` | Compteur pour cette unité, remis à zéro à chaque nouvelle unité |
| `actor` | IA Orchestrator \| IA dev \| IA Contrib \| IA reviewer \| Humain dev/IW \| CP Dev |
| `event` | Type d'événement (liste ci-dessous) |
| `verdict` | `APPROVED` \| `DEV_FIX` \| `CONTRIB_FIX` \| `HUMAN_REVIEW` (quand applicable) |
| `rejection_class` | `exécution` \| `donnée_manquante` (quand verdict ≠ `APPROVED`) |
| `payload` | Détail structuré propre à l'événement — jamais le contenu complet (qui vit dans WordPress/le code, pas dans le log) |

**Types d'`event`** :
- `phase_started` / `phase_completed`
- `loop_iteration_started`
- `contrib_applied` / `theming_applied`
- `review_verdict`
- `loop_cap_check` (itération courante vs plafond 4)
- `escalation` (cap dépassé / `HUMAN_REVIEW` direct / même écart 2× de suite)
- `human_notified` / `human_decision`
- `git_commit` (hash + qui a autorisé — toujours un humain)
- `checkpoint` (passage d'un `[contrôle …]`/`[ajustement …]` du schéma, résultat)
- `external_ticket_created` (marqueur Mantis, pas d'automatisation pour l'instant)

---

## 9. Organisation du repo et mécanisme d'installation

| Élément | Phase | Plateforme | Modèle de référence | Sortie |
|---|---|---|---|---|
| `spec` (IA Spec) | Passation | Copilot (custom agent) | `02-passation-design-dev/agents/spec.md` | `index.json` + `pages/<slug>.json` + `tokens.json` write-once |
| `sds-bootstrap` | Passation | Copilot (custom agent) | `02-passation-design-dev/agents/sds-bootstrap.md` | `agents/design-manifest/_variables.scss` (livrable préparé, appliqué au thème réel par `init`) |
| Orchestrator | Développement (transverse) | Copilot (custom agent) | `03-developpement/agents/orchestrator.md` | Journal d'exécution (§8) |
| `init` | Développement / Init | Copilot (custom agent) | `03-developpement/agents/init.md` | Socle WP instancié, CPT créés |
| `contrib` | Développement / Contribution | Copilot (custom agent) | `03-developpement/agents/contrib.md` | Composition Gutenberg par page |
| `reviewer` | Développement / Contribution + Theming | Copilot (custom agent) | `03-developpement/agents/reviewer.md` | Verdict classé (§3) |
| `dev` (theming) | Développement / Theming | Copilot (custom agent) | `03-developpement/agents/dev.md` | SCSS/theming par bloc |

**Pourquoi un repo organisé par dossier de phase plutôt qu'un clone/submodule direct comme l'ancien `figma-mcp-claude-skills`** : la découverte de skills Claude Code (`.claude/skills/`) n'est **pas récursive** — un skill placé dans un sous-dossier (ex. `.claude/skills/design/03-inspection/`) ne serait plus détecté du tout, pas juste déplacé. L'ancien repo fonctionnait en submodule/clone direct parce que sa racine était déjà, structurellement, `.claude/skills/` à plat. Ce repo-ci privilégie la lisibilité par phase dans la source (`00-setup/`, `01-design/`, `02-passation-design-dev/`, `03-developpement/`) et délègue l'aplatissement à un **script d'installation** (`scripts/install.ps1`/`.sh`, voir `README.md`).

**Mécanisme d'installation (révisé)** : le script ajoute `adscom-ia-pipeline` comme **submodule Git** en `agents/_pipeline-repo/` dans le projet consommateur — source de vérité versionnée et traçable (le SHA du submodule dit exactement quelle version du pipeline est utilisée), plutôt que l'ancien clone temporaire supprimé après coup. Depuis ce submodule, le script copie `01-design/*/` vers `.claude/skills/*/` et fusionne les dossiers `agents/` des phases Passation+Développement vers `.github/agents/*.md` — ces deux chemins restent imposés par Claude Code et GitHub Copilot respectivement (racine du repo, non récursif) et ne peuvent pas eux-mêmes vivre sous `agents/`. Relancer le script met à jour le submodule puis resynchronise les deux dossiers plats.

**Organisation attendue dans le repo d'un projet WordPress consommateur** :

```
mon-projet-wp/
├── .claude/skills/            ← chemin imposé Claude Code, généré par le script
├── .github/agents/            ← chemin imposé Copilot, généré par le script
├── agents/                    ← tout ce qui n'a pas de chemin imposé par un outil
│   ├── _pipeline-repo/        ← submodule adscom-ia-pipeline (source de vérité)
│   ├── design-manifest/       ← livrable write-once de l'agent spec (§2)
│   └── journal.ndjson         ← journal d'exécution de l'Orchestrator (§8)
└── wordpress/                 ← sources WordPress classiques, isolées du reste
    ├── wp-content/
    │   ├── themes/
    │   └── plugins/
    ├── wp-config.php
    └── ...
```

Isoler le CMS sous `wordpress/` garde la racine du repo entièrement dédiée au tooling (pipeline, skills, agents) et évite tout mélange avec le code WordPress classique.

**Ancien repo `figma-mcp-claude-skills`** : laissé intact, aucune action dessus — il continue de servir tel quel les projets déjà en cours (RJAC, CC4V, Neoville, TPbCCI45), installés par clone/submodule direct comme avant. Ce repo-ci (`adscom-ia-pipeline`) est la source de vérité pour tout nouveau projet à partir de maintenant.

**Tranché (2026-08-24)** : `reviewer` est un seul agent à deux modes (Contribution/Theming, checklist choisie selon la phase transmise par l'Orchestrator en tête de l'invocation) — pas deux agents séparés. Décision prise en autonomie pendant la rédaction du contenu comportemental complet des 6 fichiers `agents/*.md` (prompt système, journal d'exécution — voir §8 pour le chemin `agents/journal.ndjson`, logique de routage détaillée dans `orchestrator.md`) — pas encore validé sur un vrai projet, en particulier le format exact des identifiants `tools`/`mcpServers` Copilot (structure plausible, pas vérifiée contre la doc officielle caractère pour caractère).

**Point ouvert issu de cette révision** : les fichiers comportementaux `02-passation-design-dev/agents/*.md` et `03-developpement/agents/*.md` référencent encore `design-manifest/` et `.orchestrator/journal.ndjson` comme chemins à la racine du projet (état antérieur à cette révision) — à mettre à jour vers `agents/design-manifest/` et `agents/journal.ndjson` dans une passe séparée avant la première utilisation réelle, pour rester cohérents avec l'organisation ci-dessus.

---

## 10. Hors périmètre de ce document

- Mise en production / go-live : aucune des 4 phases ne couvre ce point aujourd'hui. Pas traité ici, à adresser séparément (potentiellement une 5e phase).
- Automatisation de la création des fiches Mantis depuis le journal — explicitement différée par l'utilisateur.
- Migration des 4 projets clients existants vers ce repo — explicitement exclue, ils restent sur `figma-mcp-claude-skills`.
