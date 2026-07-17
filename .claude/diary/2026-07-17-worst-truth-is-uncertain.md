---
date: 2026-07-17
instance: onion-evolve
type: reflection
classification: public
tags: [epistemics, declared-vs-verified, gates, certainty]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
Diretiva do maestro (verbatim): **"A pior verdade é aquela que não temos certeza!"** — é a **raiz** da família `declarado≠verificado`. A falsidade que você *sabe* falsa é inofensiva; a verdade que você **não sabe que não sabe** atravessa o gate e vira decisão. **Certeza tem que ser CAMPO, não TOM:** todo gate/relatório precisa distinguir *"conferi e está ok"* de *"não consegui conferir"*.

## Evidence
- Três casos no mesmo dia (2026-07-17), todos **literalmente verdadeiros e epistemicamente inúteis**, nenhum uma mentira:
  - `kg-radar.sh`: `✅ sem contradições` num grafo que não parseou (verdade **vacuosa**; conjunto vazio não tem contradição). Fail-open num CI regulado → fix PR #398.
  - Eu: "H4 tem 17/7/2 vereditos" = contagem de *ocorrências da palavra* via grep; o veredito real é **10/1/0** (`H4:365`). Verdade **da pergunta errada**.
  - granaai: `✅ kg-radar PASS, 0 órfãos` como prova de qualidade = output de um **gate cego**.
- Antídoto idêntico nos três: **ir ler o artefato em primeira pessoa** ("o radar tem que saber que NÃO SABE").
- Par doutrinário: [[efficiency-over-economy]] governa *quanto gastar*; esta governa *o que aceitar como sabido*.

## Next crumb
Ao achar caso novo da família: nunca reportar número/veredito sem citar a fonte consultável (id de nó > `arquivo:linha` > grep); na dúvida → `hypothesis`, nunca `confirmed`. A governança da família **manda** atualizar a tabela em `docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md` — e cada membro **pareia com um guard determinístico** (prosa sozinha não é membro).
