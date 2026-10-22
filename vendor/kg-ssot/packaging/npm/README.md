# kg-ssot

[![npm](https://img.shields.io/npm/v/kg-ssot)](https://www.npmjs.com/package/kg-ssot)
[![license](https://img.shields.io/npm/l/kg-ssot)](https://github.com/marciocar/kg-ssot/blob/main/LICENSE)
[![node](https://img.shields.io/node/v/kg-ssot)](https://github.com/marciocar/kg-ssot)

**The JavaScript reader for the KG-SSOT contract, the verifiable knowledge graph. Every claim says where it came
from, when someone verified it, and what depends on it.**

`kg-ssot` checks a `.kg.yaml` or `.kg.json` graph against the current contract (v4). It returns the MUST verdict and
the SHOULD warnings, with the stable codes of the conformance suite. The package ships:

- **The reader core**, which uses neither `fs` nor `process`.
- **Precompiled contract validators**, MUST and SHOULD, that never call `new Function` or `eval`. They run on engines
  without runtime code generation, like Hermes in React Native and Expo, and on Node.
- **The schemas** of the contract and of the verdict.

The reference reader is the Python package [`kg-ssot`](https://pypi.org/project/kg-ssot/). This reader passes every
case in the conformance suite (`latest/`) with the expected verdict, codes, and warnings. On every change to the
reader, CI runs the whole suite against the installed tarball.

## Install

```bash
npm install kg-ssot
```

On Node, you need version 22.12 or later. The package is ESM and ships its own TypeScript types.

## Use it in code

```js
import { verdict } from 'kg-ssot';

verdict(text);                      // .kg.yaml (the default)
verdict(text, { format: 'json' });  // .kg.json
// { verdict: 'accept', codes: [], warnings: [], detail: '' }
// { verdict: 'accept', codes: [], warnings: ['yaml.unquoted-date'], detail: '' }
// { verdict: 'reject', codes: ['form.range.node.impact', 'form.type.node.impact'], warnings: [], detail: '' }
```

- `verdict(text, { format, corpus })` returns the verdict in the suite's runner contract. `verdict` is `accept` or
  `reject`, `codes` lists the MUST codes, and `warnings` lists the SHOULD codes. Both lists are sorted, with no
  duplicates. A warning never fails a graph: a graph with warnings is still `accept`.
- `check(text, { format, corpus })` returns only the MUST codes (empty when the graph passes).
  `checkWarnings(text, { format, corpus })` returns only the warnings.
- `corpus` lets the reader verify the far end of each `external_edges` entry. It is a
  `Map<path, Set<nodeId>>`. Build it with `corpusIndex(dir)` from `kg-ssot/node`, or, without a file system, with
  `indexTexts([[path, text], ...])` from the main entry.

### Entry points

| Import | What you get |
|---|---|
| `kg-ssot` | `verdict`, `check`, `checkWarnings`, the precompiled `validateMust` and `validateShould`, and the core |
| `kg-ssot/core` | The core without the validators, for when you compile the schema yourself (`verdictOf`, `codes`, `warnings`, `parse`, `indexTexts`) |
| `kg-ssot/must`, `kg-ssot/should` | The precompiled MUST and SHOULD validators alone |
| `kg-ssot/node` | Node helpers: `corpusIndex(dir)` indexes the `.kg.yaml` and `.kg.json` graphs under a directory (the tracked ones, in a git repository); `compileMust()` compiles the schema with `ajv` at runtime |
| `kg-ssot/spec/*` | The contract and verdict schemas |

Since 4.10.0, this reader also measures the SHOULD warnings, with the same codes as the reference reader on every
suite case. Since 4.13.0, it treats `\r` as a line break, like the reference. Since 4.11.0, the three rare YAML
constructs where it used to diverge from the reference (the unnamed `!` tag, a `!!timestamp` whose text is not a
date, and a tab outside quotes) now fail in both, and the suite has cases for them. Only the Python reference reader
reports the line of each finding and the fix hints.

## TypeScript and CommonJS

The package ships types (`index.d.mts`, `core.d.mts`, `node.d.mts`, and `validator.d.mts`). It works with
`moduleResolution` set to `bundler` or `nodenext`, which covers the Expo TypeScript template. It is an ESM package.
In a CommonJS project, `require('kg-ssot')` works from Node 22.12, the minimum declared in `engines`.

## Use it from the command line

```bash
npx kg-ssot-validate decisions.kg.yaml graph.kg.yaml other.kg.json
```

```text
PASS    decisions.kg.yaml
PASS    graph.kg.yaml
  WARNING  yaml.unquoted-date
FAIL    other.kg.json
  MUST   form.range.node.impact · form.type.node.impact
```

The exit code is 0 when every file passes, 1 when any file fails, and 2 on broken input: an unreadable file, invalid
UTF-8, an unknown option, or a `--corpus` that is not a directory. Warnings never change the exit code.

- `--json` prints one JSON line per file, in the suite's runner contract:

  ```text
  {"file":"graph.kg.yaml","verdict":"accept","codes":[],"warnings":["yaml.unquoted-date"],"detail":""}
  {"file":"other.kg.json","verdict":"reject","codes":["form.range.node.impact","form.type.node.impact"],"warnings":[],"detail":""}
  ```

- `--corpus DIR` verifies the far end of each `external_edges` entry against the `.kg.yaml` and `.kg.json` graphs
  under `DIR`.

The human output is in English. The CLI speaks Brazilian Portuguese when you set `KG_SSOT_LANG=pt-BR` (or when your
locale is `pt_BR`):

```bash
KG_SSOT_LANG=pt-BR npx kg-ssot-validate graph.kg.yaml
```

The codes and the `--json` output are data, so they never change language. The documentation in Portuguese is in
[README.pt-BR](https://github.com/marciocar/kg-ssot/blob/main/README.pt-BR.md).

## Use it in a React Native or Expo app

The package is ESM, and the main entry imports nothing from Node. Your bundler (Metro, esbuild) resolves the two
dependencies, `yaml` and the `ajv` runtime. The validators come precompiled, so nothing has to generate code on the
device. We ran the conformance suite on Hermes, and it returns the same verdicts as Node.

```js
import { verdict, indexTexts } from 'kg-ssot';

const corpus = indexTexts([['other.kg.yaml', otherText]]); // optional, for external_edges
const result = verdict(graphText, { corpus });
if (result.verdict === 'reject') console.warn(result.codes);
```

## Documentation

- [Manual](https://github.com/marciocar/kg-ssot/tree/main/docs/manual): the format, the contract, the tools, and
  common problems
- [Conformance suite](https://github.com/marciocar/kg-ssot/blob/main/spec/conformance/README.md)
- [Adoption guide](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md)
- [Changelog](https://github.com/marciocar/kg-ssot/blob/main/CHANGELOG.md)
- [Issues](https://github.com/marciocar/kg-ssot/issues)

## License

Apache-2.0. See [`LICENSE`](https://github.com/marciocar/kg-ssot/blob/main/LICENSE) and
[`NOTICE`](https://github.com/marciocar/kg-ssot/blob/main/NOTICE).

Documentação em português: [README.pt-BR](https://github.com/marciocar/kg-ssot/blob/main/README.pt-BR.md).
