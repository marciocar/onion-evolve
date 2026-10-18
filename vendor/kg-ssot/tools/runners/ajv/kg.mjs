// Núcleo puro do leitor JS do contrato do .kg.yaml e do .kg.json (o pacote npm kg-ssot).
//
// Sem fs, sem processo e sem ajv: recebe o texto e um validador do schema MUST já compilado (pelo ajv em tempo
// de execução ou pré-compilado com ajv/dist/standalone) e devolve os códigos MUST da suíte. É a peça que pode
// ir a um bundle de React Native. O comportamento é portado de tools/kg_validate.py, o leitor de referência:
//   - parseYaml: o perfil YAML 1.2 core restrito do ADR 002 (Yaml12CoreLoader, _parse, canonical, json_key);
//   - parseJson: o mesmo modelo para .kg.json no perfil JSON do contrato (_parse_json): RFC 8259 e I-JSON, BOM só
//     no início, até 128 coleções e chave repetida recusada (parse.duplicate-key);
//   - formCodes: os erros do JSON Schema traduzidos para form.<tipo>.<escopo>.<campo> (form_codes);
//   - unsafeIntegerCodes: o inteiro fora de ±(2^53−1) no .kg.json, form.type no caminho do .nan (unsafe_integer_codes);
//   - integrity: ids únicos, pontas de aresta, órfãos e external_edges (integrity_located);
//   - codes: tudo junto, ordenado e sem repetição (code_counts/codes).
import { parseAllDocuments, isAlias, isMap, isPair, isScalar, isSeq } from 'yaml';

// format: date é asserção (ADR 002): AAAA-MM-DD que existe no calendário, ano de 0001 a 9999, como o
// datetime.date.fromisoformat do leitor de referência. É uma regex, e não uma função, para que o validador
// pré-compilado (standalone) a carregue inline, sem import de código de formato.
export const DATE_RE = new RegExp(
  '^(?:(?!0000)[0-9]{4}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|(?:0[13578]|1[02])-31)'
  + '|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00)-02-29)$');

// As opções do ajv que o leitor exige: todos os erros (o código é por conjunto), verbose (o `not` precisa do
// subschema) e o formato date acima. O pattern do ajv já é ECMA-262 (flag u), como o _ecma_pattern da referência.
export const AJV_OPTIONS = { allErrors: true, strict: false, verbose: true, formats: { date: DATE_RE } };

const MAX_DEPTH = 1000; // coleções abertas de uma vez (MAX_DEPTH da referência)
// coleções aninhadas que o perfil do modelo admite (PROFILE_DEPTH da referência): MUST no .kg.json. No .kg.yaml a
// referência só avisa (yaml.depth-over-128), e este leitor não mede aviso: lá ele deixa passar.
const PROFILE_DEPTH = 128;
const SLUG = /^[A-Za-z_][A-Za-z0-9_-]*$/;
const EXTERNAL_REF = /^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*\/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.yaml#[A-Za-z][A-Za-z0-9_]*$/;
const CORE_INT = /^(?:[-+]?[0-9]+|0o[0-7]+|0x[0-9a-fA-F]+)$/;
const Y = 'tag:yaml.org,2002:';

class ParseError extends Error {
  constructor(code) { super(code); this.code = code; }
}

// .nan e .inf: o JSON não os representa. Um símbolo não é número, texto, objeto nem lista para o ajv, como o
// NonFinite da referência para o jsonschema; o texto é o repr do Python (nan, inf, -inf).
const NON_FINITE = new Map([[NaN, Symbol('nan')], [Infinity, Symbol('inf')], [-Infinity, Symbol('-inf')]]);
const nonFiniteOf = (x) => (Number.isNaN(x) ? NON_FINITE.get(NaN) : NON_FINITE.get(x));
const isNonFinite = (v) => typeof v === 'symbol' && [...NON_FINITE.values()].includes(v);
// !!binary vira bytes na referência: um valor opaco que não é NonFinite.
const BYTES = Symbol('bytes');

export const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

