---
branch: fix/jq-raw-utf8-boundary
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: 5c799d68ae30a976ef51e97501330b44a1a70cb4de9e5fe2ffb263ca732bbbb6
reviewed_code_sha256: 2317f8d9a8a36b140d8e710b93b5c4f06bea5b0b563e5c3a7bb3e4d243aa98b7
findings_total: 6
findings_real: 5
findings_blocking: 2
tokens: 127277
duration_min: 8
findings_fixed: 5
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente general-purpose (opus), mandato refutar, sem o raciocínio do autor"
nota: "Revisão isolada sobre o commit 3f68590b4; os achados 1 e 2 (médios) bloqueavam e foram curados; a observação sobre o ACH-k não é defeito e virou esclarecimento no comentário. tokens = tokens do subagente refutador."
---

# Passada adversarial: `fix/jq-raw-utf8-boundary`

## O que muda

O jq até 1.8.1 (a VPS tem o pacote Ubuntu 1.7.1, que se declara `jq-1.7`) corrompe o caractere UTF-8 multibyte que
cruza cada bloco de leitura de ~4 KiB da entrada crua (`-R`, `-Rs`, `-Rsj`). Os quatro usos no core saíram do `-R`:

- `.claude/utils/federation-transport/a2a-send.sh`: a conferência de UTF-8 do corpo usa o MESMO `--rawfile` que monta o envelope;
- `.claude/utils/adopt/merge-onion-hooks.sh`: `_retired_json` por `--arg` (existe desde o jq 1.5; a falha do leitor segue parando o merge);
- `.claude/validation/review-verdict.sh`: o fixture `_mkres` do selftest por `--rawfile`, mais o caso ACH-k;
- `ops/review-gate-health.sh`: a função `parecer_envelope` por `--rawfile`, com casos no `--selftest`;
- `.claude/validation/lint-selftest.sh`: o fixture `_env` da bancada A2A e a família nova `run_jq_raw_utf8_selftests`;
- grafo `docs/onion/graph/a2a-outbound-2026-11.kg.yaml`: E_JQ_RAW_UTF8_BOUNDARY_1122, A_JQ_RAWFILE_CURE_1122 e C_JQ_SYSTEM_LAG_1122 (aberto, dono maestro: subir o jq do sistema).

## Achados

1. **Médio, bloqueante, curado.** A versão que corrige estava errada: o #3421 foi mergeado em 2025-10-31 e só está nas
   notas do jq 1.8.2; o 1.8.1 saiu em 2025-07-01. Cura: «corrigido no jq 1.8.2» e «≤ 1.8.1» nos comentários, na
   bancada e no nó E.
2. **Médio, bloqueante, curado.** No `merge-onion-hooks.sh` a leitura por `<(...)` engolia a falha do leitor da lista
   (antes, com pipefail, o merge parava): passagem de falha fechada para aberta. Cura: `l="$(…)" || return 1` e
   `jq -nc --arg v "${l}"`; caso (b2) na bancada com mutante `|| true`.
3. **Menor, curado no texto.** O nó dizia que o `a2a-doctor.sh` não lê entrada crua; ele lê (`jq -Rn … inputs < RES`).
   Ficou LISTADO, não curado: modo linha só morde linha única acima de ~4 KiB, e as causas são curtas e fixas.
4. **Menor, curado.** O defeito se repete a cada bloco (4096, 8192, 12288…), e 8192 é o teto do corpo A2A. Cura: caso
   (a) com emoji em 8187 fechando no teto de 8192, e o texto fala em bloco de ~4 KiB.
5. **Menor, curado.** O `--rawfile` exigiria jq 1.6 no `merge-onion-hooks.sh`, que viaja ao adotante; e havia espaço
   sobrando no fim de linha. Cura: o `--arg` do achado 2 resolve os dois.
6. **Observação, não defeito.** O ACH-k testa o fixture da bancada, não o código de produção do `review-verdict.sh`
   (que lê o JSON do CLI). O comentário do caso passou a dizer isso.

## Mutantes

Todos por `ops/mutate-and-restore.sh` no arquivo real, `LC_ALL=C`, helper rc 1 (morreu):

- `ops/review-gate-health.sh`: `parecer_envelope` volta ao `jq -Rsc` → três ✗ «envelope do parecer adulterou»;
- `.claude/validation/review-verdict.sh`: `_mkres` volta ao `jq -Rsc` → três ✗ «(ACH-k) … saiu adulterado»;
- `a2a-send.sh`: conferência volta ao `jq -Rsj` → ✗ «(a) a2a-send recusou … corpo não é UTF-8 válido»;
- `merge-onion-hooks.sh`: `_retired_json` volta ao `jq -R .` → ✗ «(b) regra aposentada … ficou no alvo».

Na bancada, cada ponto também tem mutante na CÓPIA; num jq sem o defeito a sonda declara o mutante equivalente
(medido com um jq falso corrigido no PATH: ✓ declarado, nunca mudo).

## Limites declarados

- `a2a-doctor.sh --json` (`jq -Rn … inputs`) segue com `-R`: listado, não curado (achado 3).
- O caso ACH-k prova o fixture da bancada; a produção do `review-verdict.sh` não tem `jq -R`.
- Não medido em bash 3.2 do macOS (não há na VPS).
- O jq do sistema segue 1.7.1: subir é do maestro (nó C_JQ_SYSTEM_LAG_1122). O CVE-2026-49839 do `--rawfile`
  (≤ 1.8.1) exige string acima do limite do jq; os corpos A2A têm teto de 8192 bytes.

## Correção da declaração (22/11)

O revisor desta passada foi um agente separado do autor, como dizem o campo `reviewer:` e o corpo, mas o
frontmatter não declarava `elenxo_isolado: true`, e o `ops/pr-merge-verified.sh` recusa o merge de PR de guarda
sem esse campo. Acrescentei só a declaração. O código revisado não mudou: o diff volta a `pendente` e o hash do
código foi apagado, para o `pr-finalize` carimbar de novo.
