---
title: "Company Brain / Personal Brain — trend 2026: definição, players, mercado e a jogada do Onion"
date: 2026-07-25
status: decision-ready
audience: maestro
decides: maestro (esta análise NÃO decide — estrutura para decidir)
kg: docs/onion/graph/company-brain-market-2026-07.kg.yaml
related:
  - ../business-context/gtm-decision-brief-2026-07.md
  - ../business-context/decisions.md
  - ../knowledge-base/concepts/inference-mitigation.md
  - ../knowledge-base/concepts/knowledge-graph-sdaal.md
---

# Company Brain / Personal Brain — a trend de 2026 e onde o Onion joga

> **Leitura em uma frase:** "Company Brain" é uma categoria **nascente e fragmentada** cujo
> gargalo declarado é o mesmo que o Onion já ataca por construção — *contexto/memória
> organizacional, não qualidade de modelo* — mas os players de mercado consolidam a memória
> por **reconciliação-LLM probabilística em runtime**, enquanto o Onion consolida por
> **git-commit determinístico auditável**. Essa é a linha que separa a nossa aposta de todas
> as outras. Amarrada às decisões GTM ratificadas em 2026-07-25 (D6=MENSAGEM P4 / PIPELINE P3,
> D1=A camadas, D3=C desacoplar mentoria do app-consumer gated).

---

## 1. O que é — definição e sub-segmentos

Não é **uma** trend; a imprensa técnica de 2026 já a chama de **"The Brain Stack"** — uma
família de **três conceitos distintos**, com público e escopo diferentes:

