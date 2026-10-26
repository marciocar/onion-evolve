---
kg: docs/evolution/research/codex-as-core-2026-10/codex-as-core-2026-10.kg.yaml
run_id: "wf_e4a2a9be-bb5"
tokens: 1384791
agents: 20
duration_min: 12
---

# O Codex roda o Onion como Onion Core? (primárias e spikes, 2026-10-26)

Pedido do maestro em 2026-10-26: avaliar se o onion-codex pode virar o Onion Core no Codex, com eficiência e
eficácia como no Claude Code, publicado como porta nova. A condição era fazer spikes e testes pequenos antes de
afirmar.

- **Fase 1, rodada de primárias:** corpus e fontes primárias, com 8 fontes, 1 leitor e 1 verificador separado por
  fonte, e o Elenxo, o método de refutar antes de selar.
- **Fase 2, spikes:** a curadoria (o repo adotante `onion-curation`) mediu três spikes no Codex CLI 0.164.0, com
  plano pré-registrado. Depois rodou uma emenda C, sobre os hooks do próprio porte. O core conferiu cada resultado
  contra as saídas literais em `evidence/`: os spikes em `onion-curation@da53ec3` e a emenda C em
  `onion-curation@bc30bce`. Os nós `E_SPIKE_*` são essa conferência.

Esta síntese projeta o grafo, que é a fonte da verdade.

## Veredito por peça (nós `C_PIECE_*`, todos `open`)

| Peça do core | Veredito | Nó |
|---|---|---|
| Hook que barra (o equivalente ao `exit 2`) | **PARCIAL** (antes FALTA). O bloqueio determinístico existe e vale até sem sandbox e sem aprovação. Mas ele pede **duas confianças**: a do projeto, gravada na configuração do usuário, e a do hook. Há três falhas abertas silenciosas: sem uma das confianças o hook é pulado, o `--ignore-user-config` desliga os hooks do projeto, e a doc declara falha aberta em erro ou timeout. | `C_PIECE_HOOKS_BLOCK_PARTIAL_THREE_FAIL_OPEN_1026` (supera `C_PIECE_HOOKS_DETERMINISTIC_BLOCK_MISSING_1026`) |
| Sandbox, aprovação e execpolicy | **PARCIAL.** Há `forbidden > prompt > allow` por prefixo de comando, mas as rules são experimentais e dependem do trust do projeto. Os spikes não testaram rules. | `C_PIECE_RULES_SANDBOX_PARTIAL_1026` |
| AGENTS.md | **EQUIVALENTE** ao CLAUDE.md em descoberta e precedência por diretório. | `C_PIECE_AGENTS_MD_EQUIVALENT_1026` |
| Skills e comandos | **EQUIVALENTE em carregamento** (antes NÃO JULGADO). Três skills do porte carregam por `$nome`, e o warm-up rodou de ponta a ponta. O destino dos 117 comandos do core segue sem medida. | `C_PIECE_SKILLS_LOAD_EQUIVALENT_1026` (supera `C_PIECE_SKILLS_COMMANDS_UNJUDGED_1026`) |
| Subagentes | **EQUIVALENTE no formato** (TOML, modelo por agente). O isolamento por worktree segue aberto. | `C_PIECE_SUBAGENTS_EQUIVALENT_FORMAT_ISOLATION_OPEN_1026` |
| MCP | **Só cliente.** O papel de servidor foi removido. | `C_PIECE_MCP_CLIENT_ONLY_1026` |
| Execução não interativa e CI | **EQUIVALENTE** ao `claude -p` para o gate que lê e reprova, agora **com limite**: quando o hook barra, o `codex exec` sai com 0 e o `--json` não traz o veto. | `C_PIECE_EXEC_CI_EQUIVALENT_1026`, limitado por `E_SPIKE_S1_BLOCK_SIGNAL_NOT_IN_RC_OR_JSON_1026` |
| Trajetória de releases | **ABERTA.** Só a 0.137 e a 0.164 foram lidas, de 27 minors em ~140 dias. | `C_PIECE_RELEASES_TRAJECTORY_OPEN_1026` |

## O que os spikes mediram

Ambiente: Codex CLI 0.164.0, repositório descartável com remoto bare, e um hook `PreToolUse` em `.codex/hooks.json`.
Foi uma rodada por caso, com uma versão e um modelo.

