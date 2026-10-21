---
branch: docs/radar-e3-r14
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 8
tokens: 208625
duration_min: 20
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: juiz da rodada (subagente opus/high pedido pela sessão; modelo declarado)
nota: "os 19 achados são 6 exageros + 13 omissões; reais e curados = 6 exageros + 2 superações não declaradas; as omissões de impacto 2 viraram nós e as de impacto 1 foram descartadas por falta de consumidor medido"
---

# Passada adversarial: `docs/radar-e3-r14`

## O que muda

A rodada r14 do radar E3 (grafo de 17 nós, SYNTHESIS e `data/` com o CHANGELOG e os vereditos) e a
baseline do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

O juiz refutou a rodada inteira. Os vereditos e a superação estão em
`docs/evolution/research/radar-E3-2026-10-21-r14/data/judge-verdicts.json`, que o
`judge-verdict-check.sh` deu rc 0.

**Os 6 EXAGERA, todos reescritos:**
- o grep só reproduz com `-E`;
- o resume da 2.1.305 é causa candidata, não a explicação;
- o critério do re-teste tinha uma dicotomia falsa;
- a linha do pin é a l.414, não a l.410;
- o impacto do SDK cai de 4 para 2;
- o número 114 da poda não tinha fonte;
- o preâmbulo do agente de execução estava escondido.

**As 2 superações da r13 que a rodada não tinha declarado** viraram `external_edges` SUPERSEDES: o
/chat "igual ao host" e a pergunta de prova presa ao v1.0.252.

## Mutantes

Não se aplica: o diff tem dado de rodada e baseline, sem guarda.

## Limites declarados

O modelo efetivo do juiz não foi medido (é declarado; ver o nó do fallback). O binário do SDK em
produção ficou NÃO MEDIDO sem sudo.
