---
title: 'Benchmark externo HeyClicky: valida o model-tiering da frota + micro-delta de roteamento dinâmico em runtime'
date: 2026-06-20
from: sessão-core (sinal de mercado trazido pelo maestro via Arthur)
to: onion-evolve (core)
type: market-signal / external-benchmark
severity: low
flow: C (in-repo / insumo de evolução do framework)
status: aberto (3 validações confirmatórias + 1 micro-delta opcional — ação = avaliar o delta no /meta:evolve, sem trabalho de documentação novo)
---

# HeyClicky — o que importar (e o que descartar) p/ a evolução do Onion

Contexto: o **HeyClicky** (`heyclicky.com` · `github.com/farzaa/clicky`, MIT, YC S26, Farza Majeed) é um
assistente de IA nativo de macOS — **screen-aware + voice-first + agentes de fundo**, posicionado para
"pessoas normais, não coders". Tese central: matar o atrito do `screenshot → alt-tab → cola no chat → espera`,
respondendo no lugar onde o trabalho acontece.

Decomposição técnica (fontes ao fim): captura via `ScreenCaptureKit`; STT AssemblyAI (websocket, sub-segundo);
**roteamento multi-modelo** (router de 1ª camada por força em tool-calling → visão/pixel para o tier mais capaz
por default → trabalho agêntico para outro modelo); guidance via tags `[POINT:x,y:label:screenN]` + overlay de
cursor; TTS ElevenLabs; **Cloudflare Worker proxy** segura as API keys; agentes de fundo via gatilho de voz
"clicky agent"; integrações zero-setup (Notion, Gmail, Calendar, Linear).

Filtrado pela identidade canônica do Onion (`.claude/` nativo de Claude Code, sem produto/CLI/UI, spec-as-code),
o sinal se decanta em **3 validações confirmatórias** + **1 micro-delta opcional**. O resto é superfície de
produto ortogonal — descartado.

> **Correção de enquadramento (pré-PR, 2026-06-21):** a 1ª versão deste sinal classificou o model-tiering como
> "achado acionável" sob a premissa de que a escolha de modelo na frota era "implícita/ad-hoc". **Isso é
> factualmente incorreto** — o padrão já é canônico e documentado (ver §1). O sinal foi rebaixado a validação +
> micro-delta para não disparar trabalho redundante no `/meta:evolve`.

## 1. VALIDAÇÃO (+ micro-delta) — model-tiering por força-do-modelo

- **O que HeyClicky faz:** despacha cada tarefa para o modelo mais forte naquela tarefa (router → visão → agêntico).
- **Estado no Onion: já é canônico e documentado** — exatamente nos alvos que valeria a pena documentar:
  - `docs/knowledge-base/concepts/agent-fleet-orchestration.md:274-281` — seção **"Hierarchical model tiers"**
    (lead opus orquestra; workers sonnet/haiku; `model` fixado por chamada de `agent(...)` na Workflow).
  - `.claude/commands/meta/fleet.md:112-117` — "**model tiering**: opus orquestra; mecânicos → haiku; médio → sonnet;
    opus reservado p/ orquestração e juízes adversariais".
  - `.claude/skills/onion-fleet/SKILL.md:99-112` — seção **"Model tiering & budget"**, mesma regra por dificuldade.
- **Micro-delta real (única coisa nova):** HeyClicky escolhe o tier **dinamicamente em runtime** (router de 1ª
  camada decide por tarefa); o Onion fixa o tier como **decisão de autoria** (quem escreve o grafo define o `model`
  por agente/fase). Avaliar no `/meta:evolve` **se** roteamento dinâmico de tier agrega — provavelmente não vale a
  complexidade no modelo spec-as-code, mas fica registrado. **Não há documentação nova a escrever.**
- **Eficácia/eficiência:** eficácia baixa (padrão já existe) · o delta é opcional e de custo de avaliação baixo.

## 2. VALIDAÇÃO — gatilho → agente de fundo → report-back

- "clicky agent" = spawn assíncrono que executa e devolve. O Onion **já tem o esqueleto**: fleet/Workflow em
  background + canal "you have mail" (📬 inbox / 📥 inbound) como report-back.
- **Não é trabalho novo** — é evidência externa de que o padrão está certo. Afinar, se algo, o **atrito de invocação**
  (um gatilho, não um ritual de comandos).

## 3. VALIDAÇÃO — proxy que segura segredos = SDAAL

- "App fala com o Worker; Worker fala com os providers" é **literalmente** o adapter/factory do Onion
  (`factory.md` em `.claude/utils/forge/` e `.claude/utils/task-manager/`). Convergência independente → **valida
  a arquitetura SDAAL**. Citar como evidência externa.

## Descartado (superfície de produto, viola identidade)

- **Voz · macOS · screen-vision · overlay de cursor · "para não-coders"** — superfície da plataforma do HeyClicky;
  importar reabre o escopo **formalmente abandonado em 2026-05-18** (CLI standalone, multi-IDE). Eficácia ~nula p/
  o Onion, custo alto.
- **"audience-as-distribution"** — o análogo no Onion já existe: família de portas + federação/co-evolução.

## Próximo passo

Item de **baixíssima** prioridade. As 3 seções são validações confirmatórias — não geram trabalho. O único item
para o `/meta:evolve` avaliar é o **micro-delta** (roteamento dinâmico de tier em runtime vs. estático na autoria);
recomendação preliminar: **não adotar** (complexidade > ganho no modelo spec-as-code), mas registrado para decisão.

---

**Fontes:**
- [heyclicky.com](https://www.heyclicky.com/) · [github.com/farzaa/clicky](https://github.com/farzaa/clicky) (MIT) · [YC S26](https://www.ycombinator.com/companies/heyclicky) — primárias.
- Secundárias (efêmeras): [HokAI review](https://hokai.io/hub/tools/heyclicky) · [DailyDropout](https://dailydropout.substack.com/p/heyclicky-give-your-cursor-infinite) · [TBPN Digest, 10/06/2026 — "now using Claude by default"](https://www.tbpndigest.com/story/2026-06-10/hey-clicky-founder-farza-majeed-built-a-voice-controlled-ai-desktop-agent-in-8-weeks-now-using-claude-4-by-default).
