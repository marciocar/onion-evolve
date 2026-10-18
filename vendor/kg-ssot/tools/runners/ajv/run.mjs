// Runner da matriz para o leitor JS do contrato (tools/runners/ajv/kg.mjs + ajv 2020-12 + yaml 2.x).
// Contrato de runner em spec/conformance/README.md: imprime UMA linha JSON {verdict, codes, warnings, detail}.
//
//   node tools/runners/ajv/run.mjs <caso> [--corpus DIR] [--precompiled ARQ]
//
// O caso pode ser .kg.yaml (ou .yaml) ou .kg.json. O schema MUST do contrato vigente é lido de spec/ a cada
// execução, sem cópia, e compilado pelo ajv; com --precompiled, o validador vem de um módulo gerado por
// standalone.mjs (ajv/dist/standalone), sem compilar nada em tempo de execução. --corpus DIR liga a
// conferência da ponta externa das external_edges contra os .kg.yaml sob DIR (vazio: o caso não é de corpus).
// warnings é null: este leitor não mede o SHOULD.
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { AJV_OPTIONS, indexTexts, verdictOf } from './kg.mjs';

// A raiz que tem o spec/: ao lado deste arquivo no pacote npm kg-ssot, três níveis acima no repo e no vendor
// (tools/runners/ajv/).
const HERE = dirname(fileURLToPath(import.meta.url));
export const ROOT = existsSync(join(HERE, 'spec', 'release.json')) ? HERE : resolve(HERE, '../../..');
export const CONTRACT_MUST = join(ROOT, 'spec', 'kg-contract-v4.schema.json');

function arg(name) {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : undefined;
}

export async function compileMust() {
  const { default: Ajv2020 } = await import('ajv/dist/2020.js');
  return new Ajv2020(AJV_OPTIONS).compile(JSON.parse(readFileSync(CONTRACT_MUST, 'utf8')));
}

// Os .kg.yaml do corpus: os rastreados, se DIR é repo git (como o gate); senão, todo .kg.yaml sob DIR (corpus_index).
function corpusFiles(root) {
  try {
    const out = execFileSync('git', ['-C', root, 'ls-files', '-z', '--', '*.kg.yaml'], { stdio: ['ignore', 'pipe', 'ignore'] });
    return out.toString('utf8').split('\0').filter(Boolean);
  } catch {
    const found = [];
    const walk = (dir) => {
      for (const ent of readdirSync(dir, { withFileTypes: true })) {
        if (ent.name === '.git') continue;
        const p = join(dir, ent.name);
        if (ent.isDirectory()) walk(p);
        else if (ent.name.endsWith('.kg.yaml')) found.push(relative(root, p).split(sep).join('/'));
      }
    };
    walk(root);
    return found.sort();
  }
}

export function corpusIndex(root) {
  if (!statSync(root, { throwIfNoEntry: false })?.isDirectory()) throw new Error(`corpus ${root} não é um diretório`);
  const items = [];
  for (const name of corpusFiles(root)) {
    const p = join(root, name);
    if (!statSync(p, { throwIfNoEntry: false })?.isFile()) continue; // FIFO, diretório e apagado ficam fora
    let text = '';
    try { text = new TextDecoder('utf-8', { fatal: true }).decode(readFileSync(p)); } catch { /* ilegível: sem ids */ }
    items.push([name, text]);
  }
  return indexTexts(items);
}

async function main() {
  let out;
  try {
    const file = process.argv[2];
    const pre = arg('--precompiled');
    const validate = pre ? (await import(pathToFileURL(resolve(pre)).href)).default : await compileMust();
    // UTF-8 inválido é erro; o BOM fica no texto (ignoreBOM), como no read_text da referência: quem descarta UM BOM é o
    // parse, e um segundo BOM tem de chegar até ele
    const text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(readFileSync(file));
    const root = arg('--corpus');
    const corpus = root ? corpusIndex(root) : null;
    out = verdictOf(text, validate, { format: file.endsWith('.json') ? 'json' : 'yaml', corpus });
  } catch (exc) {
    out = { verdict: 'error', codes: null, warnings: null, detail: `${exc?.name}: ${exc?.message}` };
  }
  process.stdout.write(`${JSON.stringify(out)}\n`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
