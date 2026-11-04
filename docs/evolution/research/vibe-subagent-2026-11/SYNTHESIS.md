---
title: O subagente do Mistral Vibe — o que a fonte pública diz e o que a medida corrigiu
date: 2026-11-04
kg: docs/evolution/research/vibe-subagent-2026-11/vibe-subagent-2026-11.kg.yaml
run_id: wf_0c8a4e9e-8da
tokens: 6646842
agents: 90
duration_min: 16
review_after: 2026-12-04
type: research
mode: qa
---

# O subagente do Mistral Vibe — o que a fonte pública diz e o que a medida corrigiu

**A pergunta** (`Q_VIBE_SUBAGENT_SESSION_HOOKS_1104`): no Vibe 3.0.4, como o subagente do `agents.spawn` grava a sessão
e o vínculo com o pai, como o registro do filho liga o `pre_tool` negado ao `toolCallId`, se os hooks do projeto rodam
nele e qual a forma dos efeitos? Veio da decisão do maestro de buscar a questão na documentação e na comunidade
(`D_PORT_SPIKES_R2_RODAR_APROVADO_E_PESQUISAR_VIBE_1104`). Esta síntese é projeção do grafo; a fonte é ele.

**Como:** `/onion-research`, gênero `qa`, orçamento 15 leituras e 20 verificações, seguido de uma conferência contra a
evidência arquivada dos testes das portas. O run terminou às 13:00Z e as células de veto do subagente rodaram a partir
das 18:55Z, então a pesquisa não as viu. **Nenhuma célula nova rodou nesta conferência:** recontei os arquivos de
`evidence-r2veto.tar.gz` e `evidence-r2.tar.gz`.

## Resposta

| Item | Fonte pública (run) | Medida na 3.0.4, modelo stub, 7 células de veto |
|---|---|---|
| (1) Onde o filho grava | código da v3.0.3: `<storage_root>/unified/<session_id>`, ao lado da raiz | **confirma** (7 de 7): `logs/session/unified/child-<id>`, com `CURRENT`, `chunks`, `generations` e `journal` |
| (1) O vínculo | `parent_session_id` documentado no stdin; `childSessionId` só no código | **confirma**, e **limita**: ver as correções 1 e 5 |
| (2) `skipped` ligado ao `toolCallId` | sem fonte | **respondido:** o efeito não traz o id; a mensagem e o aviso trazem |
| (3) Hooks no filho e stdin | doc, README, PyPI e release v3.0.2: herdados | **confirma o herdado e os campos**, mas só em escopo de usuário: ver o limite abaixo |
| (4) Forma dos efeitos | sem fonte | **respondido, e a premissa cai como forma única:** correção 3 |

## O que a medida corrigiu (`E_VIBE_SUBAGENT_MEDIDO_NOS_SPIKES_1104`)

Os nós da pesquisa ficam como estão; a correção entra por este nó e por aresta `CONSTRAINS`.

1. **O filho não tem `meta.json`.** `C_SUPERACAO_20261104_CHILD_SESSIONS_EMPTY_BY_STRUCTURE` põe o `parent_session_id`
   no meta do filho, por leitura de código. O diretório do filho não tem esse arquivo em nenhuma das 7. A chave está em
   `generations/*/runtime-state.json`, com o id do pai. O `child_sessions` vazio no `meta.json` do pai se confirma nas 7,
   sempre com um único spawn.
2. **O efeito vetado não traz `toolCallId`.** O id da chamada está na mensagem de ferramenta (`role` tool, `name` bash) e
   no aviso `hook_completed`, com `level` error e «Denied tool 'bash'». A junção real é o par `action_id` e `call_id`, em
   `journal` e `generations` (`PRE-REGISTRO-R2.md`, seção 13). Isso responde à pergunta aberta do retorno: não ganhou.
