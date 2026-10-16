---
kg: docs/evolution/research/chat-agent-isolation-2026-10/chat-agent-isolation-2026-10.kg.yaml
run_id: "wf_505962e3-7c9 (rodada 1, varredura em modo decisão) + wf_8847e3af-370 (rodada 2, primárias nomeadas)"
tokens: 8749759
agents: 122
duration_min: 43
---

# Isolar o agente do /chat do onion-bridge da raiz de confiança

> **Projeção do grafo.** A fonte é o `.kg.yaml` ao lado. Esta página não acrescenta afirmação de domínio que o grafo
> não tenha (o custo e o balanço de "valeu a pena" vêm do journal dos dois runs); quando o grafo muda, ela é regenerada. Radar `--integrity --schema` exit 0 e contrato rc 0
> antes desta prosa.

## Pergunta (`Q_CHAT_AGENT_ISOLATION_2026`)

As sessões de /chat, de admin e de convidados, rodam o agente de código (Agent SDK, com Bash) no **mesmo UID
`onion`** que é dono da raiz de confiança do A2A (JWKS, `members.yaml` do clone servido, fila pendente, estado
de jti) e dos segredos do serviço (`.env` com o M2M do Logto, `.git-credentials` com o PAT). Como isolar,
e o que serve ao ecossistema Onion?

## Decisão ABERTA: o degrau 3 sem objeto no convidado (`D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016`)

Antes de construir o degrau 3, esta rodada mediu o que ele ainda protegeria com os degraus 0 e 2 de pé
(`E_DEGRAU3_OBJETO_MEDIDO_1016`). **Nada no convidado.** Pela doc atual, o sandbox nativo cobre só Bash,
PowerShell e Monitor e os processos que eles iniciam. Ferramentas de arquivo, MCP e hooks rodam fora dele, e
`allowedDomains` não limita o WebFetch. O convidado não tem nenhuma ferramenta que execute: o bridge as nega
em três lugares e o lançador do degrau 2 recusa a sessão que não as negue. A rede que resta é a do **WebFetch**.
Ele aceita IP literal (o preflight da Anthropic respondeu `can_fetch: true` para `127.0.0.1` e
`169.254.169.254`), e o UID do runner alcança por TCP 27 de 27 portas do loopback. Hoje o que fecha o SSRF é o
**protocolo e a verificação de certificado**: o WebFetch só fala https e verifica o certificado (por leitura do código, não exercitado), e no loopback só o
Caddy fecha TLS, para nomes que resolvem no IP público. Nenhuma política o fecha.
O spike `IPAddressDeny=` na unit (`C_SUPERACAO_20261016_EGRESS_PELA_UNIT_NAO_PELO_SANDBOX`) fecha o loopback, o
link-local e as faixas privadas e mantém o DNS e o TLS com a API. Teto: os endereços públicos do próprio host seguem alcançáveis, e o wrapper teria de medi-los e negá-los na instalação.

| Opção | O quê |
|---|---|
| **A (recomendada)** | Parquear o degrau 3 com gatilho e fechar a rede local na unit do runner (`IPAddressDeny=`, um PR em cada repo e um `--apply`) |
| B | Parquear o degrau 3 com gatilho e não mexer na rede (o SSRF segue fechado só pelo protocolo e pelo certificado) |
| C | Construir o degrau 3 mesmo assim (socat, bwrap privado e perfil `userns` para um caminho que o convidado não usa) |

O degrau 3 reabre por **gatilho**: o convidado voltar a ter Bash, PowerShell ou Monitor; o admin passar a rodar
pelo runner; ou a doc do sandbox passar a cobrir o WebFetch ou as ferramentas de arquivo.

## Decisões do maestro sobre os degraus 2 e 3 (seladas em 2026-10-16)

- **Degrau 2** (`D_MAESTRO_DEGRAU2_CONSTRUIR_JA_1016`): «Construir já, instalar com você» (descartadas: «Só a cura
  parcial do data/» e «Parquear com gatilho»). Construído, provado em runtime e **em produção desde 11:31 UTC** (`E_DEGRAU2_EM_PRODUCAO_1016`: verify com 0 falha, repetido por sessão independente).
- **Degrau 3** (`D_MAESTRO_DEGRAU3_DEPOIS_DO_DEGRAU2_1016`): «Depois do degrau 2» (descartadas: «Instalar socat e
  perfil já» e «Parquear»). O caminho sem o managed-settings do host passa pela instância do degrau 2.

## Decisão do maestro (`D_MAESTRO_DEGRAU1_JA_DEGRAUS_2_3_POR_SPIKE_1016`, selada em 2026-10-16)

