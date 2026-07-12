---
title: "Nota 03 — Formas de comunicação além do chat (pergunta 3 do SEED)"
category: discussion-note
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
responde: SEED.md — pergunta 3
metodo: pesquisa orquestrada citada (2 frentes) antes de posição
relacionado: NOTE-01-telemetria-util-e-etica.md, NOTE-02-reconhecimento-de-padroes.md
atualizada_por: NOTE-05 (dogfood real — achado A abaixo)
---

# 🧵 Nota 03 — Voz, diagramas ao vivo, grafo projetado, gates visuais

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Síntese aterrada em pesquisa citada. Fontes ao final.

## Posição em uma linha

Não é "sair do chat" — o consenso é **híbrido**: chat como camada de **intenção/comando**,
superfícies estruturadas (diff, grafo, trace, gate) como camada de **estado/trabalho**. O achado
mais forte reenquadra tudo: **gate de aprovação é a superfície mais importante** — porque *fadiga de
aprovação é falha de segurança, não de UX*, e é o que decide se o modelo intake×execução do Onion
**segura de verdade** ou vira teatro.

## O eixo que atravessa as três notas

A linha **intake×execução** governa as três perguntas com **um princípio só**:
- **Nota 01** — o que a interface *coleta* sozinha (estrutura = intake autônomo; conteúdo = gated).
- **Nota 02** — o que *promove* a doutrina (candidato precisa de gate humano + refutador).
- **Nota 03** — qual *superfície e intensidade de gate* uma ação recebe (reversível = auto; irreversível = hard).

Três perguntas, um eixo. O design da interface é downstream de um princípio só.

## Não é abandonar o chat (evidência)

"The Conversation Trap": chat é escolhido por *posicionamento*, não por adequação — errado em ~metade
dos casos; "conforme tudo colapsa em conversa, clareza/controle/visibilidade somem". Mas nenhuma fonte
defende abandono total. A régua:
- **Sair do chat vale** quando há (a) **estado estruturado** que persiste/edita incrementalmente;
  (b) necessidade de **julgar trajetória/confiança** de processo longo; (c) output **executável/visual**.
- **Chat continua melhor** quando: tarefa aberta/exploratória, sessão curta e única, ou custo de errar
  a UI > custo de mais uma pergunta em texto.

O Onion já tem superfícies não-chat (`kg-console.sh`, `federation-console`). Não é greenfield — é
*quais aprofundar, quais são gimmick*.

## Lente Aristóteles por superfície

- **Voz** — *diferente por tarefa, desenha.* Ajuda para **intenção/planejamento/ditado** (120–150 wpm;
  hands-free; acessibilidade). Atrapalha para sintaxe/código/revisão precisa. "Programming by Chat"
  (11.5k sessões): devs *relatam sintoma e delegam validação* (24% = "failure reporting") — voz encaixa
  nessa interação curta. **Liga com `discuss/onion-mobile-app`**: voz = canal de intenção móvel; terminal
  = canal de precisão. Não competem.
- **Diagrama ao vivo** — *transfere com cautela.* tldraw/Excalidraw via MCP (traço a traço), Mermaid
  streaming: valor comprovado = **construir confiança + detectar divergência cedo** vendo o agente
  trabalhar. Espelho do raciocínio, não entregável.
- **Grafo projetado** — *transfere com limite DURO medido.* Node-link falha acima de **~50 nós densos /
  ~100 esparsos** (hairball; humanos não acham o caminho). Veredito: `kg-console` está **certo como modo
  de inspeção/auditoria** (dezenas de nós), **errado como workspace contínuo**. Edge-bundling + expansão
  progressiva. Debug view, não tela principal (é como LangSmith/Phoenix usam grafo).
- **Gates visuais** — *o achado mais forte.* Abaixo.

## Gates visuais: fadiga de aprovação é falha de SEGURANÇA

*"Confirmation fatigue is not a UX annoyance but a security vulnerability"* — quando aprovações chegam
mais rápido do que se lê, a supervisão colapsa em **rubber-stamping**: humano "no loop" clicando
approve, supervisão **performática**. Assimetria: aprovar = 1 keystroke; rejeitar = entender a ação.
Menor resistência vence → sempre aprovar. **É exatamente o risco do modelo gated do Onion** — gate em
chat ("digite sim") em rajada vira teatro; intake×execução deixa de ser real. Antídotos que mapeiam no eixo:
- **Gates em camadas por risco** = a própria linha: intake (ler/coletar) → **auto-approve**; execução
  reversível → **soft gate** assíncrono; execução irreversível → **hard gate** bloqueante. Régua já existe; falta a UI honrá-la.
