---
title: 'Aprendizado: sensor de comportamento — três gates (mapear consentido ≠ vigiar)'
date: 2026-07-12
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-12 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — aprendizado: sensor de comportamento (três gates)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no
> PRÓPRIO `inbound/`.

## 2026-07-12 · Aprendizado: sensor de comportamento — mapear consentido ≠ vigiar, e a linha intake↔execução vira TRÊS gates · COMPATÍVEL · alvo: adotantes

- **Informativo — sem ação requerida.** Não é bump nem pede `/meta:adopt --update`. É um **aprendizado**
  compartilhado (migalha de diário `public`), de uma **frente de discussão isolada** (`discuss/behavior-mapping-kg`,
  "pensa, não entrega") — não é doutrina fechada do core. Absorva como conhecimento; a decisão de produto está aberta.
- **O aprendizado:** ao desenhar um *sensor de comportamento* (mapear atividade do usuário → documentar/
  padronizar/automatizar), duas descobertas transferem para qualquer projeto que colete comportamento:
  1. **Mapear consentido ≠ vigilância** — a mesma técnica vira uma coisa ou outra por 4 eixos:
     finalidade, transparência, agregação e controle do titular. Autorização **dual e deliberada**
     (a pessoa **E** a organização querem+autorizam; nunca imposto nem acidental).
  2. **A linha `authorization-layers` (intake↔execução) vira TRÊS gates para um sensor**, não uma:
     **observar** (captura já é o gate — inverte "guardar é livre"), **inferir** (derivar/perfilar já é
     ato regulado — TJUE SCHUFA C-634/21), **agir** (execução clássica — Art. 22 / AI Act 14). Entre os
     gates, intake autônomo. Convergência: o estado-da-arte 2026 (tiered autonomy, gate determinístico,
     gatear pelo *side-effect*) reencontra a doutrina que o Onion já tem (VETO-não-SKIP, propose-only).
- **Lição de método (útil a quem orquestra):** para pesquisa web citada, agente `general-purpose` direto
  com WebSearch foi mais robusto que `research-agent` + schema forçado (que flakou 3/4 em stub). 
- **Onde ler:** a migalha `.claude/diary/2026-07-12-behavior-sensor-three-gates.md` (public). A frente
  completa (5 notas + pesquisas citadas + protos kg-radar) vive isolada no core, não promovida.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Sem ação requerida** (COMPATÍVEL, informativo — não pede `/meta:adopt --update`). Absorva o aprendizado.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-12-behavior-sensor-three-gates.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