function setOwn(obj, key, value) {
  Object.defineProperty(obj, key, { value, enumerable: true, writable: true, configurable: true });
}

// O repr curto de um float do Python (repr(1e16) == '1e+16', repr(1.0) == '1.0'): a forma da chave numérica.
function pyFloatRepr(x) {
  if (Number.isNaN(x)) return 'nan';
  if (!Number.isFinite(x)) return x > 0 ? 'inf' : '-inf';
  if (x === 0) return Object.is(x, -0) ? '-0.0' : '0.0';
  const [mant, expText] = Math.abs(x).toExponential().split('e');
  const exp = Number(expText);
  const digits = mant.replace('.', '');
  const sign = x < 0 ? '-' : '';
  if (exp < -4 || exp >= 16) {
    const m = digits.length > 1 ? `${digits[0]}.${digits.slice(1)}` : digits;
    return `${sign}${m}e${exp < 0 ? '-' : '+'}${String(Math.abs(exp)).padStart(2, '0')}`;
  }
  if (exp < 0) return `${sign}0.${'0'.repeat(-exp - 1)}${digits}`;
  const int = digits.slice(0, exp + 1).padEnd(exp + 1, '0');
  const frac = digits.slice(exp + 1);
  return `${sign}${int}.${frac || '0'}`;
}

// str() do Python sobre um valor do documento: é com ele que a referência compara ids e pontas de aresta.
export function pyStr(v) {
  if (typeof v === 'string') return v;
  if (v === null || v === undefined) return 'None';
  if (typeof v === 'boolean') return v ? 'True' : 'False';
  if (typeof v === 'number') return Number.isInteger(v) && Math.abs(v) < 1e16 ? String(v) : pyFloatRepr(v);
  if (isNonFinite(v)) return `NonFinite(${v.description})`;
  if (v === BYTES) return "b''";
  if (Array.isArray(v)) return `[${v.map(pyStr).join(', ')}]`;
  return `{${Object.entries(v).map(([k, x]) => `'${k}': ${pyStr(x)}`).join(', ')}}`;
}

// ---------------------------------------------------------------- YAML 1.2 core restrito

const KNOWN_SCALAR_TAGS = new Set([`${Y}str`, `${Y}int`, `${Y}float`, `${Y}bool`, `${Y}null`, `${Y}binary`, `${Y}timestamp`]);
const KNOWN_COLLECTION_TAGS = new Set([`${Y}map`, `${Y}seq`]);

// O escalar como a referência o constrói: (valor, chave na forma JSON).
function scalarOf(node) {
  const { tag, value } = node;
  if (tag && !KNOWN_SCALAR_TAGS.has(tag)) throw new ParseError('parse.yaml-error'); // sem construtor no perfil
  if (tag === `${Y}int`) {
    const src = String(node.source ?? value);
    if (!CORE_INT.test(src)) throw new ParseError('parse.yaml-error'); // !!int 0b11: o 1.2 core não lê
    const big = src.startsWith('0o') ? BigInt(src) : BigInt(src.replace(/^\+/, ''));
    return { value: Number(big), key: big.toString(), int: true };
  }
  if (tag === `${Y}timestamp`) return { value: String(node.source ?? value), key: String(node.source ?? value) };
  if (tag === `${Y}binary`) return { value: BYTES, key: "b''" };
  if (value === null || value === undefined) return { value: null, key: 'null' };
  if (typeof value === 'boolean') return { value, key: String(value) };
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) {
      return { value: nonFiniteOf(value), key: Number.isNaN(value) ? 'NaN' : value > 0 ? 'Infinity' : '-Infinity' };
    }
    const src = node.type === 'PLAIN' ? String(node.source) : '';
    if (tag !== `${Y}float` && CORE_INT.test(src)) {
      const big = src.startsWith('0o') || src.startsWith('0x') ? BigInt(src) : BigInt(src.replace(/^\+/, ''));
      return { value, key: big.toString(), int: true };
    }
    return { value, key: pyFloatRepr(value) };
  }
  if (typeof value === 'string') return { value, key: value };
  throw new ParseError('parse.yaml-error');
}

