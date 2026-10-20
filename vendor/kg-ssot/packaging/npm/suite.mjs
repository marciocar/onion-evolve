// A suíte de conformidade rodada pelo pacote npm kg-ssot INSTALADO (o que um consumidor recebe), não pelo código do
// repo. Uso, de dentro de um projeto que instalou o tarball: node suite.mjs <spec/conformance/fixtures/latest>
// Imprime 'npm: N/M' e sai com rc 0 só quando todos os casos dão o veredito, os códigos e os avisos esperados.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';

import { verdict } from 'kg-ssot';
import { corpusIndex } from 'kg-ssot/node';

const root = resolve(process.argv[2] || '');
const manifests = [];
const walk = (d) => {
  for (const e of readdirSync(d)) {
    const p = join(d, e);
    if (statSync(p).isDirectory()) walk(p);
    else if (e === 'manifest.json') manifests.push(p);
  }
};
walk(root);
let total = 0;
const bad = [];
for (const m of manifests.sort()) {
  for (const c of JSON.parse(readFileSync(m, 'utf8')).cases) {
    total += 1;
    const file = join(dirname(m), c.file);
    const corpus = c.corpus ? corpusIndex(resolve(dirname(m), c.corpus)) : null;
    const text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(readFileSync(file));
    const out = verdict(text, { format: file.endsWith('.json') ? 'json' : 'yaml', corpus });
    const want = c.valid ? 'accept' : 'reject';
    const codesOk = !c.codes || JSON.stringify([...c.codes].sort()) === JSON.stringify(out.codes);
    const warnOk = JSON.stringify([...(c.warnings || [])].sort()) === JSON.stringify(out.warnings);
    if (out.verdict !== want || !codesOk || !warnOk) {
      bad.push(`${c.file}: esperado ${want} ${JSON.stringify(c.codes)} ${JSON.stringify(c.warnings || [])}`
        + ` · ${out.verdict} ${JSON.stringify(out.codes)} ${JSON.stringify(out.warnings)}`);
    }
  }
}
process.stdout.write(`npm: ${total - bad.length}/${total}\n`);
for (const b of bad) process.stdout.write(`  X ${b}\n`);
process.exit(bad.length ? 1 : 0);
