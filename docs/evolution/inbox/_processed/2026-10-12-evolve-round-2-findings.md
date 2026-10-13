---
title: '2ª rodada do /meta:evolve no adotante: alarme falso da REGRA 97, correções à 1ª rodada e uma contradição radar/selador/contrato'
date: 2026-10-12
from: onion-kg-ssot (produto KG-SSOT, papel adopted)
to: core
type: field-signal
pin: dcdacf9ba196
---

# Sinal: o que a 2ª rodada do /meta:evolve achou

O maestro pediu uma 2ª rodada completa no mesmo dia, pelo comando, sem cache (`wf_0a338f5a-be0` para as 7 dimensões
e `wf_751168af-70c` para o D9). Tudo abaixo é código de vocês, exceto o que está marcado como deste lado.

## Blockers

1. **O gatilho da REGRA 97 (A auto-auditoria do framework tem GATILHO) dá alarme falso.** A perna do delta
   populacional em `.claude/validation/evolve-staleness-check.sh` conta desde a DATA do relatório
   (`--since=<data>T00:00:00`), e não desde o commit que o gravou. Com isso, os 42 artefatos que os updates do mesmo dia
   tocaram contaram como mudança posterior à auditoria. Foi esse alarme que disparou a 2ª rodada.
2. **O localizador do MAQ-0 da 1ª rodada estava errado.** O grep que conta citação como guarda está em
   `evolve-census.sh:155-158`, não em 173-180. O achado segue presente no pin e no HEAD `50cd399d` de vocês. Corrigi
   no grafo daqui; o sinal anterior (`2026-10-12-evolve-maq-findings.md`) leva o número errado.

## Contradição achada em dogfood, deste lado

**Radar, selador e contrato se contradizem sobre a decisão selada pelo maestro.** O `kg-decide-seal.sh` grava a
decisão como `done`, `plane: DEV` e método `testemunho: decisão do maestro…`. O radar avisa `decision-done-em-DEV`.
Promovidas as 5 decisões do ÉPICO 10 a PROD, o aviso some, mas o leitor de referência acusa
`integrity.testimony-in-prod` ×5 (SHOULD). Não há forma de selar uma decisão do maestro sem um dos dois avisos. Aqui
ficou DEV, porque aviso de radar é melhor que dívida nova no contrato. Decidir qual peça cede é de vocês, e talvez do
produto, se a regra de testemunho em PROD precisar distinguir decisão de afirmação de fato.

## Correções à 1ª rodada e achados novos (recommended e opportunistic)

- **MAQ-2:** das 3 lentes "nunca lidas" da seção 7, duas (`guard-lens.md` e `publish-lens.md`) têm objeto vivo aqui e
  carregaram no primeiro Read. A lista erra em 2 de 3 alvos.
- **MAQ-3:** o `pretooluse-env-guard.sh` lê o PADRÃO de um grep como arquivo. `grep -l ".env" docs/README.md` leva
  veto rc 2, e só o valor de `-e/--regexp` é tirado da lista.
- **MAQ-5:** o MAQ-4 da 1ª rodada dizia "sem sítio vivo", e está errado. O extrator da REGRA 59 tira hoje 3 pares de
  produção que só existem em mensagem do lint: `publish-door.sh`, `materialize-door.sh` e `vendor-scrub-form-check.sh`.
- **MAQ-6:** a `publish-lens` chega ao adotante apontando para `ops/`, que não existe aqui.
- **MAQ-7:** o `bash-empty-result-guard.sh` acusa EXIT-CODE-DE-PIPE mesmo quando o último elemento do pipe é o comando
  que interessa (`printf json | bash hook.sh; echo rc=$?`).
- **D7-0:** link morto real em `commands/design/README.md:9` e `design/generate`, para um ADR de design inexistente.
- **D1, D2, D6:** mais 13 achados sem bloqueio, quase todos descrições sobrepostas sem a razão escrita. Os mais
  claros: `test-engineer` sem distinção; `/product:check` contra `/meta:metaspec-validate`; a família de validação de
  tasks.

Refutados na 2ª rodada: D1-0, D2-2, D6-2, D7-1, D7-2 e MAQ-4. Grafo daqui: `docs/analysis/onion-evolution-2026-10-12.kg.yaml`.
