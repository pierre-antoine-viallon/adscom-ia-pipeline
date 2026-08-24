# adscom-ia-pipeline

Pipeline de production agentique ads-COM pour des sites WordPress (Drupal en second temps) — du cadrage projet à la livraison développeur, organisé en 4 phases de dossiers. Successeur de [`figma-mcp-claude-skills`](https://github.com/pierre-antoine-viallon/figma-mcp-claude-skills) pour les **nouveaux projets uniquement** — voir `PIPELINE-AGENTIQUE.md` pour l'architecture complète et le détail des décisions.

Inspiré de la plateforme de skills communautaire : [figma.com/community/skills](https://figma.com/community/skills)

---

## Organisation par phase

```
00-setup/                    ← amorçage projet (BDD, Git) — documentaire pour l'instant, pas de skill
01-design/                   ← 16 skills Claude Code (identiques à figma-mcp-claude-skills)
02-passation-design-dev/     ← agent Copilot "IA Spec" (Design Manifest)
03-developpement/            ← agents Copilot Init/Contribution/Theming + Orchestrator
```

`01-design/` contient les skills Claude Code (fichiers `SKILL.md`, un dossier par skill). `02-passation-design-dev/agents/` et `03-developpement/agents/` contiennent les modèles de référence des *custom agents* GitHub Copilot (fichiers Markdown à frontmatter YAML).

---

## Pourquoi un script d'installation plutôt qu'un clone/submodule direct

Claude Code découvre les skills uniquement à plat sous `.claude/skills/<nom>/SKILL.md` (pas de scan récursif) — un skill imbriqué dans un sous-dossier de phase ne serait pas détecté. Ce repo privilégie la lisibilité par phase dans la source ; un script se charge d'aplatir le contenu pertinent vers `.claude/skills/` et `.github/agents/` du projet consommateur.

## Installation dans un nouveau projet

Depuis la racine du projet WordPress cible :

```bash
# macOS/Linux
curl -sL https://raw.githubusercontent.com/pierre-antoine-viallon/adscom-ia-pipeline/main/scripts/install.sh | bash
```

```powershell
# Windows
irm https://raw.githubusercontent.com/pierre-antoine-viallon/adscom-ia-pipeline/main/scripts/install.ps1 | iex
```

Le script clone temporairement ce repo, copie `01-design/*/` dans `.claude/skills/` du projet, fusionne les `agents/*.md` de `02-passation-design-dev/` et `03-developpement/` dans `.github/agents/`, écrit un marqueur `.claude/skills/.source-version` (commit + date d'installation), puis nettoie le clone temporaire. Le résultat (fichiers plats) est ensuite committé normalement dans le repo du projet — relancer le script plus tard pour mettre à jour, en relisant le diff avant de committer.

Pour figer une version précise plutôt que `main` : `install.ps1 -Ref v1.2.0` (ou `install.sh --ref v1.2.0`).

---

## Les 16 skills Claude Code (`01-design/`)

| # | Skill | Commande | Mode Figma | Rôle |
|---|---|---|---|---|
| 00 | **brief-onboarding** | `/00-brief-onboarding` | — | Capture le contexte projet : client, cible utilisateur, stack Bootstrap 5, URLs Figma/SDS, contraintes RGAA, conventions |
| 01 | **generate-prompt-maquette** | `/01-generate-prompt-maquette` | — | Génère un prompt structuré (brief créatif) pour créer une maquette conforme au brief projet |
| 02 | **validation-maquette** | `/02-validation-maquette` | Lecture | Valide la conformité d'une maquette livrée : pages, variables SDS, grille Bootstrap, nommage, états |
| 03 | **inspection** | `/03-inspection` | Lecture | Cartographie un fichier Figma : pages, calques, variables primitives et sémantiques, composants, styles |
| 04 | **review-ux-ui** | `/04-review-ux-ui` | Lecture | Revue UX/UI itérative : hiérarchie visuelle, cohérence SDS, lisibilité, responsive Bootstrap 5, états. Rapport 🔴/🟡/🟢 |
| 05 | **ajustements** | `/05-ajustements` | Lecture | Co-pilotage des corrections post-review : guide le designer correction par correction en mode dialogue |
| 06 | **accessibilite-rgaa** | `/06-accessibilite-rgaa` | Lecture | Audit RGAA 4.1 : contrastes (3.2/3.3), alternatives textuelles (1.1), structure des titres (9.1), zones cliquables (13.11), formulaires (11.x) |
| 07 | **mapping-design-system** | `/07-mapping-design-system` | Lecture | Analyse les couleurs hardcodées vs. liées aux variables SDS. Produit un plan de mise à jour tokens en 3 phases |
| 08 | **nettoyage-figma** | `/08-nettoyage-figma` | **Écriture** | Automatise le nettoyage : renommage sémantique des calques, liaison hex → variables SDS, ré-instanciation des frames brutes |
| 09 | **sync-sds-bootstrap** | `/09-sync-sds-bootstrap` | Lecture | Génère `_sds-tokens.scss` depuis les variables Figma SDS |
| 10 | **composants** | `/10-composants` | **Écriture** | Détecte les patterns répétés et les transforme en composants Figma avec variantes et propriétés exposées |
| 11 | **export-assets** | `/11-export-assets` | Lecture | Génère un prompt Figma AI qui prépare l'export des assets vers une page "Export" |
| 12 | **documentation** | `/12-documentation` | — | Génère la documentation technique du projet |
| 13 | **livraison** | `/13-livraison` | — | Prépare la livraison finale : checklist de complétude, cohérence des livrables, handoff développeur |
| 14 | **sync-sds-depuis-maquette** | `/14-sync-sds-depuis-maquette` | **Écriture** | Symétrique inverse du 07 : fait évoluer les variables du SDS depuis une maquette hardcodée validée par le client |
| 15 | **annotations-dev-mode** | `/15-annotations-dev-mode` | **Écriture** (annotations) | Pose des annotations Dev Mode : correspondance ACF Block/Gutenberg ou Drupal/Paragraphs, contrôleur JS Bootstrap 5, rappels RGAA |

Le nom de dossier (préfixe numérique inclus) est la slash command exacte — `/00-brief-onboarding`, pas `/brief-onboarding`.

### Ordre d'exécution recommandé (nouveau projet)

```
1. /00-brief-onboarding          → crée brief-projet.md
2. /01-generate-prompt-maquette  → crée prompt-maquette-*.md
3. /02-validation-maquette       → valide la maquette livrée
4. /03-inspection                → cartographie le fichier Figma

   Parcours revue                Parcours tokens
5. /04-review-ux-ui           5. /07-mapping-design-system
6. /05-ajustements            6. /08-nettoyage-figma
7. /06-accessibilite-rgaa     7. /09-sync-sds-bootstrap

8.  /10-composants
9.  /11-export-assets
10. /15-annotations-dev-mode
11. /12-documentation
12. /13-livraison
```

> Nouvelle direction visuelle côté client ? Partir de `/14-sync-sds-depuis-maquette` avant `/07-mapping-design-system`/`/08-nettoyage-figma`.

Toujours commencer par `/00-brief-onboarding` — `brief-projet.md` est lu par tous les skills et agents en aval.

---

## Passation et Développement (`02-passation-design-dev/`, `03-developpement/`)

Agents GitHub Copilot — voir `PIPELINE-AGENTIQUE.md` pour le rôle de chacun (IA Spec, Orchestrator, IA dev, IA Contrib, IA reviewer) et l'état d'avancement (stubs réservés, contenu comportemental pas encore rédigé).

---

## RGAA et accessibilité

Le skill `06-accessibilite-rgaa` est calibré pour les organismes soumis à la loi n°2005-102 et au décret n°2019-768 : collectivités territoriales, EPCI, établissements publics d'État et d'enseignement. Détecte automatiquement le caractère obligatoire ou recommandé selon le client renseigné dans `brief-projet.md`.

---

## Relation avec `figma-mcp-claude-skills`

Ce repo est un successeur, pas un remplacement rétroactif. `figma-mcp-claude-skills` reste inchangé et continue de servir tel quel les projets déjà installés dessus (clone/submodule direct, aucune organisation par phase). `adscom-ia-pipeline` est la source de vérité pour tout nouveau projet à partir de sa création.

---

## Licence

Usage interne ads-COM. Dépôt public à titre de référence.
