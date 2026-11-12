---
branch: feat/meta-batuta
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 75
findings_fixed: 3
verdict: REPROVADO_E_CURADO
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio artefato, pelo dogfood; o refutador independente vem depois
nota: "tokens 0 = não medido (o agente de execução não vê o próprio consumo); duration_min é aproximado. Os 3 achados são do dogfood do medidor no core, curados no mesmo laço. elenxo false: falta a passada de um refutador independente, que a sessão do core lança depois do commit."
---

# Passada adversarial: `feat/meta-batuta`

## O que muda

- O comando `/meta:baton` (`.claude/commands/meta/baton.md`): o pulso da batuta (baton), no nível 0.
- O medidor `.claude/validation/baton-pulse.sh`: as sessões vivas do repo e da família, as classes `ACTIVE`,
  `IDLE_WITH_QUEUE`, `IDLE_NO_QUEUE`, `PARKED` e `UNREACHABLE`, a fila de dono declarado, a batida silenciosa e as
  lacunas declaradas.
- A cláusula 7 da doutrina da batuta e duas fronteiras novas no «O que ela NÃO promete».
- A bancada `run_baton_pulse_selftests` (6 casos, 6 mutantes provados).
- O grafo da forja `docs/evolution/research/forge-baton-2026-11/` (9 nós, teto 14) e a SYNTHESIS.
- O `baton` no conjunto `pending` do `roles.yaml`, o guia de comandos, o README do meta e as contagens (118 para 119).

## Achados (do dogfood, todos curados)

1. **UNREACHABLE inflado por rastro.** Os faróis velhos (stale) da família entravam como sessão e davam 22
   UNREACHABLE. Agora o farol stale sem peer sai da contagem e vira uma linha de rastro, com o `sweep` indicado.
2. **IDLE_WITH_QUEUE falso.** Um farol vivo do core, fora da lista de peers do harness, saía IDLE_WITH_QUEUE com
   42 itens de fila. Com a lista de peers lida, o farol fora dela agora é UNREACHABLE, e a nota diz por quê.
3. **Validação cara de `--since`.** A data inválida só era recusada depois de o decide-census rodar (cerca de 15 s).
   Agora a forma é conferida antes de medir.

## Mutantes

Os seis casos da `run_baton_pulse_selftests` reprovam cada um contra o seu mutante. A família vizinha
`run_batuta_census_selftests` segue verde.

## Limites declarados

- **Nome fora da regra de inglês.** A doutrina se chama `batuta-doctrine.md`. Por ordem do maestro, o nome não muda
  nesta forja. O rename para inglês é um PR à parte, com os links atualizados.
- **CLAUDE.md com a contagem antiga: o único HARD do lint.** Ele diz 118 comandos, e o inventário diz 119. A
  REGRA 9 (Contagens no CLAUDE.md em sincronia com a SSOT) reprova. O brief proíbe esta forja de editar o
  CLAUDE.md, então a troca de 118 para 119 na linha do inventário fica para a sessão do core, antes do PR.
- **Projeções regeneradas no mesmo commit.** O lint cobrou `docs/backlog.md` (REGRA 62), `docs/onion/kg-read-index.tsv`
  (REGRA 84) e `docs/onion/testing-inventory.md` (REGRA 80), porque os nós, o trace e a família são novos.
- **Lista de peers.** A lista vem do `claude agents --json`. Quando ele falha, a lacuna é declarada e o comando
  manda passar o resultado do ListAgents por `--peers`.
- **Fila sem sessão casada.** O `owner: curadoria` não casa com nenhum rótulo derivado da sessão `onion-curation`.
  Ele espera a linha do maestro no `owners.tsv`.
- **Fase 2 e fase 3.** O casamento com a fila e a medição de um dia são a fase 2; a viagem às portas é a fase 3.
  As duas estão desenhadas no grafo e não foram construídas.
