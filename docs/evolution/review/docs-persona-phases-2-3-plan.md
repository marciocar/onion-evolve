---
branch: docs/persona-phases-2-3-plan
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: c4aa6bedbb679fbcdfacfcda0088a25b895e262c2011617bad0d9cf924efd268
reviewed_code_sha256: 6bc429bca4332ef57abefa2264728112200538e2f4d787170f7307842dcae5a8
findings_total: 3
findings_real: 3
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff; gate mecânico kg-radar e kg-contract-check
nota: "tokens e duração não medidos (0). Grafo novo de 8 nós, dois resumos de sinal e um anúncio; sem código."
---

# Passada adversarial: `docs/persona-phases-2-3-plan`

## O que muda

Grafo-filho `persona-fases-2-3-2026-11` (o `persona-servico-2026-11` está no teto de 6 nós), com as 5 peças das
fases 2 e 3 da persona de chat. Entram também o anúncio ao hub e a forma-resumo dos dois sinais dele.

## Achados

1. **A afirmação da ponte nascia `confirmed` sem fonte verificável (REAL, BLOQUEIA, curado).** A única fonte é o
   relato da sessão do core, e o selo não foi localizado por grep. A gramática diz que nó sem fonte verificável não
   é `confirmed`. Passou a `open`, com a condição de fechamento no `narrative`.
2. **Só a data da peça 1 sai do selo (REAL, limite).** As datas 2 a 5 são propostas do core. Ficam declaradas no
   `note` do grafo, em cada `narrative` e no anúncio.
3. **A fase 3 não tem data (REAL, limite).** `Q_MA_CLASSIFICATION` não tem `x_due`. O anúncio diz isso em vez de
   inventar uma data.

## Mutantes

Não se aplica: o diff é dado de grafo e texto, sem lógica. O gate é o radar e o contrato.

## Limites declarados

- O pedido da peça 2 ainda não foi levado ao kg-ssot.
- Os originais dos dois sinais seguem não rastreados no checkout principal. A forma-resumo não os substitui até o
  merge.
- A resposta do kg-ssot foi lida pelo repasse do core, não no repo dele.
