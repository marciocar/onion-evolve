---
kg: docs/evolution/research/hooks-state-of-art-2026-09/hooks-state-of-art-2026-09.kg.yaml
baseline: 2026-09-21
medido_em: "Claude Code 2.1.278 (processo == disco, sem drift de versão)"
metodo_primario: "grep no ELF instalado, com controles positivos e negativos"
---

# Hooks — estado atual e o que o Onion faz com isso

## 0. O que esta rodada mediu (e o que não mediu)

**Mediu**, por fonte primária local (o binário 2.1.278 instalado, que carrega a própria
documentação de hooks embutida): o catálogo completo de eventos, a semântica de `exit 2` evento a
evento, os tipos de handler, os tetos de saída por campo. Verbatim versionado em `data/`.

**Controles do método** (sem eles a contagem não vale): negativos inventados
(`PreToolUseXyzzy`, `FooBarHookEvent`, `PreBananaSwitch`, `OnionGateEvent`) = **0 ocorrências**;
positivos conhecidos (`PreToolUse` 116, `SessionStart` 84) = altos. O método enxerga.

**Não mediu**: nenhum dos 23 eventos ociosos foi EXERCITADO. Tudo abaixo sobre eles é leitura de
contrato, não observação de comportamento — e a doutrina da casa diz que contrato lido ≠ dogfood.
O teto de 8.000 chars foi lido da tabela de constantes, não provocado com uma saída de 8.001.

## 1. A superfície: 33 eventos, o Onion usa 10

O corpus media ~30 eventos em 2026-08-16 (na 2.1.233). Re-medido hoje na **2.1.278**: **33 eventos
presentes**. O core configura **10**. Ficam **23 ociosos — 70% da superfície**.

Usados: `SessionStart` · `UserPromptSubmit` · `SessionEnd` · `PreCompact` · `PostToolUse` ·
`PreToolUse` · `PreModelSwitch` · `PostModelSwitch` · `InstructionsLoaded` · `Stop`.

Ociosos: `PostToolUseFailure` · `PostToolBatch` · `PermissionRequest` · `PermissionDenied` ·
`UserPromptExpansion` · `StopFailure` · `SubagentStart` · `SubagentStop` · `Setup` · `PostCompact` ·
`TaskCreated` · `TaskCompleted` · `TeammateIdle` · `WorktreeCreate` · `WorktreeRemove` ·
`Notification` · `ConfigChange` · `CwdChanged` · `DirectoryAdded` · `FileChanged` ·
`MessageDisplay` · `Elicitation` · `ElicitationResult`.

## 2. Os tetos de saída — afirmação RETIRADA

> **Correção.** A versão anterior desta seção dizia que o teto real era 8.000 e que isso refutava o
> corpus. **Não se sustenta, e fica retirada.**

A referência pública afirma **10.000 caracteres** para `additionalContext`, `systemMessage`,
`initialUserMessage` e stdout puro, medidos campo a campo; o excedente é gravado num arquivo da
pasta da sessão e substituído por *path + preview de 2.000 chars*. Não há setting para levantar.

O binário 2.1.278 carrega, **em separado**, uma tabela de constantes por campo
(`vdr`: additionalContext 8000, systemMessage 4000, `reason`/`stopReason`/`permissionDecisionReason`
2000; `Tdr`: 200 linhas para additionalContext, 20 para o resto), consumida por `kB()` via `u3n()`,
que em truncamento faz `e.report.truncated.push(n)`. O destino **`report`** sugere um estágio
diferente (relatório/telemetria) do estágio de **entrega** ao modelo.

As duas leituras podem coexistir e **eu não determinei qual governa o contexto que chega**. Cai
junto o corolário dos "92 bytes acima do teto". **Experimento que decide, e é barato:** um hook
descartável emitindo `additionalContext` de 8.001 e de 10.001 chars, observando o que chega.

## 3. O moat está lastreado — a correção de 2026-08-31 foi executada