- **S1, o hook barra comando e escrita** (`E_SPIKE_S1_TRUSTED_HOOK_BLOCKS_0164_1026`). Com o hook confiável, ele
  barra `git push` e `echo > MARKER.txt`. Vale sob `workspace-write` com aprovação `never` e sob
  `--dangerously-bypass-approvals-and-sandbox`, pelas duas formas de negação (exit 2 e JSON `deny`). Não há evento
  `command_execution` e não há diálogo.
- **O veto não tem sinal de máquina estável** (`E_SPIKE_S1_BLOCK_SIGNAL_NOT_IN_RC_OR_JSON_1026`). O `codex exec`
  sai com 0, e o `--json` só traz a mensagem do modelo. Há uma linha de log `ERROR` no stderr, que é log e não
  contrato.
- **Falha aberta 1** (`E_SPIKE_FAILOPEN_UNTRUSTED_HOOK_SKIPPED_1026`): o hook sem confiança gravada é pulado em
  silêncio no `codex exec`.
- **Falha aberta 2** (`E_SPIKE_FAILOPEN_IGNORE_USER_CONFIG_1026`): com `--ignore-user-config`, o hook não dispara.
  Sem sandbox, o push chegou ao remoto e o arquivo foi escrito, nas quatro rodadas.
- **A causa da falha 2** (`E_SPIKE_PROJECT_TRUST_ONLY_PERSISTED_1026`, da emenda C da curadoria): o
  `-c projects.<dir>.trust_level="trusted"` não confia o projeto. O `.codex/` só é lido com a entrada
  `[projects.<dir>] trust_level` gravada na configuração do usuário, e o `--ignore-user-config` descarta essa
  entrada. Quem grava a entrada não foi isolado (`Q_CODEX_PROJECT_TRUST_WHO_WRITES_1026`). Por isso a confiança
  do nó é 0.6.
- **S4, os hooks do próprio porte** (`E_SPIKE_S4_PORT_HOOKS_JSON_REJECTED_1026`): é um **defeito medido na LINHA
  VIVA**. O Codex 0.164.0 recusa o `.codex/hooks.json` do onion-codex com o erro `unknown field SessionStart,
  expected description or hooks`, e o `SessionStart` do porte não roda. O erro aparece no `--json`, mas o
  `codex exec` sai com 0. Com o conteúdo dentro de `{"hooks": ...}`, o hook dispara. A correção é do repo onion-codex
  (`Q_ONION_CODEX_HOOKS_JSON_FIX_IN_PORT_1026`).
- **Falha aberta 3** (`E_SPIKE_DOC_HOOK_FAIL_OPEN_DECLARED_1026`): a doc oficial, re-ancorada nesta escrita, diz
  que erro, timeout ou resposta malformada podem falhar o hook sem barrar a ferramenta. Isso não foi exercitado.
- **S2, o `apply_patch` contra o deny** (`E_SPIKE_S2_APPLY_PATCH_ADD_FILE_BLOCKED_1026`): o deny barrou a criação
  de arquivo (Add File), e a #27833 não se reproduziu nesse caso. Update File e multi-worktree não foram testados.
- **S3, as skills do porte** (`E_SPIKE_S3_PORT_SKILLS_LOAD_1026`): `$onion`, `$engineer-start` e
  `$engineer-warm-up` carregam. O warm-up rodou 13 comandos sem sandbox, numa rodada fora do pré-registro e
  declarada como tal.

**Comparação com o Claude Code, sem afirmar o que não foi medido.** O corpus mede o exit 2 barrando sob bypass
(`maestro-vivo-2026-08#E_PRETOOLUSE_BARRA_SOB_BYPASS`). Mede também que um operador desliga hooks por
`disableAllHooks` (`chat-agent-isolation-2026-10#E_PROVA1_WORKSPACE_HOOK_RUNS_WITHOUT_BASH_1016`). Não mede o
Claude Code nas condições das falhas 1 e 3 (confiança de hook de projeto no `claude -p`, erro e timeout do hook).

## O que não bateu entre o relato da curadoria e `evidence/`

- A falha aberta 2 aparece em **quatro** rodadas, não em duas: `S1-3-c` (o push rodou) e `S1-3-w` (o marcador foi
  escrito) também passaram. Logo a forma JSON `deny` falha igual.
- "Remoto igual" não discrimina nas rodadas da emenda B: o 1º lote já tinha empurrado o commit. O que prova o
  bloqueio do push é a ausência de `command_execution`.
