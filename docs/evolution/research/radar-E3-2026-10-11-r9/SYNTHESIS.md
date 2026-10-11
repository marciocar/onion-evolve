---
kg: docs/evolution/research/radar-E3-2026-10-11-r9/radar-E3-2026-10-11-r9.kg.yaml
run_id: "sem run de Workflow: rodada conduzida pelo /meta:cc-update na sessão principal, com 1 juiz opus/high (subagente não-fork)"
tokens: 153679
agents: 1
duration_min: 8
---

# Radar E3 · rodada r9 — Claude Code 2.1.295 → 2.1.296

A primeira rodada pelo `/meta:cc-update` forjado. O medidor (`cc-delta-census.sh`) separou o delta,
**uma versão com 79 itens**, e gravou a cópia em `data/2.1.296.txt`. O juiz confirmou que essa cópia é
idêntica byte a byte ao CHANGELOG oficial. O custo acima é o do juiz; a rodada principal não tem medida
de tokens própria.

## O que toca a casa (medido no vivo, julgado pelo juiz)

| Nó | Item | O que muda no core |
|---|---|---|
| `E_TIERING_DOS_WORKFLOWS_E_O_MODELO_UNICO` | `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` | A checagem "tiering declarado ≠ executado" da `onion-orchestration` é **cega** à variável nova, porque o grep procura outro nome. **Ação: SAC-105.** |
| `E_FRONTMATTER_DE_AGENTE_SEM_GUARDA_DE_CHAVE` | `autoCompactWindow` e `--debug` que nomeia campo não reconhecido | Os 51 agentes usam **11 chaves fora da tabela oficial** (344 ocorrências), e uma delas é exigida por REGRA HARD. O `--debug` acusaria todos os agentes. **Ação: SAC-106.** |
| `E_DEBUG_DE_HOOK_MEDE_DURACAO` | `--debug` com duração de hook | 20 hooks, **9 sem timeout**. Só os PreToolUse (cerca de 125 ms) e o kg-read-leg (8 ms) têm latência medida. **Ação: SAC-106.** |
| `E_GITATTRIBUTES_SEM_EOL_LF` | Workflow aceita CRLF | O core não fixa `eol=lf`, e os hooks `.sh` quebram num checkout Windows com autocrlf. **Ação: SAC-107.** |
| `E_VETO_PROPRIO_JA_PEGA_INDIRECAO_POR_VARIAVEL` | permissionador fechou `BASH_ARGV0` | Nada muda: os vetos do core já barravam a indireção. A lib resolve a atribuição literal e fecha por inanalisável a forma via `$0`. |
| `E_USERPROMPTSUBMIT_DO_CORE_NAO_VETA` | Esc durante `UserPromptSubmit` | Nada muda: nenhum dos 4 hooks desse tipo veta. |
| `E_PRECO_DO_CACHE_DO_SONNET_CAIU` | cache do Sonnet 5.5 pela metade | É informativo. 43 dos 51 agentes estão em sonnet, e a série de custo do revisor de CI muda de base. |

**Superação:** `x_supersedes_none`, porque nenhum nó da r8 cai, e o juiz confirmou. Entram duas
`external_edges` SUPPORTS para a r8:
- `E_MODS_GUARDA_NO_RESTART_CURADA`, porque os itens de hooks de plugin e mod depois de reload mostram que a classe recorre;
- `E_ZERO_SILENCIOSO_NAS_FERRAMENTAS`, por causa do truncamento silencioso em Workflow.

## Juiz (opus/high, mandato REFUTAR)

O juiz julgou 7 nós:
- **sustentam:** 2;
- **exageram e foram reescritos:** 4 (veto, tiering, frontmatter, preço);
- **reprovado e corrigido:** 1, o de duração de hook, em que a contagem de hooks sem timeout estava invertida e a afirmação "nunca mediu" era falsa.

Ele também apontou 6 locators sem as crases e 1 paráfrase, todos corrigidos para o texto exato do item. A omissão de impacto 2 que ele achou (`eol=lf`) virou nó.

## NÃO-VERIFICADOS

- **A sonda `claude -p --debug` não foi rodada.** Ela dispara o hook Stop do usuário (notificação no celular), e o `--bare` exige uma `ANTHROPIC_API_KEY` que não está no ambiente. Fica para a SAC-106.
- **Itens fora do alcance do core,** sem medida porque não tocam nada aqui: settings gerenciados, Windows, VSCode, sessões na nuvem, Claude Tag e Code Review.
- **Omissões de impacto ≤ 2 que o juiz mediu e não viraram nó:**
  - skills sincronizadas com config compartilhado (a VPS tem várias sessões no mesmo `~/.claude`);
  - subagente retomado que ouvia "o usuário rejeitou";
  - hooks de plugin omitidos por nome igual;
  - redação de segredo em debug log.
- **Itens de impacto 1:** variáveis de ambiente que o core não usa, limite de descrição de MCP e `allow_large` do Read.

## valeu-a-pena

Uma versão e 79 itens, com 12 nós no grafo. Saíram 3 ações reais (SAC-105 a SAC-107), e duas delas o rascunho
não tinha visto: o juiz as achou medindo o vivo. O custo foi o de 1 juiz (cerca de 154 mil tokens de
subagente), bem abaixo da r8, que tinha 6 versões.
