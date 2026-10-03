---
title: "Radar E3 · rodada 6 — o delta de nove versões, e a terceira porta da fabricação"
date: 2026-10-03
axis: E3-claude-code-delta
baseline_anterior: 2026-09-21 (2.1.278)
baseline_desta_rodada: 2026-10-03 (2.1.288)
kg: docs/evolution/research/radar-E3-2026-10-03-r6/radar-E3-2026-10-03-r6.kg.yaml
run_id: "sem run_id de Workflow — rodada conduzida na sessão principal com 1 juiz subagente (opus/high, worktree isolada). Declarar ausência é o contrato; inventar um wf_ seria a 4ª morada da fabricação."
tokens: 122349   # medidos, do juiz; o custo da sessão principal não é atribuível por run
agents: 1
duration_min: 6
---

# O que esta rodada mediu

Nove versões publicadas depois da baseline — **2.1.280 (22/09) a 2.1.288 (02/10)**, 990 itens
somados. A `2.1.279` **não existe** na fonte: lacuna genuína, desfecho de 1ª classe, não finding.

Os blocos de cada versão estão em `data/2.1.28*.txt`, extraídos por âncora `id="2-1-NNN"` do
documento cru (4.071.883 bytes). Guardá-los é o que torna **cada citação desta síntese
falsificável sem re-buscar** — e foi exatamente a ausência disso que deixou a 1ª passada errar
atribuição em quatro achados.

## O achado de maior consequência, que a 1ª passada enterrou numa frase falsa

A **2.1.280** adiciona `claude-opus-5-5` **como o Opus default**, e muda o modelo default dos
planos Pro e Team Standard **de Sonnet para Opus**. A **2.1.284** adiciona `claude-sonnet-5-5`
como o Sonnet default da API.

Medido no repo: o `session_models` do eixo E6 lista **apenas** `claude-fable-5-1` e
`claude-opus-5`; `grep -rl opus-5-5` devolve **zero**. A `premodelswitch-guard.sh` nega o que não
está na lista — logo **a casa veta hoje a troca para o Opus default da plataforma**, e não sabe
que o modelo existe.

Eu havia escrito que "a 2.1.279 e a 2.1.280 não aparecem no changelog". A metade sobre a 280 era
**falsa**, e era a metade que carregava o item de maior consequência do delta inteiro.

→ **Decisão PROPOSTA, o flip é do maestro** (`D_SESSION_MODELS_PRECISA_DO_OPUS_5_5`). O número do
lineup vem do eixo **E6**, que tem `last_run` próprio e **não foi rodado aqui** — editar o lineup
por esta rodada seria o carimbo-sem-medição.

## Três capacidades novas, todas de graça, nenhuma com lugar no fluxo

| Versão | O que apareceu | Por que importa aqui |
|---|---|---|
| **2.1.283** | `/doctor prompt-audit` — audita CLAUDE.md, skills, agentes e comandos por padrões escritos para **modelos antigos** | a casa mede se **guarda dispara** e não mede se **doutrina aterrissa**; é um medidor da metade não-medida do fosso (52.655 linhas de markdown) |
| **2.1.287** | `Claude Mods` + o mod **"You should know"** (agente lateral que sinaliza o que se pode ter perdido) | a plataforma embutiu um **Elenxo fraco**; e "mods podem mudar comportamento mais fundo" é substrato novo para onde uma guarda **deve morar** |
| **2.1.286** | skill chamada `verify` é rodada **antes do commit** (exceto commits docs-only/tests-only) | o Onion tem 13 skills e **nenhuma** `verify`. ⚠️ Não é "o gate já é um verify": o changelog descreve skill que **o modelo é instruído a rodar**; o gate daqui roda no `pre-commit`, mecânico. Absorver = expor o gate **também** como skill, **sem trocar o mecanismo pelo conselho** |

E o delta de configuração que ninguém tinha visto porque caía na janela que eu declarei coberta:
`"attribution": false` (2.1.281, com armadilha de compat em CLI antiga), os namespaces
`anthropic-skills`/`claude-ai` deixando de carregar como skill/comando/workflow (2.1.282), e
`availableModelsMatch`/`deniedModels` como managed settings (2.1.283) — os primeiros controles de
modelo por **política**, não por doutrina.

