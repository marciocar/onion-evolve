---
title: O exit 2 não compra mais o acoplamento por exclusividade
date: 2026-11-04
kg: docs/evolution/research/exit2-coupling-against-2026-11/exit2-coupling-against-2026-11.kg.yaml
run_id: wf_ff363b47-bb6
tokens: 9274630
agents: 106
duration_min: 49
review_after: 2026-12-04
type: research
mode: decision
---

# O exit 2 não compra mais o acoplamento por exclusividade

> Projeção do grafo: quem manda é o `.kg.yaml`. O contrato de custo acima é o do run do `/onion-research`; as duas
> medidas com sessões reais e simuladas e este fechamento ficam fora dele (ver «Valeu a pena»).

**A pergunta** (`Q_EXIT2_COUPLING_AGAINST_2026_11`): o que derruba a tese do `CLAUDE.md` de que o `exit 2` de hook,
que barra sob `bypassPermissions`, não existe fora do Claude Code, nenhum CI replica e compra o acoplamento?

**A decisão** (`D_EXIT2_COUPLING_WORDING_2026_11`, selada pelo maestro em 2026-11-04, por `/meta:decide`):
**C com o gatilho da D.** Rejeitadas: A (só a condição do mod), B (nomear outra capacidade), D (rever a postura agora).

## O que o grafo sustenta

### Exclusividade: caiu, por rodagem

| Grau de prova | Harness | O que se sabe | Nó |
|---|---|---|---|
| Medido | Codex CLI 0.164.0 | barra por `exit 2` e JSON deny sob `--dangerously-bypass-approvals-and-sandbox`, com hook confiável; sem confiança, o `codex exec` pula o hook em silêncio (`E_SPIKE_FAILOPEN_UNTRUSTED_HOOK_SKIPPED_1026`) | `E_OBJECAO_CODEX_BYPASS_MEASURED` |
| Medido | Qwen Code 0.26.6 | barra no caminho feliz; abre em toda falha do hook | `E_OBJECAO_RUN_PAID_MEASUREMENTS_LEFT_OUT` |
| Medido | Mistral Vibe 3.0.4 | o `exit 2` só barra com `strict`; o veto próprio é JSON com `exit 0` | `E_OBJECAO_RUN_PAID_MEASUREMENTS_LEFT_OUT` |
| Só por doc | Copilot CLI, Gemini CLI, Cursor | `exit 2` nega; nada medido em modo autônomo pelo Onion | `E_COPILOT_HOOK_EXIT2_DENY`, `E_GEMINI_BEFORETOOL_EXIT2_DOC`, `E_OBJECAO_CURSOR_ASK_WRONG_TARGET` |
| Só por leitura | Goose | hook de comando com `exit 2`, sem spike, em grafo ainda não rastreado | `Q_EXIT2_COUPLING_AGAINST_2026_11` |
| Sem primária | Antigravity | nenhuma doc oficial achada | `E_OBJECAO_CUT_GEMINI_REPLACED_ANTIGRAVITY` |

### Força: o veto é camada de conformidade, não fronteira de segurança

Essa frase é **conclusão do Onion**. A OpenAI diz algo próximo sobre hooks; a Anthropic diz sobre regra de Bash e sobre o
modo bypass, e não sobre hook.

**Medida 1, com hooks reais e login real** (`E_MAESTRO_MOD_BEATS_VETO_LOGIN_MAX_1104`, `data/mods-real-hooks/`):

| Célula | Mod | Read e Bash no `.env`, 3 repetições cada |
|---|---|---|
| A | nenhum | barrou 6 de 6 |
| B | aprova em `tool.check` | venceu 6 de 6, com o hook rodando e saindo 2 |
| C | processo lê em `tool.call` | leu 6 de 6 |

A guarda de mods não sentou em nenhuma das 9 sessões. Limites: modelo haiku, `--setting-sources project,local`, só o veto
do `.env`, só o caminho feliz do hook, clone sem aceite de confiança.

**Medida 2, configuração gerenciada em contêiner** (`E_MODS_MANAGED_CONTAINER_STUB_1104`, `data/mods-managed/`, 39
células, 117 repetições):