3. **`toolName` «tool» e `input` null valem só no vetado.** O efeito vetado tem `toolName` "tool", `input` null, `status`
   skipped e o veto em `settledMessage`. Os concluídos mantêm o `input` e o nome qualificado: `file_system.bash` no filho
   do controle (3 de 3), e `file_system.read_file`, `agents.spawn` e `self.wait` no pai (7 de 7). No stdin do hook o nome
   vem sempre qualificado, inclusive na chamada vetada.
4. **O hook dispara de dentro do `run_typescript`**, lacuna que nenhuma fonte cobria: o `agents.spawn` chega ao hook com
   `tool_call_id` `typescript:5:call_…:0:tool:0`, em 7 de 7. O mesmo vale para o bash e o `process.start` no lote `r2`.
5. **O campo documentado não é o que o pai expõe.** O retorno recomendava depender do `parent_session_id`. No stdout
   JSON do pai aparece o `childSessionId`, não documentado, e não aparece o `parent_session_id`, que só chega por hook.
   Quem lê só o stdout depende do detalhe de implementação, e a recomendação pede um hook no caminho.
6. **O `childSessionId` null é a forma `running`.** Ele aparece nos chunks do pai em 7 de 7, e a forma `completed` traz o
   id. Com um spawn por célula, isso não diz nada sobre N filhos concorrentes.

**Confirmado sem correção, em 7 de 7:**
- o stdin do `pre_tool` traz exatamente `cwd`, `hook_event_name`, `parent_session_id`, `session_id`, `tool_call_id`,
  `tool_input`, `tool_name` e `transcript_path`;
- no hook do filho, o `parent_session_id` é o id do pai, e nos hooks do pai é null;
- o `transcript_path` aponta o store da própria sessão;
- o motivo do veto chega ao modelo do filho como resultado de ferramenta, com o `tool_call_id` da chamada;
- `_meta['mistral.vibe.subagent']` traz `agentName`, `agentType`, `childSessionId`, `generation` e `spawnCallId`, este igual
  ao `tool_call_id` do hook do spawn.

**O limite que mais pesa:** os hooks das células ficam em `$VIBE_HOME/hooks.toml`, escopo do usuário. A pesquisa fala de
hooks **do projeto**, em pasta confiável, e isso a medida não testou. Uma porta que instale o hook no projeto ainda
depende só da documentação nesse ponto.

## Mercado (`E_MERCADO_VIBE_SUBAGENT_1104`)

Sem sinal. O ângulo de mercado e capital só devolveu a documentação do pacote no PyPI: nenhuma rodada, M&A ou leitura de
analista sobre o Vibe nem sobre o desenho de subagentes e hooks da Mistral. Ausência de sinal numa busca estreita, sobre
formato de registro, não é conclusão de que não há movimento.

## NÃO-VERIFICADOS

**Do retorno do run (`E_LACUNAS_VIBE_SUBAGENT_1104`):** 16 confirmadas, 4 refutadas, nenhuma por fonte fraca, 0 não
verificadas, 0 reprovações recusadas pelo motor, 4 superações.

**Sem medida depois desta conferência:**
- hooks de projeto e pasta confiável;
- `post_tool` e `post_agent`: só `pre_tool` estava configurado, logo «`post_tool` não dispara na negação» segue só documentado;
- modelo real no filho: se ele relataria o veto ao pai não foi medido;
- N filhos concorrentes;
- a 3.1.0, publicada no PyPI no dia da pesquisa: tudo acima é da 3.0.4, e a leitura de código pública é da 3.0.3;
- o formato interno do journal, sem fonte pública;
- a durabilidade do store do filho: ele estava presente ao fim das 7 células, mas a afirmação de que o harness apaga o
  store de um filho fechado foi cortada por orçamento e não foi testada;
- `childSessionId` como contrato estável: segue sem documentação;
- o contrato de `parent_session_id` e `transcript_path`: já sumiram e voltaram na 2.26.0;
- Discord, Reddit e blogs técnicos: sem sinal nesta rodada.

