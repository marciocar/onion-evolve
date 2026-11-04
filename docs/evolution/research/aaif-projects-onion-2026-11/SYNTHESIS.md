---
title: Os dez projetos da AAIF contra as peças do Onion e do kg-ssot
date: 2026-11-04
kg: docs/evolution/research/aaif-projects-onion-2026-11/aaif-projects-onion-2026-11.kg.yaml
run_id: wf_d0eaf605-d27
tokens: 2056182
agents: 25
duration_min: 24.7
review_after: 2026-12-04
type: research
mode: primaries
---

# Os dez projetos da AAIF contra as peças do Onion e do kg-ssot

**A pergunta** (`Q_AAIF_PROJECTS_ONION_2026_11`, SAC-275): para cada projeto da fundação, que peça nossa ele toca, por caminho, e o que fazer. Critério pré-registrado: **ADOTAR**, **COSTURAR**, **PERFIL POR CIMA**, **SEM RELAÇÃO**; sem medida em rodagem, o teto é **PARQUE** com gatilho nomeado. Ser membro da fundação não conta, nem estrelas do GitHub.

**A resposta:** nada novo a adotar, e nenhuma peça muda por esta tabela. MCP já está em uso nas duas peças. Agent Skills e o card A2A ficam como perfil medido. Nenhum projeto chega a COSTURAR, porque nenhum tem consumidor nomeado.

Este texto é projeção do grafo: a tabela sai dos campos `x_` dos nós `C_TETO_*` (`C_TABELA_FINAL_AAIF_2026_11`). A classe é aplicação do critério, não selo do maestro. A coluna kg-ssot é testemunho da sessão kg-ssot como dono, salvo onde indica medida.

## Tabela projeto × peça

| Projeto | Onion | peça Onion | kg-ssot | peça kg-ssot | Gatilho |
|---|---|---|---|---|---|
| **MCP** | ADOTAR (já vigente, ação zero) | .claude/utils/federation-transport/a2a-rt-mcp.py | ADOTAR (já vigente, ação zero) | vendor/kg-ssot/tools/kg_mcp.py | Sem parque. a2a-rt-mcp ganha a era nova quando um cliente só 2026-07-28 aparecer; kg_mcp larga a era antiga quando Qwen, Vibe e Desktop migrarem (testemunho). |
| **Agent Skills** | PERFIL POR CIMA (medido), com exceção declarada para paths | .claude/skills/ e o molde em .claude/skills/onion-patterns/SKILL.md | PERFIL POR CIMA (medido, 1/1) | vendor/kg-ssot/skills/kg-ssot/SKILL.md | Sem parque. Mudar o molde onion-patterns só depois de medir o efeito de name no Claude Code e nas portas. |
| **A2A** | PERFIL POR CIMA no card 0.3.0 (medido); PARQUE no fio e na v1.x | .claude/utils/federation-transport/ e docs/onion/agent-card.json | SEM RELAÇÃO (testemunho) | nenhuma por caminho | v1.1.0 final do A2A publicada, ou membro que exija cliente v1 estrito. |
| **AGENTS.md** | SEM RELAÇÃO no core; PARQUE no porte onion-codex | nenhuma no core (0 AGENTS.md rastreados); AGENTS.md só no repo onion-codex | PARQUE (testemunho) | nenhuma por caminho; parque por escolha do dono | kg-ssot: um adotante pedir. Core: o core ou uma porta ganhar AGENTS.md. onion-codex: medida do arquivo dele no Codex. |
| **Goose** | PARQUE | .claude/hooks/ (o veto a comparar) e docs/evolution/research/port-spikes-qwen-vibe-2026-11/harness/ | PARQUE (testemunho) | vendor/kg-ssot/tools/kg_mcp.py | Entrar como célula na bancada das portas (kg-ssot); para o Onion, também uma porta ou adotante que o nomeie como consumidor. |
| **agentgateway** | PARQUE | .claude/utils/federation-transport/a2a-send.sh e a2a-verify.sh | PARQUE (testemunho) | vendor/kg-ssot/tools/kg_mcp.py, perfil atrás de proxy | Adotante em produção que ponha A2A ou MCP atrás de um gateway (kg-ssot). |
| **OpenSandbox** | PARQUE | ops/chat-runner.sh (degrau 2 do isolamento do /chat) | PARQUE (testemunho) | ferramenta de bancada, caminho não conferido no vendor | Onion: o convidado do /chat voltar a executar código, ou adotante com KVM pedir isolamento por sessão. kg-ssot: medida de agente que precise de escrita ou rede. |
| **OpenEnv** | SEM RELAÇÃO | nenhuma por caminho; a bancada .claude/validation/ é gate de shell | PARQUE (testemunho) | ferramenta de bancada, caminho não conferido no vendor | kg-ssot: medida de agente que precise de escrita ou rede. Onion: reabre se o core passar a treinar ou avaliar agente por reforço. |
| **Agent Router** | SEM RELAÇÃO | nenhuma por caminho | SEM RELAÇÃO (testemunho) | nenhuma por caminho | Reabre se uma porta ou adotante precisar rotear entre provedores de modelo. |
| **Open Responses** | SEM RELAÇÃO | nenhuma por caminho | SEM RELAÇÃO como interface (testemunho) | nenhuma como interface; vendor/kg-ssot/spec/conformance/ é parente possível | Reabre se uma porta exigir o fio Responses. kg-ssot: leitura possível de bin/compliance-test.ts como parente de spec/conformance/, sem compromisso. |