| Sub-segmento | Escopo | Raiz | Proximidade do Onion |
|---|---|---|---|
| **Second Brain (PESSOAL)** | memória individual — notas/ideias/decisões de UMA pessoa | metodologia manual CODE (Tiago Forte, pré-IA), relançada em 2026 como "AI Second Brain" | onion-pessoal (N=1 no device) |
| **Company Brain (EMPRESA)** | camada de memória organizacional compartilhada, legível por agentes, permission-aware | **termo 2026-nativo** (não existia antes) | docs/*-context + KG como "brain de projeto" |
| **Single/Shared Brain (MULTI-AGENTE)** | substrato de memória comum entre múltiplos agentes coordenando | orquestração multi-agente | federação RFC-0004/0005 + orquestração Onion |

**Por que virou trend em 2026** (causa-raiz citada por múltiplas fontes independentes):

> *"frontier model quality stopped being the bottleneck for enterprise AI; organizational
> context became the bottleneck."*

A qualidade do modelo **parou de ser o gargalo**; a ausência de memória/contexto
organizacional é o gargalo atual. Sintoma citado: ganho individual com ChatGPT/Claude memory
**não escala para o time** — colegas repetem trabalho de forma inconsistente, agentes não
conhecem a política da empresa, handoffs perdem contexto.

**O que habilitou tecnicamente:** memory tools nativos dos labs (Anthropic descreve memória
como key-value store com retrieval em nível de modelo + *context editing* baseado em arquivo)
— infra de 1ª parte que antes só existia via frameworks de terceiros.

**Distinção-chave que separa "brain de verdade" de mero índice de busca:** **consolidação
automática** — reconciliar contradições sem edição manual. Sem isso, é só um índice de busca,
não uma "memória" viva. Isso ecoa diretamente a doutrina já registrada no Onion
(`inference-mitigation.md` / P5): **SSOT executável vs. cerimônia sem substância**.

**Trajetória técnica confirmada (3 estágios):** notas/PKM estático → knowledge
graph/GraphRAG como backbone semântico → **memória de agente como camada arquitetural própria**
com benchmarks (LoCoMo, LongMemEval, BEAM) e disciplina de engenharia de produção. RAG está
evoluindo de *pattern* para **"Context Engine"/knowledge runtime** (retrieval + verificação +
raciocínio + controle de acesso + audit trail unificados). "Context Engineering" é o termo
guarda-chuva que muitos artigos usam como pai de "Company Brain".

---

## 2. O que o mercado diz + quem está na frente

Categoria **nascente e fragmentada** — múltiplos players correndo para *definir* a categoria
no 1º semestre de 2026 (não-verificado que algum seja "líder"). Divide-se por camada:

### Agente / AI-infra (memory-for-agents)
- **Mem0 — líder de facto.** $24M Series A (Basis Set), 41k stars, 14M downloads, API calls
  35M→186M (Q1→Q3 2025); **provider EXCLUSIVO de memória do AWS Agent SDK**. Pricing Hobby
  free → Pro $249/mês. **Força:** adoção massiva de devs, ecossistema. **Fraqueza:** é
  infra pura (vetor+extração), **não** produto de conhecimento fim-a-fim — não compete em UX
  de "segundo cérebro".
- **Zep/Graphiti** (grafo temporal), **Letta/ex-MemGPT** (LLM como "SO que gerencia a própria
  memória"), **Cognee** (graph-native, >12k stars, seed $7.5M, 70+ deploys). **Fraqueza:**
  nicho técnico de arquitetura de memória, sem tração B2B/B2C comparável.
- ⚠️ Claims de benchmark (Mem0: +26% acurácia, −91% latência p95, −90% tokens vs full-context)
  são **do próprio vendor, não-verificados por terceiro**.

### Empresa (Company Brain / enterprise knowledge)
- **Glean — incumbente mais valioso.** $7.2B valuation, ARR ~$200M→$300M (+89% YoY). Saiu de
  "busca empresarial" para **grafo de conhecimento permission-aware** (Agentic Engine 2 +
  Canvas). **Força:** dado estruturado com permissões corporativas (compliance-first), tração
  em receita. **Fraqueza:** preço/complexidade enterprise, não serve o indivíduo/prosumer.
- **ClickUp Brain²** (23/06/2026): "consciência total" via work-graph interno + *compound
  memory* + roteamento multi-LLM; compliance SOC2/ISO42001/HIPAA/GDPR nativo. **Força:**
  distribuição embutida na suíte. **Fraqueza:** fechado dentro do ClickUp — não agnóstico.
- **Microsoft Copilot Memory + Windows Recall.** **Força:** distribuição Windows/M365 (maior
  base do mundo) + compliance embutido. **Fraqueza:** Recall carrega **estigma de segurança
  persistente** — pesquisadores ainda acham vetores de exfiltração 1 ano+ após lançamento.

### Pessoal (personal brain) — consolidação forçada por M&A
- **Limitless** (pendant) **adquirida pela Meta** em dez/2025; parou de vender, features de
  captura descontinuadas, roadmap opaco. **Rewind.ai** (precursor) **encerrou** em 19/12/2025.
  **Sinal duro:** hardware de "memória perfeita pessoal" **não sustentou** modelo de negócio
  independente — foi absorvido/descontinuado por Big Tech.
- Notas+IA (Reflect, Capacities, Obsidian+IA, Notion AI, Tana, Mem X, todas <$40/mês) seguem
  vivas mas **sem player dominante nem funding/ARR relevante** — categoria de nicho/prosumer.

### Whitespace confirmado
1. **Ninguém cobre pessoal + empresa + agente com a MESMA camada** — Mem0 vence infra, Glean/
   ClickUp vencem empresa (em silo/vendor), pessoal está fragmentado/engolido.
2. **Compliance/governança-first como fronteira:** Glean e ClickUp já embutem SOC2/ISO/HIPAA/
   GDPR — mas **nenhum amarra isso a um framework de DESENVOLVIMENTO** (produto+engenharia+
   compliance juntos). Todos são camada de conhecimento, **não motor de execução de trabalho**.
3. **"device-first + zero-knowledge sync"** (arquitetura já adotada no onion-pessoal — KG cru
   nunca sai do device) **não tem equivalente direto verificado** entre os players. Recall/
   Copilot são cloud/OS-vendor-controlados; nenhum major declara sync zero-knowledge como
   modelo de privacidade central.

---

## 3. Evolução, tamanho e trajetória

| Mercado | Base | Projeção | CAGR |
|---|---|---|---|
| PKM software (notas) | ~$1,3–1,8bi (24/25) | ~$4,7–4,9bi (2033) | 11–15% |
| **Personal Knowledge Base AI** (IA embutida) | $1,36bi | **$11,87bi (2033)** | **27,2%** |
| Knowledge Management (enterprise, maduro) | $17,5–39bi | $34,5–92bi (2033) | 8,5–14,8% |
| **Agentic AI Orchestration & Memory** | $6,16–6,27bi (2025) | **$28,45bi (2030)→$69bi (2033)** | **~35,3%** |

**O segmento mais quente é a camada de memória de agente** (~35% CAGR) — confirma a trajetória
notas→grafo→memória-de-agente.

**Sinais macro:**
- **Gartner:** 40% das apps enterprise com agentes task-specific até 2026 (vs <5% em 2025);
  "shakeup" de **$58bi** em ferramentas de produtividade até 2027.
- **a16z:** IA evolui de ferramenta → ambiente/sistema/agente; em KM, a IA assume conectar
  docs/políticas/respostas aprovadas numa única camada em linguagem natural (**confirma a
  direção Company Brain**).
- **CB Insights:** memory management = baixa maturidade comercial + alto momentum; **GraphRAG**
  apontado como arquitetura vencedora de 2026.
- **Zylos:** ~65% das falhas de agentes enterprise em 2025 vieram de *context drift*/perda de
  memória → aponta para **grafo de memória persistente, versionado e governado** (exatamente o
  KG do Onion).