**«1 já, 2 e 3 por spike»** (descartadas: «Degraus 1 e 2 juntos» e «Parar no degrau 0»), à pergunta «Isolamento
do /chat, degraus 1 a 3 (corrigidos pelas provas). O que selar e executar?». O degrau 1 vira um wrapper core-only
que instala o drop-in de integridade; os degraus 2 e 3 viram spike, sem nada persistente. A decisão-mãe segue
open até os degraus 2 e 3.

## Decisão anterior (`D_MAESTRO_DEGRAU0_E_TRES_PROVAS_1016`, selada em 2026-10-16)

**«Degrau 0 já + 3 provas»** (descartadas: «Só as 3 provas primeiro» e «Selar os degraus 0→3 como estão»).
Rodada anterior (2026-10-15): «Primárias antes de tudo», que gerou a rodada 2.

A decisão-mãe `D_ISOLATE_CHAT_AGENT_FROM_TRUST_ROOT` **segue open**. O selo decide o degrau 0 e as provas, e
os degraus 1–3 esperam as provas virarem evidência.

## A escada recomendada pelo Elenxo (afirmação de 1 agente, sem votação)

| Degrau | O quê | Exige | Estado |
|---|---|---|---|
| **0** | Convidado sem Bash; deny Edit/Write no home do onion fora do workspace **e** no `.claude/` e `CLAUDE.md` do próprio workspace (`E_OBJECAO_32_WORKSPACE_CLAUDE_DIR_WRITABLE`) | nada de root | **decidido (aplicar já)** |
| **1** | systemd reescrito, **só integridade**: sem `EnvironmentFile=` (o segredo iria para o environ legível pelo mesmo UID, `E_OBJECAO_01`), `ReadOnlyPaths=` no código do bridge, `.claude` do home, dotfiles, JWKS e `members.yaml`; `InaccessiblePaths=` no `.ssh` e no `.git-credentials` depois de medir o uso | root uma vez; medir as escritas de um chat real antes do restart | **decidido; ensaiado** (`E_DEGRAU1_INTEGRITY_DROPIN_ENSAIO_1016`), a aplicar pelo wrapper |
| **2** | UID separado por sessão (template `onion-chat@` com `DynamicUser=`), plugado pela costura `spawnClaudeCodeProcess`; a troca de UID é do **chamador** (`E_SDK_SPAWNOPTIONS_HAS_NO_UID`), e o bridge não consegue trocá-la (`E_OBJECAO_27`): lançador ativado por socket, instalado pelo root | root; dogfood do wrapper | **em produção** (`E_DEGRAU2_EM_PRODUCAO_1016`); falta medir um turno real de convidado com a API |
| **3** | sandbox nativo como defesa em profundidade, só com perfil AppArmor numa **cópia privada** do bwrap (`E_OBJECAO_30`: o perfil no bwrap do sistema libera userns às 6 contas), `failIfUnavailable` explícito no nível de política e `allowUnsandboxedCommands:false` | root; política | **sem objeto no convidado** (`E_DEGRAU3_OBJETO_MEDIDO_1016`); decisão aberta (`D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016`) |
| 4 | microVM/container por sessão | KVM (ausente nesta VPS) | fora desta VPS; opcional por adotante |
| 5 | broker estreito (proxy da `ANTHROPIC_API_KEY`, git atrás de ferramenta) **sobre** o degrau 2 | o degrau 2 | aguarda |

## As 3 provas (2026-10-16, medidas em sandbox, sem chave real)

| Prova | Nó | Resultado | Degrau |
|---|---|---|---|
| 1. settings hostil no workspace | `E_PROVA1_WORKSPACE_HOOK_RUNS_WITHOUT_BASH_1016` | Um `SessionStart` no `.claude/settings.json` do workspace **roda** com `settingSources:["project"]` e `tools:["Read"]`, sem Bash, como o UID do chamador. `managedSettings.allowManagedHooksOnly` e `settings.disableAllHooks` o cortam, cada um sozinho. O filtro do `managedSettings` mantém `deny`, `sandbox` e `allowManagedHooksOnly` (e também um `allow`, logo não é puramente restritivo), e descarta `hooks` e `disableSkillShellExecution`. | **corrige o degrau 0**: tirar o Bash não basta, os hooks têm de cair (aplicado no PR do bridge) |
| 2. CLI sob `DynamicUser` | `E_PROVA2_DYNAMICUSER_CLI_SDK_HANDSHAKE_1016` | Unit transitória: UID dinâmico, home 0750 do onion, `.env`, `.git-credentials` e environ do bridge **negados**; o SDK completa o handshake por stdin/stdout via `spawnClaudeCodeProcess`. | **confirma o mecanismo do degrau 2**; o lançador por socket instalado pelo root segue sem prova (o teste usou sudo) |
| 3. sandbox ligado sem sandbox disponível | `E_PROVA3_SANDBOX_FAIL_CLOSED_ONLY_WHEN_EXPLICIT_1016` | Falha **fechado** só com `Options.sandbox` (default `true`) ou com `failIfUnavailable:true` explícito; `settings` e `managedSettings` só com `enabled` **rodam sem gaiola**. | **corrige o degrau 3**: `failIfUnavailable` explícito sempre; `socat` é dependência além do bwrap |

