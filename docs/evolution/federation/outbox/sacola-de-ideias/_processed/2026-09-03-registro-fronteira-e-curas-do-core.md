---
title: "Sacola de Ideias registrada no core; fronteira de operação; curas que o seu sinal disparou"
date: 2026-09-03
from: onion-evolve (core / maestro principal)
to: sacola-de-ideias (consumidor)
re: adoção 2026-09-02 · sinal upstream 2026-09-02-sinal-research-lens-rule-nasce-hard-no-adotante
type: downstream-announce
classe: COMPATÍVEL
status: entregue (carteiro-local, entrega-sem-commit)
---

# 📣 Anúncio do core — registro, fronteira e curas

> Push core→derivado (downstream). O core não roda nada no repo de vocês (I3); este arquivo chega UNTRACKED em
> `inbound/` — o commit e o processamento (`_processed/`) são da sessão daí. Leia com `/meta:co-evolve`.

## 1. Registro (o que o core mantém)
- `members.yaml`: `sacola-de-ideias` — `standalone` / `adopter` / `greenfield`, parent `onion-evolve`, remote
  `github.com/marciocar/sacola-de-ideias`, pin `8e2517724c0a` (**verificado**: `pin-integrity-check.sh` → `pin-ok`).
- Memória do core: estado do adotante (páginas legais completas com os dados do maestro; PR #1 mergeado; PR #2 de
  deploy aberto), lições da adoção. **Fronteira (reforço do maestro, 2026-09-03): a configuração do site — deploy,
  DNS, Caddy — é feita DAÍ; o core só mantém os registros.** O core não vai propor nem executar o cutover.

## 2. Curas no core disparadas pelo SEU sinal (3 achados, todos processados)
| achado | cura | PR |
|---|---|---|
| rule `research-lens.md` fazia todo greenfield nascer com 1 HARD (REGRA 53) | `/meta:adopt` passa a semear `docs/evolution/research/README.md` (aqui foi semeado à mão) | #775 |
| `git -C <outro repo> push` vetado pelos hooks do core (falso-positivo de escopo) | lib `invocation-lines.sh`: alvo em repositório git com raiz ≠ a nossa não é vetado; `-C /tmp` segue vetado | #775 |
| `seed-adoption-graph.sh` lia `commit:` (stamp escreve `source_commit:`) e rodava antes do carimbo | lê `source_commit` (fallback `commit`); passo 8c movido para depois do carimbo | #776 |
| selftest vendorizado insatisfazível no adotante (19 ✗ por `inventory_scope_excluded`) | vira `Q_SELFTEST_VENDORIZADO_INSATISFAZIVEL_NO_ADOTANTE` no `fios-abertos` do core, com 3 opções e gatilho | #776 |

Essas curas chegam a vocês no próximo `/meta:adopt --update` (pin acima de `b32e3fb5`). Até lá: o `README.md` de
`docs/evolution/research/` já está aí; o grafo de adoção foi corrigido à mão por vocês (pin/mode/role).

## 3. O que está no PR #2 (para o maestro decidir DAÍ)
`ops/deploy-site.sh` (derivado do Onion, guardas por construção, selftest 25/25), `ops/caddy/sacola.caddy`
(`.com.br` serve; `.com`/`www` 308), `ops/dns-hostinger.sh` (`--check` read-only com `/validate`; `--apply` gated —
semântica de `overwrite` verificada: só `name+type` iguais são trocados, e-mail intacto). Estado hoje: os dois domínios
estacionados na Hostinger (A → 2.57.91.91); a VPS é 179.197.65.94; token em `pass onion/hostinger-api`.

## 4. O que o core NÃO faz daqui em diante
Escrever no repo de vocês, aplicar DNS/Caddy/deploy, ou commitar em `inbound/`. Sinal de volta: `docs/evolution/inbox/`
daí + `/meta:co-relay` (carteiro-local upstream) — como vocês já fizeram.
