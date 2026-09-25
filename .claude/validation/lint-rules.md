# Registro de REGRAS do lint — Onion

> **Documento GERADO** por `.claude/validation/rules-registry.sh` a partir dos docstrings
> `# REGRA N — …` de `lint-artifacts.sh`. A **severidade** é a UNIÃO do que a guarda
> *realmente emite* (`violation "HARD"` / `"SOFT"`) com o tag `[SEV]` declarado no
> docstring. **Não edite à mão** — rode:
>
> ```bash
> bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md
> ```
>
> A coluna **O que previne** vem do campo `# previne:` no docstring de cada regra (o
> modo-de-falha que ela evita). A REGRA 39 mantém este arquivo em paridade com as guardas,
> e o gerador **falha (exit 2)** nas **5 catracas de clareza** — número duplicado · regra
> sem categoria · regra sem `# previne:` · regra sem o tag `[SEV]` · severidade que não
> resolve. Regra nova sem essas quatro declarações não entra: é anti-drift por construção.
>
> **Limite conhecido da derivação** (medido 2026-08-03, `gated-until-trigger`: sem dano
> observado, não vale reescrever o parser): o scan associa a cada regra o **primeiro**
> `nome() {` após o header, então em regras cujo header antecede um *helper* — ou que
> **delegam** a um script externo com `violation "${sev}"` dinâmico — a severidade vem do
> tag `[SEV]`, não do corpo. Hoje as duas fontes concordam em **todas** as regras (nenhuma
> sai com severidade indefinida). Se um dia divergirem, o tag ganha — por isso ele é o
> contrato para as guardas delegadas.

São as regras que o gate mecânico do Onion aplica a **todo repo da rede**: o mesmo
lint roda no core e em cada adotante. **HARD** bloqueia o merge; **SOFT** avisa, mas não
bloqueia o CI.

**89 regras** no total — **78 HARD**, **28 SOFT**.

## Frontmatter & conformidade de artefato

Campos obrigatórios, válidos e bem-formados no frontmatter de agentes e comandos.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 1 | Frontmatter de agente: name:, description:, tools: obrigatórios | HARD | agente sem name/description/tools obrigatórios — não carrega nem roteia direito |
| 2 | Frontmatter de comando: description: obrigatório | HARD | comando sem description — invisível/ambíguo no menu |
| 3 | Campo model: restrito à allowlist sonnet\|opus\|haiku\|fable | HARD | model fora da allowlist embarcado num artefato |
| 12 | Nomes de tool de agente válidos no Claude Code | HARD | agente declara uma tool inexistente no Claude Code |
| 17 | Frontmatter: valor escalar com ': ' não-aspado | HARD | YAML de frontmatter quebrado por escalar com ': ' não-aspado |
| 23 | Frontmatter: category: em agentes (a metade 'model: em comandos' foi REVOGADA pela REGRA 71) | HARD | agente sem category: — o roteamento/inventário dependem dele. Até 2026-09-03 esta regra também EXIGIA |
| 51 | Agentes branch-* documentam a distinção vs o par geral | SOFT | par de agentes com overlap invisível — dispatcher que roteia por description não escolhe |

## Higiene de artefato

Tamanho saudável, nomes kebab-case, dialeto puro e links que resolvem.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 5 | Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal) | HARD + SOFT | artefato inchado muito além do saudável para o seu tipo |
| 6 | Filenames em .claude/ devem ser kebab-case | SOFT | filename fora de kebab-case — inconsistência e link quebrado |
| 13 | Templates canônicos devem ser dialeto-puro | HARD | template canônico contaminado com dialeto não-canônico |
| 14 | Meta-specs (autoridade L0) sem dialeto Cursor em exemplos | HARD | exemplo de meta-spec L0 com dialeto Cursor |
| 15 | Frescor de contexto de domínio: carimbo de atualização | SOFT | contexto de domínio sem carimbo de atualização — frescor incerto |
| 22 | Links relativos quebrados em docs/evolution/ e docs/knowledge-base/ | HARD | link relativo quebrado em docs/evolution ou docs/knowledge-base |
| 48 | Referência de caminho `.claude/…` em backtick (prosa) que não resolve | HARD | referência .claude/ em backtick na prosa apontando p/ arquivo inexistente (ponteiro morto silencioso) |
| 60 | Identificador de código em INGLÊS | HARD | identificador em pt-BR entrando no código sem que nenhuma guarda mecânica o veja. |
| 71 | Comando não declara model: no frontmatter — segue a escada da sessão | HARD | o Claude Code 2.1.259 passou a HONRAR model: de comando em sessão interativa (radar E3 rodada 2, l.17): |
| 72 | Namespace de comando em plugin é /<plugin>:<cmd>, nunca o do core | HARD | comando empacotado citando `/engineer:pr` — ponteiro que não resolve no consumidor |
| 73 | Hook empacotado resolve no plugin instalado | HARD | hook morto e silencioso no plugin (script ausente, motor não embarcado, caminho $REPO/${CLAUDE_PLUGIN_ROOT}, matcher perdido) |
| 74 | Caminho .claude/ NU dentro de plugin só resolve no core, com catraca | HARD + SOFT | comando/agente empacotado apontando .claude/{utils,commands,templates,…} que não viajou — ponteiro morto no consumidor |
| 75 | Link markdown relativo dentro de plugin resolve no plugin | HARD | `[irmã](../kb/x.md)` num plugin apontando para arquivo que não viajou — 404 no consumidor |

