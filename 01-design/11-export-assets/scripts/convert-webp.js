#!/usr/bin/env node
// convert-webp.js — ads-COM export pipeline
// Usage : node convert-webp.js [--input <dir>] [--output <dir>] [--quality <0-100>] [--manifest <path.json>] [--dry-run]
// Prérequis : sharp  →  npm install sharp  (ou npm install -g sharp-cli)
//
// Deux familles de fichiers sources, distinguées par un suffixe `-source` avant l'extension :
//
//   <rel>-source.<ext>   → image bitmap propre (rawImages de download_assets, jamais un rendu
//                          composite avec texte/dégradé/rayon). Produit TOUJOURS <rel>-original.webp
//                          (passthrough, résolution native) ; produit EN PLUS <rel>.webp (recadré/
//                          redimensionné via sharp "cover") si le manifest fournit une taille cible
//                          pour <rel> — c'est la version à taille d'affichage, dérivée localement,
//                          jamais rasterisée depuis un nœud Figma composite.
//
//   <rel>.<ext>           → tout le reste (icônes/vecteurs exportés via le rendu Figma direct,
//                          sans fill image à isoler) → passthrough simple vers <rel>.webp.

import { readdir, mkdir, stat, readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, parse, relative } from 'node:path';
import { parseArgs } from 'node:util';
import sharp from 'sharp';

const { values: args } = parseArgs({
  options: {
    input:    { type: 'string',  short: 'i', default: './assets/img/_source' },
    output:   { type: 'string',  short: 'o', default: './assets/img' },
    quality:  { type: 'string',  short: 'q', default: '85' },
    manifest: { type: 'string',  short: 'm', default: '' },
    'dry-run': { type: 'boolean', default: false },
  },
  strict: true,
});

const INPUT_DIR  = args.input;
const OUTPUT_DIR = args.output;
const QUALITY    = Math.min(100, Math.max(0, parseInt(args.quality, 10)));
const DRY_RUN    = args['dry-run'];
const MANIFEST_PATH = args.manifest;

const SOURCE_SUFFIX = /-source$/i;

async function loadManifest() {
  if (!MANIFEST_PATH) return {};
  if (!existsSync(MANIFEST_PATH)) {
    console.error(`Manifest introuvable : ${MANIFEST_PATH}`);
    return {};
  }
  return JSON.parse(await readFile(MANIFEST_PATH, 'utf8'));
}

async function walkDir(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...await walkDir(full));
    else if (/\.(png|jpg|jpeg)$/i.test(entry.name)) files.push(full);
  }
  return files;
}

function toSlug(name) {
  return name
    .normalize('NFD').replace(/[̀-ͯ]/g, '') // remove accents
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase();
}

async function writeWebp(inputPath, outPath, resizeTo) {
  const outDirPath = parse(outPath).dir;
  if (!existsSync(outDirPath)) await mkdir(outDirPath, { recursive: true });

  const inputStat = await stat(inputPath);
  if (existsSync(outPath)) {
    const outStat = await stat(outPath);
    if (outStat.mtimeMs >= inputStat.mtimeMs) {
      console.log(`[skip]  ${relative(OUTPUT_DIR, outPath)}  (à jour)`);
      return { skipped: true };
    }
  }

  let pipeline = sharp(inputPath).rotate(); // auto-oriente selon l'EXIF (photos de téléphone) puis retire le tag
  if (resizeTo) {
    pipeline = pipeline.resize(resizeTo.width, resizeTo.height, { fit: 'cover', position: 'centre' });
  }

  const info = await pipeline.webp({ quality: QUALITY, effort: 4 }).toFile(outPath);
  const saved = ((1 - info.size / inputStat.size) * 100).toFixed(1);
  console.log(`[ok]    ${relative(OUTPUT_DIR, outPath)}  ${(info.size / 1024).toFixed(0)} KB  (${saved}% saved)`);
  return { skipped: false, sizeKb: (info.size / 1024).toFixed(0) };
}

async function convert(inputPath, manifest) {
  const rel      = relative(INPUT_DIR, inputPath);
  const parsed   = parse(rel);
  const isSource = SOURCE_SUFFIX.test(parsed.name);
  const baseName = toSlug(parsed.name.replace(SOURCE_SUFFIX, ''));
  const relKey   = join(parsed.dir, baseName).replace(/\\/g, '/'); // clé manifest, toujours en /

  if (!isSource) {
    // Icône/vecteur — passthrough simple, pas de version -original
    const outPath = join(OUTPUT_DIR, parsed.dir, `${baseName}.webp`);
    if (DRY_RUN) { console.log(`[dry-run] ${inputPath} → ${outPath}`); return { dryRun: true }; }
    return await writeWebp(inputPath, outPath, null);
  }

  // Source bitmap propre — toujours -original (passthrough natif)
  const originalOut = join(OUTPUT_DIR, parsed.dir, `${baseName}-original.webp`);
  const target = manifest[relKey];

  if (DRY_RUN) {
    console.log(`[dry-run] ${inputPath} → ${originalOut}` + (target ? ` + ${join(OUTPUT_DIR, parsed.dir, baseName)}.webp (${target.width}x${target.height})` : ''));
    return { dryRun: true };
  }

  const results = [await writeWebp(inputPath, originalOut, null)];

  // Version recadrée/redimensionnée à la taille d'affichage Figma, si fournie par le manifest
  if (target?.width && target?.height) {
    const resizedOut = join(OUTPUT_DIR, parsed.dir, `${baseName}.webp`);
    results.push(await writeWebp(inputPath, resizedOut, target));
  }

  return { skipped: results.every(r => r.skipped) };
}

async function main() {
  if (!existsSync(INPUT_DIR)) {
    console.error(`Dossier source introuvable : ${INPUT_DIR}`);
    process.exit(1);
  }

  const manifest = await loadManifest();
  const files = await walkDir(INPUT_DIR);
  if (files.length === 0) {
    console.log('Aucun PNG/JPG trouvé dans', INPUT_DIR);
    process.exit(0);
  }

  console.log(`\nConversion WebP — qualité ${QUALITY}%${DRY_RUN ? ' [DRY RUN]' : ''}`);
  console.log(`  Source    : ${INPUT_DIR}  (${files.length} fichier(s))`);
  console.log(`  Sortie    : ${OUTPUT_DIR}`);
  console.log(`  Manifest  : ${MANIFEST_PATH || '(aucun — pas de version recadrée pour les sources bitmap)'}\n`);

  const results = await Promise.all(files.map(f => convert(f, manifest)));
  const converted = results.filter(r => !r.skipped && !r.dryRun).length;
  const skipped   = results.filter(r => r.skipped).length;

  console.log(`\nBilan : ${converted} fichier(s) converti(s) · ${skipped} ignoré(s) (à jour)`);
}

main().catch(err => { console.error(err); process.exit(1); });