// A profundidade de coleções abertas na árvore do YAML, sem recursão e sem seguir alias (o _too_deep da
// referência conta o stream de eventos, em que o alias não abre coleção).
function tooDeep(root) {
  const stack = [[root, 0]];
  while (stack.length) {
    const [node, d] = stack.pop();
    if (isMap(node) || isSeq(node)) {
      if (d + 1 > MAX_DEPTH) return true;
      for (const item of node.items) {
        if (isPair(item)) stack.push([item.key, d + 1], [item.value, d + 1]);
        else stack.push([item, d + 1]);
      }
    } else if (isPair(node)) {
      stack.push([node.key, d], [node.value, d]);
    }
  }
  return false;
}

// Converte a árvore de um documento no valor que a referência constrói. Alias compartilha o valor (como o
// PyYAML), âncora repetida e alias sem âncora são erro de composição, chave composta é erro, e chave repetida
// é comparada na forma JSON (1 e "1" colidem; 1 e 1.0, não).
function convertDocument(doc) {
  const anchors = new Map();
  const built = new Map();
  const walk = (node) => {
    if (node === null || node === undefined) return null;
    if (isAlias(node)) {
      if (!anchors.has(node.source)) throw new ParseError('parse.yaml-error');
      const target = anchors.get(node.source);
      return built.has(target) ? built.get(target) : walk(target);
    }
    if (node.anchor) {
      if (anchors.has(node.anchor)) throw new ParseError('parse.yaml-error'); // found duplicate anchor
      anchors.set(node.anchor, node);
    }
    if (isScalar(node)) {
      const v = scalarOf(node).value;
      built.set(node, v);
      return v;
    }
    if (node.tag && !KNOWN_COLLECTION_TAGS.has(node.tag)) throw new ParseError('parse.yaml-error');
    if (isSeq(node)) {
      const out = [];
      built.set(node, out);
      for (const item of node.items) out.push(walk(item));
      return out;
    }
    if (isMap(node)) {
      const out = {};
      built.set(node, out);
      const seen = new Set();
      for (const pair of node.items) {
        let keyNode = pair.key;
        if (isAlias(keyNode)) {
          if (!anchors.has(keyNode.source)) throw new ParseError('parse.yaml-error');
          keyNode = anchors.get(keyNode.source);
        } else if (keyNode && keyNode.anchor) {
          if (anchors.has(keyNode.anchor)) throw new ParseError('parse.yaml-error');
          anchors.set(keyNode.anchor, keyNode);
        }
        let key = 'null';
        if (keyNode !== null && keyNode !== undefined) {
          if (!isScalar(keyNode)) throw new ParseError('parse.yaml-error'); // chave composta (mapa ou lista)
          key = scalarOf(keyNode).key;
        }
        if (seen.has(key)) throw new ParseError('parse.duplicate-key');
        seen.add(key);
        setOwn(out, key, walk(pair.value));
      }
      return out;
    }
    throw new ParseError('parse.yaml-error');
  };
  return walk(doc.contents);
}

// O documento construído, contando cada alias pelo que ele repete, passa de `budget` valores? (_expands_beyond)
function expandsBeyond(value, budget) {
  let seen = 0;
  const stack = [value];
  while (stack.length) {
    const v = stack.pop();
    seen += 1;
    if (seen > budget) return true;
    if (Array.isArray(v)) stack.push(...v);
    else if (isObj(v)) {
      const vals = Object.values(v);
      stack.push(...vals);
      seen += vals.length;
    }
  }
  return false;
}

const codePoints = (text) => {
  let n = 0;
  for (const _ of text) n += 1; // eslint-disable-line no-unused-vars
  return n;
};

