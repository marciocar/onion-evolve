---
branch: docs/comms-stable-degraus-medidos
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 26b9e08d74a22a0e796ac3b34384780ababd372de8f1e801d5dcec6406b06fa9
reviewed_code_sha256: 145b1cba8dc6e1ab7c1f7c6b332ecbe304acb6b043130978220d5b3a412b9efd
findings_total: 4
findings_real: 3
findings_blocking: 0
findings_fixed: 2
tokens: 0
duration_min: 15
verdict: APROVADO
elenxo: sim
reviewer: "o próprio agente de execução, uma passada adversarial curta (o brief proíbe subagente nesta tarefa)"
nota: >-
  Só o grafo comms-stable-2026-11: dois nós ganham o estado medido e seguem open, um fecha como done por
  testemunho. tokens: 0 = não medido (passada do próprio agente, sem contador).
---

# Passada adversarial: `docs/comms-stable-degraus-medidos`

## O que muda

- `Q_CS_DEGRAU1_CAMPAINHA_1109` e `Q_CS_DEGRAU3_SESSAO_COM_SESSAO_1109`: `verified_at` e `verified_against`
  com o que foi medido (`gh pr view` dos PRs #2 e #3 do onion-messaging, `gh run list` na main, o ensaio do
  kit no PR #4), narrativa com o estado e o que falta. `status` segue `open` até o teste ao vivo.
- `Q_CS_CUR_DISSECAR_CHANNELS_1107`: `done`, `evidence_class: testimony`, `verified_against` com o merge do
  PR #228 da curadoria.

## Achados

1. REAL, corrigido: a primeira redação dava o degrau 3 como "pronto menos o teste ao vivo". O ensaio do kit
   mediu um bloqueio de política antes dele (a curadoria é `standalone` e o gate do core não a aceita como
   receptor); a narrativa agora nomeia esse ato do maestro junto com as chaves.
2. REAL, corrigido: o `verified_against` da dissecação dizia só "relato"; o merge do PR #228 foi medido
   (`gh pr view`), o conteúdo e as 3 respostas não. A frase separa os dois, e a classe segue `testimony`.
3. REAL, declarado: "35 mortos, 0 vivos" do degrau 3 vem do resíduo do PR #3 do onion-messaging, não de uma
   rodada minha dos mutantes da fila nesta passada.
4. Refutado: suspeita de estourar o teto de 16 nós do grafo. Nenhum nó entra; o radar conta 16 nós e 15
   arestas, sem contradição.

## Rodadas

- `bash ops/kg-vocab-ci.sh`: rc 0, nenhum código novo sem termo.
- radar no grafo: rc 0, sem contradições estruturais (16 nós, 15 arestas), 2 nós testemunho.
- `bash .claude/validation/kg-contract-check.sh`: conforme ao contrato.