- O `--json` não traz evento do hook, mas o stderr traz uma linha de log com o veto, nas nove rodadas que barraram.
- O hook recebe `permission_mode: "bypassPermissions"` inclusive sob `workspace-write` com aprovação `never`, então
  o campo não distingue o modo.
- Na emenda C, três pontos do relato não têm artefato em `evidence/runs-c`: não há `args.txt` nem cópia da
  configuração do usuário. Por isso não se pode conferir que a diferença entre as rodadas S4 e S4T é a entrada
  gravada. Também não foi guardado o arquivo-sinal do controle `S4-CTRL`. E o "o Codex gravou a entrada sozinho" é,
  no próprio RESULTS.md, uma hipótese provável, não isolada. O que a evidência sustenta é que, nas S4, o
  `hooks.json` nem foi lido: o mesmo arquivo malformado que dá erro de parse nas S4T não dá nada nelas.

## Recomendação (`C_RECOMMENDATION_AFTER_SPIKES_1026`, supera `C_ELENXO_NOT_EQUIVALENT_NO_NEW_DOOR_YET_1026`)

O Codex 0.164.0 tem o primitivo do bloqueio determinístico, mas ainda não roda o Onion Core com eficácia
equivalente. Esta rodada não autoriza a porta nova. O onion-codex segue como LINHA VIVA. **A decisão de porta é do
maestro, e esta sessão não sela.**

Um Onion Core no Codex teria de fechar as falhas 1 e 2 por mecanismo próprio, não por doutrina: por exemplo, um hook
gerenciado, ou uma guarda que reprove a ausência do hook. E a LINHA VIVA tem hoje um hook que não roda (S4).

## O que ainda falta (perguntas abertas, cada uma com o teste que a fecha)

1. `Q_ONION_CODEX_HOOKS_JSON_FIX_IN_PORT_1026`: a correção no repo onion-codex, não neste. Envolver o
   `hooks.json` em `{"hooks": ...}` e cobrar a forma no gate do porte. Fecha quando o erro de parse sumir num clone
   corrigido e o commit no onion-codex for citado aqui.
2. `Q_CODEX_APPLY_PATCH_UPDATE_AND_WORKTREES_1026`: o deny contra Update File e Delete File, numa worktree principal
   e numa secundária.
3. `Q_CODEX_HOOK_FAIL_OPEN_EXERCISED_1026`: três hooks defeituosos (exit 1, timeout, JSON malformado), mais um hook
   gerenciado sem a flag de confiança.
4. `Q_CODEX_PROJECT_TRUST_WHO_WRITES_1026`: quem grava a confiança do projeto, e em que modo. O teste parte de uma
   configuração limpa, roda uma vez por modo e faz o diff do `config.toml` depois de cada rodada, guardando os
   `args.txt`. Ela supera `Q_CODEX_IGNORE_USER_CONFIG_LAYER_1026`, já respondida pela emenda C.
5. `Q_CODEX_BLOCK_MACHINE_SIGNAL_FOR_CI_1026`: verificar se existe sinal de máquina estável do veto para o CI.

Seguem abertos também: o `PreToolUse` sobre tool MCP, as notas de 0.138 a 0.163 e o isolamento por worktree dos
subagentes.

## Mercado

O Codex lança estáveis a cada poucos dias (27 minors em ~140 dias). As perguntas abertas ficam ligadas a release,
pelo `review_after` do grafo.

## NÃO-VERIFICADOS

- **Fase 1:** 16 claims rejeitadas na ancoragem (9 sem citação e 7 exageradas). A contabilidade está no nó
  `E_LACUNAS_PRIMARIES_CODEX_AS_CORE_1026`. A lacuna `codex-hooks` foi fechada pelos spikes e pela re-ancoragem;
  as de skills e comandos (citação oficial), subagentes e releases seguem abertas.
- **Fase 2:** os hooks gerenciados (`requirements.toml`) não foram testados. O modo com sandbox não executa nada
  nesta VPS, porque o bwrap não sobe, e isso é limite do ambiente.

## Valeu a pena

A fase 1 custou 1.384.791 tokens para 62 nós, cerca de 22 mil por nó. A fase 2 foi medição local da curadoria,
sem fan-out. Ela mudou dois vereditos e substituiu a pergunta "o hook barra?" por cinco perguntas menores, cada uma
com seu teste.
