---
date: 2026-07-21
instance: onion-evolve
type: innovation
classification: collective
tags: [provenance, knowledge-graph, ratchet, gate, coverage-vs-truth, dogfood]
affects: [meta, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Quem for reusar a catraca de proveniência invertida: instalá-la SEMPRE com baseline emitido do filesystem do alvo (nunca herdando o baseline do core — ele explodiria o gate do adotante) e ciente de que o gate mede COBERTURA, não verdade. Enquanto quem alimenta o grafo for orquestração com verificação adversarial, o flanco fica fechado; no dia em que virar rotina apressada, o gate fica verde e o grafo fica oco. Se isso for detectado, o próximo mecanismo é um gate de PROFUNDIDADE (nó que não sustenta afirmação verificável não conta como cobertura) — e ele entra provando-se, pela REGRA DE ADMISSÃO."
review_after: 2026-10-19
conflict_class: conditional
valid_when: "o grafo continua sendo alimentado por orquestração com verificação adversarial, e não por rotina apressada de nó-por-documento"
significance: "Invertemos a pergunta da proveniência — de 'as citações apontam para fontes reais?' para 'toda fonte é alcançável a partir do grafo?' — e a catraca pagou 92 documentos até o piso zero sem uma regressão."
---

## Signal
**Proveniência invertida com catraca**: o gate não pergunta se as citações do grafo apontam para fontes
reais (proteção contra fabricação) — pergunta se **todo documento-fonte tem representação no grafo**
(proteção contra conhecimento que existe mas não é alcançável). A catraca (`baseline` que **só encolhe**)
é o que permite instalar o gate num acervo já em dívida sem parar o mundo.

## Evidence
- **Mecanismo:** `.claude/validation/kg-provenance-coverage.sh` + `.claude/validation/kg-coverage-baseline.txt`.
  Escopo `docs/analysis` + `docs/evolution/research`. Severidade **por delta**: documento novo sem nó soma
  HARD; documento que já estava no baseline soma SOFT. Baseline que CRESCE vs. o ref é HARD.
- **Resultado medido:** baseline **75 → 0** em seis levas; cobertura final **92/92**; grafo
  `federation-research-2026-06-reconciled.kg.yaml` de 677 nós/854 arestas para **881/1086**. Lint 0 HARD/0
  SOFT, 380 guardas verdes.
- **A catraca no piso muda o regime:** com baseline vazio, **qualquer documento novo sem nó é HARD**. Não
  há mais passivo tolerado onde se esconder.
- **O gate se provou vivo durante a própria construção** — a REGRA DE ADMISSÃO aplicada a ele achou: (a)
  que era **NO-OP no CI**, (b) falso-positivo em formas de citação que o repo já usa, (c) que o baseline
  **viajaria para os adotantes e explodiria o gate deles** (fix: `/meta:adopt` passo (9) regenera o baseline
  do filesystem do alvo, espelhando o passo (8) do `inventory.md`).
- **O radar foi o revisor até o fim:** na última leva o `--integrity` apanhou dois nós órfãos e uma
  contradição de status antes do commit, e forçou a corrigir uma aresta que eu modelara como `REFUTES`
  quando a relação honesta era `DEPENDS_ON`.
- **⚠️ O flanco, nomeado antes de alguém o descobrir do jeito ruim — o gate mede COBERTURA, não VERDADE.**
  Ele exige que cada documento tenha *um nó*. Nó raso e genérico **passa**. Nesta mesma sessão um worker
  emitiu placeholder (`id: a`, `label: x`) e o merge deixou passar porque satisfazia o **schema** — quem
  pegou foi a consequência (um documento sem cobertura), não a regra. Guarda adicionada (id/label ≤3 chars
  rejeitado), mas ela fecha a forma grosseira, não a rasa.
- **Nota de medição:** meu script descartável de merge reportou "+209 nós" por aritmética de linhas; a
  contagem verdadeira do radar era **+204**, igual ao que os workers emitiram. Contar pela ferramenta
  canônica, não pelo andaime.

## Next crumb
Ver `next_recommended`. A catraca é **gameável por profundidade, não por presença** — e no dia em que ficar
verde sobre um grafo oco, ela mente com autoridade de mecanismo, que é a pior forma de mentir neste sistema.
Ver [[mechanism-beats-prose]] (a lei que este instrumento tornou visível) e [[admission-rule-blindspot]]
(o rigor com que o próximo gate de profundidade deve entrar).