**Onde a tabela contraria alguém, de propósito:**
- **MCP:** o kg-ssot diz "nada a adotar agora", e o critério dá ADOTAR pelo braço "padrão com implementação conferida". As duas coisas cabem: a classe registra que o padrão já está dentro, e a ação é zero. Ele também disse que falta cliente real da era nova; esta cura mediu um, o Goose, com stub no lugar do modelo.
- **OpenEnv:** o Onion fica em SEM RELAÇÃO e o kg-ssot em PARQUE. O core não tem peça por caminho. A peça de bancada do kg-ssot é testemunho dele; o caminho não foi conferido no vendor.

## O que foi medido

Tudo com script e log em `data/`, chave fictícia, isolado, em loopback. Stub mede a decisão local do harness, não um modelo.

| Medida | Resultado | Nó |
|---|---|---|
| `skills-ref validate` | core 4/14; só com `name`, em cópia, 12/14; as 2 restantes caem por `paths`. kg-ssot 1/1 | `E_MEDIDA_SKILLS_REF_VALIDATE_1104` |
| Goose como cliente MCP | fala 2026-07-28 com o `kg_mcp` e chama `kg_schema_help`; no `a2a-rt-mcp` recebe -32601 e cai para 2025-11-25 | `E_MEDIDA_GOOSE_CLIENTE_MCP_REAL_1104` |
| Sonda stdio dos dois servidores | `kg_mcp`: 2, 7 ou 9 ferramentas sem `initialize`, conforme `--root` e `--read-only`. `a2a-rt-mcp`: ecoa em `initialize` uma versão que não implementa | `E_MEDIDA_MCP_STDIO_DOIS_SERVIDORES_1104` |
| AGENTS.md na requisição do Claude Code | com os dois arquivos só o CLAUDE.md vai; com `@AGENTS.md` importado, os dois | `E_MEDIDA_AGENTS_MD_NA_REQUISICAO_1104` |
| `a2a-sdk` 1.3.0 no nosso card | `parse_agent_card` lê pela compatibilidade; o parse estrito do tipo v1 falha em `protocolVersion` | `E_MEDIDA_A2A_SDK_LE_CARD_0_3_1104` |
| Envelope `{jws, signal}` pelo agentgateway | sha256 idêntico, com ou sem a política `a2a`; com ela, o `url` do card é reescrito | `E_MEDIDA_AGENTGATEWAY_ENVELOPE_INTEGRO_1104` |
| 41 citações, reabertas cruas | 35 literais, 5 só por marcação, 1 paráfrase de campos JSON que `gh api` confirma | `E_CONFERENCIA_CRUA_DAS_41_CITACOES` |

**O veto de hook**, com controle positivo verde nos dois (`E_MEDIDA_VETO_GOOSE_E_CC_1104`). A prova é o marcador criado pelo comando, não o rc do harness:

