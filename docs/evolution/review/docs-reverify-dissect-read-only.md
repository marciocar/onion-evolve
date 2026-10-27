---
branch: docs/reverify-dissect-read-only
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada própria, adversarial sobre o diff, com re-medição ao vivo (peer-ref-check, censo de dissecação, sondas do core em cópia descartável); gate mecânico kg-radar --integrity --schema, kg-contract-check e dissect-census --check-verdict
---

# As dissecações lidas, re-medidas

## Achados

1. **Uma afirmação da re-medida do Duolingo não era verificável.** A 1ª escrita do
   `E_REMEDIDA_DUOLINGO_1027` dizia que os 6 nós de apoio estavam "com o mesmo status de antes". O nó
   lido não registrava esses status, então "de antes" não tinha com que comparar. Curado: agora diz o
   que foi medido hoje (os 6 presentes, 4 open e 2 confirmed).
2. **O README da pasta afirmava que não havia dissecação selada** (linha 23, apontado pela curadoria).
   Era falso. Curado com a contagem do `dissect-census.sh --tsv` de 2026-10-27: 10 dissecações, todas
   com estado `veredito`, com o comando citado e o aviso de que o número envelhece.
3. **Um código ambíguo entrou na prosa de um nó.** O contrato KG-SSOT do commit reprovou
   (`vocab.code-ambiguous`): o label e a narrative do `E_REMEDIDA_N1_CORPUS_1027` escreviam "N1", que o
   vocabulário resolve para três termos. Curado: o texto diz "nível 1", e o `ops/kg-gate-ci.sh` dá
   "nenhum código novo sem termo".

## O que se conferiu e se manteve

- Nenhuma decisão selada mudou de veredito. Na ai-front, o nó lido virou `superseded` por um nó de
  medição e o veredito segue `perseguir`. A decisão de rodar o piloto 3 foi cumprida, não derrubada.
- O Superpowers recebeu o critério e a superação `nenhuma` copiados da origem e re-medidos hoje, sem
  trocar o veredito.
- Não entrou nome de cliente nem conteúdo do repo do cliente. Os nós citam só os ids do grafo da
  curadoria e caminhos do core.