| O que se pôs | Mod que aprova | Mod de processo | Plugin sem mod |
|---|---|---|---|
| Nada | vence | lê | segue |
| Política neutra, que só senta a guarda | barrado | **lê** | não medido |
| Hook gerenciado | barrado pelo gerenciado | **lê** na chamada inocente | não medido |
| `disableSideloadFlags` | flags recusadas na partida; em skills, barrado | **lê** se vier por skills do projeto | carrega por skills; recusado por flag |
| `allowManagedModsOnly` | recusado, por flag e por skills | **não lê** por flag; por skills, só medido com a combinação | segue, inventário igual ao da linha de base |
| `blockedMarketplaces` skills-dir, em conjunto com `disableSideloadFlags` e hook gerenciado | não medido | **não lê** por skills | não medido |

Sem política, sob bypass, a sessão grava o mod com `Write` ou `Bash` e, com aceite de confiança, **a sessão seguinte vence**
(células W1, W4); em `acceptEdits` a escrita é recusada (célula W2). Sem aceite, o mod não carrega das skills do projeto
(célula S2), mas das skills do usuário carrega (célula S5). Em falha, o JSON gerenciado inválido não inicia (célula X1), e o hook
gerenciado com arquivo inexistente falha aberto (célula X2). Limites: API simulada, chave fictícia, sem modelo real, sem login Max. Seis células
foram escolhidas depois de ver a 1ª rodada, e isso está na Emenda 1 do pré-registro.

**A revisão da curadoria, conferida sem rerodar** (`onion-curation@6ca64f3`, `evidence/lab/out/cells-review.jsonl`): arquivo
gerenciado só com `prependPlugins` vazio, ou só com `managedSourcesBehavior`, não senta a guarda, e o mod fura, 3 de 3 cada. Com
`cleanupPeriodDays` senta. Logo conta a chave de política, não o arquivo não vazio, e a recomendação do Elenxo, que dizia «não
vazia», fica registrada como estava no nó selado e corrigida aqui. Regra `deny` com mod que aprova sob bypass também fura, 3 de 3.

O `onFailure: block` está nos 5 vetos do core (`.claude/settings.json`, lido no fechamento): env, protect-main, merge-gate,
moat-gate e direct-provider-api.

### CI: a frase estreitou

Só o momento **antes da execução na sessão** não tem par no CI. Para a `main`, onde o plano dá ruleset, os checks exigidos já cobrem
(`E_OBJECAO_THESIS_NO_CI_NARROW`); neste repo, público, `onion-main-required-checks` está ativo, lido no forge em 2026-11-04.
Em repo privado na conta Free o ruleset devolve 403 (`E_DOGFOOD_B1_BLOQUEADO_PRIVADO_E_GUARDA_DE_MAIN`). Para `.env` e efeitos locais, o concorrente é sandbox e permissão de sistema.

### Alternativa: o vazio fica declarado

A postura pede capacidade que não exista fora, e **hoje nenhuma capacidade exclusiva está medida**. Workflow e
PreModelSwitch são candidatas sem comparação com concorrentes (`E_OBJECAO_OPTION_B_NO_MEASURED_SUBSTITUTE`). Por isso a
pergunta segue `open`: o selo declara o vazio, não o preenche.

**Gatilho de reabertura:** um harness que não seja o Claude Code passar, na mesma bancada, nos 5 vetos reais do core, em
caminho feliz, falha e modo autônomo; ou `/meta:cc-update` mudar a regra da guarda. O Copilot é o primeiro candidato.

## As massas

No perímetro declarado em 2026-08 (`.sh` rastreados de validation, hooks e utils; `.md` rastreados de commands, agents e
skills), por `git ls-tree` e `wc -l`:

| Onde | Shell | Markdown |
|---|---|---|
| Número do `CLAUDE.md` até hoje | 26.596 | 52.655 |
| Re-medido em `6850818dc`, o commit que o declarou | **27.355** | **52.655** |
| `origin/main` em `1cf173342` | 103.649, com 49.924 da bancada | 57.637 |

