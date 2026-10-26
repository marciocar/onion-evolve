---
kg: docs/evolution/research/codex-as-core-2026-10/codex-as-core-2026-10.kg.yaml
run_id: "wf_e4a2a9be-bb5"
tokens: 1384791
agents: 20
duration_min: 12
---

# O Codex roda o Onion como Onion Core? (rodada de primárias, 2026-10-26)

Pedido do maestro em 2026-10-26: avaliar se o onion-codex pode virar o Onion Core no Codex, com eficiência e
eficácia como no Claude Code, publicado como porta nova. A condição era fazer spikes e testes pequenos antes de
afirmar. Esta rodada é a fase 1: corpus e fontes primárias, com 8 fontes, 1 leitor e 1 verificador separado por
fonte, e o Elenxo, o método de refutar antes de selar. Esta síntese projeta o grafo, que é a fonte da verdade.

## Veredito por peça (nós `C_PIECE_*`, todos `open`)

| Peça do core | Veredito | Nó |
|---|---|---|
| Hook que barra (o equivalente ao `exit 2`) | **FALTA, sem equivalente provado.** O PreToolUse é parcial, o deny não vale no `apply_patch` (issue #27833 aberta), há fail-open, e nada foi medido sob `never` ou `danger-full-access`. | `C_PIECE_HOOKS_DETERMINISTIC_BLOCK_MISSING_1026` |
| Sandbox, aprovação e execpolicy | **PARCIAL.** Há `forbidden > prompt > allow` por prefixo de comando, mas as rules são experimentais e dependem do trust do projeto. | `C_PIECE_RULES_SANDBOX_PARTIAL_1026` |
| AGENTS.md | **EQUIVALENTE** ao CLAUDE.md em descoberta e precedência por diretório. | `C_PIECE_AGENTS_MD_EQUIVALENT_1026` |
| Skills e comandos | **NÃO JULGADO.** Todas as claims caíram na ancoragem. | `C_PIECE_SKILLS_COMMANDS_UNJUDGED_1026` |
| Subagentes | **EQUIVALENTE no formato** (TOML, modelo por agente). O isolamento por worktree segue aberto. | `C_PIECE_SUBAGENTS_EQUIVALENT_FORMAT_ISOLATION_OPEN_1026` |
| MCP | **Só cliente.** O papel de servidor foi removido. | `C_PIECE_MCP_CLIENT_ONLY_1026` |
| Execução não interativa e CI | **EQUIVALENTE** ao `claude -p` para o gate que lê e reprova. | `C_PIECE_EXEC_CI_EQUIVALENT_1026` |
| Trajetória de releases | **ABERTA.** Só a 0.137 e a 0.164 foram lidas, de 27 minors em ~140 dias. | `C_PIECE_RELEASES_TRAJECTORY_OPEN_1026` |

**Recomendação do Elenxo** (`C_ELENXO_NOT_EQUIVALENT_NO_NEW_DOOR_YET_1026`): a rodada NÃO autoriza dizer que o
Codex roda o Onion Core com eficácia equivalente, nem abrir porta nova. A peça que define o core é o hook que
barra no modo mais permissivo, e ela não tem equivalente provado. O onion-codex segue como LINHA VIVA.

## O que muda o veredito (spikes propostos, ainda não rodados)

1. **PreToolUse que nega:** um hook que barra comando e escrita, rodado sob `approval_policy=never` e
   `danger-full-access`, no Codex atual. É a única peça que decide a porta.
2. **`apply_patch` contra o hook:** medir se a issue #27833 ainda deixa a edição passar por fora do deny.
3. **Skills e comandos:** releitura com fonte melhor, e um teste de invocação de 2 ou 3 skills do onion-codex.
4. **Releases:** varrer as 27 minors entre a 0.137 e a 0.164 no que toca hooks, skills e subagentes.

## Mercado

O Codex lança estáveis a cada poucos dias (27 minors em ~140 dias), então a peça que falta pode chegar rápido.
Por isso os gatilhos dos spikes ficam ligados a release.

## NÃO-VERIFICADOS

Há 16 claims rejeitadas na ancoragem (9 sem citação e 7 exageradas) e 4 lacunas abertas: hooks, skills e
comandos, subagentes e releases. A contabilidade está no nó `E_LACUNAS_PRIMARIES_CODEX_AS_CORE_1026`. Não houve
corte por orçamento.

## Valeu a pena

São 1.384.791 tokens para 62 nós, cerca de 22 mil por nó. Fica abaixo do modo de primárias medido em 2026-09-13
(cerca de 42 mil por nó), e a rodada deu o veredito que decide o próximo passo: a peça do hook.
