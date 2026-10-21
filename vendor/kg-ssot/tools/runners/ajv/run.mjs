// Runner da matriz para o leitor JS do contrato (tools/runners/ajv/kg.mjs + ajv 2020-12 + yaml 2.x).
// Contrato de runner em spec/conformance/README.md: imprime UMA linha JSON {verdict, codes, warnings, detail}.
//
//   node tools/runners/ajv/run.mjs <caso> [--corpus DIR] [--precompiled ARQ] [--precompiled-should ARQ]
//
// O caso pode ser .kg.yaml (ou .yaml) ou .kg.json. Os schemas MUST e SHOULD do contrato vigente são lidos de spec/
// a cada execução, sem cópia, e compilados pelo ajv; com --precompiled e --precompiled-should, os validadores vêm de
// módulos gerados por standalone.mjs (ajv/dist/standalone), sem compilar nada em tempo de execução. --corpus DIR
// liga a conferência da ponta externa das external_edges contra os .kg.yaml e .kg.json sob DIR (vazio: o caso não é de corpus).
// warnings são os avisos SHOULD, como os da referência.
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
export const CONTRACT_SHOULD = join(ROOT, 'spec', 'kg-contract-v4.should.schema.json');

function arg(name) {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : undefined;
}

export async function compileMust(schema = CONTRACT_MUST) {
  const { default: Ajv2020 } = await import('ajv/dist/2020.js');
  return new Ajv2020(AJV_OPTIONS).compile(JSON.parse(readFileSync(schema, 'utf8')));
}

export const compileShould = () => compileMust(CONTRACT_SHOULD);

// Os grafos do corpus (.kg.yaml e, desde o v4.7, .kg.json): os rastreados, se DIR é repo git (como o gate); senão, todo
// grafo sob DIR (corpus_index).
function corpusFiles(root) {
  try {
    const out = execFileSync('git', ['-C', root, 'ls-files', '-z', '--', '*.kg.yaml', '*.kg.json'], { stdio: ['ignore', 'pipe', 'ignore'] });
    return out.toString('utf8').split('\0').filter(Boolean);
  } catch {
    const found = [];
    const walk = (dir) => {
      for (const ent of readdirSync(dir, { withFileTypes: true })) {
        if (ent.name === '.git') continue;
        const p = join(dir, ent.name);
        if (ent.isDirectory()) walk(p);
        else if (ent.name.endsWith('.kg.yaml') || ent.name.endsWith('.kg.json')) found.push(relative(root, p).split(sep).join('/'));
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
    const preShould = arg('--precompiled-should');
    const validate = pre ? (await import(pathToFileURL(resolve(pre)).href)).default : await compileMust();
    const validateShould = preShould ? (await import(pathToFileURL(resolve(preShould)).href)).default : await compileShould();
    // UTF-8 inválido é erro; o BOM fica no texto (ignoreBOM), como no read_text da referência: quem descarta UM BOM é o
    // parse, e um segundo BOM tem de chegar até ele
    const text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(readFileSync(file));
    const root = arg('--corpus');
    const corpus = root ? corpusIndex(root) : null;
    out = verdictOf(text, validate, { format: file.endsWith('.json') ? 'json' : 'yaml', corpus, validateShould });
  } catch (exc) {
    out = { verdict: 'error', codes: null, warnings: null, detail: `${exc?.name}: ${exc?.message}` };
  }
  process.stdout.write(`${JSON.stringify(out)}\n`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
