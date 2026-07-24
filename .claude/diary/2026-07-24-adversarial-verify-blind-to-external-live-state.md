---
date: 2026-07-24
instance: onion-evolve
type: learning
classification: collective
tags: [orchestration, verify, adversarial, declarado-vs-verificado, live-state, gh, verificacao-externa]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Quando um verify adversarial orquestrado APROVAR um artefato cujas afirmações incluem ESTADO EXTERNO VIVO (visibilidade de repo, status de deploy, se um serviço está no ar, versão publicada), NÃO confiar no approved sozinho: adicionar uma checagem-de-estado-vivo (gh/curl/stat) como camada extra do verify, OU conferir à mão as afirmações de estado-externo antes de commitar. O verify de texto rastreia fonte e consistência interna; ele não vai ao mundo conferir."
review_after: 2026-10-22
conflict_class: static
significance: "Um verify adversarial (opus) APROVOU (approved:true) uma síntese que afirmava onion-standalone 'privada/flip-gated' — mas gh repo view mostrou PUBLIC. O verify checou 12+ claims contra arquivos/commits e passou, mas NÃO foi ao gh conferir o estado externo vivo — exatamente onde o worker do synth errou. Só o cheque ao vivo pegou."
---

## Signal
**O verify adversarial orquestrado tem um ponto cego: estado externo vivo.** Ele é forte no que faz —
rastrear cada afirmação a uma fonte do repo, checar consistência interna, pegar fabricação. Mas afirmações
sobre **estado que vive FORA do repo** (um repo é público? um endpoint está no ar? uma versão foi publicada?)
ele **não vai conferir** — não roda `gh`/`curl`/`stat`. Então um erro de estado-externo passa pelo approved.

## Evidence
- No refresh da KB `onion-federation-and-adoption.md` (circulação pública), um worker escreveu que
  `onion-standalone` estava "privada, flip público gated". O verify adversarial (opus) auditou 5 eixos,
  confirmou 12+ claims contra arquivos/commits reais, e deu **`approved: true`** — sem pegar o erro.
- Só peguei porque, antes de commitar, **fui ao vivo**: `gh repo view marciocar/onion-standalone` →
  `"visibility":"PUBLIC"`. O worker (e o verify) tinham conflado "sem commit de flip" (verdade — flip é ação
  `gh`, não commit) com "não flipou" (falso). A verdade exata: o door **flipou público**; só o repoint do
  redirect `onion-claude` segue gated (e `onion-claude` está privado — verificado no mesmo gh).
- O verify não é inútil — ele pegou o resto certo. O ponto cego é específico: **claim de estado externo vivo
  precisa de um cheque externo vivo**, que o verify de texto não faz.

## Next crumb
Ver `next_recommended`. Irmã de [[what-the-maestro-taught-me]] e de [[workflow-resume-after-process-death-reexecutes]]:
o `declarado≠verificado` não termina no verify orquestrado — para estado externo, a fonte da verdade é o
mundo (`gh`/`curl`/`stat`), não a auditoria de texto. Vale um degrau extra no verify quando o artefato afirma
estado-vivo (candidato à Onda 2 do plano de automação graduada — o degrau monitorado que confere o vivo).