**Dor quantificada:** perda de conhecimento institucional custa **$1,3 trilhão/ano** (EUA,
Deloitte); 42% do conhecimento reside só na cabeça de funcionários, com turnover 22–25%/ano;
agentes sem contexto sofrem **−38% de acurácia**. Enquadramento de valor que mais ressoa (Forbes
jul/2026): **"Centaur CEO"** — remover 10% de dependência do fundador move o valuation em M&A
"em milhões" (~200h/ano economizadas).

**⚠️ Honestidade:** **não** há fonte primária (CB Insights/a16z com PDF/número) nomeando e
dimensionando **"Company Brain"** ou **"federação de memória"** como categoria. O enquadramento
é **síntese/aposta de tendência, não um número de mercado existente sob esse nome**.

---

## 4. O que o Onion TEM vs. FALTA (honesto)

### JÁ TEM (IGUAL → transfere direto)
- **KG local-first como "cérebro"** (`.kg.yaml` SDAAL): modela qualquer domínio (audit + SSOT
  durável), com **radar determinístico** (kg-radar.sh) para atenção/reconciliação/integridade/
  frescor, e arestas REFUTES/SUPERSEDES que **auto-corrigem contradição**. É *exatamente* a
  promessa "brain" — **já dogfoodado em produção** (3 dogfoods de campo), não é hipótese.
- **N=1 provado no device real** (onion-pessoal, Moto G54): cifra XChaCha20 at-rest, life-KG
  runtime store, **sync zero-knowledge** (só ciphertext sobe). Prova funcionando, não deck —
  diferencial forte vs. a maioria dos "personal brain" que são wrapper de RAG sobre vetor-store
  centralizado.
- **Doutrina de inferência** (`inference-mitigation.md`) — **a peça que a concorrência não tem:**
  reconhece que o risco real de um KG-de-vida não é o dado em repouso nem o host, é o **próprio
  motor deduzindo o não-declarado** (Staab et al. 2024, até 85% top-1). Stack de 6 camadas
  negativas (L1 escopo → L6 ε-ledger), mapeando o que o Onion **já transfere** (query-gate,
  responder-gated/gerador≠porteiro, de-id "none" fail-safe, exposes:/trust, guardrails R15).
- **Federação zero-knowledge (parcial):** RFC-0004/0005 + doc-bridge já operam com "contexto
  bruto soberano/local, só predicado destilado sobe" e classificação por **pior caso de
  inferência** — a MESMA doutrina, aplicada primeiro a comunicação inter-repo.