| Célula | Goose 1.57.0 (auto) | Claude Code 2.1.318 (bypass) |
|---|---|---|
| sem hook (controle) | roda | roda |
| exit 2 | barra (3/3) | barra (1) |
| exit 1 | libera (3/3) | libera (1) |
| comando inexistente | libera (1) | libera (1) |
| exit 1 ou inexistente, com block | barra (1 cada) | barra (1 cada) |

Isso corrige o rótulo de `E_OBJECAO_C21`: o fail-open é dos dois, logo não é "a diferença real". O que a medida significa para a frase do `CLAUDE.md` (l.16 em `1cf173342`) ficou em `Q_DOCTRINE_EXIT2_REVIEW_2026_11`, fechada pelo selo do maestro de 2026-11-04 (`D_EXIT2_COUPLING_WORDING_2026_11`, em `docs/evolution/research/exit2-coupling-against-2026-11/`). Esta rodada não redigiu doutrina.

**Dois tropeços do laboratório, declarados:**
- Na 1ª passada do veto, o controle positivo não rodou: o stub morria por herdar o pipe da substituição de comando. O lote foi descartado.
- Na 1ª passada do agentgateway, o proxy estava em 127.0.0.1, mas as portas de gestão padrão escutaram em todas as interfaces (stats e readiness) por poucos segundos, sem credencial nem proxy nelas. A rodada que vale fixa as três em 127.0.0.1, com prova no log dele.

## Mercado e capital

`aaif.io/members/` traz preço de tabela (`E_AAIF_MEMBERSHIP_DUES_TABLE`, trecho em `data/aaif-members-dues-excerpt.txt`):

| Nível | Fora da LF | Já membro da LF |
|---|---|---|
| Platinum (limite de 8, "Not Available") | $370.000 | $350.000 |
| Gold | $220.000 | $200.000 |
| Silver, por headcount | $10.000 a $95.000 | $5.000 a $75.000 |
| Associate, pré-aprovados sem fins lucrativos e universidades | sem custo | sem custo |

Ser Silver da LF é pré-requisito. É preço de tabela da fundação: não diz quem pagou, quanto entrou, nem o recorte por projeto, e a página não declara o período da cota. Nenhuma rodada, M&A ou down round entrou nesta pesquisa: o eixo de capital aqui é só esta tabela.

## O que a revisão da curadoria mudou

Os 15 achados foram tratados como hipótese e conferidos. Nenhum foi recusado por inteiro; quatro tiveram parte recusada ou corrigida (2, 4, 7 e 13).

| # | Achado | Destino |
|---|---|---|
| 1 | Tetos contra o critério | **Aplicado**, com as células re-medidas |
| 2 | Antecedente da doutrina | **Aplicado:** arestas e frase retirada. A formulação proposta para a doutrina foi **recusada**: esta rodada não redige doutrina, e a parte sobre mods não foi re-medida nem cabe citar aqui |
| 3 | "Diferença real" é falso contraste | **Aplicado**, com medida própria |
| 4 | Ausência de capital | **Aplicado com correção:** a revisão só deu a coluna Silver de quem já é membro; faltavam "Not Available", o pré-requisito e a falta de período |
| 5 | kg-ssot reduzido a um arquivo | **Aplicado:** coluna própria, `SKILL.md` validado, licenças lidas |
| 6 | Gatilho ausente | **Aplicado** nas dez linhas |
| 7 | Peça sem caminho | **Aplicado.** `ops/chat-runner.sh` conferido como peça do OpenSandbox. **Recusado** o cruzamento com "91 nós de treino": a palavra casa em maioria treinamento humano e pós-treino de modelo, sem relação com agente por reforço |
| 8 | Adotantes do Agent Router | **Aplicado:** 12 entradas, 11 reais, autoinscritas |
| 9 | Charter do AGENTS.md | **Aplicado** |
| 10 | Objeções superadas pela medida | **Aplicado**, uma superação por objeção, sem apagar |
| 11 | OpenEnv sem nó ancorado | **Aplicado:** 3 nós |
| 12 | Rejeitadas sem nó | **Aplicado:** 4 nós |
| 13 | Resumidor virando "lido" | **Aplicado** nos 41 nós; a conta é 35 + 5 + 1, não 36 + 5 |
| 14 | Infraestrutura em repo público | **Aplicado** |
| 15 | Data do agentgateway | **Aplicado:** faixa, sem data exata |

