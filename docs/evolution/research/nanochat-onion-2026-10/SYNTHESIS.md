---
title: "Nanochat e o Onion — não treinar agora, e o eval de domínio fica no gatilho"
date: 2026-10-05
kg: docs/evolution/research/nanochat-onion-2026-10/nanochat-onion-2026-10.kg.yaml
run_id: wf_c8ba4e42-5e6
tokens: 6608790
agents: 104
duration_min: 18
---

# Decisão selada

`D_NANOCHAT_ONION_DOMAIN_TRAINING_2026_10` → **A: não treinar agora**, selada pelo maestro em
2026-10-05. B (bancada de estudo), C (SLM-ferramenta) e D (dataset do corpus) vivem cada uma no seu
gatilho; E (o Onion como modelo) segue refutada. A pesquisa disparou o gatilho que o corpus já tinha
nomeado, `S7_decision_trigger_research`.

O maestro pediu também o **eval de domínio**. Na pergunta seguinte ("custa muito? é o momento?") a
resposta foi: barato de construir, porque o corpus já tem os rótulos, mas sem consumidor hoje. Virou
`Q_EVAL_DE_DOMINIO_DO_ONION`, aberto com gatilho.

## O que o Nanochat é hoje

- Treina um modelo **classe GPT-2** (CORE ≈ 0,26) por **≈ US$48** em 1,65 h num nó 8xH100, ou ≈ US$15
  em spot. Licença MIT, ≈ 58 mil estrelas.
- O custo real é **engenharia**: o único derivado medido (porte JAX/TPU) custou ≈ US$2.500 em 3 meses,
  contra ≈ US$61 do treino limpo.
- O `autoresearch` (agente que mexe só no `train.py`, rodadas de 5 min, métrica `val_bpb`) é o precedente
  mais próximo da opção B: diff restrito, orçamento fixo, medida barata.

## Por que A, e o que cada opção espera

| Opção | Estado | Gatilho |
|---|---|---|
| A — LLM como runtime | **decisão operante** | — |
| B — bancada de estudo do ciclo de vida de modelo | viva | o maestro nomear essa lacuna para um adotante com runtime |
| C — SLM-ferramenta (Motor 2) | viva, **não pelo Nanochat** | 2º caso de uso de SLM além do de-id; antes, decisão tipada local sem treino |
| D — dataset do corpus | gated | um consumidor; só corpus público destilado, nunca PRIVATE/NDA |
| E — o Onion como modelo | refutada | — |

A anti-tese do corpus (`S7_claim_analogy_breaks`: um modelo treinado perde a auditabilidade em PR que o
markdown tem) não foi derrubada.

## Mercado

Fraco. Nenhuma rodada, M&A ou analista ligado ao Nanochat. O capital visível compra o Nanochat como
**bancada para avaliar agentes** (Imbue, Catalyst, jul/2026), não modelos treinados nele.

## NÃO-VERIFICADOS

| Categoria | Quantidade |
|---|---|
| refutadas no voto | 11 |
| não verificadas por orçamento (`maxVerify` 25) | 32 |
| cortadas por orçamento de fetch | 17 |
| sem veredito | 0 |

Entre as refutadas estão números de custo antigos (US$73, US$72) que o primário já superou, e o pipeline
de customização de identidade em 4 passos, que não sobreviveu ao voto sem fonte primária.

## Valeu a pena

6.608.790 tokens ÷ 46 nós ≈ **144 mil por nó**, abaixo da varredura `decision` de 2026-09-13
(≈291 mil/nó). A próxima rodada sobre o tema, se vier, já tem as lacunas nomeadas: deve ser `primaries`.
