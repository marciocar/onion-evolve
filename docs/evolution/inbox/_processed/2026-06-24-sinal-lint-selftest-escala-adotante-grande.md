---
title: 'Sinal de campo — lint-selftest.sh é O(fixtures × tamanho-do-repo): inviável em adotante grande'
date: 2026-06-24
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: update vendorizado `.claude/` → source_commit 025225e286d8 + escalabilidade do lint-selftest.sh
type: federation-doc-bridge (feedback de adoção — não-solicitado)
status: update aplicado e commitado neste adotante (develop, commit 04ec3f1; housekeeping af28b0f)
---

# Sinal de campo ao core — lint-selftest escala mal em adotante grande (2026-06-24)

> Doc-bridge derivado→core. Confirmação de adoção + **um achado de performance que só um adotante com
> `docs/` grande revela** (o core tem `docs/` pequeno e nunca veria isto). Modo `standalone`: o core
> consome quando rodar a co-evolução do seu lado (humano-no-loop transporta).

## O que foi adotado

- **025225e286d8** aplicado via `/meta:adopt --update --integration-branch rhilo/main`, commitado em
  `develop` (commit `04ec3f1`). `.onion-version` → `source_commit: 025225e286d8` + carimbo
  `integration_branch: rhilo/main`.
- **Superfície do delta (36 arquivos, +1.460/-61):** vertical de design (`/design:generate`,
  `/design:identity`, `@brand-generator`, `@design-system-specialist`, `utils/design-{source,sink}/`,
  `lint-design-tokens.sh`); `/meta:co-deliver` + `utils/co-evolution/co-deliver.sh`;
  `merge-prettierignore.sh` + template; `lint-selftest.sh`; KBs e meta-specs atualizados (49→51 agentes).

## ✅ Loop fechado — o sinal anterior de prettierignore FOI atendido

O sinal de 2026-06-22 (`_processed/2026-06-22-sinal-prettier-vendor-quebra-ssot.md`) pediu que o
`/meta:adopt` **provisionasse** a proteção do formatador. Este delta entregou exatamente isso:
`merge-prettierignore.sh` + `prettierignore-onion.tpl`, e o `adopt.md` atualizado agora o **invoca**
na Fase 3/--update (passo 5, `bash .../merge-prettierignore.sh "$DEST"`). Confirmado idempotente neste
adotante (no-op: `.prettierignore` já protegido). **Obrigado — recurso correto, operação correta.**

## 🔴 Achado principal (acionável) — o lint-selftest é O(fixtures × tamanho-do-repo)

Ao rodar `bash .claude/validation/lint-selftest.sh` neste adotante, ele **passa (45/0, exit 0)** —
funcionalmente correto, todas as guardas reagem. **Mas leva ~10-17 min** e estoura qualquer timeout
razoável de CI/sessão. Medição neste repo:

| Métrica                                                 | Valor                                                      |
| ------------------------------------------------------- | ---------------------------------------------------------- |
| `lint-artifacts.sh` (1 passada)                         | **41 s**                                                   |
| Fixtures no `manifest.tsv`                              | **25** (modos lint/fix re-rodam o lint inteiro no sandbox) |
| Arquivos em `docs/` (copiados via `cp -a` por selftest) | **463**                                                    |
| Wall-clock total estimado                               | **~10-17 min**                                             |

**Causa raiz (hipótese):** dois custos lineares amplificados pelo nº de fixtures:

1. **Sandbox pesado:** o selftest faz `cp -a .claude/ + docs/ + CLAUDE.md` para um `mktemp` (linhas 56-58).
   Ele copia `docs/` **inteiro** "para o `inventory.sh` ver os números reais" — mas `inventory.sh` só conta
   `.claude/{agents,commands,skills}` + KBs (`docs/knowledge-base/`). Os 463 docs de **domínio** do
   adotante (`wrr/` 70, `api/` 39, `technical-context/` 84, etc.) são copiados à toa.
2. **Lint completo por fixture:** cada `run_lint_fixture`/`run_fix_fixture` chama `lint-artifacts.sh` no
   sandbox (linha 108/168), que **re-escaneia todo `docs/`** (41 s/passada aqui). Com ~15-20 fixtures
   lint/fix → 10-13 min só aí.

No core (`docs/` pequeno) `lint-artifacts.sh` roda em ~1-2 s, então 25× é tolerável e o problema é
invisível. Num adotante real com `docs/` grande, o produto explode.

## Recomendação ao core (candidato a evoluir o lint-selftest)

Não prescrevo a implementação — só o alvo. Sugestões, da mais barata à mais estrutural:

- **Sandbox mínimo:** copiar para o sandbox só o que o selftest exercita + o que `inventory.sh` precisa
  contar (`.claude/` + `docs/knowledge-base/` + `docs/meta-specs/`), **não** `docs/` inteiro. Corta o I/O
  do `cp -a` e encolhe a superfície que o `lint-artifacts.sh` escaneia.
- **Escopo de scan no lint:** se o `lint-artifacts.sh` aceitasse limitar o scan aos paths relevantes (ou
  cacheasse a parte invariável entre fixtures), o selftest reusaria o caro trabalho de base.
- **Guard-rail de tempo:** o próprio selftest poderia `log()` o tamanho do repo e avisar quando o
  wall-clock projetado passar de um limiar — hoje ele "parece travado" para quem roda com timeout (foi
  minha 1ª leitura, errada: não trava, só é lento).

Generaliza para **qualquer adotante grande** — quanto mais maduro o repo (mais docs de domínio), pior.
O princípio espelha o do prettierignore: o que é barato no core (repo pequeno) vira armadilha no campo.

## NÃO pedido (deliberado)

- Nenhuma ação obrigatória ao core. Feedback voluntário de um adotante real.
- O selftest **funciona** (45/0) — isto é otimização, não correção de bug. Não bloqueia nada neste adotante.

## Premissa inalterada — o adotante é cego

Como nos sinais anteriores: sem comunicação viva e sem o repo do core no escopo, este adotante só "vê" o
que for commitado neste `inbox/` E transportado por humano. **Silêncio do core = invisível.** A resposta a
este sinal precisa ser anúncio explícito no `inbound/`.
