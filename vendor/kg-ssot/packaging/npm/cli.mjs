#!/usr/bin/env node
// kg-ssot-validate: julga grafos .kg.yaml e .kg.json contra o contrato vigente, com o validador pré-compilado.
//
//   kg-ssot-validate <arquivo>... [--json] [--corpus DIR]
//
// rc 0 quando todos passam no MUST, 1 quando algum reprova, 2 com entrada quebrada (arquivo ilegível, UTF-8
// inválido). Os avisos SHOULD saem numa linha AVISO e não mudam o rc. --json imprime uma linha JSON por arquivo, no contrato de runner da suíte. --corpus confere a ponta
// externa das external_edges contra os .kg.yaml e .kg.json sob DIR.
import { readFileSync } from 'node:fs';

import { verdict } from './index.mjs';
import { corpusIndex } from './run.mjs';

const USAGE = 'uso: kg-ssot-validate <arquivo.kg.yaml|arquivo.kg.json>... [--json] [--corpus DIR]\n';
const args = process.argv.slice(2);
let json = false;
let corpusDir = null;
const files = [];
for (let i = 0; i < args.length; i += 1) {
  const a = args[i];
  if (a === '--help' || a === '-h') {
    process.stdout.write(USAGE);
    process.exit(0);
  } else if (a === '--json') json = true;
  else if (a === '--corpus') {
    corpusDir = args[++i];
    if (!corpusDir) {
      process.stdout.write(`ENTRADA QUEBRADA  --corpus sem diretório\n${USAGE}`);
      process.exit(2);
    }
  } else if (a === '--') files.push(...args.slice(i + 1)), (i = args.length);
  else if (a.startsWith('-')) {
    process.stdout.write(`ENTRADA QUEBRADA  opção desconhecida: ${a}\n${USAGE}`);
    process.exit(2);
  } else files.push(a);
}
if (!files.length) {
  process.stdout.write(USAGE);
  process.exit(2);
}
let rc = 0;
let corpus = null;
try {
  corpus = corpusDir ? corpusIndex(corpusDir) : null;
} catch (exc) {
  process.stdout.write(`ENTRADA QUEBRADA  ${exc.message}\n`);
  process.exit(2);
}
for (const file of files) {
  let out;
  try {
    const text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(readFileSync(file));
    out = verdict(text, { format: file.endsWith('.json') ? 'json' : 'yaml', corpus });
  } catch (exc) {
    out = { verdict: 'error', codes: null, warnings: null, detail: `${exc?.name}: ${exc?.message}` };
  }
  if (out.verdict === 'error') rc = 2;
  else if (out.verdict === 'reject' && rc === 0) rc = 1;
  if (json) process.stdout.write(`${JSON.stringify({ file, ...out })}\n`);
  else if (out.verdict === 'accept') process.stdout.write(`PASSA   ${file}\n`);
  else if (out.verdict === 'reject') process.stdout.write(`REPROVA ${file}\n  MUST   ${out.codes.join(' · ')}\n`);
  else process.stdout.write(`ERRO    ${file}\n  ${out.detail}\n`);
  if (!json && out.warnings?.length) process.stdout.write(`  AVISO  ${out.warnings.join(' · ')}\n`);
}
process.exit(rc);
