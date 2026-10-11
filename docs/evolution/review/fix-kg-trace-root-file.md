---
branch: fix/kg-trace-root-file
pr: pendente
date: 2026-10-11
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 40
verdict: REPROVADO_E_CURADO
nota: SAC-81 — arquivo da raiz entra no índice de leitura; ./ normalizado no gerador e no hook
reviewer: passada adversarial por subagente refutador (default reprovado) + 9 mutantes executados
REVISOU: true
---

# Resíduo — `fix/kg-trace-root-file`

**Origem:** SAC-81, sinal de campo de um adotante (inbox 2026-10-08), conferido no código. A cura
foi selada em 2026-10-08.

## O defeito, medido

- `kg-trace-resolve.sh`, regra (b): exige `/` no alvo, então `trace: "CLAUDE.md"` caía em
  SKIP_NOTPATH e nunca chegava ao `--emit-index`.
- `kg-read-leg.sh`: tira o `./` do caminho lido, mas o índice guardava o alvo cru. `./CLAUDE.md`
  no índice nunca casaria.
- Efeito: o CLAUDE.md, que é a âncora mais importante de um adotante, ficava sem vigilância do hook.

## A cura

- Nome solto entra quando é **arquivo rastreado na raiz com o nome exato**. O gerador confere com
  `git ls-files` e comparação de linha inteira, mais `-f`. Fica fora se houver homônimo ao lado do
  grafo ou no pai dele, porque aí é ambíguo.
- `./` (um ou mais) normalizado nos dois lados: no gerador antes de julgar e de emitir, e no hook.
- O teste de hostname é pulado para o arquivo da raiz, porque `CLAUDE.md` tem ponto no 1º segmento.

## Índice, antes e depois (core)

2243 linhas antes, 2250 depois, e nenhuma linha removida. As 7 linhas novas:

```
CLAUDE.md  C_IDENTITY_CANON                        docs/onion/graph/onion-identity-2026-07.kg.yaml
CLAUDE.md  C_p4_gate_visibility                    docs/onion/graph/m3-federation-admin-2026-07.kg.yaml
CLAUDE.md  D_FAMILIA_TEM_DOIS_REGIMES_2026_09      docs/onion/graph/onion-identity-2026-07.kg.yaml
CLAUDE.md  E_CLAUDE_MD                             docs/onion/graph/onion-identity-2026-07.kg.yaml
CLAUDE.md  E_F3_BYPASS_EM_PROJECT_SETTINGS_IGNORADO docs/evolution/research/radar-E3-2026-09-02/…
CLAUDE.md  E_F3_PERMISSION_PROMPTS_NONE            docs/evolution/research/radar-E3-2026-09-03/…
LICENSE    SY6_ev_licenca_mit                      docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml
```

Na rodada humana: 2250 julgáveis, 0 TARGET-MISSING. Dogfood do hook vivo: um Read do CLAUDE.md
absoluto nomeia os 6 nós, e um Read de `./LICENSE` nomeia 1.

## Bancada: família `kg_trace_root_file` (7 casos, `LC_ALL=C`)

Casos: (a) raiz sem barra entra · (b) inexistente, quase-igual (`README` com `README` solto no
disco), diretório, não-rastreado e apagado ficam fora · (c) homônimo ao lado do grafo fica fora ·
(d) `./README.md` vira `README.md` no índice · (e) inexistente não vira TARGET-MISSING · (f) hook:
`./CLAUDE.md` e `././CLAUDE.md` casam · (g) `./SUMIDO.md` segue TARGET-MISSING e `./VIZINHO.md` entra como caminho do grafo. As famílias vizinhas `kg_read_leg` e `kg_trace_resolve`
seguem verdes: 27/27.

## Mutantes (via `mutate-and-restore`, 11, todos morreram)

| mutante | caso que reprovou |
|---|---|
| M1 sem a exceção da raiz | (a) |
| M2 sem `-f` | (e): o rastreado-apagado vira TARGET-MISSING |
| M3 `ls -A` no lugar de `git ls-files` | (b) |
| M4 casamento por prefixo (sem `\n` final) | (b) |
| M5 sem a trava de ambiguidade | (c) |
| M6 sem normalizar `./` no gerador | (d) |
| M7 sem pular o teste de hostname | (a) |
| M8 sem normalizar `./` no hook | (f) |
| M9 hook tira um `./` só | (f) |
| M10 (b) lê o alvo normalizado | (g) |
| M11 (c) lê o alvo normalizado | (g) |

## Teto declarado (não é defeito)

- Se o arquivo da raiz **sumir**, o nome volta a parecer palavra solta e a guarda **cala**: não
  acusa TARGET-MISSING. Acusar exigiria julgar todo nome solto, que é o que a regra (b) evita.
- Em disco case-insensitive (macOS) o `-f` casaria `readme.md`. Quem trava é a comparação exata
  contra o `git ls-files`, e isso não dá para exercitar no Linux.

## Paridade de leitores (REGRA 31)

Fora o hook, nenhum leitor resolve `trace:` contra o disco (varredura de `.claude/` e `ops/`).
REGRA 84 (lint), regen-core-projections e o regen-ssot-projections da adoção usam o **mesmo**
gerador. Não há 2ª gramática a alinhar.

## Gate

Commits com `--no-verify` declarado (checkpoint). O que validou: as famílias tocadas, os mutantes
e o dogfood do hook. O veredito vale no `pr-finalize --push` e no CI.

## Passada adversarial (subagente refutador, default reprovado): REPROVADO e CURADO

**Achado real, alto: regressão do `./X`.** A 1ª redação normalizava o `./` **antes** das regras
(b) e (c). Com isso `./missing.md` perdia a barra, caía em não-caminho, e um TARGET-MISSING que
antes reprovava ficava **calado**. `./SYNTHESIS.md`, ao lado do grafo, também saía de vigilância.
O refutador mediu com o gerador da `origin/main` lado a lado: antes eram 4 julgáveis e 1
TARGET-MISSING, depois 3 julgáveis e 0 TARGET-MISSING.

**Cura:** (b) e (c) leem o alvo **original** (`_orig`). A normalização só alimenta o julgamento em
disco e o índice. Ganho colateral: a 2ª raiz agora emite `gdir/X`, e não mais `gdir/./X`. A cura
tem caso e mutantes: o caso (g) da bancada e os mutantes M10 e M11 (fazer (b) ou (c) lerem o alvo
normalizado). Os dois morreram em (g). O índice do core ficou byte a byte igual ao do 1º commit:
nenhum `trace:` do corpus usa `./`.

**Achados baixos, aceitos e declarados:**
- Symlink rastreado na raiz entra porque o `-f` segue o link. O efeito é só uma linha a mais no
  índice, nunca um TARGET-MISSING falso.
- O hook não casa `//` nem `x/../` no caminho lido. Já era assim antes, não é regressão.

**Sem achado** nos demais pontos: caixa, `README` contra `README.md`, quoting do `ls-files`,
submódulo, `.env` não rastreado, prosa.

Placar final: findings_total 3 · real 1 · curado 1.