## Fronteiras & contratos de arquitetura

Proibições estruturais, documentação no lugar certo e os contratos de conformance e de adoção.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 7 | Nenhum agente pode ter name: contendo 'worker-orchestrator' | HARD | agente com o nome do anti-padrão 'worker-orchestrator' |
| 18 | Sem documentação versionada sob .claude/docs/ | HARD | documentação versionada no lugar errado (.claude/docs/) |
| 20 | Capability Contract: tier de conformance cumprido | HARD | componente reivindica um tier de conformance que não cumpre |
| 40 | Adotante: .onion-version DEVE estar trackeado no git | HARD | adotante com .onion-version não-trackeado — 156 falso-HARD |
| 53 | Regra path-scoped declara `paths:` que casa algo real | HARD | regra em .claude/rules/ que nunca carrega — instrução que o modelo jamais vê |
| 77 | Contrato de dependência entre plugins | HARD + SOFT | dois plugins embarcando a mesma skill/KB (cópias divergem) ou um plugin usando skill que só outro embarca sem declarar |

## SDAAL — abstração de provider

O consumidor fala com a abstração, nunca com o provider direto.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 10 | SDAAL: sem chamada direta a provider no consumidor | HARD | consumidor chamando o provider direto, furando a abstração SDAAL |
| 11 | Método de abstração usado no consumidor deve existir na interface | HARD | consumidor chama método de abstração que não existe na interface |

## SSOT anti-drift