**Refutadas no run, com superação (4):**
- (0-3, tier 9) A documentação oficial do Vibe sobre agentes/subagentes não cobre o formato de gravação da sessão do subagente, nem childSessionId/parent_session_id, hooks PreToolUse, toolCallId, settledMessage ou agents.spawn/run_typescript; não confirma nem refuta o que o core leu no código. Fonte: https://docs.mistral.ai/vibe/code/cli/agents
- (1-2, tier 8) As sessões 2.0+ são pastas com meta.json e messages.jsonl sob ~/.vibe/logs/ (VIBE_HOME). A página não menciona store, chunks, PublicSessionState nem childSessionId; o vínculo pai→filho só aparece como parent_session_id nos hooks, sem documentação como contrato estável. Fonte: https://github.com/MistralAI/mistral-vibe
- (0-3, tier 8) As release notes não documentam o formato de armazenamento da sessão do subagente, o vínculo pai→filho (childSessionId/parent_session_id), o registro de PreToolUse negado com skipped/toolCallId, nem a forma dos efeitos (kind tool, settledMessage); não confirmam nem refutam a leitura do core. Fonte: https://api.github.com/repos/mistralai/mistral-vibe/releases
- (0-3, tier 6) O vínculo pai→filho não é estável: numa issue de spawn, o 3º subagente teve childSessionId null na projeção, e meta.json mostrou child_sessions vazio apesar de 3 subagentes no estado de runtime. Fonte: https://github.com/mistralai/mistral-vibe/issues/1277

**Cortadas por orçamento de verificação (41 afirmações, sem voto):**

<details><summary>A lista inteira, como o run a devolveu</summary>

