---
branch: fix/preflight-always-runs
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: a própria sessão executora (SAC-141), sem revisor independente; ataques por 3 mutantes e dogfood do pr-finalize real sem a variável de checkpoint
nota: "passada feita pelo executor, não por um revisor independente. tokens e duration_min ficam em 0 porque não foram medidos (não é custo zero). O hash do diff é carimbado no pr-finalize."
---

# Passada adversarial — `fix/preflight-always-runs`

Decisão do maestro de 2026-10-15 (`D_PRE_VOO_SEMPRE_E_SOMBRA`, grafo `preflight-gap-2026-10`), tomada sobre
a pesquisa da SAC-141: 29 reprovações do CI de 10-07 a 10-14, sendo 9 casos que o pré-voo pegaria se tivesse
rodado (ele só rodava com `ONION_FINALIZE_CHECKPOINT=1`, passado em 21% dos fechamentos) e 20 de famílias que
ele não seleciona.

## O que muda

- O corpo do pré-voo sai do `pr-finalize.sh` para `ops/testing/preflight-run.sh`, com **cache pela árvore do
  índice** (`git write-tree` mais as famílias, no git-common-dir). O `pr-finalize` o roda **sempre**; o escape
  `ONION_FINALIZE_SKIP_PREFLIGHT=1` continua e agora diz que pulou.
- O `pre-push`, para branch com PR aberto e commit que o `pr-finalize` não julgou, roda o mesmo pré-voo na
  worktree destacada depois do lint verde, e recusa quando ele reprova.
- `ops/testing/preflight-shadow.sh record` roda em paralelo ao pré-voo: chama o seletor do nível PR do CI sobre
  merge-base...HEAD e grava uma linha TSV fora do índice com a lacuna. Nunca muda o rc. `report` é o consumidor,
  e é a entrada do `Q_FAMILIAS_BARATAS_DO_MAPA_NO_PRE_VOO` (gatilho: ~2 semanas de dados).

## Casos e mutantes

- `machine_slots` (g) agora roda o `pr-finalize` **sem** a variável e exige o pré-voo; (g2) exige que a
  re-rodada com a mesma árvore pule pelo cache e diga.
- `preflight_shadow` (família nova): (a) lacuna gravada e anunciada; (b) CI completo vira ALL; (c) seletor
  quebrado dá rc 0, "sombra indisponível" e nada gravado; (d) o report lê o que foi gravado; (e) os dois pontos
  chamam o mesmo corpo, sem a condição do checkpoint.
- `preflight_families` (b) passa a conferir o ambiente do runner em `preflight-run.sh`.
- Mutantes (reprovam): M1 recoloca a condição do checkpoint → (g), (g2) e (e); M2 cache que nunca pula →
  (g2); M3 sombra que propaga a falha do seletor → (c).
- **Achado do M1, curado:** com o pré-voo desligado, o (g) **abortava a bancada inteira** (exit 2) em vez de
  reprovar: o `sed` sobre o `args.log` ausente saía 2 numa atribuição sob `set -e`, e a mensagem de falha
  tinha um `grep` sem saída sob pipefail. O caminho de falha do caso só se testa com o mutante.

## Limites declarados

- `--no-verify` no push e o 1º push antes de o PR existir continuam sem pré-voo.
- A sombra julga o HEAD (o commit), e o pré-voo julga o índice; no `pr-finalize` os dois coincidem no conteúdo
  do PR, e as projeções geradas entram depois.
- O `--check` também roda o pré-voo agora (antes só sob checkpoint); o cache dele fica no git-common-dir, fora
  do repo, e a sombra não roda no `--check`.
- As 20 da classe A seguem indo ao CI até a decisão do `Q_` com os dados da sombra.
