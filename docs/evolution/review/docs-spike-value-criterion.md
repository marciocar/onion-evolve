---
branch: docs/spike-value-criterion
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 50
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutante executado (sem subagente) — gate mecânico: família decide, radar e contrato
---

# O sinal do critério de valor em spike entra nas doutrinas do drive e do Elenxo

## Triagem (decisão do maestro pelo /meta:co-evolve, 2026-10-12)

O onion-kg-ssot relayou um sinal de campo do seu ÉPICO 10: em spike de hipótese de produto, o critério de
**sobrevivência** à selagem premia a proposta trivial (100% numa cópia), e só o critério de **valor**, com
avaliador cego, separa cópia de conhecimento (0 de 8). O maestro escolheu "absorver nas duas doutrinas":

- **`onion-drive-doctrine.md` §3.1**: spike de hipótese de produto declara, num commit anterior à amostra, o
  critério de morte com denominador fixo e uma medida de valor com avaliador cego. Estende o pré-registro que a
  casa já tinha, sem duplicá-lo.
- **`onion-elenxo-doctrine.md`**: a etapa 3 ganha uma pergunta fixa quando o artefato é um critério: "o critério
  separa a proposta útil da trivial?". O texto não nomeia o adotante, porque o arquivo viaja.
- Grafo `sinais-de-campo-2026-09`: a evidência `E_SPIKE_SOBREVIVENCIA_PREMIA_O_TRIVIAL_1012` (testemunho de
  terceiro, plane DEV) e a decisão `D_ABSORVER_CRITERIO_DE_VALOR_EM_SPIKE`, selada pelo `kg-decide-seal.sh`.
  O sinal vai para `inbox/_processed/`.

## Achado do dogfood (curado)

1. **O selador não ligava uma decisão nova a uma evidência nascida no mesmo movimento.** A evidência fica
   órfã até a aresta do selo existir, e o passo 0 (radar e contrato) recusava antes de a aresta nascer: as duas
   dependiam uma da outra. Curado com uma exceção estreita: com `--new --link`, tolera-se apenas o caso em que
   **toda** reprovação é o órfão do próprio alvo do `--link`. O radar e o contrato finais julgam o grafo
   inteiro, como sempre.

## Prova

- Família decide **25/0**. O caso (s14) cobre o órfão do alvo tolerado e o órfão de OUTRO nó recusado com
  rc 2.
- Com o selador de `origin/main` (o mutante), o s14 reprova (rc 2 no link para o órfão).
- Selo real no grafo de sinais: rc 0, radar e contrato rc 0.