### FALTA (honesto — não prometer o que não existe)
- **O motor executável (SSOT) da mitigação de inferência é declaradamente NÃO-embarcado no core
  por design** (fronteira: core=doutrina, adotante=SSOT executável). Hoje o Onion vende um
  **frame/contrato de conformidade rigoroso** (REGRA DE ADMISSÃO, 9 pressupostos G0–G8), **não**
  um produto plug-and-play de "personal brain seguro". Falta a **superfície** que um leigo
  consumiria sem construir o motor.
- **Trilho consumer/leigo está formalmente DESACOPLADO e GATED (D3, ratificado 2026-07-25):** o
  app-consumer não avança como pilar até ter "super storytelling + branding + posicionamento".
  Decisão consciente de **NÃO competir agora como produto B2C**. Lacuna de **go-to-market**, não
  técnica.
- **Extrapolação N-tenant** (multi-usuário/empresa) da mitigação de inferência é **"a verificar,
  não citar como bloqueio direto"**: a prova em N=1 pessoal **não generaliza** para um Company
  Brain de equipe, onde o threat model muda (múltiplos leitores do mesmo grafo, RBAC real). É o
  **gap mais crítico** se a ambição for "Company" (não só pessoal): falta desenho e prova de
  campo do L1 (schema-masking + fatia-por-propósito) multi-tenant.
- **Branding/mensagem de categoria:** a GTM ratificada (D6) é **P4 (regulado)** com promessa
  "workflows faseados + auditabilidade estrutural" — **deliberadamente SEM** prometer "federação
  segura de dado regulado" (o mecanismo L1–L6, ainda gated). O Onion tem o ativo técnico mais
  avançado da categoria, mas **conscientemente não o comunica ainda** por guardrail
  anti-declarado≠verificado.

---

## 5. Como SURFAR a onda (jogadas concretas)

Todas compatíveis com o vivo hoje — **sem** prometer L1–L6 gated.