/** O parse do .kg.yaml no perfil do contrato: { doc } ou { code: 'parse.*' }. */
export function parseYaml(text) {
  let docs;
  try {
    docs = parseAllDocuments(text, {
      version: '1.2', schema: 'core', uniqueKeys: false, merge: false, maxAliasCount: -1, prettyErrors: false,
    });
  } catch {
    return { code: 'parse.yaml-error' }; // aninhamento que estoura a pilha do parser, entre outros
  }
  if (!Array.isArray(docs)) docs = [docs]; // EmptyStream é lista; um documento só também vem como lista
  const raw = [];
  try {
    for (const d of docs) {
      if (d.errors.length) return { code: 'parse.yaml-error' };
      if (d.contents && tooDeep(d.contents)) return { code: 'parse.yaml-error' };
      raw.push(convertDocument(d));
    }
  } catch (exc) {
    if (exc instanceof ParseError) return { code: exc.code };
    return { code: 'parse.yaml-error' };
  }
  if (expandsBeyond(raw, 2 * codePoints(text) + 1000)) return { code: 'parse.yaml-error' };
  const present = raw.filter((d) => d !== null);
  if (!present.length) return { code: 'parse.empty-document' };
  if (raw.length !== 1) return { code: 'parse.not-single-document' };
  if (!isObj(raw[0])) return { code: 'parse.root-not-mapping' };
  return { doc: raw[0] };
}

// ---------------------------------------------------------------- JSON

const JSON_WS = new Set([' ', '\t', '\n', '\r']);
// Só o espaço em branco da RFC 8259: o trim() do JS tiraria também NBSP, U+2028 e o BOM.
const isJsonBlank = (text) => [...text].every((c) => JSON_WS.has(c));

// Chave repetida num objeto JSON, comparada depois de desfazer o escape ("a" e "\u0061" colidem). Roda sobre um
// texto que o JSON.parse já aceitou, então a varredura só precisa achar strings, chaves e ':'.
function hasDuplicateKey(text) {
  const stack = []; // Set de chaves por objeto aberto; null por lista
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === '{') { stack.push(new Set()); i += 1; } else if (c === '[') { stack.push(null); i += 1; } else if (c === '}' || c === ']') { stack.pop(); i += 1; } else if (c === '"') {
      let j = i + 1;
      while (text[j] !== '"') j += text[j] === '\\' ? 2 : 1;
      const literal = text.slice(i, j + 1);
      i = j + 1;
      const keys = stack[stack.length - 1];
      if (keys) {
        let k = i;
        while (JSON_WS.has(text[k])) k += 1;
        if (text[k] === ':') {
          const key = JSON.parse(literal);
          if (keys.has(key)) return true;
          keys.add(key);
        }
      }
    } else i += 1;
  }
  return false;
}

/** Quantas coleções (objetos e listas) o valor aninha, a raiz contando 1; para assim que passa de limit. Sem recursão
 * (collection_depth da referência). */
export function collectionDepth(value, limit = PROFILE_DEPTH) {
  let best = 0;
  const stack = [[value, 1]];
  while (stack.length) {
    const [v, d] = stack.pop();
    let items;
    if (Array.isArray(v)) items = v;
    else if (isObj(v)) items = Object.values(v);
    else continue;
    if (d > best) best = d;
    if (best > limit) return best;
    for (const x of items) stack.push([x, d + 1]);
  }
  return best;
}

// Um surrogate (U+D800 a U+DFFF) sem o par: o par alto+baixo é um caractere, como na referência.
function loneSurrogateIn(s) {
  for (let i = 0; i < s.length; i += 1) {
    const c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff) {
      const d = s.charCodeAt(i + 1);
      if (d >= 0xdc00 && d <= 0xdfff) { i += 1; continue; }
      return true;
    }
    if (c >= 0xdc00 && c <= 0xdfff) return true;
  }
  return false;
}

/** Alguma chave ou texto do valor tem surrogate solto (has_lone_surrogate da referência)? Sem recursão. */
export function hasLoneSurrogate(value) {
  const stack = [value];
  while (stack.length) {
    const v = stack.pop();
    if (typeof v === 'string') {
      if (loneSurrogateIn(v)) return true;
    } else if (Array.isArray(v)) stack.push(...v);
    else if (isObj(v)) for (const [k, x] of Object.entries(v)) stack.push(k, x);
  }
  return false;
}

