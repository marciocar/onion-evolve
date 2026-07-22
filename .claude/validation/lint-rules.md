# Registro de REGRAS do lint — Onion

> **Documento GERADO** por `.claude/validation/rules-registry.sh` a partir dos docstrings
> `# REGRA N — …` de `lint-artifacts.sh`. A **severidade** é derivada do que cada guarda
> *realmente emite* (`violation "HARD"` / `"SOFT"`), não de um comentário que pode ter
> driftado. **Não edite à mão** — rode:
>
> ```bash
> bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md
> ```
>
> A REGRA 39 mantém este arquivo em paridade com as guardas e **falha se houver número
> duplicado ou regra sem categoria** — a catraca de clareza.

São as regras que o gate mecânico do Onion aplica a **todo repo da rede**: o mesmo
lint roda no core e em cada adotante. **HARD** bloqueia o merge; **SOFT** avisa, mas não
bloqueia o CI.

**40 regras** no total — **36 HARD**, **6 SOFT**.

## Frontmatter & conformidade de artefato

Campos obrigatórios, válidos e bem-formados no frontmatter de agentes e comandos.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 1 | Frontmatter de agente: name:, description:, tools: obrigatórios | HARD |
| 2 | Frontmatter de comando: description: obrigatório | HARD |
| 3 | Campo model: não pode conter gpt-4 | HARD |
| 12 | Nomes de tool de agente válidos no Claude Code | HARD |
| 17 | Frontmatter: valor escalar com ': ' não-aspado | HARD |
| 23 | Frontmatter: model: em comandos e category: em agentes | HARD |

## Higiene de artefato

Tamanho saudável, nomes kebab-case, dialeto puro e links que resolvem.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 5 | Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal) | HARD + SOFT |
| 6 | Filenames em .claude/ devem ser kebab-case | SOFT |
| 13 | Templates canônicos devem ser dialeto-puro | HARD |
| 14 | Meta-specs (autoridade L0) sem dialeto Cursor em exemplos | HARD |
| 15 | Frescor de contexto de domínio: carimbo de atualização | SOFT |
| 22 | Links relativos quebrados em docs/evolution/ e docs/knowledge-base/ | HARD |

## Fronteiras & contratos de arquitetura

Proibições estruturais, documentação no lugar certo e os contratos de conformance e de adoção.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 4 | Ausência de 'mcp_onion-orchestrator' em .claude/ | HARD |
| 7 | Nenhum agente pode ter name: contendo 'worker-orchestrator' | HARD |
| 18 | Sem documentação versionada sob .claude/docs/ | HARD |
| 20 | Capability Contract: tier de conformance cumprido | HARD |
| 40 | Adotante: .onion-version DEVE estar trackeado no git | HARD |

## SDAAL — abstração de provider

O consumidor fala com a abstração, nunca com o provider direto.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 10 | SDAAL: sem chamada direta a provider no consumidor | HARD |
| 11 | Método de abstração usado no consumidor deve existir na interface | HARD |

## SSOT anti-drift

Toda superfície DERIVADA fica em sincronia com a fonte única — contagens, mapas, plugins.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 8 | Inventário canônico sincronizado com o filesystem | HARD |
| 9 | Contagens no CLAUDE.md em sincronia com a SSOT | HARD |
| 16 | Contagem de inventário-TOTAL divergente da SSOT | SOFT |
| 19 | Plugins de vertical (plugins/*) sincronizados com as fontes | HARD |
| 21 | Grafo (docs/onion/graph.md) sincronizado com a spec-as-code | HARD |
| 27 | Dependência de script de comando empacotado | HARD |
| 37 | Mapa role→bundle (roles.yaml) consistente com os verticais | HARD |
| 39 | Registro de REGRAS derivado e em paridade com as guardas | HARD |

## KG & proveniência

Conhecimento nasce no grafo e não morre em prosa; proveniência com catraca.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 26 | Pesquisa nasce em KG, não morre em prosa | HARD |
| 29 | Gate de PROVENIÊNCIA INVERTIDO, com catraca | HARD + SOFT |
| 31 | Lente do grafo: DERIVADA e em paridade com o motor | HARD |
| 32 | Página pública do grafo: números conferidos contra o mapa | HARD |

## Federação

Mapa, console, agent-card e canais de membro em sincronia com o SSOT da rede.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 24 | Console da federação (docs/onion/federation-console.html) sincronizado com o SSOT | HARD |
| 25 | Agent Card A2A do core (docs/onion/agent-card.json) sincronizado com o SSOT | HARD |
| 28 | Anúncio em staging para membro SEM canal de recepção | SOFT |
| 38 | Mapa da federação (docs/onion/federation-map.md) sincronizado com members.yaml | HARD |

## Projeção & privacidade

O que pode sair para superfícies públicas ou vendorizadas — nome de cliente e deep-link privado nunca vazam.

| Nº | Regra | Severidade |
|---:|-------|:----------:|
| 30 | Segurança de PROJEÇÃO: nome comercial de membro privado não sai | HARD |
| 33 | Segurança de projeção no HISTÓRICO DE FEDERAÇÃO (mailbox-aware) | HARD |
| 34 | Migalhas: superfícies DERIVADAS da fonte, sem drift | HARD |
| 35 | Site público não linka deep-link do repo PRIVADO (404 garantido) | HARD |
| 36 | Superfície VENDORIZADA sem nome comercial de cliente | HARD |
