---
title: 'ADR — Onion Mini: destilação federada como produto de entrada da família'
date: 2026-07-05
type: adr
status: aceito e executado (rebrand + refresh v2 entregues; publicação web gated)
decision-scope: meta / família-onion / distribuição / identidade
supersedes: none
extends: onion-adr-education-vertical-2026-07.md
deciders: maestro + sessão de evolução
context_freshness: 2026-07-05
related:
  - docs/knowledge-base/concepts/source-vs-derivation.md (fonte≠derivação — aplicado a PRODUTOS)
  - docs/knowledge-base/education/applications/educational-design-guidelines.md (o motor PLEA destilado)
  - docs/evolution/federation/members.yaml (registro do membro onion-mini)
---

# ADR — Onion Mini (`marciocar/onion-mini`, ex-onion-portable)

> **Status: ACEITO E EXECUTADO (2026-07-05).** Revisão estratégica do maestro: o `onion-portable`
> foi adotado em definitivo, renomeado **Onion Mini** e refrescado (v2.0). Relação com o core:
> **destilação federada**.

## Contexto

O maestro pediu a adoção definitiva do `onion-portable` como **a versão mini do Onion** — porta de
entrada para quem inicia no desenvolvimento (foco: gestão de tasks), carregando produto + contextos
de negócio/técnico com SSOT, "dogfoodando Transformers com SDAAL". A exploração revelou:

- O repo (público, ~230 linhas) já era uma destilação madura: master-prompt (4 personas, Fase
  Zero, regra de ouro faseada, guardião) + 5 ciclos + 2 contextos lite — desenhado para **web
  chats gratuitos E IDEs agênticas**. É a tese **LLM-as-VM em estado puro: o master-prompt é o
  bytecode; qualquer Transformer é a VM**.
- Existe uma **família Onion multi-plataforma** não registrada no core (hub `onion` — "prova de
  universalidade" — + onion-cursor/codex/copilot/zed/antigravity). O Mini é a destilação máxima.

## Decisões

### D1 — Nome: **Onion Mini** (rebrand executado)
"Mini" é o **posicionamento** (versão de entrada); "portátil" é a **propriedade** (tagline).
Repo renomeado (`gh repo rename`; GitHub redireciona as URLs antigas).

### D2 — Relação com o core: **destilação federada**
- O core (`onion-evolve`) é a **fonte da doutrina**; o Mini é **derivação curada** —
  [fonte≠derivação](../knowledge-base/concepts/source-vs-derivation.md) aplicado a produtos.
- Doutrina flui core→Mini por **co-evolução curada** (reescrita destilada), **nunca**
  cópia/assemble automático (o conteúdo do Mini é reescrita, não subset de arquivos) e o Mini
  **nunca vendoriza `.claude/`**.
- **A identidade do core fica INTACTA**: Claude-Code-only, não-distribuído. O Mini é quem é
  multi-plataforma e público — são produtos diferentes da mesma família.
- Registro: membro da federação com `role: standalone` + nota de destilação (um role `distilled`
  formal no trust engine é **costura gated** — só na 2ª destilação real).

### D3 — O que o Mini é/faz (a resposta a "o que pode ser feito com ele?")
1. **Funil/escada de adoção**: iniciante começa no Mini (task management agnóstico + 2 SSOTs +
   ciclos) e **gradua** para a adoção plena do core quando o projeto crescer — rampa documentada
   no README do Mini.
2. **Kit do aluno** (sinergia com a vertical educacional): roda em conta gratuita de web chat;
   os ciclos v2 carregam o **motor PLEA** destilado do F1 (Planificar→Executar→Avaliar dentro de
   cada etapa; fechamento em redesenho; crédito Rosário com rótulo teoria≠adaptação).
3. **SDAAL destilado**: Task Manager Lite provider-agnóstico (default "manual" = o backlog do
   business-context como quadro-SSOT; plugável por "adapter de prompts") — dogfood da tese em
   qualquer plataforma.
4. **Vitrine pública da metodologia** — publicação em `onionevolve.com` fica **gated** (decisão
   do maestro: sem web nesta rodada).

### D4 — Refresh v2.0 (executado; commit `bb2bcc3` no Mini)
Master-prompt: +§3.1 motor PLEA · +§3.2 Dogfood Mini · +§3.3 Task Manager Lite · fix "4→5 ciclos".
Ciclos: marcação [P]/[E]/[A] por etapa + Checkpoint PLEA de fechamento por ciclo + o checklist de
engenharia explicitado como **quadro de tasks** (a porta de entrada). Contextos: SSOT explícito.
README: reposicionamento + rampa de graduação + créditos. Tetos de webchat respeitados
(master 77 linhas · ciclos 149).

## Rampa (estado)

| Fase | O quê | Estado |
|---|---|---|
| M0 | Estratégia (este ADR) + rebrand + registro na federação | ✅ 2026-07-05 |
| M1 | Refresh v2.0 (PLEA/SDAAL lite/dogfood mini) + dogfood do master-prompt | ✅ 2026-07-05 |
| M2 | Publicação web (`onionevolve.com/mini/`) | ⏳ gated (decisão do maestro) |
| M3 | Refresh dos irmãos da família (cursor/codex/copilot/zed/antigravity) destilando DO Mini v2 | ⏳ gated (ciclos próprios) |
| M4 | Role `distilled` formal no trust engine | ⏳ gated (2ª destilação real) |

## Histórico

| Data | Mudança |
|---|---|
| 2026-07-05 | ADR aceito; rebrand onion-portable→onion-mini; v2.0 entregue e dogfoodada; membro registrado |
| 2026-07-05 | Revisão do maestro → **AGENTS.md** (config universal, wrapper fino de 32 linhas sobre o master-prompt SSOT) + CLAUDE.md (`@AGENTS.md`, padrão do core) + master-prompt v2.1 (bootstrap oferece AGENTS.md como 1ª opção) + rebrand completado (presentation/sessions). Dogfood: leitor fresco entrou SÓ pelo AGENTS.md e chegou ao comportamento correto; modo degradado (só invariantes) aceitável. Mini `61a1bf2` |
| 2026-07-05 | **Contextos lite v2** (pedido do maestro: "organizado e padronizado com o melhor do Onion"): cada seção mapeia nominalmente uma camada do core (01-customer/02-product; 01-core/adr/02-ai-context/04-workflow) com rodapé de graduação — "zero retrabalho" literal. Novidades destiladas: Personas, Métricas, Pendências [INFERIDO], Fora-do-escopo, **ADR-lite**, Débitos/Riscos e a **casa do redesenho PLEA** (§8/§7 — os checkpoints dos ciclos apontam por nome; fecha o gap do dogfood). Dogfood ponta-a-ponta (iniciante fictício preencheu o template) + 5 ajustes aplicados. Mini `f59efd0` |
