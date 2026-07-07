# Semente de pesquisa — orquestrar SLMs federados × a linha "quem orquestra" do Onion

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Esta semente colide diretamente com uma decisão já
> tomada e marcada "não reabrir sem evidência nova" — ver abaixo. Registrar isso não é julgar a
> semente; é o mínimo de honestidade que a doutrina `declarado≠verificado` exige.

## Por que esta pesquisa

O maestro propõe: orquestrar **SLMs específicos** (modelos pequenos, especializados) **em
federação** para resolver problemas — várias "cabeças" pequenas colaborando, em vez de uma cabeça
grande fazendo tudo.

**Isto já foi considerado e rejeitado, duas vezes, por nome.**
[`onion-engine-economy.md`](../knowledge-base/concepts/onion-engine-economy.md) §5 ("Rejeitado
conscientemente — NÃO reabrir sem evidência nova") lista:
> *"SLM-como-agente [...] fere o invariante 'SLM é ferramenta via adapter, não orquestrador'."*
> *"Model-routing multi-LLM — fere a identidade de plataforma única (Claude Code)."*

Há um ADR dedicado que traçou a linha com precisão —
[`onion-adr-slm-as-tool-de-identification-2026-06.md`](onion-adr-slm-as-tool-de-identification-2026-06.md):
> *"Um modelo auxiliar (SLM local) entra no Onion como ferramenta atrás de um adapter SDAAL, nunca
> como orquestrador [...]. A linha não é 'qual modelo', é quem orquestra."*

Um sinal externo real e próximo (HeyClicky, roteamento de modelo por força em tool-calling) já foi
processado pelo canal de inbox e recebeu **recomendação preliminar de não adotar**
(`docs/evolution/inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md`) — "complexidade
> ganho no modelo spec-as-code".

**O pano de fundo que torna esta semente relevante mesmo com a rejeição prévia** (achado de uma
conversa direta do maestro com o agente de exploração desta rodada, sobre "não sermos reféns de
ninguém"): o próprio SDAAL já nomeia a ambição de portabilidade multi-provider desde o whitepaper
original (`docs/sdaal/sdaal.md` §10.4 — `llm-provider | Anthropic, OpenAI, Google, local, none |
📝 Roadmap`, nunca construída). E a resposta real que a organização já deu a "não depender de um
único fornecedor" **não foi tornar o core multi-LLM** — foi criar o onion-mini como produto-irmão
portátil, mantendo o core 100% Claude-Code. Prova viva: o Onion Mini já roda como Custom GPT no
ChatGPT (`chatgpt_gpt:` em `members.yaml`, registrado nesta mesma sessão) — é o Onion sendo livre
de um único runtime, só que via produto-irmão, não via orquestração multi-modelo dentro do core.

**Nenhum documento lido reconcilia essas duas direções** — "trabalhar juntos até ser livres" e a
rejeição explícita de model-routing multi-LLM apontam para lugares diferentes na camada de
orquestração, lado a lado, sem síntese registrada.

**Retrofit 2026-07-06** — [`onion-parecer-rejection-vs-spinoff-signal-2026-07.md`](onion-parecer-rejection-vs-spinoff-signal-2026-07.md)
nomeou a categoria que a tensão acima já apontava: **`bifurcado`** — o lugar (core) está errado,
não o mérito da capacidade. O onion-mini já É essa resposta, com rótulo agora. Isso não fecha
Q1-Q3 abaixo — só evita que a pesquisa redescubra o que o parecer já nomeou.

## Questões de pesquisa

**Q1 — O que mudaria a decisão?** A rejeição é "NÃO reabrir sem evidência nova" — o que contaria
como evidência nova? Um caso de uso real (não hipotético) onde orquestrar SLMs federados resolve
algo que o modelo atual (1 Transformer orquestrador + SLM-ferramenta via adapter) genuinamente não
resolve?

**Q2 — "Federação de SLMs" é sobre orquestração, ou sobre outra coisa?** Talvez a semente do
maestro não seja "trocar quem orquestra" mas sim uma variação do que o Onion já faz com
repos-humanos (federação de instâncias soberanas, git-async, maestro humano coordena) — só que
aplicada a modelos em vez de repos. Isso seria uma categoria nova (federação de *execução*, não de
*repositório*) ou é a mesma ideia com um substantivo trocado? A pesquisa deveria testar essa
distinção antes de qualquer outra coisa.

**Q3 — A tensão "reféns" × "quem orquestra"**: existe uma leitura em que as duas doutrinas não
colidem? Ex.: o core continua 1-orquestrador-só (identidade preservada), mas os "SLMs federados"
vivem inteiramente do lado de fora, como produtos-irmãos adicionais à família multi-plataforma
(onion-cursor/codex/copilot/zed/antigravity, hoje não registrada na federação) — replicando o
padrão onion-mini em vez de importar orquestração multi-modelo pra dentro.

**Q4 — O que a literatura recente diz.** Panorama já absorvido na KB
(`docs/analysis/panorama-ia-generativa-2026-06.md`) chama SLMs de *"a tese mais subestimada do
ano"* e cita o arXiv *"Small Language Models are the Future of Agentic AI"*
(arxiv.org/html/2506.02153v2) — mas isso é sobre SLM-como-ferramenta-eficiente, não sobre
federação-de-orquestradores. A pesquisa precisa checar se a literatura recente (pós-2506.02153)
propõe algo estruturalmente diferente do que já foi rejeitado aqui.

## Método previsto

Deep-research (fan-out multi-fonte + verificação adversarial) sobre: precedentes reais (não
hipotéticos) de sistemas multi-agente com múltiplos SLMs especializados coordenados sem um único
LLM orquestrador central; literatura pós-2506.02153 sobre "federação" (não "roteamento") de
modelos pequenos. Se algum achado sobreviver à verificação adversarial como evidência nova
genuína, ele vai para revisão humana explícita antes de qualquer proposta de reabrir a decisão —
não é decisão de IA reabrir uma rejeição marcada "não reabrir sem evidência nova".

## Gatilho

O maestro pede ("roda a pesquisa de SLMs federados") → executar a partir DESTA semente. Registro
na memória da sessão: `sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
