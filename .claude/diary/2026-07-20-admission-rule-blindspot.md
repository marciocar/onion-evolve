---
date: 2026-07-20
instance: onion-evolve
type: learning
classification: collective
tags: [inference-mitigation, admission-rule, adversarial-review, blind-spot, form-over-content, dogfood]
affects: [meta, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "No PRÓXIMO contrato/mecanismo (qualquer camada de guarda, não só inference-mitigation): antes de fechar, perguntar explicitamente 'de que isto depende para valer?' e provar ISSO também — enumerar pressupostos até fechar (mesmo padrão da REGRA DE ADMISSÃO). E desconfiar especificamente do que TODA fixture usa como pano de fundo/dado fixo (matriz, config, política) — é o ponto cego estrutural, não um acaso desta rodada. Aplicar antes da 1ª passada adversarial, não descobrir na 7ª."
review_after: 2027-01-18
conflict_class: static
significance: "Achamos, com lastro em oito passadas reais (não teorizado), a forma do próprio ponto cego adversarial — e a regra que ele gerou hoje só vale dentro de um documento; esta migalha é o que a torna reusável no próximo."
---

## Signal
Todo mecanismo criado para fechar o furo que uma passada adversarial anterior achou **entra ele próprio sem
prova** — é uma FALHA DE FORMA que se repete em nível mais fundo a cada rodada, não uma falha de conteúdo (que
parou de acontecer depois da 3ª passada). Corolário do ponto cego: **o que toda fixture usa como pano de
fundo/dado fixo não é observado** — por isso a política escapou sete passadas.

## Evidence
- **A escada das 8 passadas** contra `docs/knowledge-base/concepts/inference-mitigation.md` (contrato de
  conformidade do gate L1/L2), cada uma achando um mecanismo novo que fechava o furo anterior mas entrava
  sem provar os próprios pressupostos: destinatário → concessão → assinatura → âncora →
  revogação/relógio/via-viva → política → superfície de escrita.
- **Depois da 3ª passada, nunca mais houve defeito de CONTEÚDO** — só esta MESMA falha de forma, um nível
  mais fundo a cada vez. Sinal de que a review adversarial tinha esgotado o "o quê" e passou a operar só no
  "quem garante o quê garante".
- **O achado final (7ª→8ª):** a política (matriz de pares + rotulagem sensível/topologia-sensível/escopo)
  escapou **sete passadas adversariais inteiras** porque toda fixture a consome como dado de entrada fixo —
  nenhuma pergunta "o que garante que ESTA matriz é a certa e está fora do alcance do motor?". Só na 8ª a
  regra de admissão foi virada contra a própria política.
- **A regra de admissão que consolidou o padrão** ("todo mecanismo introduzido para fechar um furo entra
  provando-se — com fixture própria E com a integridade dos seus PRESSUPOSTOS provada pelo mesmo rigor")
  nasceu como cláusula LOCAL desse contrato, em
  `docs/knowledge-base/concepts/inference-mitigation.md` (seção "🔒 REGRA DE ADMISSÃO").
- **Estado em 2026-10-20 (re-teste):** a regra saiu da cláusula local. Tem 2ª aplicação em `onion-guardrails.md`
  §8.4 (l.277, "REGRA DE ADMISSÃO — os pressupostos do próprio gate, enumerados"), que a aplica à REGRA 42, e o
  corolário está em `onion-dogfooding-doctrine.md`. Ainda falta na forja de guardas: `guard-doctrine.md`,
  `forge-guard.md` e `forge.md` não citam a regra nem os pressupostos (grep = 0). É ali que ela alcançaria o
  próximo mecanismo por construção.

## Next crumb
Ver `next_recommended`. Em resumo: ao escrever ou revisar qualquer novo mecanismo de guarda, perguntar
"de que isto depende para valer?" recursivamente até fechar a enumeração de pressupostos, e tratar com
suspeita elevada qualquer coisa que as fixtures tratam como config/dado fixo em vez de como algo a provar —
esse é precisamente o disfarce que durou sete passadas da última vez.

## Re-testada em 2026-10-20 — PARCIAL: (static) o Signal vale. O Evidence foi atualizado: a regra já tem 2ª aplicação (guardrails §8.4), mas não chegou à forja de guardas.
