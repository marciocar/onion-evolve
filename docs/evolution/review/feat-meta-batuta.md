---
branch: feat/meta-batuta
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 10
findings_blocking: 3
tokens: 0
duration_min: 120
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: true
reviewer: "subagente refutador independente lançado pela sessão do core (mandato REFUTAR), provas em scratch-1111/refute-baton/; curas pelo agente de execução"
nota: "tokens 0 = não medido (o agente de execução não vê o próprio consumo nem o do refutador); duration_min é aproximado, forja mais cura. 10 achados do refutador: 3 bloqueantes curados com caso e mutante (2) ou regeneração (1), 4 limites baratos curados, 3 limites declarados (não curados, por desenho). Antes dele, a passada própria pelo dogfood achou e curou 3 defeitos, descritos no corpo."
---

# Passada adversarial: `feat/meta-batuta`

## O que muda

- O comando `/meta:baton` (`.claude/commands/meta/baton.md`): o pulso da batuta (baton), no nível 0.
- O medidor `.claude/validation/baton-pulse.sh`: as sessões vivas do repo e da família, as classes `ACTIVE`,
  `IDLE_WITH_QUEUE`, `IDLE_NO_QUEUE`, `PARKED` e `UNREACHABLE`, a fila de dono declarado, a batida silenciosa e as
  lacunas declaradas.
- A cláusula 7 da doutrina da batuta e duas fronteiras novas no «O que ela NÃO promete».
- A bancada `run_baton_pulse_selftests` (8 casos, 8 mutantes provados).
- O grafo da forja `docs/evolution/research/forge-baton-2026-11/` (9 nós, teto 14) e a SYNTHESIS.
- O `baton` no conjunto `pending` do `roles.yaml`, o guia de comandos, o README do meta e as contagens (118 para 119).

## Achados do refutador independente (10)

**Bloqueantes (3, curados):**

1. **`parked.tsv` ilegível virava «ninguém parado».** Com chmod 000, ou com um diretório no lugar, a sessão parada
   saía IDLE_WITH_QUEUE. Agora o arquivo que existe e não se lê é lacuna e fail-closed: toda sessão alcançável sai
   `PARK_UNMEASURED`, sem oferta. Caso (g) da bancada, com mutante.
2. **`--quiet --since` sem `--last-sha` escondia mudança real.** Uma sessão que caiu ou um PR que ficou vermelho
   passavam calados. Agora «sem mudança» só sai quando o sha bate; o `--since` só acrescenta eventos. Caso (h) da
   bancada, com mutante.
3. **REGRA 62 (Projeção GERADA em sincronia com a fonte (docs/backlog.md)).** O `docs/backlog.md` não tinha sido
   regenerado depois dos selos do maestro. Regenerado pela projeção do `/meta:backlog`, junto com o índice de leitura.

**Limites baratos (4, curados):**

4. O sha cobre os ids dos sinais pendentes, não só a contagem: trocar um sinal por outro muda o sha.
5. Com o gh indisponível ou `--no-gh`, a seção de PRs diz «NÃO MEDIDO» em vez de «nenhum», e a linha única do
   `--quiet` leva o aviso. O mesmo vale para sinais, perguntas e parada.
6. Um diretório de perguntas ilegível é lacuna, não «0».
7. O comando diz onde salvar o JSON dos peers: no scratchpad ou em `~/.local/state/onion/baton/`, nunca no repo.

**Limites declarados (3, não curados por desenho):**

8. **Farol cujo dono é o daemon.** Um farol pode registrar como dono o processo do daemon do harness, não a sessão.
   Ele sai «vivo» pelo `session-beacon.sh` e só cai em UNREACHABLE quando a lista de peers é lida e não o traz.
9. **Sessão de outra conta sai UNREACHABLE.** A lista de peers é a do usuário e da conta que rodam o pulso. A sessão
   viva de outra conta Claude, com farol no repo, não está nela e sai UNREACHABLE. A causa não é estar morta.
10. **Rótulo derivado de nome e pasta.** O casamento `owner:` com sessão é heurístico (nome, pasta, pasta sem `onion-`,
    `core`) até o `owners.tsv` declarar. O que não casa sai como fila sem sessão, nunca atribuído.

## Achados da passada própria pelo dogfood (antes do refutador, curados)

1. **UNREACHABLE inflado por rastro.** Os faróis velhos (stale) da família entravam como sessão e davam 22
   UNREACHABLE. Agora o farol stale sem peer sai da contagem e vira uma linha de rastro, com o `sweep` indicado.
2. **IDLE_WITH_QUEUE falso.** Um farol vivo do core, fora da lista de peers do harness, saía IDLE_WITH_QUEUE com
   42 itens de fila. Com a lista de peers lida, o farol fora dela agora é UNREACHABLE, e a nota diz por quê.
3. **Validação cara de `--since`.** A data inválida só era recusada depois de o decide-census rodar (cerca de 15 s).
   Agora a forma é conferida antes de medir.

## Mutantes

Os oito casos da `run_baton_pulse_selftests` reprovam cada um contra o seu mutante (os casos (g) e (h) nasceram dos achados 1 e 2 do refutador). A família vizinha
`run_batuta_census_selftests` segue verde.

## Limites declarados

- **Nome fora da regra de inglês.** A doutrina se chama `batuta-doctrine.md`. Por ordem do maestro, o nome não muda
  nesta forja. O rename para inglês é um PR à parte, com os links atualizados.
- **CLAUDE.md:** a contagem de 119 comandos foi corrigida pela sessão do core num commit próprio (esta forja não
  edita o CLAUDE.md).
- **Projeções regeneradas no mesmo commit.** O lint cobrou `docs/backlog.md` (REGRA 62), `docs/onion/kg-read-index.tsv`
  (REGRA 84) e `docs/onion/testing-inventory.md` (REGRA 80), porque os nós, o trace e a família são novos.
- **Lista de peers.** A lista vem do `claude agents --json`. Quando ele falha, a lacuna é declarada e o comando
  manda passar o resultado do ListAgents por `--peers`.
- **Fila sem sessão casada.** O `owner: curadoria` não casa com nenhum rótulo derivado da sessão `onion-curation`.
  Ele espera a linha do maestro no `owners.tsv`.
- **Fase 2 e fase 3.** O casamento com a fila e a medição de um dia são a fase 2; a viagem às portas é a fase 3.
  As duas estão desenhadas no grafo e não foram construídas.

## Refutador independente, 2ª passada

APROVADO COM LIMITES sobre o a4144cab7: os 3 bloqueios e os 3 limites curados resistiram, sem regressão (30 de 30, lint 0 HARD). Limites novos declarados: o «NÃO MEDIDO» de PRs e sinais casa o texto do aviso do decide-census.sh, e a batida que fala não nomeia qual sessão caiu (só o sha e as contagens).