**O método não é reprodutível na metade shell.** O nó de origem declara «comando não registrado», e nenhum commit de
2026-08-01 a 2026-08-16 dá 26.596 nesse perímetro. O `CLAUDE.md` deixou de citar os números e manteve a inversão como
leitura qualitativa. A ordem das massas inverteu; se a inversão precisar de número, o comando acima é o que se registra.

## Mercado

**O eixo voltou vazio.** Nenhuma claim confirmada traz rodada, M&A, receita ou analista sobre veto de hook ou sobre quem
financia cada harness. É lacuna, não irrelevância (`E_MERCADO_EXIT2_COUPLING_1104`). O sinal fraco, de uma busca
secundária do Elenxo (o método de refutar antes de selar), aponta capital em isolamento fora do harness, com valores sem primária, e por isso não entra aqui. O
Thoughtworks Radar Vol. 35 põe agent sandboxing em Adopt, o que é sinal de analista, não de capital.

## NÃO-VERIFICADOS

- **Login Max com configuração gerenciada:** nenhuma célula. A medida 2 é por chave de API, e a medida 1 não tem configuração
  gerenciada. A aplicação de `allowManagedModsOnly` nesta máquina é ato do maestro; nada foi aplicado, e o efeito no login
  dele segue sem medida.
- **Login Team ou Enterprise:** só por doc.
- **Hook gerenciado com `onFailure: block`:** a falha aberta do gerenciado foi medida sem essa chave e com arquivo inexistente.
- **Mod de processo por skills sob `allowManagedModsOnly` sozinho:** só com a combinação; sozinha, a política recusou o mod que aprova.
- **`blockedMarketplaces` sozinho:** só em conjunto com `disableSideloadFlags` e hook gerenciado.
- **Os outros 4 vetos do core sob mod:** as duas medidas só exercitam o do `.env`.
- **Copilot, Gemini e Cursor em modo autônomo:** sem rodagem do Onion. O gatilho exige exatamente isso.
- **Antigravity:** sem primária. **Goose:** por leitura, em grafo não rastreado (`aaif-projects-onion-2026-11`), citado sem aresta.
- **Edit ou Write em `.claude/` sob bypass:** as células W1 e W4 mostram a escrita em `.claude/skills/x` passando com os hooks
  reais, em API simulada; nos demais caminhos de `.claude/` segue só a leitura estática. Não há sandbox configurado, e a cura
  candidata fica fora desta redação.
- **Agente e comando de plugin sob `allowManagedModsOnly`:** só listados, não invocados.
- **Capital:** valores do Elenxo sem primária.
- **Citações de Copilot, Gemini, Cursor e Codex:** vieram por WebFetch mediado por modelo.

## Valeu a pena

Sim, com uma ressalva de custo. O run custou 9.274.630 tokens e 106 agentes, e o ganho foi tirar uma afirmação falsa da
identidade canônica e de dois README públicos gerados. A ressalva: o contraexemplo decisivo, o Codex sob bypass, **já estava
pago no corpus**, e o run só o achou na fase adversarial (`E_OBJECAO_CODEX_BYPASS_MEASURED`). As condições de força vieram das
duas medidas, 9 sessões em haiku e 117 repetições em stub, ambas fora do contrato acima e sem contagem de tokens registrada.
Da próxima vez, corpus e célula antes do fan-out.

## Saneamento de `data/`

Saíram caminho de máquina, usuário e host, trocados por `⟨…⟩`; ficaram de fora `clone/`, `runs/`, `pilot/`, `canary.value` e as
5 cópias da guarda em `policies/*/hooks/`, iguais à `pretooluse-env-guard.sh` em `88793c4a9` (mesmo sha256, `c4c26976be089b4e…`).
Os `SHA256SUMS.*` valem para os originais, e por isso `PRE-REGISTRO*.md`, `run_cell.sh`, `consolidado.txt`, `results.jsonl` e
`efeitos-*.txt` saneados não batem com eles. O único IP é `127.0.0.1`, do stub.
