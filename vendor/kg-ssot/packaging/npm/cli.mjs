#!/usr/bin/env node
// kg-ssot-validate: julga grafos .kg.yaml e .kg.json contra o contrato vigente, com o validador pré-compilado.
//
//   kg-ssot-validate <arquivo>... [--json] [--corpus DIR]
//
// rc 0 quando todos passam no MUST, 1 quando algum reprova, 2 com entrada quebrada (arquivo ilegível, UTF-8
// inválido). Os avisos SHOULD saem numa linha WARNING e não mudam o rc. --json imprime uma linha JSON por arquivo, no contrato de runner da suíte. --corpus confere a ponta
// externa das external_edges contra os .kg.yaml e .kg.json sob DIR.
//
// A saída humana sai em inglês (a língua-fonte) ou na tradução pt-BR, negociada como no kg_i18n do Python:
// KG_SSOT_LANG, LANGUAGE, LC_ALL, LC_MESSAGES e LANG, parando na primeira definida; C, POSIX e vazio são o inglês.
// Como no gettext, o LANGUAGE só vale quando o locale efetivo (LC_ALL, LC_MESSAGES, LANG) não é o C.
// As frases ficam também no catálogo locale/pt_BR/LC_MESSAGES/kg-ssot.po (referência #: packaging/npm/cli.mjs), para o tradutor ter um lugar
// só. A saída --json é dado e não se traduz.
import { readFileSync } from 'node:fs';

import { verdict } from './index.mjs';
import { corpusIndex } from './run.mjs';

// A tradução pt-BR (igual às entradas do cli.mjs no kg-ssot.po); a chave é o msgid em inglês.
const PT_BR = {
  'usage: kg-ssot-validate <file.kg.yaml|file.kg.json>... [--json] [--corpus DIR]':
    'uso: kg-ssot-validate <arquivo.kg.yaml|arquivo.kg.json>... [--json] [--corpus DIR]',
  'BROKEN INPUT': 'ENTRADA QUEBRADA',
  '--corpus without a directory': '--corpus sem diretório',
  'unknown option: {option}': 'opção desconhecida: {option}',
  'corpus {root} is not a directory': 'corpus {root} não é um diretório',
  PASS: 'PASSA',
  FAIL: 'REPROVA',
  ERROR: 'ERRO',
  WARNING: 'AVISO',
};

// true quando a língua do ambiente é o português (pt, pt_BR e afins); o inglês e língua sem tradução dão false.
function wantsPortuguese(vars) {
  const isC = (v) => { const t = v.trim().split('.')[0].split('@')[0].toLowerCase(); return !t || t === 'c' || t === 'posix'; };
  const effective = ['LC_ALL', 'LC_MESSAGES', 'LANG'].map((n) => vars[n]).find((v) => v);
  const localeIsC = !effective || isC(effective);
  for (const name of ['KG_SSOT_LANG', 'LANGUAGE', 'LC_ALL', 'LC_MESSAGES', 'LANG']) {
    const value = vars[name];
    if (!value || (name === 'LANGUAGE' && localeIsC)) continue;
    for (const raw of name === 'LANGUAGE' ? value.split(':') : [value]) {
      const tag = raw.trim().split('.')[0].split('@')[0].replace(/-/g, '_').toLowerCase();
      if (!tag || tag === 'c' || tag === 'posix') return false;
      const lang = tag.split('_')[0];
      if (lang === 'pt') return true;
      if (lang === 'en') return false;
    }
    return false; // a variável definida decide, mesmo sem tradução: o inglês
  }
  return false;
}

const TABLE = wantsPortuguese(process.env) ? PT_BR : {};
const _ = (msgid, vals = {}) =>
  (TABLE[msgid] ?? msgid).replace(/\{(\w+)\}/g, (m, k) => (k in vals ? String(vals[k]) : m));
// o rótulo da linha do arquivo, com a coluna do nome alinhada
const label = (msgid) => `${_(msgid).padEnd(7)} `;

const USAGE = `${_('usage: kg-ssot-validate <file.kg.yaml|file.kg.json>... [--json] [--corpus DIR]')}\n`;
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
      process.stdout.write(`${_('BROKEN INPUT')}  ${_('--corpus without a directory')}\n${USAGE}`);
      process.exit(2);
    }
  } else if (a === '--') files.push(...args.slice(i + 1)), (i = args.length);
  else if (a.startsWith('-')) {
    process.stdout.write(`${_('BROKEN INPUT')}  ${_('unknown option: {option}', { option: a })}\n${USAGE}`);
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
  const msg = exc?.kgMsgid ? _(exc.kgMsgid, exc.kgArgs) : exc?.message;
  process.stdout.write(`${_('BROKEN INPUT')}  ${msg}\n`);
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
  else if (out.verdict === 'accept') process.stdout.write(`${label('PASS')}${file}\n`);
  else if (out.verdict === 'reject') process.stdout.write(`${label('FAIL')}${file}\n  MUST   ${out.codes.join(' · ')}\n`);
  else process.stdout.write(`${label('ERROR')}${file}\n  ${out.detail}\n`);
  if (!json && out.warnings?.length) process.stdout.write(`  ${_('WARNING')}  ${out.warnings.join(' · ')}\n`);
}
process.exit(rc);