`maestro-vivo-2026-08/C_ERRA_O_EXIT_2_DETERMINISTICO_DE_HOOK_COMO_A_C` mediu, em 2026-08-31, que a
capacidade que o `CLAUDE.md` declara como compradora do acoplamento era **declaração vazia**: ZERO
`PreToolUse`, 1 único hook com `exit 2` de 7.

Medido hoje: **3 entradas `PreToolUse`**, **6 de 15 hooks com `exit 2`**, e `Stop` bloqueante. A
correção foi executada entre 08-31 e 09-02. O nó merece carimbo de resolvido.

## 4. Duas derivas que o corpus não sabe

**(a) O core adotou um `Stop` bloqueante.** `radar-E3-2026-09-03/E_F8_STOP_HOOK_NAO_SE_APLICA`
(tier 9, CHANGELOG oficial) declarou: *"o core NÃO tem hook Stop... vale só se o core vier a adotar
um Stop bloqueante"*. Adotou — `rule-title-in-prose.sh` sai com `exit 2` em `Stop`, adicionado **um
dia depois** do nó. A premissa é falsa hoje e a ressalva está viva.

**(b) O moat não viaja pelo canal de instalação.** `maestro-vivo-2026-08/C_INEF_DISTRIBUICAO_DO_MOAT`
persiste, agora com número:

| | core | plugin |
|---|---|---|
| hooks (.sh) | 15 | **2** |
| eventos de hook | 10 | **2** |
| validação (.sh) | 72 | 19 |
| lint (87 REGRAs, 63 HARD) | sim | **nenhuma** |

Quem instala o Onion pelo plugin recebe a metade que **aconselha** e nada da metade que **reprova**
— justamente a metade agnóstica, barata de distribuir, que o corpus identificou como o fosso real.

## 5. A alavanca central

O Onion já possui a parte cara: **26.596 linhas de shell agnóstico** e **87 REGRAs de lint (63 HARD)**
que reprovam. Mas elas rodam no **pre-commit e no CI** — ou seja, *post-hoc*, e puláveis com
`--no-verify` (o próprio corpus registra o autor pulando três vezes numa sessão).

A superfície de hooks não pede lógica nova: pede **gatilhos novos para lógica que já existe**. Mover
um subconjunto das 63 HARD de "pego no commit" para "impedido no ato" custa quase nada de
acoplamento, porque **a lógica continua agnóstica — só o gatilho é do Claude Code**. É exatamente a
postura declarada no `CLAUDE.md`: acoplar só onde a capacidade não existe fora.

## 6. As sete oportunidades, ordenadas por (impacto ÷ custo)

**1. `Setup` fecha um nó ABERTO.** `audit-textual-gates-2026-09/Q_PRECOMMIT_ARMADO_EM_CLONE_FRESCO`
pergunta como armar o gate num clone fresco (o `core.hooksPath` é config local; clone novo nasce sem
os 5 vetos e nada acusa). A cura que o nó propõe é *"SessionStart que mede e AVISA"*. O evento
`Setup` — `trigger: init|maintenance`, campo `runsOnce`, exit 0 devolve `additionalContext` — é
estritamente melhor: dispara **no momento certo**, uma vez, em vez de ruído em toda sessão. A
plataforma cresceu a janela que o nó estava esperando.

**2. `PreCompact` já é usado, mas pela metade.** Contrato: *exit 0 — stdout é anexado como instruções
customizadas de compactação*. Hoje `worklog-precompact-breadcrumb.sh` só grava migalha. O mesmo hook
pode **dirigir o que sobrevive à compactação** (ids de nó do KG, decisões abertas, fase da sessão) —
serve direto à doutrina de retomada (`/onion:catch-up`). Custo: uma dezena de linhas no hook que já existe.

**3. `SubagentStart` é a única janela documentada para injetar contexto em subagente.** Contrato:
*exit 0 — JSON `additionalContext` mostrado ao subagente*. O Onion orquestra pesado (uma rodada
medida usou 105 agentes) e hoje a doutrina só chega ao worker se for colada no prompt. Um hook aqui
injeta corpus/doutrina em **todo** worker, mecanicamente. Restrição: 8.000 chars.