A **2.1.288** — e só ela — passou `PreToolUse`/`PermissionRequest` a **bloquear** a chamada quando
o matching falha ou o input não serializa. As duas guardas `PreToolUse` da casa têm matcher
literal `Bash`, o que torna "matching failed" implausível para elas; o candidato real é matcher
**regex**. A alcançabilidade **não foi medida** — isto é inferência declarada.

# Os três buracos de fluxo (apontados pelo maestro, medidos aqui)

1. **Nada checa contiguidade de versão.** O eixo mede delta contra a baseline por desenho, e
   não existe verificação de que toda versão foi lida por **alguma** rodada. Sem o juiz, sete
   versões ficariam permanentemente não-medidas e **nenhum mecanismo acusaria**. A cura é
   aritmética, não pesquisa: a baseline já guarda `cc_version`.
2. **Comunidade é eixo separado e nada cruza.** O E3 não declara fonte nenhuma em
   `radar-sources.yaml`; a comunidade é outro eixo, com `last_run` próprio e não-por-versão.
   Hoje "o que quebrou para quem usa" **nenhum dos dois** responde.
3. **Não há passo de absorção.** A etapa 5 cobre veredito que **derruba** decisão selada; não há
   passo para **adotar** capacidade nova. O fluxo sabe refutar diretiva e não sabe absorver
   mecanismo — e as três capacidades acima são a prova viva.

# A lição de método, que vale mais que os achados

**Placar do juiz: 1 aprovado · 5 reprovados · 1 lacuna genuína**, mais a isenção de escopo
reprovada estruturalmente.

- **A terceira morada da fabricação é a ATRIBUIÇÃO DE VERSÃO.** Quatro dos cinco reprovados
  tinham o texto **certo** na versão **errada**. Conferir a citação e conferir **em que versão
  ela mora** são dois atos, e a 1ª passada fez só o primeiro. (r4: fonte externa · r5: medição do
  repo · r6: atribuição.)
- **O corpus virou instrumento de isenção.** Na r5 o erro foi **pular** o `kg-corpus-grep`; nesta
  foi invocá-lo e ler `id`+`tier` **sem** ler `impact` e `confidence`. Três nós tier 9 — dois com
  `impact: 2`, um com `confidence: 0,4` e auto-rótulo *"informação próxima de zero"* — foram
  tratados como cobertura selada de seis versões. **Tier alto é qualidade da FONTE, nunca
  extensão da COBERTURA.** → **Curado nesta leva**: o `kg-corpus-grep` passou a imprimir `imp=` e
  `conf=` junto de `tier=`, para a isenção falhar na **leitura** em vez de falhar no juiz.
- **O `WebFetch` é o instrumento errado para medir atribuição.** Sobre a página de 4 MB ele
  **resume, trunca e inventa atribuição**: datou a 2.1.281 como "October 1" (é 23/09, ordem
  impossível) e copiou a lista `Changed` dela para a 2.1.286. Mesma família de
  *testar-no-caminho-errado-é-não-testar*: o resumo é projeção, não fonte.

# NÃO-VERIFICADOS

- **Alcançabilidade** da condição corrigida na 2.1.288 nas duas guardas `PreToolUse` da casa —
  inferência declarada, não medição.
- **Visão da comunidade** sobre estas nove versões (buraco de fluxo 2): fora do escopo do eixo
  hoje, declarado em vez de simulado.
- **Eixo mercado/capital** não foi rodado nesta rodada (a r5 já o media como sinal fraco com
  roster a melhorar); não há reivindicação de mercado aqui.

# valeu-a-pena

122.349 tokens / 1 agente / ~6 min para **14 nós** ⇒ ~8,7k tokens/nó — contra os ~68–74k/nó do
censo. O barato tem causa nomeável: **a fonte é local e conferível** (`data/`), e o juiz mediu em
vez de buscar. O custo que **não** aparece aqui é o da 1ª passada reprovada — e ele é o argumento
mais forte para a cura de contiguidade: refazer é mais caro que checar.
