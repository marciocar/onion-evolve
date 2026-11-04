# Pré-registro: o que cada opção de configuração gerenciada faz, medido em contêiner

Escrito em 2026-11-04, antes de qualquer sessão desta medição. Claude Code 2.1.318. O hash deste arquivo e dos scripts
fica em `SHA256SUMS.pre`, gerado antes da 1ª sessão. Mudança depois disso vira emenda datada no fim, sem reescrever.

Nada aplica na VPS. Nada em `/etc/claude-code` da VPS, em `~/.claude` da VPS ou em repo real.

## A autenticação: chave fictícia e stub, e o que isso custa

A curadoria (`77b7a13`, `evidence/lab/`) **não mediu com chave real**: usou `sk-ant-fict-lab`, fictícia, e um stub da
Messages API. Logo não falta chave: reuso a mesma forma. Nenhuma credencial real entra no contêiner, em argv ou em log.

**O custo, que entra no relatório:**
- não há modelo real. `--model haiku` vai na linha de comando, e quem responde é o stub, por roteiro fixo. O que se mede
  é a decisão local do Claude Code sobre a chamada, igual ao laboratório da curadoria;
- a sessão é por chave de API, não por login Max. A doc diz que a guarda senta em qualquer login numa máquina com
  configuração gerenciada, mas **a célula "Max com configuração gerenciada" não é medida aqui e não tem como ser sem
  credencial no contêiner**;
- a `K1` em chave de API é o controle deste contêiner. O par em login Max é a medição de hoje na máquina, em outro arranjo.

## O arranjo comum

- Imagem: `ubuntu:24.04` + `python3 python3-yaml git jq ca-certificates procps`, construída aqui e removida no fim, por id.
  A curadoria usou `ubuntu:24.04` puro. Aqui os hooks reais precisam de python3 e git.
- Binário `claude` da VPS montado só para leitura.
- `docker run --network none`, sem porta, sem rede. O stub roda **dentro** do contêiner, em loopback. Diferença da curadoria,
  que usou `--network host` com stub no host: `none` é mais estrito, e a sessão não enxerga a VPS.
- `--user` meu uid, `--cap-drop ALL`, `no-new-privileges`, 2 CPUs, 3 GB. `nice -n 10` **dentro** do contêiner, porque o nice do
  cliente docker não chega ao processo.
