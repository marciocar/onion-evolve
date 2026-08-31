---
title: "MAESTRO-VIVO — o Onion medido contra si e contra o mundo (ago/2026)"
category: research
date: 2026-08-31
status: veredito-selado-pendente-carteira
method: "3 fases orquestradas: F0 capacidade×uso (8 workers sonnet/medium, 8 famílias, 0 descartes) · F1 scan-mundo (6 eixos sonnet/medium + 6 juízes opus/high em pipeline; juiz ABRE as fontes) · F2 confronto interno×mundo (6 confrontos opus/high + 6 refutadores Elenxo opus/high, mandato REFUTAR, default REPROVADO)"
run_id: "wf_6e6ef552-897 + wf_6a4da33e-97e + wf_e27840db-527"
tokens: 2872141
agents: 32
duration_min: 31
kg: docs/evolution/research/maestro-vivo-2026-08/maestro-vivo-2026-08.kg.yaml
verified_at: 2026-08-31
---

# MAESTRO-VIVO — interno × mundo, por medição

> **Projeção do grafo.** SSOT: [`maestro-vivo-2026-08.kg.yaml`](./maestro-vivo-2026-08.kg.yaml)
> (radar exit 0; 52 nós, 48 arestas). Dados crus (JSON por fase, com evidência por item): [`data/`](./data/).

## ⚖️ A resposta à pergunta do maestro

**"Temos /meta:* como versão viva do Maestro?" — Parcialmente.** Medido: 7 instrumentos de
introspecção+condução, **zero de percepção externa recorrente** (o canal-radar S9 é semente parada
desde 07-06, invisível no backlog). Este programa é a primeira passada completa interno×mundo; a
superfície permanente está desenhada abaixo (§Radar) e **gated** para decisão do maestro.

## 📊 F0 — o mapa interno (capacidade × uso real)

| Família | total | vivos | sub-usados | nunca-exercitados |
|---|---|---|---|---|
| guardas (validation+hooks) | 58 | **47** | 4 | 7 |
| doutrinas (KBs) | 57 | 39 | 16 | 2 |
| federação (medidos 36/59) | 59 | 24 | 7 | 5 |
| comandos-meta | 41 | 17 | 7 | **16** |
| agentes | 51 | 14 | **31** | 6 |
| skills | 12 | 7 | 3 | 2 |
| orquestração | 7 | 3 | 3 | 1 |
| comandos-workflow | 64 | **7** | 11 | **46 (72%)** |

A inversão do CLAUDE.md (shell-que-reprova vivo × prosa-que-aconselha) agora está medida
**família a família**: a família mais viva é a das guardas; a mais morta, a dos comandos-workflow.

## 🌍 F1 — o mundo em ago/2026 (34 findings aprovados, 13 reprovados pelo juiz, 28 lacunas declaradas)

Manchetes que sobreviveram ao juiz (fonte aberta e conferida): plataformas absorvendo memória como
feature (memory tool + Dreaming/Anthropic, Cloudflare Agent Memory); Mem0 como camada comercial de
fato (US$24M; híbrido, não KG-puro); Letta pivotou de memória para agente de código (categoria pura
não sustenta empresa); Cognee US$7,5M e Graphon US$8,3M (o dinheiro subiu para a camada de DADOS que
alimenta o grafo); guardrails determinísticos com capital e número (Obsidian US$85M; Sponsio
5.000-60.000× mais rápido que LLM-as-judge; FailproofAI 1,6k★ multi-harness); superfícies grandes de
comandos/agentes viraram commodity de 72h (headcount: 803★ em 3 dias). Detalhe: `data/f1-scan-mundo.json`.

## 🥊 F2 — o confronto (6 teses: 4 sustentadas-com-emendas, 2 REPROVADAS pelo Elenxo)

As teses de **estrategia-preco** e **massa-morta-comandos** foram REPROVADAS — a queda é achado, e
as objeções sobreviventes estão preservadas no grafo (nós `E_ELENXO_*`). Dos 40 vereditos emitidos,
19 caíram no Elenxo; **21 sobreviveram**:

