---
date: 2026-07-17
instance: onion-evolve
type: error
classification: protected
tags: [ssot-as-runtime, declared-vs-verified, co-announce, forged-pin, dogfood, kg, changelog]
affects: [meta, method, federation]
breadcrumb_for: [meta:co-announce, meta:co-evolve, warm-up, catch-up]
share_with: []
next_recommended: "2026-07-16-kg-sdaal-dogfood-gold-backlog"
review_after: 2026-10-15
conflict_class: static
---

## Signal
**Anúncio é plane DEV; só o artefato no repo é plane PROD.** O core **anunciou a doutrina
SSOT-as-runtime como seção da KB antes de a seção existir** — o CHANGELOG de 2026-07-16 e 3 anúncios
downstream em staging afirmavam `knowledge-graph-sdaal.md, nova seção`, e `git log --all -S
"SSOT-as-runtime"` naquela KB era **vazio**. Antes de declarar um artefato entregue num anúncio ou
CHANGELOG, **verifique o artefato**, não a intenção de tê-lo escrito.

## Evidence
- `git log --oneline --all -S "SSOT-as-runtime" -- docs/knowledge-base/concepts/knowledge-graph-sdaal.md`
  → **vazio**; `git show HEAD:<KB> | grep -c "SSOT-as-runtime"` → **0**. A seção nunca existiu.
- Quem afirmava o contrário: `docs/evolution/federation/CHANGELOG.md:41-43` (append-only, commitado) +
  `outbox/{metagamify,gustavo-pulga,marcio-pessoal}/2026-07-16-kg-ssot-freshness-schema-runtime.md:29`.
- **A doutrina existia — no ADR** (`onion-adr-kg-freshness-gate-2026-07.md` §SSOT como runtime), nunca
  promovida à KB. O anúncio raciocinou sobre a decisão (DEV), não sobre o artefato (PROD).
- **Classe idêntica ao pin forjado** que a própria KB cita (`knowledge-graph-sdaal.md`, §Governança
  DEV↔PROD) como evidência da regra. A doutrina de `declarado ≠ verificado` foi **declarada e não
  verificada** — e a doutrina violada era a *anti-forja*.
- **Quem pegou: o dogfood.** O `/warm-up` rodou e seu próprio Passo 0 apontava para um §inexistente.
  Lint e selftest estavam **verdes** — gate mecânico não pega ponteiro doutrinário pendurado; só o uso pega.
- **Salvo pelo tempo:** os 3 anúncios estavam `status: a transportar` (staging). Fechado em `3cf0ab2`
  **antes** do transporte → o anúncio virou verdadeiro em vez de mentira entregue.
- Erro derivado, meu: escrevi a 1ª versão da seção derivando do **sinal** em vez do **ADR**, e **fundi
  dois episódios distintos** (3× do `ssot-como-runtime` × ≥4× do `mandar-a-doutrina`). O ADR os mantinha
  corretos. `source-vs-derivation` ("reescrever = criar uma 2ª fonte que vai divergir") se provou **em
  minutos**, contra mim.

## Next crumb
**O `/meta:co-announce` deveria verificar o alvo antes de anunciar** — se a entrada do CHANGELOG cita um
artefato (`arquivo §seção`), checar que ele existe **no repo** antes de gerar o anúncio. É a regra
DEV↔PROD aplicada ao próprio carteiro. Candidato **gated** (`gated-until-trigger`): este é o **1º**
near-miss registrado dessa classe no doc-bridge — se repetir, o gatilho disparou e vira guarda
determinística. Ver `[[2026-07-16-kg-sdaal-dogfood-gold-backlog]]` para a fila do eixo KG.