## NÃO-VERIFICADOS

Também em `Q_AAIF_NAO_MEDIDO_2026_11`.

- **Adoção real** de qualquer projeto: só há autodeclaração, depoimento ou autoinscrição.
- **Quem paga por projeto e receita da fundação:** só preço de tabela; documento fiscal da LF não aberto.
- **OpenEnv, OpenSandbox, Agent Router e `compliance-test` de Open Responses nunca rodaram.** O wheel do OpenEnv foi só inspecionado. OpenSandbox pede Docker, com a máquina em carga alta.
- **Envio real ao perfil A2A por cliente v1:** só o parse do card, sem POST em produção. O parse usa `ignore_unknown_fields`, logo não prova conformidade v1. A rodagem em produção vem do corpus, não refeita.
- **`a2a-verify.sh` atrás do proxy** e MCP pelo agentgateway.
- **Efeito de `name` no Claude Code e nas portas:** por isso o molde das skills não muda aqui.
- **AGENTS.md do `onion-codex` no Codex:** peça real, sem medida.
- **Goose** em ferramentas além de shell e em subagentes. Plugin de projeto carregou sem pedir confiança; o efeito disso não foi medido.
- **Login real:** tudo com chave fictícia e `-p`. A maioria das células teve 1 corrida.
- **Suíte de conformidade do MCP** contra servidor próprio.
- **Goose contra o `a2a-rt-mcp.py` atual:** o rebase sobre origin/main 1cf173342 mudou o arquivo, mas não o handshake. A sonda stdio foi refeita com o mesmo resultado; a célula do Goose, não.
- **Varredura funcional fora do core:** bridge e repos das portas.
- **Nomes das 10 cadeiras do Governing Board:** vieram por WebFetch; o texto cru de `aaif.io/about/` não os traz.
- **Extensão Skills over MCP e Open Plugins hooks specification:** sem cruzamento.
- **Data exata de entrada do agentgateway** na AAIF.
- **O diretório da pesquisa de doutrina** ainda não existia em `origin/main` nesta data, então é citado em texto, sem aresta.

## Ações nomeadas, não executadas

- `C_DEFEITO_A2A_RT_MCP_ECOA_VERSAO`: `a2a-rt-mcp.py` l.482-483 ecoa em `initialize` uma versão que não implementa. Sem efeito no Goose; fica para o core tratar.
- Molde `onion-patterns`: prescrever `name` depende de medir o efeito no Claude Code e nas portas.

## Valeu a pena

**Valeu, e a rodada sozinha não bastava.**

- **Custo do run:** 2.056.182 tokens, 25 agentes, 24,7 minutos, ≈20k por nó nos 101 nós da rodada. O histórico do modo primárias era ≈42k por nó (`wf_1865aba9-e20`), então é o mais barato por nó já citado na doutrina.
- **O que o run entregou:** o mapa e as 41 citações, que se sustentaram.
- **O que não entregou:** a tabela. A rodada de leitura não podia passar de PARQUE, e deixou três linhas contra o próprio critério.
- **O que pagou a diferença:** a revisão cruzada da curadoria, o parecer do dono e 26 células de rodagem baratas, mais as sondas. Elas moveram 6 das 10 linhas: Agent Skills e A2A ganharam medida, AGENTS.md, Agent Router, Open Responses e OpenEnv caíram para SEM RELAÇÃO no core.
- **Custo da cura e da revisão:** não instrumentado; nenhum dos dois está nos tokens acima.
- **Lição para a próxima rodada de primárias:** rodar o barato faz parte da rodada, senão a coluna classe nasce vazia.

Próxima revisita: 2026-12-04, cadência de ferramenta (REGRA 67 (Grafo de pesquisa com REVISITA carimbada)). Antecipam: v1.1.0 final do A2A, fecho da pesquisa do exit 2, consumidor nomeado para Goose ou agentgateway.