**4. `PostToolBatch` troca N injeções por 1.** Contrato explícito: *"Return additionalContext via
hookSpecificOutput to inject context once for the whole batch"*. O `kg-read-leg.sh` hoje é
`PreToolUse` em `Read|Edit|Write|Bash` — dispara **por chamada**. Mesma informação, uma vez por lote.
Bônus: `exit 2` aqui **para o loop agêntico** (veto forte).

**5. `ConfigChange` converte aviso em mecanismo.** `exit 2` **bloqueia a mudança de config na sessão**;
as fontes incluem `user_settings`, `project_settings`, `local_settings`, `policy_settings` e `skills`.
Hoje `session-version-drift.sh` **sempre sai 0 por desenho** ("reiniciar é ato do maestro"). Onde a
casa quiser mecanismo em vez de prosa, esta é a porta.

**6. `PreToolUse` + `updatedInput`: sair do veto para a CORREÇÃO.** Os 6 hooks com `exit 2` só sabem
dizer não. `updatedInput` (só em `PreToolUse`) deixa o hook **reescrever a chamada**, com validação de
schema e fallback para o input original quando falha. Caso concreto desta própria sessão: o
`bash-empty-result-guard.sh` me barrou por um `2>/dev/null` **depois** do comando rodar; em
`PreToolUse` ele poderia remover o silenciamento **antes**. ⚠️ Reescrever comando em silêncio é
perigoso — tem de vir casado com `systemMessage`, ou vira mágica invisível, que é o oposto da doutrina.

**7. `MessageDisplay` é o tamanho certo para o `Stop` atual.** O `rule-title-in-prose.sh` usa um
**veto bloqueante** (`Stop`, `exit 2`) para impor **formatação de prosa** — e o CHANGELOG registrou
que Stop bloqueante custava raciocínio e cache no turno seguinte. `MessageDisplay` devolve
`displayContent` substituindo o delta na tela, é display-only e não bloqueia. Ferramenta do tamanho
do problema.

## 7. Riscos nomeados

- **Política de organização pode desligar hooks.** O binário carrega `allowManagedHooksOnly`,
  `disabledByPolicy`, `managedOnly`, `policyHookCount`, `managedHooksStillApply`. Se uma org puder
  desabilitar hooks não-gerenciados, o gate do Onion morre em adotante enterprise **sem aviso**.
  Precisa de confirmação de contrato — é a pergunta de maior consequência em aberto.
- **Ordem de prioridade.** Nada do item 6 importa para adotante enquanto o plugin levar 2 de 15
  hooks e zero lint. **Consertar a distribuição vem ANTES de adicionar evento novo** — caso contrário
  constrói-se fosso que não embarca.
- **`Q_RISCO_PLATAFORMA_COME_O_GATE` segue vivo.** Handlers `prompt` e `agent` (restritos a
  `PreToolUse`/`PostToolUse`/`PermissionRequest`) são o dogfood do Onion virando primitiva nativa.

## 8. Boa notícia de plataforma

Delta 2.1.262→2.1.278: *"saída de hook SessionStart fazia a sessão continuada perder parte da
primeira mensagem, causando perda TOTAL de prompt-cache"* — **corrigido**. O core tem **4 hooks
SessionStart que imprimem**, então pagava esse custo em toda retomada. A versão instalada já cura.
Também corrigidos: crash ao retomar sessão com sumário de stop hook malformado; `SubagentStop` com
matcher disparando para todo subagente de tipo vazio.

---

## 9. Perna externa — o que o mercado faz com hooks (2026)

Fonte: busca web em 2026-09-21. Números de estrela vêm do índice do GitHub no momento da busca;
não reabri cada repositório, então tratá-los como ordem de grandeza.

O ecossistema se organiza em **duas camadas, e nenhuma é a do Onion**:

