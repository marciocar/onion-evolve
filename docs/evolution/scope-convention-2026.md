# Convenção de escopo Onion (framework → empresa → time → pessoa)

> **RFC-0005 Fase 1** (cavalgar o nativo). Doutrina + convenção — **zero código de runtime**. Define ONDE cada
> camada de escopo vive e COMO os 3 planos (cognitivo/config/conhecimento) resolvem a herança, fechando o loop
> do `compose-settings.sh` (F1 do 1º slice de escopo). Fundamentação: `docs/evolution/research/scope-inheritance-2026/`.

## Os 3 planos × onde cada escopo vive

| Escopo | Cognitivo (CLAUDE.md/skills/agentes) | Config (`settings.json`) | Conhecimento (verdade) |
|--------|--------------------------------------|--------------------------|------------------------|
| **framework** | `.claude/` vendorizado (onion/vendor) | `.claude/settings.json` do vendor (base) | doutrina do core (KB/meta-specs) |
| **empresa** | `.claude/` do repo adotado (customização da org) | `.claude/settings.json` do repo | ADRs/contexto da org |
| **time** | **`<time-dir>/.claude/CLAUDE.md`** + skills no dir do time | **`<time-dir>/.claude/settings.json`** | regras do time |
| **pessoa** | `~/.claude/CLAUDE.md` (user) + `.claude/settings.local.json` | `~/.claude/settings.json` (user) | preferências pessoais |

## Plano 1 — Cognitivo: CAVALGAR o nativo (zero código)

O Claude Code **já cascateia** o plano cognitivo:
- **CLAUDE.md hierárquico**: a sessão lê o `CLAUDE.md` da **árvore de diretórios** (raiz → cwd) + `~/.claude/CLAUDE.md`
  (user) + imports `@path`. → **time-dentro-do-repo é nativo**: coloque o `CLAUDE.md`/skills do time no
  **subdiretório do time**; ao rodar o Claude ali, ele compõe framework + empresa + time + pessoa em runtime.
- **Skills/agentes**: user (`~/.claude/`) + project (`.claude/`) coexistem por precedência nativa.
- **Convenção:** `<time-dir>/.claude/` (CLAUDE.md + skills) por time; `~/.claude/` por pessoa. Nada a construir.

## Plano 2 — Config: o GAP, resolvido por `compose-settings.sh` (o loop que fecha)

O `settings.json` **NÃO** herda pela árvore de diretórios (self-contained por diretório — o único gap real).
O nativo cascateia managed → user → project → local, **mas não** o subdiretório do TIME. Então, p/ o time:

```bash
# settings.json EFETIVO de um membro de time (base → mais específico):
bash .claude/utils/scope/compose-settings.sh \
  <vendor>/.claude/settings.json \        # framework (base)
  .claude/settings.json \                  # empresa (repo)
  <time-dir>/.claude/settings.json \       # time (o que o nativo NÃO herda)
  ~/.claude/settings.json \                # pessoa (user)
  > <time-dir>/.claude/settings.json.effective
```

O `compose-settings` faz merge type-aware (objetos recursam · arrays unem: hooks/permissions · escalares
last-wins) + **proveniência-por-chave** via `--show-scope` (paridade `git config --show-scope`; `--provenance`
é alias). **O nativo cobre user/project/local; o `compose-settings` cobre o TIME (subdiretório) + a base
vendor explícita.** É exatamente o gap que ele preenche.

```bash
# Quem setou cada chave? (auditável — importante p/ regulado)
bash .claude/utils/scope/resolve-scope-layers.sh <time-dir> --show-scope
# layers: empresa time pessoa · role: adopted · form: docs-only     ← role/forma lidos do .onion-version
# pessoa	theme="light"	# sobrepõe: empresa                          ← sobreposto (vencedor + sombreadas)
# time	model="opus"                                                 ← set (1 camada)
# empresa	permissions.allow[0]="Bash(git *)"
# time	permissions.allow[1]="Bash(nx *)"	# merged                    ← array união, origem por elemento

# Formato JSON p/ auditoria (regulado): {meta:{layers,role,form}, keys:{<path>:{value,scope,status,overrides}}}
bash .claude/utils/scope/resolve-scope-layers.sh <time-dir> --show-scope --json
```

Camadas aceitam rótulo explícito no compose (`empresa=path.json`); sem rótulo, o basename. A cada execução o
script verifica a invariante `strip(provtree) == compose` (a proveniência nunca deriva do merge real —
declarado≠verificado; divergência = exit 4).

## Plano 3 — Conhecimento: `SUPERSEDES` (gated, Fase 3)

Override de VERDADE por escopo (a regra do time supera a do framework **sem apagá-la**) usa o `SUPERSEDES` do
KG (`/meta:kg`) — ortogonal ao merge de arquivo ("git merge não reconcilia verdades"). **Gated atrás de dogfood**
(RFC-0005 §7 Fase 3). Não é este slice.

## Invariantes
- **Versão × escopo separados**: escopo = camadas que compõem (esta convenção); versão = `vendor-branch` no tempo.
  **Branch NÃO é escopo** (não compõe — RFC-0005 §3).
- **Cavalgar o nativo** (non-friction): o plano cognitivo é grátis; só o `settings.json` do time exige o compose.
- **Never-clobber**: o compose é merge determinístico + proveniência, não clobber.

## O que fica p/ design/dogfood
- ~~**Resolver da cadeia** (`resolve-scope-layers.sh`)~~ — ✅ entregue: descobre empresa→time→pessoa, compõe e
  repassa `--show-scope` com rótulos canônicos + role/forma do stamp.
- **Dogfood no Grana.Ai**: empresa(granaai)+time(desenvolvimento)+pessoa(mauricio) no nx monorepo (próximo passo #3).
