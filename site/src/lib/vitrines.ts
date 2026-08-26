// vitrines — projeção das vitrines de PR em BUILD, do grafo pr-decision-history-2026-08.kg.yaml.
//
// GRAFO-PRIMEIRO: o grafo é a SSOT da SELEÇÃO (quais PRs, data do merge, URL, vitrine); o texto
// (one-liner/erro-aprendizado-lei) vive em src/data/vitrines.ts. Este módulo JUNTA os dois em build
// e VALIDA: se a vitrine referenciar um PR que o grafo não selecionou, o build FALHA — foi esse
// hand-curar que fez o ticker envelhecer (drift de 2026-08). Agora a SSOT não deixa.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { TICKER, PROVA } from '../data/vitrines';

const repoRoot = fileURLToPath(new URL('../../..', import.meta.url));
const KG = `${repoRoot}/docs/onion/graph/pr-decision-history-2026-08.kg.yaml`;

interface PrMeta { date: string; url: string; vitrines: Set<string> }

function parseKg(): Map<number, PrMeta> {
  const lines = readFileSync(KG, 'utf-8').split('\n');
  const meta = new Map<number, PrMeta>();
  // 1ª passada: nós PR_N → data (verified_at) + URL (trace)
  let cur: number | null = null;
  for (const line of lines) {
    const mId = line.match(/^\s*-\s*id:\s*PR_(\d+)\s*$/);
    if (mId) { cur = Number(mId[1]); meta.set(cur, { date: '', url: '', vitrines: new Set() }); continue; }
    if (/^\s*-\s*id:\s*/.test(line)) { cur = null; continue; } // nó não-PR (hub)
    if (cur != null) {
      const mDate = line.match(/^\s*verified_at:\s*(\S+)/);
      if (mDate) meta.get(cur)!.date = mDate[1];
      const mTrace = line.match(/^\s*trace:\s*"?([^"]+?)"?\s*$/);
      if (mTrace) meta.get(cur)!.url = mTrace[1].trim();
    }
  }
  // 2ª passada: arestas PR_N --TRACES_TO--> E_VITRINE_X → membresia de vitrine
  let ef: number | null = null;
  for (const line of lines) {
    const mF = line.match(/^\s*-\s*from:\s*PR_(\d+)/);
    if (mF) { ef = Number(mF[1]); continue; }
    if (/^\s*-\s*from:\s*/.test(line)) { ef = null; continue; }
    if (ef != null) {
      const mTo = line.match(/^\s*to:\s*E_VITRINE_(\w+)/);
      if (mTo && meta.has(ef)) meta.get(ef)!.vitrines.add(mTo[1].toLowerCase());
    }
  }
  return meta;
}

const KGMETA = parseKg();

function enrich(n: number, requireVitrine?: string): { date: string; url: string } {
  const m = KGMETA.get(n);
  if (!m) throw new Error(`vitrines: PR #${n} não existe no grafo pr-decision-history — a vitrine referencia um PR fora da SSOT (drift?).`);
  if (m.vitrines.size === 0) throw new Error(`vitrines: PR #${n} não é publicável no grafo (sem aresta E_VITRINE_*) — não pode ir à vitrine.`);
  if (requireVitrine && !m.vitrines.has(requireVitrine)) {
    throw new Error(`vitrines: PR #${n} não está na vitrine "${requireVitrine}" no grafo (está em: ${[...m.vitrines].join(', ') || 'nenhuma'}). Reclassifique no .kg.yaml ou troque o card.`);
  }
  return { date: m.date, url: m.url };
}

export function ticker() {
  return TICKER.map((t) => ({ ...t, ...enrich(t.n) }));
}

export function prova() {
  return PROVA.map((c) => ({ ...c, ...enrich(c.n, 'prova') }));
}