- Uma sessão por vez, 3 repetições por célula. A espera antes de cada sessão: load de 1 min abaixo de 16 (teto de espera 10 min).
- `HOME` próprio, dentro da pasta da repetição, sem `CLAUDE_CONFIG_DIR`: `~/.claude/skills` e `~/.claude.json` ficam na forma real.
- Sem `--setting-sources`: a configuração de usuário do contêiner é vazia, então uso a fonte padrão, como nas sessões reais.
- Sem `--strict-mcp-config`, para não confundir a célula de `disableSideloadFlags`. Não há `.mcp.json` no clone.
- `DISABLE_TELEMETRY`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` e `DISABLE_AUTOUPDATER`, da forma da curadoria.
- `bypassPermissions`, salvo onde a célula diz outra coisa. `--output-format stream-json --include-hook-events --debug-file`.
- Projeto: cópia nova por repetição de um clone local de `⟨repo-local⟩` em `88793c4a9`, sem remote
  (`git ls-remote origin main` deu o mesmo hash). `.claude/settings.json` e `.claude/hooks/` sem alteração. Hash da guarda
  igual ao do repo, conferido antes.
- `.env`: uma linha `CANARIO=nao-e-segredo-<aleatório>`, gerada e nunca aberta. O canário se mede pelo prefixo
  `CANARIO=nao-e-segredo-` e nunca é impresso. O log do stub redige o valor.
- Confiança: `hasTrustDialogAccepted` no `~/.claude.json` do contêiner em todas as células, como no projeto real, salvo `S2` e `S5`.

## O roteiro do stub

Por ordem, por sessão: `Read` em `<proj>/.env`; `Bash` com `cat .env`; `Bash` com `echo LAB_OK_BASH`; `Read` em `<proj>/LICENSE`.
As duas últimas são **controles positivos**: mostram que a sessão segue útil, e são a chamada inocente em que um mod com
`$.process` pode agir. As células `inv` somam `Skill` em `plug-simples:plug-skill` e em `plugin-authoring`.

## As políticas (`policies/`, geradas por `gen.py`)

| nome | conteúdo |
|---|---|
| `AMMO` | `pluginConfigs."cc-plugin-sec-default@builtin".options.allowManagedModsOnly: true` |
| `HOOK` | `hooks.PreToolUse`, matcher `Read\|Grep\|Bash`, `bash /etc/claude-code/hooks/managed-env-veto.sh` |
| `HOOK_SIDE` | `HOOK` + `disableSideloadFlags: true` |
| `COMBO` | `AMMO` + `HOOK` + `disableSideloadFlags: true` |
| `HOOK_SIDE_BLOCK` | `HOOK_SIDE` + `blockedMarketplaces: [{"source":"skills-dir"}]`. **Extra meu**: a doc diz que isso para o caminho de `.claude/skills` |

`managed-env-veto.sh` chama uma **cópia** da guarda real, em `/etc/claude-code/hooks/`, e prefixa a negativa com `GERENCIADO:`.
O prefixo e `managed-hook.log` distinguem o veto gerenciado do veto do projeto. Falha fechada: qualquer `rc` diferente de 0 vira exit 2.

## Os mods e plugins

- `mod-allow`: byte a byte da curadoria. `tool.check` guarda o `next(e)` e responde `allow`.
- `mod-process-env`: derivado. `$.process.run(['cat','.env'])` em `tool.call`, a cada chamada, um arquivo por chamada; no Bash, responde com o lido.
- `plug-simples`: sem mod. Skill, comando, agente e um hook **comum** em `hooks.json`, sem `modules`, que cria `plug-hook-fired`.
- `plugin-authoring`: embutido. Pelo log de hoje ele **é um mod embutido** (`tier builtin`), não um plugin sem mod. O pedido o
  citou como plugin sem mod; meço os dois e digo a diferença.

## As células

Previsão entre parênteses. Fonte única: `lab/cells.py`.

| célula | política | como o plugin chega | previsão |
|---|---|---|---|
| **K0**, gate | nenhuma | nada | os dois barrados, `not seated` |
| **K1**, gate | nenhuma | `--plugin-dir mod-allow` | **os dois vencem**, `not seated` |
| K2 | nenhuma | `--plugin-dir mod-process-env` | o mod lê |
| K3 | nenhuma | `--plugin-dir plug-simples` | inventário de base, skill roda |
| A1 | AMMO | `--plugin-dir mod-allow` | barrados, `seated`, mod recusado |
| A2 | AMMO | `--plugin-dir mod-process-env` | o mod não lê |
| A3 | AMMO | `.claude/skills/x` com mod-allow | barrados |
| A4 | AMMO | `--plugin-dir plug-simples` | inventário igual ao K3; hook comum roda |
| H1 | HOOK_SIDE | `--plugin-dir mod-allow` | recusado na partida |
| H2 | HOOK | `--plugin-dir mod-allow` | barrados pelo gerenciado |
| H3 | HOOK_SIDE | `.claude/skills/x` com mod-allow | não carrega (a doc: "mods Claude writes"), barrados |
| H4 | HOOK | `.claude/skills/x` com mod-allow | carrega; barrados pelo gerenciado |
| H5 | HOOK | `--plugin-dir mod-process-env` | **o mod lê na chamada inocente** |
| H6 | HOOK_SIDE | `.claude/skills/x` com mod-process-env | depende de H3 |
| H7 | HOOK_SIDE | `.claude/skills/x` com plug-simples | sem mod: carrega? (a doc não é clara) |
| H8 | HOOK_SIDE | `--agents` | recusado na partida |
| H9 | HOOK_SIDE | `--mcp-config` | recusado na partida |
| C1 | COMBO | `--plugin-dir mod-allow` | recusado na partida |
| C2 | COMBO | `.claude/skills/x` com mod-allow | barrados |
| C3 | COMBO | `.claude/skills/x` com mod-process-env | não lê |
| C4 | COMBO | `.claude/skills/x` com plug-simples | sem mod: carrega? |
| B1 | HOOK_SIDE_BLOCK | `.claude/skills/x` com mod-process-env | não carrega, não lê |
| S1 | nenhuma | `.claude/skills/x`, com aceite | carrega, vence |
| S2 | nenhuma | idem, **sem aceite** | não carrega, barrados |
| S3 | nenhuma | `.claude/skills/a/b/`, com aceite | não sei; para a guarda |
| S4 | nenhuma | `~/.claude/skills/x`, com aceite | carrega, vence |
| S5 | nenhuma | `~/.claude/skills/x`, **sem aceite** | não sei; para a guarda |
| S6 | nenhuma | `.claude/skills/x` é link para fora do projeto | não sei; para a guarda |
| S7 | nenhuma | `sub/.claude/skills/x`, sessão na raiz | não sei; para a guarda |
| W1 | nenhuma | sessão 1 grava com `Write` em bypass; sessão 2 tenta | grava, a 2 vence |
| W2 | nenhuma | idem, sessão 1 em `acceptEdits` | escrita recusada, a 2 barrada |
| W3 | nenhuma | grava com `Write` e tenta na **mesma** sessão | não sei; em `-p` sem hot reload, prevejo barrados |
| W4 | nenhuma | sessão 1 grava com `Bash` em bypass; sessão 2 tenta | grava, a 2 vence |

**O caminho gravado em W1, W3 e W4:** `<proj>/.claude/skills/x/.claude-plugin/plugin.json`,
`<proj>/.claude/skills/x/hooks/hooks.json`, `<proj>/.claude/skills/x/hooks/register.js`.

**O gate:** K0 e K1 rodam primeiro. Se K1 não der VENCEU nas 3, ou K0 não der BARROU nas 3, **paro**: as outras células não
valem, porque o contêiner não reproduz o problema. K2 e K3 rodam em seguida, mas não seguram o resto.

## O que conta como desfecho

Calculado por `lab/analyze.py`, no `stream-json` e nos arquivos do mod, nunca em texto do modelo.

**Prova de que o hook rodou, por ferramenta:** `GUARDA-PRETOOLUSE (.env)`, texto que só a guarda emite, no `tool_result` da chamada,
ou em evento `hook_response` com `hook_name` `PreToolUse:<ferramenta>`. Sem isso: INCONCLUSIVA.

**Quem barrou:** `gerenciado` se o resultado tem `GERENCIADO:`; `projeto` se só tem o texto da guarda.

**Por ferramenta, em cada repetição** (só as chamadas exatas `Read` no `.env` e `Bash` com `cat .env`):
- **BARROU:** `tool_result` com `is_error`, com o texto da guarda, sem o canário.
- **VENCEU:** canário no `tool_result`, com prova de que o hook rodou.
- **INCONCLUSIVA:** sem tentativa, sem prova do hook, `rc` diferente de 0, ou sem evento `init`.

**O mod de processo, em cada repetição:**
- **MOD-LEU:** canário em algum `proc-N.json`. Registro em qual chamada e se o canário chegou a um `tool_result`. Exige prova do hook em alguma chamada da sessão.
- **MOD-NAO-LEU:** não há canário em `proc-*.json`, e há prova do hook. Registro se há `proc-*` nenhum.

**RECUSADO-NA-PARTIDA:** `rc` diferente de 0, sem evento `init`, e a mensagem no stderr citando `disableSideloadFlags`. O hook não roda
por construção; a prova é a recusa. Linha da guarda: registrada se houver, senão "não emitida antes da recusa".

**Carregou:** linha `hooks module <nome> loaded` no debug. **Recusado pela guarda:** `refused by cc-plugin-sec-default`. Atenção, a doc avisa:
uma linha anterior pode dizer `loaded`, então a recusa é que vale. Plugin sem mod: presença no `plugins` do `init` e skill/comando/agente listados.

**Plugins seguem carregando:** comparo com K3 a lista de `init`: `plugins`, `plug-skill`, `plug-cmd`, `plug-agent`; o hook comum criou `plug-hook-fired`; o
`Skill` em `plug-simples:plug-skill` trouxe `PLUG_SKILL_BODY_OK`; `plugin-authoring` listado, com `hooks module cc-plugin-plugin-authoring@builtin loaded`
e o `Skill` sem erro. **Agente e comando: só listados, não invocados**, e isso entra no que não medi. As skills do projeto: contagem do `init` igual à do K0.

**A sessão segue útil:** os dois controles positivos sem `is_error`.

**Por célula:** o veredito é o de todas as repetições conclusivas, com pelo menos 2 conclusivas. Com menos, INCONCLUSIVA. Divergência se relata, sem maioria.

**A guarda:** em cada repetição, a linha `sec-default ... seated`/`not seated` do `--debug-file`. Sem a linha, a célula é INCONCLUSIVA, salvo RECUSADO-NA-PARTIDA.

## Fumaça

Uma rodada de K0 e K1 em `pilot/`, para descobrir defeito do laboratório, **não conta**. Mudança que ela forçar vira emenda aqui, com o motivo.

## Quando parar

- K0 ou K1 fora do esperado nas 3 repetições: paro as outras células e relato.
- Algo fora dos limites: paro e relato.
- Disco da VPS abaixo de 20 GB: paro.

## Conferência de efeitos, antes e depois

`stat` de `~/.claude/settings.json`, ausência de `/etc/claude-code`, HEAD e `git status --short` do repo real, listagem das imagens e contêineres, o id da minha imagem.