1. **Nomear o KG do Onion como "Company Brain de projeto de engenharia/produto"** no material
   P4 — a arquitetura já-construída (docs/*-context como SSOT viva + KG via /meta:kg + skills
   onion-*-context) **é** estruturalmente um Company Brain. Surfa o vocabulário sem construir
   nada novo.
2. **Vender a distinção git-commit vs. LLM-reconcile como FEATURE, não desvantagem:** onde o
   mercado consolida por reconciliação-LLM probabilística (com risco de alucinação/context
   drift — 65% das falhas!), o Onion consolida por **commit determinístico auditável**. Para
   P4 (regulado), "toda mudança de memória é revisável em PR" **é o diferencial**, não o legado.
3. **Publicar a doutrina de inferência como thought-leadership** (a KB já existe): posiciona o
   Onion como **a autoridade de "brain seguro"** citando Staab et al. — sem vender o motor,
   ganha a mensagem. Alavanca o whitespace #2 (governança-first amarrada a desenvolvimento).
4. **Case do "Centaur CEO"/remover dependência do fundador** como pitch de valor (Forbes) — casa
   com PIPELINE P3 (sistemas internos de empresa) e com receita "mais próxima" (mentoria D4).
5. **Reusar o radar como demo:** rodar kg-radar.sh ao vivo sobre um KG mostra "memória que se
   auto-audita" — algo que Glean/ClickUp não expõem ao usuário. Prova visível > claim de vendor.

---

## 6. Como IR ALÉM — o diferencial que ninguém tem

A tríade que **nenhum player pesquisado combina**:

**`local-first (device) + inference-mitigation (doutrina Staab) + federação zero-knowledge`**

- **Local-first + zero-knowledge sync:** confirmado sem equivalente direto entre os majors
  (Recall/Copilot são cloud/OS-vendor). O Onion **já tem N=1 rodando** (KG cru nunca sai do
  device). Enquanto o mercado corre para centralizar memória na nuvem do vendor, o Onion oferece
  o oposto — **soberania de dado por construção**.
- **Inference-mitigation:** todos os concorrentes tratam privacidade como *dado em repouso +
  permissões* (RBAC, criptografia, SOC2). **Nenhum** endereça o motor **deduzindo o
  não-declarado** — o vetor de vazamento que os benchmarks de Staab mostram ser o mais perigoso.
  Essa é a **fronteira de pesquisa** onde o Onion já tem doutrina publicada.
- **Federação zero-knowledge multi-agente:** o "Single/Shared Brain" (sub-segmento de menor
  maturidade) é justamente onde a orquestração + doc-bridge do Onion já operam com "só predicado
  destilado sobe". É a **próxima fronteira de interoperabilidade** que o mercado ainda nem
  dimensionou.

> **O ângulo de defesa:** o mercado optimiza *recall* (lembrar tudo); o Onion optimiza *recall
> governado* (lembrar tudo, revelar só o permitido, e provar que não inferiu além). Em setor
> regulado, "prova de que NÃO vazou por inferência" vale mais que "lembra mais".

**Ressalva doutrinária (dura):** ir-além ≠ prometer-já. O motor L1–L6 é **gated** por
declarado≠verificado. A jogada "ir além" é de **posicionamento/pesquisa** (ser a autoridade),
não de venda de garantia não-construída. Ativação segue o gate de D2.

---

## 7. O que está MAIS PRÓXIMO (menor esforço × maior probabilidade)

**Vencedor: jogadas #1 + #2 + #3 da seção 5** — tudo é **re-embalagem/comunicação de ativos que
já existem e já são dogfoodados**, custo marginal ~zero, risco doutrinário ~zero (não promete
nada gated). Amarra em **D6=MENSAGEM P4** (já ratificada): "Company Brain auditável para setor
regulado — memória versionada em git, não reconciliada por LLM."

Especificamente o **mais próximo de tudo**: **nomear o KG como Company Brain no material P4 +
publicar a doutrina de inferência como thought-leadership.** Zero código novo, alavanca o
whitespace confirmado, e reforça a MENSAGEM já escolhida.

---

## 8. O que gera MAIS VALOR

**Fechar o gap N-tenant do L1 (schema-masking multi-tenant) — MAS gated.** É a única peça que
transforma "Personal Brain provado (N=1)" em "**Company** Brain provável", que é o segmento com
maior CAGR (~35%) e maior dor quantificada ($1,3tri). É também o **gap mais crítico** da seção 4.

**Porém**, por D3 (consumer desacoplado/gated) e pela doutrina anti-declarado≠verificado, o
maior-valor **não é o mais-próximo** — depende do gate de **D2-ativação** (flywheel de moeda-dado
L1–L6). A sequência correta:

1. **Agora (mais-próximo, seção 7):** surfar com re-embalagem P4 — captura a mensagem sem custo.
2. **Instrumentar** (pré-requisito de D2): 1–2 prospects P4 reais + "valor medido por adotante"
   (a lacuna de Q_instrument do brief GTM). Sem isso, "Company Brain regulado" é chute educado.
3. **Quando o gate D2 abrir:** desenhar+dogfoodar o L1 multi-tenant — aí sim o maior-valor vira
   vendável, com prova de campo, não promessa.

> **Síntese para o maestro:** o mais-próximo (seção 7) e o mais-valor (seção 8) são **fases
> distintas do mesmo caminho**, separadas pelo gate D2. Surfar agora **financia e informa** o
> ir-além depois. Nada aqui contradiz D3/D6 ratificados nem fura o guardrail da doutrina.

---

## Fontes

Ver o KG-irmão (`../onion/graph/company-brain-market-2026-07.kg.yaml`) — cada evidência carrega
`url:` no label e `verified_at: 2026-07-25` quando verificada externamente. Dimensões
pesquisadas: definição-trend, players, mercado-evolução, posição-Onion (interna: decisions.md,
inference-mitigation.md, knowledge-graph-sdaal.md + memória do device).