// O 1e400 do JSON.parse vira Infinity: marca como não finito, como o .inf do YAML (form.type, não form.range). Sem
// recursão (um reviver do JSON.parse desceria recursivo) e só depois da guarda de profundidade.
function markNonFinite(root) {
  const stack = [root];
  while (stack.length) {
    const v = stack.pop();
    const entries = Array.isArray(v) ? v.entries() : isObj(v) ? Object.entries(v) : null;
    if (!entries) continue;
    for (const [k, x] of entries) {
      if (typeof x === 'number' && !Number.isFinite(x)) v[k] = nonFiniteOf(x);
      else stack.push(x);
    }
  }
  return root;
}

/** O parse do .kg.json no perfil JSON do contrato: { doc } ou { code: 'parse.*' }, com o mesmo vocabulário do YAML
 * e a mesma ordem da referência (_parse_json): vazio, sintaxe, profundidade e surrogate, chave repetida, null, raiz. */
export function parseJson(text) {
  const body = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text; // um BOM inicial; o segundo o JSON.parse recusa
  if (isJsonBlank(body)) return { code: 'parse.empty-document' };
  let value;
  try {
    value = JSON.parse(body);
  } catch {
    return { code: 'parse.yaml-error' }; // o vocabulário de códigos do contrato não tem parse.json-error
  }
  if (collectionDepth(value) > PROFILE_DEPTH || hasLoneSurrogate(value)) return { code: 'parse.yaml-error' };
  if (hasDuplicateKey(body)) return { code: 'parse.duplicate-key' };
  if (value === null) return { code: 'parse.empty-document' };
  if (!isObj(value)) return { code: 'parse.root-not-mapping' };
  return { doc: markNonFinite(value) };
}

// ---------------------------------------------------------------- forma (JSON Schema -> códigos)

const FORM_TYPE = {
  required: 'required', enum: 'enum', type: 'type', pattern: 'pattern', minimum: 'range', maximum: 'range',
  minLength: 'range', maxLength: 'range', const: 'const', additionalProperties: 'unknown-key', format: 'pattern',
  minItems: 'range',
};
// Erros do ajv que só embrulham outros (o jsonschema não os emite): o if/then/else, o propertyNames, os compostos.
const WRAPPERS = new Set(['if', 'propertyNames', 'allOf', 'anyOf', 'oneOf']);

// O caminho do erro, de JSON Pointer para lista com índice numérico onde o valor é lista (absolute_path).
function pathOf(pointer, doc) {
  if (!pointer) return [];
  const out = [];
  let cur = doc;
  for (const raw of pointer.slice(1).split('/')) {
    const part = raw.replace(/~1/g, '/').replace(/~0/g, '~');
    if (Array.isArray(cur)) {
      out.push(Number(part));
      cur = cur[Number(part)];
    } else {
      out.push(part);
      cur = isObj(cur) && Object.hasOwn(cur, part) ? cur[part] : undefined;
    }
  }
  return out;
}

const scopeOf = (path) => ({ meta: 'meta', nodes: 'node', edges: 'edge' })[path[0]] || 'top';
const notIndex = (p) => typeof p !== 'number';

function innerNames(path) {
  let rest = path;
  if (path[0] === 'meta') rest = path.slice(1);
  else if ((path[0] === 'nodes' || path[0] === 'edges') && path.length >= 2 && typeof path[1] === 'number') rest = path.slice(2);
  return rest.filter(notIndex);
}

