// Gera o validador pré-compilado (ajv/dist/standalone) do schema MUST, ou do SHOULD com --should: um módulo ESM que
// não chama new Function nem eval, para motores sem geração de código em tempo de execução (o Hermes do React Native).
//
//   node tools/runners/ajv/standalone.mjs <saída.mjs> [--should] [--absolute]
//
// O schema é lido de spec/ na hora, como no run.mjs. O módulo gerado importa só o runtime do ajv
// (ucs2length): num bundle, ele precisa do pacote ajv instalado, não do compilador. O ajv emite require() mesmo
// com esm: true; aqui cada require vira import. --absolute aponta o import para o node_modules desta pasta, para o
// módulo rodar fora dela (a medição); sem ele, o especificador fica nu (ajv/dist/...), o que um bundler resolve.
import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

import Ajv2020 from 'ajv/dist/2020.js';
import standaloneCode from 'ajv/dist/standalone/index.js';

import { AJV_OPTIONS } from './kg.mjs';
import { CONTRACT_MUST, CONTRACT_SHOULD } from './run.mjs';

const out = process.argv[2];
if (!out) {
  process.stderr.write('uso: standalone.mjs <saída.mjs>\n');
  process.exit(2);
}
const ajv = new Ajv2020({ ...AJV_OPTIONS, code: { source: true, esm: true } });
const schema = process.argv.includes('--should') ? CONTRACT_SHOULD : CONTRACT_MUST;
const validate = ajv.compile(JSON.parse(readFileSync(schema, 'utf8')));
const base = process.argv.includes('--absolute') ? pathToFileURL(new URL('./node_modules/', import.meta.url).pathname).href : '';
const code = standaloneCode(ajv, validate).replace(
  /const (\w+) = require\("(ajv\/dist\/[\w/]+)"\)\.default;/g,
  (_, name, spec) => `import ${name}_mod from "${base}${spec}.js";const ${name} = ${name}_mod.default;`,
);
if (code.includes('require(')) throw new Error('o módulo gerado ainda tem require(): ajuste a troca por import');
writeFileSync(out, code);
process.stdout.write(`${out}: ${code.length} bytes\n`);