- tool_name enviado ao hook é sempre qualificado (file_system.bash, process.start, mcp_<servidor>.<ferramenta>). A página não documenta kind, input nulo no estado assentado nem settledMessage, nem agents.spawn. Fonte: https://github.com/MistralAI/mistral-vibe
- O harness mantém o store de cada sessão e apaga o de um filho fechado, então o store do filho não é garantidamente durável. Fonte: https://raw.githubusercontent.com/mistralai/mistral-vibe/v3.0.3/vibe/app_server/_subagent_runs.py
- Este arquivo não cobre hooks PreToolUse no subagente, efeito skipped ligado a toolCallId, stdin dos hooks nem settledMessage ou input null. Esses pontos não são confirmados nem refutados por esta fonte. Fonte: https://raw.githubusercontent.com/mistralai/mistral-vibe/v3.0.3/vibe/app_server/_subagent_runs.py
- O nome da ferramenta nos hooks segue o formato grupo.ferramenta (ex.: file_system.bash) e MCP como mcp_<server>.<tool>; post_tool traz tool_status success|failure e tool_output null em falha. Fonte: https://docs.mistral.ai/vibe/code/cli/hooks
- A página de hooks não documenta o store de sessões do subagente, journal, chunks, PublicSessionState, agents.spawn, run_typescript, kind tool, input null no estado assentado nem settledMessage; esses pontos não são confirmados nem refutados pela doc oficial de hooks. Fonte: https://docs.mistral.ai/vibe/code/cli/hooks
- A v3.0.3 (2026-10-26) incluiu agent_name no payload do hook post_agent; as notas não listam os demais campos do stdin. Fonte: https://api.github.com/repos/mistralai/mistral-vibe/releases
- A v3.0.4 foi publicada em 2026-10-30 (não em novembro); a v3.1.0 saiu em 2026-11-04. Fonte: https://api.github.com/repos/mistralai/mistral-vibe/releases
- O release 2.26.0 restaurou a lista de subagentes e as transcrições ao retomar uma sessão. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/2.26.0
- Plugins não podem reivindicar os namespaces reservados subagent e skill. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/2.26.0
- A página não documenta agents.spawn, childSessionId, PublicSessionState, efeitos skipped nem settledMessage, e não permite confirmar ou refutar o formato de efeitos nos registros. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/2.26.0
- Na v2.26.0 do Mistral Vibe, hooks.toml do harness unificado voltam a receber session_id, transcript_path e parent_session_id no stdin. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v2.26.0
- Na v2.26.0, o tool_input embutido chega aos hooks com os nomes de argumento voltados ao autor da CLI. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v2.26.0
- Plugins não podem reivindicar os namespaces reservados subagent ou skill na v2.26.0. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v2.26.0
- A página não cobre agents.spawn, store de sessões, childSessionId, skipped/toolCallId, settledMessage nem a v3.0.4. É insuficiente para confirmar ou refutar os itens 1, 2 e 4, e não diz se hooks rodam dentro do subagente. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v2.26.0
- A página do PyPI mostra mistral-vibe 3.1.0, publicada em 2026-11-04, e não a 3.0.4 citada na pergunta. Ela não documenta agents.spawn, childSessionId, PublicSessionState, settledMessage nem o formato kind/toolName dos efeitos. Só parent_session_id aparece, no contexto dos hooks. Fonte: https://pypi.org/project/mistral-vibe/
- As sessões do Vibe ficam em VIBE_HOME/logs/ como pastas com meta.json e messages.jsonl. Não há indicação de que o subagente use esse formato, e os subagentes têm enable_subagents (padrão true) e max_subagents. Fonte: https://pypi.org/project/mistral-vibe/
- Subagentes do Vibe são definidos com agent_type = "subagent", acionados pelo agente principal, e devolvem ao pai apenas resultados em texto. Fonte: https://docs.mistral.ai/vibe/code/cli/agents
- Subagentes só usam as ferramentas integradas listadas no seu arquivo (sem MCP, conectores ou plugins), nunca com permissões mais amplas que as do pai; regras [tools.<tool>] só podem restringir. Fonte: https://docs.mistral.ai/vibe/code/cli/agents
- Até 32 subagentes simultâneos por padrão, ajustáveis por max_subagents e max_concurrent_subagents; desativáveis com enable_subagents = false. Fonte: https://docs.mistral.ai/vibe/code/cli/agents
- O changelog do mistral-vibe 3.0.3 não documenta store de sessões, journal, chunks, PublicSessionState, childSessionId nem parent_session_id; o vínculo pai→filho não é documentado nesta fonte. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/3.0.3
- O único hook citado nas notas da 3.0.3 é post_agent, cujo payload inclui agent_name; PreToolUse, skipped e toolCallId não aparecem. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/3.0.3
- As notas da 3.0.3 indicam que mudanças de permissão via /reload chegam aos subagentes já em execução e que subagentes customizados usam o modelo de active_model, sem detalhar hooks de projeto no subagente nem o stdin. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/3.0.3
- A forma dos efeitos nos registros (kind tool, toolName grupo.ferramenta, input null, settledMessage) não aparece nesta fonte, que não confirma nem refuta o que o core leu no código. Fonte: https://newreleases.io/project/pypi/mistral-vibe/release/3.0.3
- A página do PyPI 3.0.3 não documenta store de sessões do subagente, childSessionId, PublicSessionState, nem a forma dos efeitos (kind tool, input null, settledMessage). Cita só sessões em pastas com meta.json e messages.jsonl, e o parent_session_id como campo de hook, sem garantia de estabilidade do vínculo. Fonte: https://pypi.org/project/mistral-vibe/3.0.3/
- Um despacho de hook_call durante spawn/stop de subagente quebra o turno com pydantic ValidationError por deriva de schema entre o core Rust e o adaptador Python; subagentes ficam running para sempre. Fonte: https://github.com/mistralai/mistral-vibe/issues/1277
- A issue não cobre skipped/toolCallId em negação por PreToolUse, stdin dos hooks no subagente nem a forma input null/settledMessage; é bug report da v2.26.1, não doc da 3.0.4. Fonte: https://github.com/mistralai/mistral-vibe/issues/1277
- Na v3.0.2 do Mistral Vibe, hooks definidos em hooks.toml passaram a rodar também para chamadas de ferramenta feitas dentro de subagentes. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.2
- A v3.0.2 corrigiu a abertura de sessões salvas pela v3.0.0, que falhavam com 'Invalid Unified session store'; isso é a única menção a store de sessões, sem documentar vínculo pai→filho. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.2
- Subagentes personalizados passaram a aplicar suas regras de permission, allowlist e denylist às próprias chamadas de ferramenta, e os limites padrão subiram para 32 ativos/32 simultâneos (antes 8 e 4). Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.2
- As notas da v3.0.2 não documentam registro de efeito skipped, toolCallId, settledMessage, childSessionId nem campos de stdin dos hooks; esses pontos não são confirmados nem refutados por esta fonte. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.2
- As notas de release do Mistral Vibe (página v3.0.4, conteúdo que lista mudanças da v3.1.0) não contêm nenhuma informação sobre agents.spawn, run_typescript, store de sessões, PublicSessionState, childSessionId/parent_session_id, hooks PreToolUse com toolCallId ou settledMessage; os pontos (1) a (4) não podem ser confirmados nem refutados por esta fonte. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.4
- O changelog menciona melhorias de UI de subagentes: a lista oculta subagentes em espera quando o trabalho termina, e respostas a perguntas de subagentes chegam até eles. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.4
- O changelog indica que hooks de plugins nativos agora executam e que hooks de plugins de outros agentes são reportados como não suportados, sem detalhar se rodam dentro de subagentes nem os campos do stdin. Fonte: https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.4
- Em Mistral Vibe, o payload de hooks inclui parent_session_id, preenchido quando o hook roda dentro de um subagente; a página não documenta estabilidade do vínculo nem childSessionId. Fonte: https://tessl.io/registry/skills/github/mistralai/mistral-vibe/vibe
- Subagentes herdam a configuração de hooks do pai, e os eventos de hook do subagente são gravados no log de sessão do subagente, sem propagar para a UI do pai. Fonte: https://tessl.io/registry/skills/github/mistralai/mistral-vibe/vibe
- O stdin dos hooks traz hook_event_name, session_id, parent_session_id, transcript_path, cwd, tool_name, tool_call_id e tool_input; post_tool acrescenta tool_status, tool_output, tool_output_text, tool_error e duration_ms. Fonte: https://tessl.io/registry/skills/github/mistralai/mistral-vibe/vibe
- Uma negação em pre_tool devolve o reason como erro da ferramenta ao LLM, e post_tool não dispara quando a ferramenta nunca executou; a página não descreve registro skipped, role tool ou outcome ligados ao toolCallId no log do filho. Fonte: https://tessl.io/registry/skills/github/mistralai/mistral-vibe/vibe
- As sessões locais são gravadas em ~/.vibe/logs/session/ (configurável por session_logging.save_dir); a página não menciona journal, chunks, PublicSessionState, run_typescript, kind/settledMessage nem input null. Fonte: https://tessl.io/registry/skills/github/mistralai/mistral-vibe/vibe
- O hook pre_tool do Mistral Vibe é registrado em ~/.vibe/hooks.toml (nome rtk-rewrite, match=bash, strict=false); com strict=false uma falha do hook vira aviso e a chamada passa. Fonte: https://github.com/rtk-ai/rtk/pull/3391
- O Vibe usa saída de hook em snake_case (hook_specific_output com tool_input reescrito; negação via {"decision":"deny","reason":...}); passagem é exit 0 com stdout vazio; não há decisão ask_user. Fonte: https://github.com/rtk-ai/rtk/pull/3391
- A fonte não aborda subagentes (agents.spawn, run_typescript), store de sessões, childSessionId/parent_session_id, efeitos skipped, settledMessage nem hooks dentro de subagente; não confirma nem refuta os pontos 1-4. Fonte: https://github.com/rtk-ai/rtk/pull/3391