## Degrau 1 ensaiado e spikes dos degraus 2 e 3 (2026-10-16)

| Medição | Nó | Resultado | Degrau |
|---|---|---|---|
| drop-in de integridade numa unit transitória | `E_DEGRAU1_INTEGRITY_DROPIN_ENSAIO_1016` | Antes: `src/`, `jwks/` e `.bashrc` graváveis e o `.git-credentials` legível no namespace vivo. Com o drop-in: as **duas árvores inteiras** (bridge e clone servido) só-leitura e pontos de montagem próprios, com as escritas do serviço aninhadas graváveis (`data/`, `.claude/sessions`, `trust-log.md`), dotfiles e placeholders só-leitura, `.ssh` e `.git-credentials` ilegíveis, e **0 EROFS** sob strace num turno do SDK. | **confirma o degrau 1 e corrige o escopo**: a 1ª forma (subdiretórios) caiu no refutador, porque renomear o pai dava uma árvore nova gravável; a árvore inteira também fecha os `.git` (o `core.fsmonitor` rodaria no git do update-bridge) e o lockfile; placeholders para `.claude/settings*.json`, `.config` e `.npmrc`; `-` em todo caminho (ausente sem `-` = 226/NAMESPACE) |
| lançador por socket sob `DynamicUser` | `E_SPIKE2_SOCKET_LAUNCHER_DYNAMICUSER_1016` | O CLI sobe sob um UID dinâmico por conexão e o SDK completa o init por `spawnClaudeCodeProcess`, sem a home do serviço e sem chamar a API. | **confirma o mecanismo do degrau 2 e corrige três peças**: `User=onion-chat-%i` (sem ele as instâncias simultâneas dividem o UID), `CollectMode=inactive-or-failed`, e o teardown (o EOF encerra o CLI ocioso em 644 ms, mas com requisição em voo só o `RuntimeMaxSec` o matou: o lançador tem de supervisionar, não fazer exec). Aberto: o workspace (0750 da conta do serviço) |
| o que o AppArmor desta VPS exige do sandbox | `E_SPIKE3_APPARMOR_SANDBOX_REQUIREMENTS_1016` | `socat` ausente; o bwrap cai no perfil `unprivileged_userns` (audit do kernel: `setpcap` e `uid_map` negados); o `managedSettings` **descarta** `bwrapPath` e `socatPath`; o perfil `runc` (unconfined, com userns) já existe com o binário instalado. | **corrige o degrau 3**: a cópia privada do bwrap pediria o `managed-settings.json` do root, válido para todo Claude Code do host; o caminho sem esse efeito é dentro da instância do degrau 2. O passo de instalação está no nó, para o maestro |

## Degrau 2 construído (2026-10-16)

| Medição | Nó | Resultado |
|---|---|---|
| spike do workspace | `E_DEGRAU2_WORKSPACE_SPIKE_1016` | O nome da instância (`<n>-<PID>-<UID>`) e o fd passado pela conexão não servem. Escolhido: **grupo + ACL padrão**, com o estado do bridge escondido por `TemporaryFileSystem`; o dono de cada sessão devolve ao grupo o que criou fechado. Teto: o grupo é comum, e entre convidados quem separa é o degrau 0, não o UID |
| construção e dogfood | `E_DEGRAU2_CONSTRUIDO_DOGFOOD_1016` | Um turno inteiro do SDK correu pelo socket sob UID dinâmico. O `resume` funcionou com outro UID, e sessões simultâneas ficaram em UIDs distintos. A recusa (exit 64) não derruba o bridge, o abort mata o CLI em voo e o SIGKILL do lançador cai no `ExecStopPost`. O dogfood achou e curou um defeito que derrubava o processo do bridge (ECONNRESET sem handler). O refutador, em duas passadas, deu 19 achados, curados ou declarados |

## O que sustenta (evidências ancoradas)

- **Primárias da Anthropic:** `.env` e `.git-credentials` são arquivos de risco (`E_SECDEP_RISK_FILES_*`);
  proxy fora da fronteira para credencial (`E_SECDEP_PROXY_PATTERN_*`); o sandbox nativo cobre só o shell e
  não é fronteira completa (`E_SANDBOXING_*`); autenticação inbound num gateway na frente do agente
  (`E_HOSTING_INBOUND_AUTH_AT_GATEWAY`, a única claim ancorada da página de hosting).
- **CVEs do sandbox nativo:** CVE-2026-25725 (hook plantado em settings) e CVE-2026-39861 (fuga por symlink,
  corrigido na 2.1.64; o CLI embutido no SDK do bridge é 2.1.232, então hoje vale por acaso de versão, sem
  guarda de pin).