/** Um erro do ajv -> códigos da suíte: form.<tipo>.<escopo>.<campo> (form_codes da referência). */
export function formCodes(err, doc) {
  if (WRAPPERS.has(err.keyword)) return [];
  const path = pathOf(err.instancePath, doc);
  let scope = path.length ? scopeOf(path) : 'top';
  const prefix = scope !== 'top' ? innerNames(path) : path.filter(notIndex);
  if (err.propertyName !== undefined) { // dentro de propertyNames: o nome da chave
    if (err.keyword === 'pattern') return [`form.pattern.${scope}.${[...prefix, 'key'].join('.')}`];
    if (!SLUG.test(err.propertyName)) return [];
    return [`form.unknown-key.${scope}.${[...prefix, err.propertyName].join('.')}`];
  }
  let kind = FORM_TYPE[err.keyword] || err.keyword;
  if (err.keyword === 'not' && isObj(err.schema) && 'pattern' in err.schema) kind = 'pattern';
  if (err.keyword === 'required') return [`form.${kind}.${scope}.${[...prefix, err.params.missingProperty].join('.')}`];
  if (err.keyword === 'additionalProperties') {
    return [`form.${kind}.${scope}.${[...prefix, err.params.additionalProperty].join('.')}`];
  }
  scope = path.length >= 2 ? scopeOf(path) : 'top';
  if (path.length && typeof path[path.length - 1] === 'number') {
    const lead = scope === 'top' ? path.slice(0, -1).filter(notIndex) : [];
    return [`form.${kind}.${scope}.${[...lead, 'item'].join('.')}`];
  }
  const names = scope !== 'top' ? innerNames(path) : path.filter(notIndex);
  return [`form.${kind}.${scope}.${names.length ? names.join('.') : 'root'}`];
}

// Algum valor sob v (ele incluído) satisfaz hit? Sem recursão (_contains da referência).
function contains(v, hit) {
  const stack = [v];
  while (stack.length) {
    const x = stack.pop();
    if (hit(x)) return true;
    if (Array.isArray(x)) stack.push(...x);
    else if (isObj(x)) stack.push(...Object.values(x));
  }
  return false;
}

/** Número de valor inteiro fora de ±(2^53−1) (is_unsafe_integer da referência). */
export const isUnsafeInteger = (x) => typeof x === 'number' && Number.isInteger(x) && !Number.isSafeInteger(x);

const NESTED = { node: ['provenance'] };

// form.type.<escopo>.<campo> onde algum valor satisfaz hit (_scoped_type_codes da referência).
function scopedTypeCodes(doc, hit) {
  const has = (v) => contains(v, hit);
  const out = new Set();
  for (const [key, value] of Object.entries(doc)) {
    if ((key === 'nodes' || key === 'edges') && Array.isArray(value)) {
      const scope = key === 'nodes' ? 'node' : 'edge';
      for (const item of value) {
        if (hit(item)) out.add(`form.type.${scope}.item`);
        else if (isObj(item)) {
          for (const [k, v] of Object.entries(item)) {
            if ((NESTED[scope] || []).includes(k) && isObj(v)) {
              for (const [kk, vv] of Object.entries(v)) if (has(vv)) out.add(`form.type.${scope}.${k}.${kk}`);
            } else if (has(v)) out.add(`form.type.${scope}.${k}`);
          }
        }
      }
    } else if (key === 'meta' && isObj(value)) {
      for (const [k, v] of Object.entries(value)) if (has(v)) out.add(`form.type.meta.${k}`);
    } else if (has(value)) out.add(`form.type.top.${key}`);
  }
  return out;
}

/** form.type para .nan/.inf em qualquer posição (non_finite_codes). */
export function nonFiniteCodes(doc) {
  return scopedTypeCodes(doc, isNonFinite);
}

/** form.type para o inteiro fora de ±(2^53−1), MUST no .kg.json (unsafe_integer_codes). */
export function unsafeIntegerCodes(doc) {
  return scopedTypeCodes(doc, isUnsafeInteger);
}

// ---------------------------------------------------------------- integridade

const located = (doc, key) => (Array.isArray(doc[key]) ? doc[key].filter(isObj) : []);
const has = (o, k) => Object.hasOwn(o, k);
const get = (o, k) => (has(o, k) ? o[k] : null); // dict.get: ausente e null valem None
const present = (v) => v !== null && v !== undefined;