1. **Encanamento** — SDKs para escrever hook em linguagem tipada em vez de shell cru:
   [cchooks Python](https://github.com/GowayLee/cchooks) (~123★),
   [cchooks Go](https://pkg.go.dev/github.com/brads3290/cchooks),
   [claude-hook TS](https://github.com/StanislavKozachenko/claude-hook),
   [claude-hooks TS](https://github.com/johnlindquist/claude-hooks), claude-hooks-sdk PHP (~62★),
   e [cchook](https://github.com/syou6162/cchook), que troca o JSON por YAML.
2. **Coleções pequenas e utilitárias** —
   [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks) (~298★, 10 hooks:
   cost-tracker, rate-limiter, branch-guard) distribuída **como marketplace instalável**;
   [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery);
   [awesome-claude-code-hooks](https://github.com/ithiria894/awesome-claude-code-hooks).

**Leitura para o Onion.** Ninguém publica **método** com hooks como braço de execução — as 87 REGRAs
são outra categoria de artefato, e isso é posição defensável. Mas o projeto de **10 hooks** já
distribui pelo canal que o Onion subaproveita. A vantagem do Onion é de conteúdo; a desvantagem é de
canal, e canal é o mais barato de consertar.

Há ainda sinal **acadêmico** de que a fronteira pode descer do harness para o SO
([ActPlane, arXiv](https://arxiv.org/pdf/2606.25189), policy enforcement em nível de SO para
harnesses de agente). Não foi lido nesta rodada — lacuna nomeada.

## 10. O defeito que só o cruzamento externo→interno revelou

A literatura de campo converge num ponto: **fail-open é o modo de falha dominante e é silencioso**.
Hook que estoura não imprime nada e sai 0 — o Claude Code lê como "sem objeção". E **`exit 1` não
bloqueia**: é tratado como erro não-bloqueante e a ação passa. Só `exit 2` barra.
([um](https://dev.to/redpa/your-claude-code-hooks-probably-fail-open-heres-why-thats-dangerous-2nfi),
[dois](https://dev.to/suyann/your-claude-code-hooks-probably-dont-fire-on-windows-a-60-second-test-and-the-nine-ways-they-37jk),
[três](https://dev.to/yurukusa/5-claude-code-hook-mistakes-that-silently-break-your-safety-net-58l3))

Levada essa lente para dentro: **o único veto incondicional da casa falha aberto.**
`pretooluse-protect-main.sh` (nega force-push para `main`) extrai o comando via `python3` na linha 6.
Se o `python3` sumir, ou se o formato do JSON de entrada mudar, `cmd` vem vazio e a linha 9
(`[ -z "$cmd" ] && exit 0`) **deixa o force-push passar**.

Varredura nos 6 hooks com `exit 2`: **nenhum tem trap de erro**, e cada um tem de 4 a 5 portas de
`exit 0`. Isso não quer dizer que `exit 0` esteja errado — a maioria das portas é legítima ("não é
repo git", "não há comando"). Quer dizer que **falta a guarda-da-guarda**: não há como distinguir
*"deliberadamente não se aplica"* de *"a guarda quebrou"*.

**Cura candidata:** `trap ERR` que emite `systemMessage` e sai 2 nos hooks de VETO, mais uma sonda de
auto-teste que quebre o `python3` de propósito e **exija** o bloqueio. É a mesma forma do
`ops/verify-adopter-gate.sh` — provar por comportamento, não por leitura.

## 11. Contrapeso honesto à tese do CLAUDE.md

A mesma fonte externa que **corrobora** o argumento central (hooks `PreToolUse` disparam antes da
checagem de modo de permissão, então `permissionDecision: deny` barra inclusive sob
`bypassPermissions` e `--dangerously-skip-permissions`) também recomenda que hooks sejam **automação
local rápida**, com CI, proteção de branch e controles de infraestrutura permanecendo a camada
**autoritativa**.

Isso não derruba a postura da casa — **reforça a inversão que o corpus já tinha medido**: o fosso do
Onion é o shell agnóstico que roda em qualquer CI, não o gatilho acoplado. O gatilho é o que dá
*imediatismo*; o CI é o que dá *autoridade*. Vender o `exit 2` como garantia, sozinho, é vender mais
do que ele entrega — e é ainda mais arriscado enquanto `Q_POLITICA_DE_ORG_PODE_DESLIGAR_O_GATE`
seguir aberto.

## 12. Custo que nunca foi medido

Relatos de campo registram **18,2s por interação com hooks ligados contra 4,8s sem**, e timeouts
duros de 30s ([issue](https://github.com/ruvnet/ruflo/issues/1530)). O core dispara **4 hooks em
`SessionStart` e 4 em `UserPromptSubmit`**, todos com `timeout: 5`. O custo agregado por turno
**nunca foi cronometrado** — e esta casa já errou declaração de tempo por ordem de grandeza
(`onion-refinaria-2026-08/E_gate_declara_1min_e_leva_15`: o pre-commit declarava ~1min e levou 921s).

**Cronometrar a soma dos hooks por turno vem antes de adicionar qualquer evento novo.**

## 13. Ordem recomendada

1. **Consertar o fail-open dos 2 hooks de veto** (`trap ERR` + sonda). Defeito real, custo baixo.
2. **Consertar a distribuição** (plugin leva 2 de 15 hooks e zero lint). Sem isso, fosso não embarca.
3. **Cronometrar** o custo agregado de hooks por turno.
4. **`Setup`** para armar o gate no clone fresco — fecha nó aberto.
5. **`PreCompact`** emitindo instruções de compactação — melhor retorno por linha.
6. **`SubagentStart`** injetando doutrina no worker.
7. Resolver `Q_POLITICA_DE_ORG_PODE_DESLIGAR_O_GATE` antes de vender `exit 2` em contexto corporativo.


---

## 14. Correções desta rodada (confronto com a referência pública)

Uma perna independente baixou a referência oficial e confrontou a minha medição no binário. **Quatro
afirmações minhas caíram, uma resistiu.**

**Caíram:**

1. *"Handlers `prompt`/`agent` só em 3 eventos"* — **errado**. A doc lista **13** eventos que
   suportam os cinco tipos, e os exemplos canônicos dela são `Stop` com `type: prompt` e `Stop` com
   `type: agent`. O que sobrevive: eles **não** retornam `additionalContext` (schema só
   `{ok, reason, impossible}`) — são decisores puros.
2. *"Quatro tipos de handler"* — são **cinco**: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Só
   `agent` é experimental. `mcp_tool` tem contrato próprio (`server`/`tool`/`input`).
3. *"`updatedInput` só em PreToolUse"* — também há `decision.updatedInput` em `PermissionRequest`
   (nível diferente, escapou do grep) e `updatedToolOutput` em `PostToolUse`. A oportunidade fica
   **maior**, não menor.
4. **Os tetos** — ver seção 2.

**Resistiu:** o bloqueio de destino dos HTTP hooks. A string do binário diz literalmente
*"Loopback (127.0.0.1, ::1) is allowed for local dev"* — o que **concorda** com o exemplo oficial
`http://localhost:*`, em vez de contradizê-lo.

### A lição de método, que vale mais que as correções

O binário carrega **duas coisas diferentes**, e eu as tratei como uma: (a) uma **doc de ajuda
resumida** (`## Hooks Configuration`, tabela com apenas 10 eventos, exemplos simplificados) e (b) o
**`eventCatalog` interno** (~557k), com semântica de exit code evento a evento para os 33. Li (a) e
carimbei *tier 10 primary* — e as quatro afirmações erradas saíram exatamente dali. O catálogo (b)
**resistiu** ao confronto: a lista de quem bloqueia no `exit 2` bateu com a doc quase item a item.

**Regra prática:** resumo embutido no binário é UI, não contrato. E o corolário que mais importa —
*fonte primária local não vence fonte primária pública por ser local; vence por ser a fonte certa.*

## 15. O risco de maior consequência: RESPONDIDO, e é sim

`Q_POLITICA_DE_ORG_PODE_DESLIGAR_O_GATE` deixou de ser suspeita. Duas chaves **públicas** de settings:

- **`disableAllHooks`** — em escopo *Managed* desliga **tudo, inclusive os hooks managed** (preserva
  só os do Agent SDK); fora de managed desliga user/project/local/plugin.
- **`allowManagedHooksOnly`** — escopo *Managed*: só rodam hooks managed + Agent SDK + plugins
  force-enabled via `enabledPlugins`; bloqueia user, project, local, demais plugins e hooks de
  frontmatter de agente.

**Consequência para o Onion:** o gate determinístico **pode ser desligado por política de
organização** no adotante enterprise, e o Onion não tem como perceber isso de dentro. Não se deve
vender o `exit 2` como garantia em contexto corporativo sem checar a política do cliente.

(Os identificadores que achei no binário — `disabledByPolicy`, `policyHookCount`,
`managedHooksStillApply` — **não** são chaves públicas. São internos; não se constrói config sobre eles.)

## 16. Fail-open: de folclore a contrato declarado

A referência oficial confirma o que a comunidade relatava, e isso **eleva** o defeito da seção 10 de
"risco plausível" para "modo documentado":

- Script inexistente ou sem bit de execução → `exit 127` → **erro não bloqueante, a ação prossegue**.
  Um path errado no `settings.json` deixa o gate silenciosamente desligado.
- **Timeout em `PreToolUse` é fail-open** (saída descartada, a call segue): hook travado **não é gate**.
- JSON no nível errado (`permissionDecision` no topo em vez de dentro de `hookSpecificOutput`)
  parseia, é **ignorado**, e não gera erro visível — só com `--debug`.
- `exit 1` **não** bloqueia.

O único ponto **fail-closed** por default é subagente em background não-interativo (a call é **negada**
se nenhum hook decidir), mais `PreModelSwitch` e os eventos de worktree.

## 17. O número de mercado que corta contra o entusiasmo

Em 2.500 repos públicos amostrados de 8.298 com config Claude Code
([State of Claude Code 2026](https://www.buildthisnow.com/blog/real-examples/state-of-claude-code-2026),
junho/2026):

| Feature | Adoção |
|---|---|
| CLAUDE.md | 84,9% |
| `.claude/` | 62,1% |
| Skills | 28,1% |
| slash commands | 25,6% |
| subagentes | 24,6% |
| `.mcp.json` | 17,0% |
| **Hooks** | **13,3%** |

**Hooks é o feature menos adotado da lista** — metade de skills (sobe a ~21% entre repos com
`.claude/` estruturado). No marketplace, de 358.699 componentes indexados: skills 222.015 contra
**hooks 7.776** (~2,2%), razão ~28:1 (*caveat*: conta entradas de hook, não plugins que embarcam hook).

**Leitura dupla, e as duas pontas valem.** (a) O Onion aposta no eixo mais **raro** — fosso de
verdade *se* a aposta estiver certa, porque quase ninguém concorre ali. (b) É também o eixo de menor
**demanda comprovada**: vender hooks como diferencial para quem não adota hooks é vender contra a
corrente. Quem usa, usa muito (coleções de 10, 26, 30, 95 hooks) — público pequeno e concentrado.

## 18. Correção à recomendação de `PreCompact`

A sobrevivência de `additionalContext` à compactação **não é documentada**, e o padrão **oficial** de
re-injeção é `SessionStart` com matcher **`compact`** (dispara *depois* da compactação) — não
`PreCompact` nem `PostCompact`, que não injetam contexto.

O que sobrevive da oportunidade: `PreCompact` com `exit 0` **anexa o stdout como instrução de
compactação**, dirigindo o que o resumo preserva — coisa diferente de re-injetar depois. Desenho
certo, então, são as **duas pernas**: `PreCompact` diz *o que preservar*; `SessionStart:compact`
*recoloca*. O core hoje não faz nenhuma das duas.
