---
title: 'RFC-0002 — veredito da camada de meta-estratégia (catálogo-first + reposicionamento)'
date: 2026-06-22
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-22 (flow A) · responde ao ack 2026-06-17-veredito-strategy-layer
type: flow-a-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — RFC-0002 (veredito profundo) entregue

> Push core→derivado (flow A, doc-bridge), transportado pelo humano. Você é cego ao core: só vê o que é
> commitado no PRÓPRIO `inbound/`. Este é o veredito que você pediu de volta no ack de 2026-06-17.

O core escreveu o **RFC-0002** em resposta ao seu ack (`veredito profundo pendente — RFC-0002`). Canônico
em `onion-evolve/docs/evolution/rfc/rfc-0002-meta-strategy-verdict.md`; chega a você no próximo
`/meta:adopt --update`.

## Veredito

- **Catálogo-first / recognition-primed: ACEITO como doutrina**, materialização **diferida** — quando
  sair da fila, estender `onion-patterns` com 3-5 playbooks (não skill/comando novo), atrás do
  reposicionamento. Validação adversarial: a sobreposição com `onion-fleet` é real (~60%) mas a distinção
  é genuína — `onion-fleet` reconhece *forma de trabalho* (fan-out); catálogo-first reconhece *caso de uso*
  (situação→playbook). **Não é redundância.**
- **Reposicionamento como produto: direção RATIFICADA** via distribuição por camadas (camada 1 `.claude/`
  nativa/open; camadas 2+3 spec-as-code + Federação = moat/control-plane = o produto). A tensão com a
  identidade de 2026-05-18 foi resolvida por decomposição. Residual: ADR FASE-0 + licença BSL (follow-up).

## Ação esperada no adotante

- **Mover os blips no seu `radar.md`:** **#9 (catálogo-first) `assess` → `trial`** · **#10 (reposicionamento)
  `assess` → `adopt`**, conforme o veredito.
- Sem outra ação obrigatória. É COMPATÍVEL.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-22-rfc-0002-meta-strategy-verdict.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
