---
kg: docs/evolution/research/radar-E3-2026-10-14-r10/radar-E3-2026-10-14-r10.kg.yaml
run_id: "sem run de Workflow: rodada conduzida pelo /meta:cc-update na sessão principal, com 1 juiz opus/high (subagente não-fork)"
tokens: 157956
agents: 1
duration_min: 35
---

# Radar E3 · rodada r10 — Claude Code 2.1.296 → 2.1.299

O medidor (`cc-delta-census.sh`) separou o delta: **uma versão, 190 itens**, em `data/2.1.299.txt`. O juiz
baixou o CHANGELOG oficial e confirmou a cópia byte a byte (sha256 igual, 193 linhas). O custo acima é o do
juiz; a rodada principal não tem medida de tokens própria.

## O que toca a casa (medido no vivo, julgado pelo juiz)

| Nó | Item | O que muda no core |
|---|---|---|
| `E_COMPACTACAO_OCIOSA_E_A_SESSAO_DO_MAESTRO` | compactação ociosa (200K+, ~54 min) | Nada que já não fosse zero: o hook PreCompact sai 0 fora de `feature/`/`hotfix/`/`release/`, e 0 de 312 refs do core usam esses prefixos. **Ação: SAC-117.** |
| `E_HOOK_DE_PLUGIN_FECHA_E_O_BUNDLE_LEVA_3` | hook de plugin recusa no handoff | O plugin `onion` publicado leva 3 hooks, um PostToolUse com exit 2. Não sondado ao vivo. **Ação: SAC-118.** |
| `E_WEBFETCH_DA_PESQUISA_HERDA_O_ESFORCO` | esforço do WebFetch segue o chamador | A fase Fetch do `/onion-research` (sonnet/medium) muda de base de custo; comparar tokens por nó com rodadas antigas deixa de ser direto. |
| `E_RELATORIO_DE_SUBAGENTE_EM_DOBRO_CURADO` | relatório final em dobro em auto mode | O juiz e o fan-out do core rodam assim; a correção tira um risco de leitura dupla. |
| `E_UPS_ANTES_DA_EXPANSAO_NAO_MUDA_O_CORE` | UserPromptSubmit antes da expansão | Nenhum hook UserPromptSubmit do core bloqueia; a injeção dos 8 comandos e 2 skills segue igual. |
| `E_PLAN_MODE_E_VETOS_SEM_ALLOW` | plan mode e PreToolUse que permite | Os 6 vetos PreToolUse nunca emitem allow. |
| `E_MCP_ALLOW_ESTREITADO_SEM_EFEITO_NO_CORE` | allow de MCP estreitado | O settings do core não tem regra MCP; os 2 agentes com MCP usam o nome inteiro. |
| `E_NOME_DE_SKILL_COM_CARACTERE_INVALIDO_ZERO` | nome de skill com caractere invisível | 0 de 176 caminhos (medido com `-z`). |
| `E_AGENT_SPAWN_RESUME_E_SENDMESSAGE_SEM_USO` | agent.spawn no resume, SendMessage | A maquinaria não usa nenhum dos dois (0). |
| `E_REVISOR_DO_CI_NAO_CHAMA_CLAUDE_P` | claude -p lista settings inválido | O revisor roda pela Agent SDK dentro da action pinada; a correção não o alcança. |

## Juiz

Opus/high, mandato REFUTAR: **2 sustentam, 3 exagerados e reescritos, 2 reprovados e remedidos**, mais 3
omissões de impacto 2 incorporadas como nós. As duas reprovações valem como lição:

- **O grep cego por construção.** `git ls-files` sem `-z` escapa não-ASCII em octal ASCII, e o padrão que
  procurava caractere invisível dava zero de qualquer jeito. O juiz provou com U+200B num repo temporário; a
  medição refeita com `-z` deu 0 de 176. Nenhuma guarda do core usa o padrão cego.
- **A migalha que não existia.** A 1ª redação supunha o PreCompact vivo nas sessões do core; ele é do worklog
  GitFlow e sai 0 em toda branch que o core usa.

## Aufhebung

`x_supersedes_none`: nenhum item de 2.1.299 contradiz nó da r9. A deriva de `E_DEBUG_DE_HOOK_MEDE_DURACAO`
(20 → 22 hooks, 9 → 11 sem timeout) e do `onFailure` (0 → 6) vem do core, não do delta, e vai ao
`/meta:kg-freshness` (**SAC-119**).

## NÃO-VERIFICADOS

- O comportamento do bundle `onion` sob 2.1.299 numa falha de handoff de hook (SAC-118).
- Se a compactação ociosa chega ao PreCompact como `trigger: auto` (a doc só lista `manual` e `auto`).
- O efeito real do esforço herdado no custo por nó do `/onion-research` (sem medida antes/depois).
- Itens que o juiz mediu com impacto 1 ficaram fora do grafo: shell embutido rodando 2 vezes (os 8
  comandos são só leitura), hook UserPromptSubmit no frontmatter de skill (0), `--plugin-dir` (0), `/btw`
  não interativo, ScheduleWakeup (só como padrão proibido na bancada), avisos do `/usage` (nenhum esforço max).
- Itens de gerenciado, mods, Windows, VSCode, nuvem e Claude Tag não tocam o core e não foram medidos.