</details>

**Cortadas por orçamento de leitura (19 fontes, nunca abertas):**

<details><summary>A lista inteira</summary>

- Notas de release mistral-vibe 3.0.1 (high): https://newreleases.io/project/pypi/mistral-vibe/release/3.0.1
- Creating sub-agents with Mistral Vibe (blog técnico) (medium): https://www.sicpers.info/2026/01/creating-sub-agents-with-mistral-vibe/
- xhluca/session-migrate (medium): https://github.com/xhluca/session-migrate
- Atoll92/agent-standup (medium): https://github.com/Atoll92/agent-standup
- Issue #1232: mudança de config torna a sessão não retomável (high): https://github.com/mistralai/mistral-vibe/issues/1232
- Issue #1231: run_typescript esperando subagent.wait atinge o deadline de segurança (medium): https://github.com/mistralai/mistral-vibe/issues/1231
- TabNews: o que aprendi lendo os logs não documentados do Claude Code, Codex e Mistral Vibe (medium): https://www.tabnews.com.br/atoll92/pitch-o-que-aprendi-lendo-os-logs-nao-documentados-do-claude-code-codex-e-mistral-vibe
- Issue #1379: subagentes terminados ainda contam contra max_subagents (low): https://github.com/mistralai/mistral-vibe/issues/1379
- mistral-vibe v3.0.1 release notes (low): https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.1
- mistral-vibe v3.0.3 release notes (medium): https://newreleases.io/project/github/mistralai/mistral-vibe/release/v3.0.3
- mistral-vibe 3.0.0 (PyPI) release notes (medium): https://newreleases.io/project/pypi/mistral-vibe/release/3.0.0
- TypingMind: skill mistralai vibe (low): https://www.typingmind.com/skills/mistralai-vibe
- CLIArena (comparação de scaffolding de agentes) (low): https://github.com/charles-azam/CLIArena
- ahh1539/vibe-helper (low): https://github.com/ahh1539/vibe-helper
- Claude Code issue 26495: PreToolUse hooks cannot detect subagent vs main session (low): https://claudeissues.com/issue/26495-pretooluse-hooks-need-a-way-to-detect-subagent-vs-main-session-context
- Claude Code docs issue 19946: SubagentStart input schema missing (low): https://claudeissues.com/issue/19946-docs-missing-subagentstart-input-schema-definition-in-hooks-reference
- Mistral compra a Koyeb (primeira aquisição) (low): https://www.pulse.bot/ma/news/mistral-seals-first-acquisition-deal-with-cloud-startup-koyeb-8325d5e6-4a5a-4ed7-9e72-fa9636f148f3/
- Mistral levanta cerca de €3 bi (avaliação de ~€21 bi) (low): https://w.media/mistral-ai-raises-e3-billion-in-record-european-tech-funding-round/
- Mistral Vibe: Architecture Overview (doc comunitário) (low): https://codedocs-2gm.pages.dev/raw/mistral-vibe/00-overview