- **systemd.exec(5):** `ProtectProc=` e `ProcSubset=` não fecham o environ do **mesmo** UID; o segredo só se
  resolve com UID distinto.
- **SDK TypeScript:** `SpawnOptions` sem uid/gid; `SpawnedProcess` com contrato mínimo; `Options.env` substitui
  o ambiente; teardown de ~2 s; `pathToClaudeCodeExecutable` (o binário tem de sair do home 0750).
- **Ubuntu:** userns sem privilégio só com perfil AppArmor confinado com `userns,`; liberar tem custo para o host.
- **Medição da sessão (testemunho):** o Bash do /chat lê o `.env` e o `.git-credentials`; o filtro de env tira
  segredo das variáveis, não dos arquivos.

## Objeções sobreviventes que restringem (CONSTRAINS)

27 objeções do Elenxo (20 na rodada 1, 7 na rodada 2), todas modeladas como `E_OBJECAO_*`. As que mudam a
escada: a premissa estava errada, só o admin roda em bypass (`_03`); o chip de aprovação não é fronteira,
porque o convidado aprova a si mesmo (`_23`); o runner compartilhado mistura inquilinos (`_24`); o default de
`failIfUnavailable` depende da rota (`_31`: `true` por `Options.sandbox`, `false` por settings); o `.claude` do
workspace é gravável e carregado por `settingSources:["project"]` (`_32`).

## NÃO-VERIFICADOS

0. **Degraus 2 e 3 (2026-10-16):** um turno real de convidado logado com a API sob o runner; o WebFetch chamado
   por um modelo contra um IP do loopback (medidos só o código, o preflight e o TLS); `IPAddressDeny=` na unit
   do runner real.
1. **O que as três provas deixaram aberto:** se a deny de Edit/Write em `<workspace>/.claude/**` barra a
   escrita **pelo modelo** (exige chamada real à API); o lançador por socket do degrau 2 (a prova usou sudo);
   o teardown por EOF; o caminho específico do AppArmor no degrau 3 (com `socat` ausente o CLI para antes; um
   `socat` falso no PATH também não chega ao userns, e instalar o real muda o sistema).
2. Se `Options.managedSettings` conta como "admin-controlled" para `sandbox.bwrapPath`.
3. O comportamento do retry sem sandbox e das `excludedCommands` em `bypassPermissions` no SDK **headless**
   (a primária escopa o trecho à sessão interativa).
4. A página de hosting não diz nada sobre UID (grep = 0): falta reancorar as quotes literais
   (`C_SUPERACAO_20261015_REANCHOR_HOSTING_LITERAL_QUOTES`).
5. `DynamicUser=`/`PrivateUsers=` sem citação ancorada; aninhamento RO dentro de RW só medido localmente.
6. Se o CLI 2.1.232 sai sozinho no EOF do stdin (teardown pelo canal).
7. Se o PAT ainda é necessário (o core é público desde 2026-10-13).
8. **Mercado/capital:** nenhuma claim confirmada de rodada, M&A ou receita de vendedores de sandbox para
   agentes (`E_MERCADO_AGENT_SANDBOX_CAPITAL_1015`); único sinal é o Thoughtworks Radar v34 em Trial.
9. Cortes por orçamento da rodada 1: 33 fontes e 41 claims; 13 claims rejeitadas na ancoragem da rodada 2
   (11 exageradas, 2 sem citação), nenhuma virou nó.

## Contrato de custo

| Run | Modo | Tokens | Agentes | Duração |
|---|---|---|---|---|
| `wf_505962e3-7c9` | varredura em modo decisão | 7.481.207 | 106 | 25 min |
| `wf_8847e3af-370` | primárias nomeadas | 1.268.552 | 16 | 18 min |
| **Total** | | **8.749.759** | **122** | **43 min** |

O selo da decisão é escrita determinística de 0 tokens (`kg-decide-seal.sh`).

## Valeu a pena?

**Sim, com ressalva de custo na rodada 1.** A rodada 2 custou 17% da 1ª e foi a que mudou a decisão: corrigiu
o degrau 0 (o `.claude` do workspace), derrubou a ideia de que o bridge troca de UID sozinho, achou o perfil
bwrap que vale para o host inteiro e o default de `failIfUnavailable` que depende da rota. A rodada 1 gastou
7,5 M tokens para 75 nós, dos quais 21 superações e 20 objeções valeram. As 22 evidências web saíram muito
redundantes (a mesma afirmação em três URLs-irmãs da doc secure-deployment, um nó por URL), e esse é o
desperdício a não repetir. A pergunta sem a medição local (KVM, AppArmor, UID) teria terminado na microVM, que
não sobe nesta VPS.
