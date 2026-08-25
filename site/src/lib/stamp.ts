// site-stamp — números do site derivados da SSOT em BUILD TIME, nunca hand-coded.
//
// As TRÊS CLASSES DE NÚMERO (KB de identidade §6 — declarar a classe é parte do
// contrato; o redrift de 2026-08-03 nasceu de misturá-las em silêncio):
//   · inventario-vivo    — lido de docs/onion/inventory.md (SSOT gerada do filesystem)
//   · congelado-no-tempo — medido no instante do build e carimbado com a data
//   · estado-de-programa — afirmação sobre o runtime (subdomínios, serviços)
import { readFileSync, readdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// site/src/lib/ → raiz do repo
const repoRoot = fileURLToPath(new URL('../../..', import.meta.url));

function inventoryTable(): string {
  return readFileSync(`${repoRoot}/docs/onion/inventory.md`, 'utf-8');
}

function countFrom(md: string, row: string): number {
  const re = new RegExp(`\\|\\s*${row}\\s*\\|\\s*\\*\\*(\\d+)\\*\\*\\s*\\|`);
  const m = md.match(re);
  if (!m) throw new Error(`site-stamp: linha "${row}" não encontrada no inventory.md — a SSOT mudou de forma?`);
  return Number(m[1]);
}

export interface Stamp {
  classe: 'inventario-vivo' | 'congelado-no-tempo' | 'estado-de-programa';
  em: string; // ISO date do build
}

export function inventario() {
  const md = inventoryTable();
  const em = new Date().toISOString().slice(0, 10);
  return {
    comandos: countFrom(md, 'Comandos invocáveis'),
    agentes: countFrom(md, 'Agentes'),
    skills: countFrom(md, 'Skills'),
    kbs: countFrom(md, 'Knowledge Bases'),
    stamp: { classe: 'inventario-vivo', em } as Stamp,
  };
}

export function historiaGit() {
  const em = new Date().toISOString().slice(0, 10);
  const commits = Number(
    execSync('git rev-list --count HEAD', { cwd: repoRoot, encoding: 'utf-8' }).trim()
  );
  // contagem mensal para a curva da autobiografia (AAAA-MM → n)
  const porMes: Record<string, number> = {};
  const datas = execSync('git log --format=%ad --date=format:%Y-%m', {
    cwd: repoRoot,
    encoding: 'utf-8',
    maxBuffer: 32 * 1024 * 1024,
  })
    .trim()
    .split('\n');
  for (const d of datas) porMes[d] = (porMes[d] ?? 0) + 1;
  return {
    commits,
    porMes,
    stamp: { classe: 'congelado-no-tempo', em } as Stamp,
  };
}

/**
 * Plugins publicáveis no marketplace — nomes e CONTAGEM lidos dos manifestos
 * (`.claude/utils/marketplace/verticals/*.manifest.sh`), a SSOT do que se publica.
 * Classe inventario-vivo: se um plugin nasce ou sai, a página muda sozinha.
 * O núcleo `onion` vem primeiro; o resto em ordem alfabética.
 */
export function pluginsPublicados() {
  const dir = `${repoRoot}/.claude/utils/marketplace/verticals`;
  const em = new Date().toISOString().slice(0, 10);
  const nomes = readdirSync(dir)
    .filter((f) => f.endsWith(".manifest.sh") && !f.startsWith("__"))
    .map((f) => {
      const m = readFileSync(`${dir}/${f}`, 'utf-8').match(/^PLUGIN_NAME="([^"]+)"/m);
      if (!m) throw new Error(`site-stamp: manifesto sem PLUGIN_NAME — ${f}`);
      return m[1];
    })
    .sort((a, b) => (a === 'onion' ? -1 : b === 'onion' ? 1 : a.localeCompare(b)));
  return { nomes, stamp: { classe: 'inventario-vivo', em } as Stamp };
}