</details>

## Valeu a pena

**6.646.842 tokens, 90 agentes, 15,6 min, 23 nós: cerca de 289 mil tokens por nó.** Os tokens são o `totalTokens` do
diário do run, e os 90 agentes batem com o journal (90 inícios e 90 resultados) e com os 90 transcritos. **O journal não
guarda tokens.** Somei os transcritos para conferir e não reconciliou: entrada, saída e criação de cache dão 5.344.439
sem repetir mensagem e 9.729.521 com repetição, e a leitura de cache soma mais 28,9 milhões sem repetir. Fica o número
do diário, que é o que o corpus usa, com essa ressalva. A conferência desta síntese não está nesse custo e não foi medida.

Valeu em parte:
- **Valeu:** separou o que é contrato documentado (`parent_session_id`, hooks herdados, datados na v3.0.2) do que é detalhe
  de implementação (`childSessionId`), o que uma célula sozinha não diz.
- **Não valeu tanto:** o custo por nó é o da varredura (cerca de 291 mil na medição da skill) e não o das primárias (cerca
  de 42 mil). As fontes úteis já tinham nome, e menos de seis horas depois as células responderam os itens 2 e 4, que a pesquisa
  não alcançou. Numa próxima pergunta com lacuna nomeada, o modo `primaries` é o indicado.