/** Os códigos de integridade (integrity_located): corpus é Map caminho -> Set de ids, ou null. */
export function integrity(doc, corpus = null, refs = ['trigger', 'on']) {
  const out = [];
  const nodes = located(doc, 'nodes');
  const ids = new Map();
  for (const n of nodes) {
    const id = get(n, 'id');
    if (!present(id)) continue;
    const s = pyStr(id);
    ids.set(s, (ids.get(s) || 0) + 1);
    if (ids.get(s) > 1) out.push('integrity.duplicate-id');
  }
  const touched = new Set();
  for (const e of located(doc, 'edges')) {
    for (const end of ['from', 'to']) {
      const ref = get(e, end);
      if (!present(ref) || !ids.has(pyStr(ref))) out.push(`integrity.dangling-${end}`);
      else touched.add(pyStr(ref));
    }
    for (const key of refs) {
      if (!has(e, key)) continue;
      const ref = e[key];
      if (!present(ref) || !ids.has(pyStr(ref))) out.push(`integrity.dangling-${key}`);
      else touched.add(pyStr(ref));
    }
  }
  for (const e of located(doc, 'external_edges')) {
    for (const end of ['from', 'to']) {
      const ref = get(e, end);
      if (!present(ref)) continue; // from ausente: o grafo inteiro
      if (typeof ref === 'string' && ref.includes('#')) {
        const cut = ref.lastIndexOf('#');
        const path = ref.slice(0, cut);
        const nid = ref.slice(cut + 1);
        if (corpus && EXTERNAL_REF.test(ref) && !(corpus.get(path) || new Set()).has(nid)) {
          out.push('integrity.dangling-external');
        }
      } else if (ids.has(pyStr(ref))) touched.add(pyStr(ref));
      else out.push('integrity.dangling-external-local');
    }
  }
  for (const id of ids.keys()) if (!touched.has(id)) out.push('integrity.orphan-node');
  for (const n of nodes) if (!present(get(n, 'id'))) out.push('integrity.orphan-node');
  return out;
}

// ---------------------------------------------------------------- juntando

/** Os códigos MUST de um documento já parseado: lista ordenada, sem repetição. format 'json': o inteiro inseguro
 * também reprova (no YAML ele só avisaria, e este leitor não mede aviso). */
export function docCodes(doc, validate, corpus = null, format = 'yaml') {
  const out = new Set();
  if (!validate(doc)) for (const err of validate.errors || []) for (const c of formCodes(err, doc)) out.add(c);
  for (const c of nonFiniteCodes(doc)) out.add(c);
  if (format === 'json') for (const c of unsafeIntegerCodes(doc)) out.add(c);
  for (const c of integrity(doc, corpus)) out.add(c);
  if (located(doc, 'edges').some((e) => has(e, 'on'))) out.add('yaml.forbidden-key-on');
  return [...out].sort();
}

/** O parse do formato pedido: 'yaml' (o default) ou 'json'. */
export function parse(text, format = 'yaml') {
  return format === 'json' ? parseJson(text) : parseYaml(text);
}

/** Os códigos MUST de um texto (codes() da referência). */
export function codes(text, validate, { format = 'yaml', corpus = null } = {}) {
  const { doc, code } = parse(text, format);
  return code ? [code] : docCodes(doc, validate, corpus, format);
}

/** O corpus de [(caminho, texto)]: Map caminho -> Set de ids (index_texts). Texto que não parseia entra vazio. */
export function indexTexts(items) {
  const index = new Map();
  for (const [name, text] of items) {
    const { doc } = parseYaml(text);
    const nodes = doc && Array.isArray(doc.nodes) ? doc.nodes : [];
    index.set(name, new Set(nodes.filter((n) => isObj(n) && present(get(n, 'id'))).map((n) => pyStr(n.id))));
  }
  return index;
}

/** A linha do contrato de runner para um texto: { verdict, codes, warnings: null, detail }. */
export function verdictOf(text, validate, opts = {}) {
  const found = codes(text, validate, opts);
  return { verdict: found.length ? 'reject' : 'accept', codes: found, warnings: null, detail: '' };
}