Toda superfície DERIVADA fica em sincronia com a fonte única — contagens, mapas, plugins, topologia.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 8 | Inventário canônico sincronizado com o filesystem | HARD | inventário mentindo vs o filesystem real (contagem drifta) |
| 9 | Contagens no CLAUDE.md em sincronia com a SSOT | HARD | contagens no CLAUDE.md drifta da SSOT do inventário |
| 16 | Contagem de inventário-TOTAL divergente da SSOT | SOFT | contagem-TOTAL do inventário divergindo da SSOT |
| 19 | Plugins de vertical (plugins/*) sincronizados com as fontes | HARD | plugin de vertical driftando das fontes — bundle de adoção errado |
| 21 | Grafo (docs/onion/graph.md) sincronizado com a spec-as-code | HARD | docs/onion/graph.md desatualizado vs a spec-as-code |
| 27 | Dependência de script de comando empacotado | HARD | comando empacotado dependendo de script ausente no bundle |
| 37 | Mapa role→bundle (roles.yaml) consistente com os verticais | HARD | mapa role->bundle (roles.yaml) driftando dos verticais |
| 39 | Registro de REGRAS derivado e em paridade com as guardas | HARD | lint-rules.md driftando das guardas (nº duplicado ou regra órfã) |
| 41 | Topologia da família: SSOT no KG com procedimentos EXISTENTES | HARD | SSOT de topologia da família apontando a procedimentos inexistentes |
| 50 | Contagens do SITE público sincronizadas com a SSOT | HARD | pitch público driftando da SSOT — número que mente para quem não pode conferir |
| 59 | Modo que a produção consome é exercitado pela bancada | HARD | guarda que roda no gate por um caminho que nenhum teste percorreu — o modo consumido |
| 62 | Projeção GERADA em sincronia com a fonte (docs/backlog.md) | HARD | projeção gerada que envelhece calada — o item existe no grafo e some da superfície que as sessões leem |
| 63 | Colheita de grafo emite os ids colhidos no resíduo de revisão | HARD + SOFT | nó removido de um .kg.yaml sem registro consultável de que existiu — a promessa "a história fica no artefato de revisão" cumprida só na letra |
| 70 | fallbackModel do settings.json é PROJEÇÃO da escada de modelos (eixo E6) | HARD | a escada (session_models + session_floor em docs/onion/radar-baselines.yaml) e o fallback nativo do |
| 76 | marketplace.json da raiz é projeção do gerador | HARD | .claude-plugin/marketplace.json envelhecendo calado (o core também é marketplace instalável) |
| 80 | Números do harness saem de SSOT gerada, nunca de comentário | HARD | contagem sobre o próprio harness escrita à mão, que envelhece calada e é citada como medição |
| 81 | Painel de estado é GERADO dos produtores, nunca redigido | HARD | painel de testes com número sem produtor — metas redesenhadas como medição, que foi o defeito real deste repo |
| 83 | Id de modelo VERSIONADO só na SSOT declarada | HARD | versão literal de modelo espalhada por config, que caduca sem aviso |
| 84 | Índice de leitura do KG em sincronia com os traces | HARD + SOFT | o hook da perna de leitura mentir POR OMISSÃO |
| 85 | Porta pública espelha o core, com catraca | HARD + SOFT | a porta MENTIR sobre o que o core é, por falta de re-materialização |
| 90 | Prosa de comando conhece os papéis que o script aceita | SOFT | o par script×prosa dos comandos de co-evolução desencontrar — e ele JÁ desencontrou duas |

## KG & proveniência

Conhecimento nasce no grafo e não morre em prosa; proveniência com catraca (por citação e por marcador autodeclarado); e frescor doutrinário — afirmação sensível-ao-tempo carimbada e dentro do TTL.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 26 | Pesquisa nasce em KG, não morre em prosa | HARD | pesquisa morrendo em prosa, sem .kg.yaml irmão (não nasce no grafo) |
| 29 | Gate de PROVENIÊNCIA INVERTIDO, com catraca | HARD + SOFT | relatório de análise órfão do grafo (nenhum nó o cita) |
| 31 | Lente do grafo: DERIVADA e em paridade com o motor | HARD | lente do grafo divergindo do motor que a deriva |
| 32 | Página pública do grafo: números conferidos contra o mapa | HARD | página pública do grafo com números que não batem com o mapa |
| 42 | Gate de FRESCOR DOUTRINÁRIO, com catraca | HARD + SOFT | afirmação sensível-ao-tempo sem carimbo ou fora do TTL |
| 43 | Integridade do marcador kg: (proveniência virada p/ DENTRO) | HARD | marcador kg: (born-in-graph) inconsistente com o grafo |
| 47 | Narração do KG cita ids que existem no grafo | HARD | narração que cita nó inexistente no grafo — console embute e DROPA ids mortos silenciosamente |
| 49 | Nó plane:PROD de alto impacto carrega VERIFICAÇÃO, com catraca | HARD + SOFT | nó afirmando sobre produção sem nunca ter sido medido contra o vivo |
| 52 | Todo .kg.yaml do repo passa no radar de INTEGRIDADE | HARD | grafo com contradição estrutural vivendo no repo sem ninguém medir |
| 55 | O `trace:` de um nó APONTA para alvo que EXISTE | HARD | âncora declarada que não resolve — quem tenta voltar ao "porquê" cai no vazio |
| 57 | O veredito do run está SELADO no grafo que ele julgou | HARD | run que mede e não sela — a SSOT segue afirmando o que a medição já derrubou |
| 58 | O backlog cumpre as promessas do próprio `meta:` | HARD | backlog que promete teto e carimbo no cabeçalho e não cobra nenhum dos dois — inchando |
| 67 | Grafo de pesquisa com REVISITA carimbada (meta.review_after) | SOFT | pesquisa que envelhece em silêncio — 27 grafos em docs/evolution/research/ sem nenhuma data de |
| 68 | Confiança alta com fonte fraca | SOFT | evidência externa "confirmada" com confidence >= 0.8 apoiada em fonte de baixa autoridade |
| 69 | Roster de fontes com revisita vencida (docs/onion/radar-sources.yaml) | SOFT | fonte de rotina (semanal/mensal/trimestral/anual) esquecida — o roster nasceu na F2 como DADO da |
| 78 | `.kg.yaml` versionado é YAML VÁLIDO, com catraca | HARD + SOFT | grafo que o kg-radar aceita (parser awk sobre TEXTO) e que qualquer consumidor com lib YAML rejeita |
| 82 | Os dois leitores do corpus CONCORDAM sobre quem é nó | HARD + SOFT | grafo válido em que o radar (awk sobre texto) e o PyYAML veem populações DIFERENTES |
| 87 | PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele | SOFT | propor contra o próprio corpus — o defeito medido em 2026-09-19 |
| 89 | Rodada de radar selada reconcilia o corpus que superou (Aufhebung), com catraca | HARD + SOFT | a UNICA divida deste corpus que piora sozinha — rodada de radar selada como baseline sem |

## Automação Graduada

Classes de ação (HUMAN→MONITORED→DYNAMIC→AUTO) sobem de degrau com gate de promoção alcançável — nenhum rung-jump forjado.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 44 | Integridade da escada de Automação Graduada | HARD | classe sobe de degrau sem gate de promoção alcançável (rung-jump forjado) |
| 65 | Radar de mundo com baseline DATADA por eixo | HARD + SOFT | decidir estratégia com percepção externa vencida SEM AVISO — o modo-de-falha medido no |

## Federação

Mapa, console, agent-card e canais de membro em sincronia com o SSOT da rede.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 24 | Console da federação (docs/onion/federation-console.html) sincronizado com o SSOT | HARD | console da federação publica estado que não bate com o SSOT |
| 25 | Agent Card A2A do core (docs/onion/agent-card.json) sincronizado com o SSOT | HARD | agent-card A2A do core driftando do SSOT — interop mente |
| 28 | Anúncio em staging para membro SEM canal de recepção | SOFT | anúncio a um membro sem canal de recepção — entrega no vazio |
| 38 | Mapa da federação (docs/onion/federation-map.md) sincronizado com members.yaml | HARD | mapa da federação driftando de members.yaml |
| 46 | Canal da federação: diretório de outbox tem membro correspondente | SOFT | anúncio órfão — diretório de outbox cujo nome não é id de membro nunca é servido pelo pull, e some em silêncio |
| 66 | Registro da federação validado no gate (members.yaml) | HARD | membro quebrado entrando calado no ledger — o M2 da spec m3-federation-admin |

## Projeção & privacidade

O que pode sair para superfícies públicas ou vendorizadas — nome de cliente e deep-link privado nunca vazam (nem a HOME crua do source privado, num artefato de plugin); e o compose commitado nunca publica porta em 0.0.0.0 nem sobe com segredo de fallback.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 30 | Segurança de PROJEÇÃO: nome comercial de membro privado não sai | HARD | nome comercial de membro privado vazando em superfície pública |
| 33 | Segurança de projeção no HISTÓRICO DE FEDERAÇÃO (mailbox-aware) | HARD | nome privado vazando no histórico de federação (mailbox) |
| 34 | Site: a derivação nunca vira fonte | HARD + SOFT | o build do site (derivação) entrando no git como se fosse fonte |
| 35 | Site público não linka deep-link do repo PRIVADO (404 garantido) | HARD | site público linkando deep-link de repo privado — 404 garantido |
| 36 | Superfície VENDORIZADA sem nome comercial de cliente | HARD | nome comercial de cliente vazando em superfície vendorizada |
| 45 | Link vendorizado não aponta caminho core-privado, com catraca | HARD + SOFT | link vivo em superfície vendorizada para caminho core-privado — morto no adotante |
| 61 | Fronteira de MOAT: manifesto de plugin publicável não vaza meta-fábrica nem grafo privado | HARD | publicar a AUTO-REPLICAÇÃO (create-*/adopt/marketplace/decouple) ou o SSOT PRIVADO do core |
| 64 | Compose sem bind local ou com segredo em fallback literal | HARD + SOFT | porta publicada em todas as interfaces (o Docker ignora o firewall do HOST — ufw/iptables |
| 79 | Artefato de plugin não publica o repo-fonte PRIVADO como endereço | HARD | plugin/marketplace publicando a URL do source privado — 404 no instalador |

## Processo com resíduo

O trabalho PROPOSTO carrega rastro material de ter sido revisado — o gate cria a cadência, o worker testa a verdade.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 56 | PR aberto carrega RESÍDUO da passada adversarial | HARD | trabalho proposto sem revisão semântica — e sem forma de saber que não houve |

## Integridade do próprio gate

As demais categorias perguntam 'achei violação?'. Esta pergunta 'eu cheguei a olhar?' — porque varredura cega devolve zero violações, que é indistinguível de conformidade. Categoria nova em 2026-08-04, quando o lint rodou de dentro de um worktree de harness e varreu 0 dos 51 agentes sem emitir uma linha de aviso. A REGRA 86 entrou aqui em 2026-09-17 pelo mesmo motivo, um andar acima: um workflow que não PARSEIA não é um gate que falhou, é um gate que nunca rodou — e o repo o contava como existente. A REGRA 88 entrou em 2026-09-20 pela versão mais perversa da classe: o gate rodava, mas sem árvore — `bash <script do repo>` saía 127, o job reprovava TODO PR e a mensagem culpava o código revisado. Gate que nunca olhou, acusando.

| Nº | Regra | Severidade | O que previne |
|---:|-------|:----------:|---------------|
| 54 | A varredura ENXERGA o que existe (guarda-das-guardas) | HARD | gate que varre ZERO arquivo e mesmo assim reporta OK — verde sem ter olhado |
| 86 | Workflow de CI PARSEIA como YAML | HARD | workflow inexecutável passando por existente, e guarda morta por sintaxe |
| 88 | Job de workflow que EXECUTA arquivo do repo faz checkout | HARD + SOFT | job sem `actions/checkout` invocando script versionado; o bash sai 127 e o `rc != 0` |