- **Diff-first** (mostrar a mudança, não descrever) + **evidence pack** (o quê / por quê / o que pode dar errado, decisão <15s).
- **Batching** por unidade lógica (diff coerente de 20 > 20 prompts) + evals automáticos removendo o que nem devia chegar ao gate.
- **Progressive disclosure** (máx 2 níveis). **Confiança calibrada**, não máxima.

## Calm tech: o estado da sessão como *Dangling String*

Para "comunicar sem roubar atenção" (o SEED pede), o clássico é **Calm Technology** (Weiser/Seely Brown;
Amber Case). O *Dangling String* do Xerox PARC: um fio que gira com o tráfego — "você *sente* o estado
sem abrir dashboard nem interromper ninguém". O estado da sessão deve viver na **periferia** (cor/forma/
movimento sutil, pré-atento <250ms) e só **migrar pro centro** ao cruzar limiar de decisão real. Três
canais por urgência (indicador / validação / notificação); **modal só pro crítico irreversível**.

## O loop que as três notas fecham

A telemetria `blocked_on_user` (Nota 01, tempo esperando gate) é a **métrica que diz se o design de gate
da Nota 03 está fatigando o maestro**. Batching + risco-em-camadas + evidence-pack **reduzem** esse tempo
*sem remover* o gate. Ciclo: instrumenta (01) → reconhece padrão de atrito (02) → redesenha gate/superfície
(03) → re-mede. É o loop dogfood-auditável (NS1) aplicado à própria interface.

> **⟳ Correção do dogfood (NOTE-05, telemetria real):** o `blocked_on_user` **existe e é capturável**, mas
> **só tem sinal em sessão INTERATIVA** — num `claude -p` headless ele flatlina (~9ms de overhead, sem humano
> esperando). Consequência direta para esta nota: **a fadiga de gate só se mede com humano no loop**; o loop
> 01→02→03 tem que ser instrumentado sobre sessões **interativas** (não headless), senão a métrica-âncora do
> ciclo é cega justamente ao que ela deveria medir. O gate visual não é só desejável — sem sessão interativa
> instrumentada, ele é **inobservável**.

## Fios abertos que voltam ao maestro

1. **Gates em camadas por risco** (auto/soft/hard) como *materialização visual da linha intake×execução* —
   é a peça central, acima de voz/diagrama/grafo?
2. **Grafo como modo de inspeção, não workspace** (teto de ~50 nós) — `kg-console` fica onde está, esforço
   vai pra *gate visual + estado calm*?
3. **Voz = canal de intenção (móvel), terminal = canal de precisão** — divisão explícita, passa o bastão
   pra `discuss/onion-mobile-app`?

## Fontes (seleção)

- The Conversation Trap — https://www.designative.info/2026/03/19/the-conversation-trap-why-defaulting-to-chat-might-be-the-biggest-interaction-design-mistake-of-the-ai-era/
- Beyond Chat (biblioteca de padrões) — https://beyondchat.design/
- Software as Content (3 falhas do chat puro) — https://arxiv.org/abs/2603.21334
- GenerativeGUI (CHI EA 2025) — https://dl.acm.org/doi/10.1145/3706599.3719743
- ExploreLLM (Google) — https://arxiv.org/abs/2312.00763
- tldraw AI / agent starter kit — https://tldraw.dev/docs/ai
- Node-link vs matriz (limiares de escala) — https://www2.cs.arizona.edu/~kobourov/NL-AM-TVCG18.pdf · https://arxiv.org/abs/2008.07944
- Programming by Chat (11.5k sessões) — https://arxiv.org/abs/2604.00436
- The case against conversational interfaces (Lehr) — https://julian.digital/2025/03/27/the-case-against-conversational-interfaces/
- Confirmation Fatigue (falha de segurança) — https://changkun.de/blog/ideas/human-in-the-loop-agents/
- Approval Fatigue (padrões) — https://aipatternbook.com/approval-fatigue
- Evidence packs / HITL approval UX — https://matheuspalma.com/blog/human-in-the-loop-llm-tool-approval-production
- Trust calibration — https://www.designative.info/2026/05/21/trust-calibration-in-agentic-ai-designing-for-appropriate-reliance-not-blind-trust/
- Calm Technology (Weiser & Seely Brown, PDF) — https://people.csail.mit.edu/rudolph/Teaching/weiser.pdf
- 8 princípios de Calm Technology (Amber Case) — https://www.caseorganic.com/post/principles-of-calm-technology
- Glanceable UX / processamento pré-atento — https://uxdesign.cc/glanceable-ux-turning-information-into-instant-understanding-bc2317283ef4
- Progressive Disclosure (NN/G) — https://www.nngroup.com/articles/progressive-disclosure/
- Indicators, Validations, Notifications (NN/G) — https://www.nngroup.com/articles/indicators-validations-notifications/