| Veredito | Tema | Capacidade | Proposta / gatilho |
|---|---|---|---|
| **ERRADO** | estrategia-preco | Gate de instrumentação valor-por-adotante — a precondição de preço-por-outcome (Q_instrume | Reabrir o nó como `open` com critério CONTÁVEL (o carimbo atual mede o artefato, não o resultado): ≥8 semanas de linhas JSONL por adotante, reproduzível por comando. Cura de mecani |
| **ERRADO** | federacao-capital | federation-engagement.sh — o sinal de saúde da própria fronteira-de-venda (SINAL 4 da inst | Não descartar o sinal — inverter a perna. (1) Trocar o discriminador: `active` = sinal upstream do membro dentro da janela (`from:` do frontmatter em `docs/evolution/inbox/_process |
| **ERRADO** | kg-vs-plataforma | Perna de LEITURA do KG — read(KG) disparar no momento da decisão | SUPERAÇÃO (não demolição): parar de tentar INJETAR e passar a NEGAR. Todas as curas já refutadas eram da mesma classe — texto pedindo que o modelo leia (A: 1/9; B: 1/9; E: 3/7, e a |
| **ERRADO** | massa-morta-comandos | A hipótese de que a massa morta é custo de manter a família multi-IDE congelada | Não reabrir a família e não usá-la como bode expiatório: reapontar a conta para os dois custos medidos (duplicação na fonte + ausência de gate de uso). Gatilho nomeado que reabre e |
| **ERRADO** | moat-gates | O exit 2 determinístico de hook como 'a capacidade que COMPRA o acoplamento' (CLAUDE.md, c | Superação em duas metades, na mesma sessão: (1) escrever UM PreToolUse mínimo (ex.: negar `git push --force` em main) e MEDIR o bloqueio sob `bypassPermissions` — se barrar, a fras |
| **SUBESTIMADO** | auto-evolucao | Critérios contáveis de promoção na escada de automação graduada (+ rollback do promovido) | Os 3 critérios do Kulaxyz são a forma que falta ao nosso 'promoted_by': hoje ele aponta um DOCUMENTO (onion-guardrails.md, members.yaml); passa a apontar um CONTADOR — N execuções  |
| **SUBESTIMADO** | auto-evolucao | Fechamento de nó do grafo / frescor da própria memória (censo, kg-freshness) | Não trocar o grafo por event-sourcing (git+KG já dão queryability e a tese do Lobu tem 1 case, o dele). O que falta é o INGEST: hoje o fechamento é PULL (custa um worker que mede), |
| **SUBESTIMADO** | estrategia-preco | Q_COLD_ADOPTER — existe pull dos diferenciais raros fora da órbita? (o desempate do NS1) | Sinal novo, sem decidir o nó: a ausência de adotante frio do Onion NÃO é evidência de que ninguém quer o mecanismo — é evidência sobre a FORMA DE ENTREGA (ritual de adoção vs. um ` |
| **SUBESTIMADO** | estrategia-preco | A escada D5 inteira × o moat declarado (mecanismo verificável: exit-2, 64 REGRAS, catraca, | Não é 'parar de dar de graça' — install≠adopt e o grátis é o funil recém-nascido. É acrescentar o degrau que falta: a ASSURANCE do mecanismo (o relatório auditável de que as guarda |
| **SUBESTIMADO** | federacao-capital | A metade formal da federação: /meta:federation-publish, /meta:federation-status, /meta:fed | Primeiro dogfood real, pequeno e imediato: registrar UM contrato que já existe de fato — o Agent Card do core (`docs/onion/agent-card.json`, servido em app.onionevolve.com/.well-kn |
| **SUBESTIMADO** | moat-gates | Empacotamento público — o que a landing diz que o Onion é | Reescrever o hero pelo mecanismo, não pelo inventário: trocar '82 comandos · 49 agentes' por '63 REGRAS que reprovam o merge · 6 catracas que congelam o passivo legado · radar de a |
| **SUBESTIMADO** | moat-gates | O comprador com gatilho de compra: a dimensão compliance sobre gate determinístico | O ativo pronto (148 vetos com string emitida e read-path) é literalmente um relatório de evidência de controle — é o que um auditor ISO/SOC2 pede e o que os produtos de $85M vendem |
| **INEFICIENTE** | federacao-capital | D7 — "a fronteira de venda é a federação" (hub = adoção de EMPRESA / federação como camada | Manter a FORMA de D7 (grátis embaixo, pago em cima) e mover a fronteira um degrau: o upsell não é "o time está junto" (comoditizado por cumora/headcount) e sim "a frota está compro |
| **INEFICIENTE** | federacao-capital | a2a-live: canal vivo com aceite gated (a2a-accept.sh / a2a-verify.sh / a2a-ssrf-check.sh + | Não matar — nomear o gatilho e corrigir a etiqueta agora. (1) Gatilho de reabertura (condição observável, não julgamento): um membro exigir canal vivo que o git-async não sirva — c |
| **INEFICIENTE** | kg-vs-plataforma | Manutenção do grafo — FECHAR o nó, não só carimbar verified_at (/meta:kg-freshness + censo | SUPERAÇÃO em duas metades, ambas no molde que já provamos. (1) CATRACA DE FECHAMENTO no lint, irmã da REGRA 62 (projeção gerada com catraca byte-a-byte): medir a razão `open`/total |
| **INEFICIENTE** | moat-gates | Distribuição do moat — o que o canal de INSTALAÇÃO (plugin/marketplace) efetivamente leva | Cindir 'moat de FÁBRICA' de 'moat de GATE'. Fábrica (create-*, adopt, marketplace, federation, *.kg.yaml, grafo privado) permanece fora — REGRA 61 está certa e não se mexe. Gate ge |
| **INEFICIENTE** | moat-gates | A régua com que medimos as próprias guardas ('47/58 vivas') | Trocar a régua por CAPTURA: quantos vetos cada REGRA emitiu por semana, em quais repos da rede (13 membros em `docs/evolution/federation/members.yaml`, 1 source + 12 adotantes). O  |
| **UNICO** | moat-gates | Catraca com baseline — o passivo legado congelado que só pode DIMINUIR (REGRA 62, REGRA 64 | É isto que se vende, e é o único ativo do tema com zero par no mundo medido: 'ligue o gate hoje, num repo que reprova, sem parar ninguém — o passivo fica congelado e só desce'. Tra |
| **VALIDADO** | auto-evolucao | Produto do loop de auto-melhoria: REGRA determinística de lint em vez de conselho em promp | Explorar o que o mundo prova e nós não usamos: (1) publicar o número — a taxa de REGRAS nascidas de falha real e a mortalidade medida do próprio grafo são a nossa versão do 'x5.000 |
| **VALIDADO** | kg-vs-plataforma | Grafo como camada de VERDADE GOVERNADA — a perna da escrita, protegida por script | A leitura estratégica que este par autoriza: a absorção-como-feature ameaça MEMÓRIA-COMO-ARMAZENAMENTO (o que a Cloudflare empacotou, e sem KG), não GRAFO-COMO-GOVERNANÇA (o que a  |
| **VALIDADO** | moat-gates | A tese-mãe: verificação determinística > LLM julgando LLM (radar sem-LLM, gate mecânico) | Nada a corrigir na tese; o que falta é o NÚMERO. O mundo validou a tese publicando métrica (5.000-60.000×, 2/10→10/10, $85M) e nós publicamos narrativa. Temos o dado cru e não o em |

**O achado mais pesado (selo do maestro):** a frase do CLAUDE.md que justifica o acoplamento — o
`exit 2` de PreToolUse "que barra inclusive sob bypassPermissions" — **não é exercitada neste
repo**: zero PreToolUse no settings.json; o único hook com exit 2 é PostToolUse (sensor, não
catraca), e ele mesmo confessa "PreToolUse é substrato NÃO-VERIFICADO". É a MESMA classe do
SendMessage que a correção de 08-16 removeu. Proposta no grafo: provar OU reescrever a frase —
**flip do CLAUDE.md é ato do maestro**.

## 📦 §Carteira — proposta de refill do fios-abertos (selo do maestro; nada re-litiga D1-D8/NS1)

1. **PROVA-PRETOOLUSE** — escrever 1 PreToolUse mínimo e medir o bloqueio sob bypassPermissions;
   o resultado (qualquer que seja) corrige a frase-moat do CLAUDE.md. (ERRADO, impacto 5)
2. **BENCHMARK-DO-GATE** — publicar o número que já temos (latência do lint 16s, 0 tokens,
   vetos reais capturados) no formato que Sponsio/Statewright provaram que vende. (VALIDADO→número)
3. **PEÇA-CATRACA** — o antes/depois arandek (38 HARD legados tolerados, gate ligado em repo sujo,
   0 merge travado): o único ativo SEM PAR no mundo medido. (UNICO)
4. **HERO-PELO-MECANISMO** — landing 64 dias velha vende a metade commodity (contagens); a decisão
   `onion-moat-verifiable-mechanism` já existe e não desceu ao material. (SUBESTIMADO)
5. **RADAR-SURFACE** — implementar o §Radar abaixo (fecha S9). (decisão gated)
   Itens fora da carteira: cada veredito da tabela acima carrega o próprio gatilho nomeado.

## 📡 §Radar — desenho da superfície permanente (`/meta:radar`, GATED)

- **Maestro-invocado** (W7 intacto — sem cron/loop); a **detecção de idade** vai ao LINT
  (regra SOFT: baseline datada por eixo; passa de N dias → aviso "eixo X está velho, rode
  /meta:radar E<X>"), o padrão que a REGRA 62 já provou: a máquina detecta, o humano dispara.
- 6 eixos com **baseline datada** (E1 KG-agente · E2 self-improving · E3 delta-plataforma ·
  E4 capital · E5 gates · E6 fronteira/preço), cada rodada mede só o **delta** vs a baseline.
- Molde executável = o F1 deste programa (pipeline scan→juiz, juiz-fixo que ABRE fontes,
  search-by-trajectory + follow-the-money obrigatórios no prompt, lacuna declarada de 1ª classe).
- `write(KG)` em grafo próprio por rodada + `SUPERSEDES` sobre a baseline anterior (Aufhebung).

## 🧭 Honestidade declarada

- **Custo estourou o teto**: 2,87M vs 2,5M declarados (+15%); F2 opus/high custou 47% acima do
  projetado. Lição no grafo (`E_CUSTO_PROGRAMA`): projetar F2 pela medida de F1, não por chute.
- 13/47 findings externos REPROVADOS por fonte fabricada/data desonesta — o juiz-fixo pagou o
  custo; nenhum reprovado entrou na síntese.
- A reconciliação veredito↔derrubado usa casamento fuzzy de 40 chars (nomes de capacidade não são
  chaves estáveis) — 19 quedas contadas por esse método; o exato daria menos. Chave estável por
  veredito é melhoria nomeada para a próxima rodada.
- F0 mediu 36/59 itens de federação (o worker declarou os 23 não-medidos, não os chutou).
