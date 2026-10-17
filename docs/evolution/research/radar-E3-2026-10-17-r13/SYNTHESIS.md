---
kg: docs/evolution/research/radar-E3-2026-10-17-r13/radar-E3-2026-10-17-r13.kg.yaml
run_id: "sem run de Workflow: rodada conduzida pelo /meta:cc-update num agente de execução, com 1 juiz opus/high (subagente não-fork)"
tokens: 298330
agents: 2
duration_min: 60
---

# Radar E3 · rodada r13 — Claude Code 2.1.301 → 2.1.302

O medidor (`cc-delta-census.sh`) separou o delta: **uma versão, 63 itens**, copiados em `data/2.1.302.txt`. O
juiz baixou o CHANGELOG oficial e conferiu a cópia byte a byte: `cmp` vazio, 66 linhas.

- **Custo.** Os tokens do frontmatter somam os dois subagentes: o juiz (156.656, 7,5 min) e o refutador do diff
  (141.674). Os 60 min cobrem a rodada inteira, que não tem medida de tokens própria.
- **Guarda de deriva.** A guarda de binário que o censo manda rodar (`lint-selftest.sh --families
  cited_directive`, com `LC_ALL=C`) saiu rc 0: 6 casos passaram, 0 falharam.
- **Versões.** A tabela do censo mostra baseline 2.1.301 e disco, processo e SDK do bridge em 2.1.302.

## O achado: desta vez o delta chega à produção

Na r12, o /chat rodava o CLI 2.1.232 e o delta não chegava lá. Agora o clone servido do bridge está em
`7f4322c` (PR #78): SDK 0.3.302, binário 2.1.302, processo reiniciado depois do deploy. O `chat-runner verify`
desta rodada saiu rc 0 com `n_fail=0`. A cerca de rede, o DynamicUser e o aperto de mão pelo socket estão
provados no CLI novo. Por isso o nó `E_SDK_0_3_301_EM_PRODUCAO_1016` da r12 foi superado (`external_edges`
SUPERSEDES), com o mesmo precedente que a r12 usou.

Com o delta chegando ao /chat, o que importa é a mudança de comportamento do `claude -p` e do Agent SDK.

## O que toca a casa (medido no vivo, julgado pelo juiz)

| Nó | Item | O que muda |
|---|---|---|
| `E_FORK_LIGADO_POR_PADRAO_ALCANCA_O_ADMIN_DO_BRIDGE` | fork de subagente ligado por padrão no `-p` e no SDK | Medido com um servidor local que captura a requisição, sem chamar a API: a ferramenta Agent passa a oferecer `fork`. São 10 menções na 2.1.302 e 2 na 2.1.301; com `CLAUDE_CODE_FORK_SUBAGENT=0`, 2. O admin do bridge não restringe ferramentas e recebe o fork. O convidado não: sob as flags dele, o init só tem `Read`. **Ação SAC-168.** |
| `E_REVISOR_DO_CI_INSTALA_O_CLI_2_1_220` | o delta inteiro (alcance) | O revisor de IA do CI instala o CLI 2.1.220, fixado no pin `be7b93b1` da `claude-code-action`. São 69 versões publicadas atrás do host, e nenhum dos dois censos vê esse CLI. O revisor está desligado por padrão (label `review:ia`). **Ação SAC-169.** |
| `E_NENHUM_ITEM_TOCA_SANDBOX_WEBFETCH_STREAMJSON_1017` | modo padrão em provedor de terceiros; teto de 12 hooks prompt/agent | Nenhum item cita sandbox, WebFetch, stream-json, `--settings`, socket ou Workflow. O bridge e o runner passam o modo de permissão sempre. Os 23 hooks do core são `command`. |
| `E_CLAUDE_DESIGN_STANDALONE_FECHA_EM_DEZEMBRO` | Claude Design standalone fecha em 14/12/2026 | O core não usa a superfície. Dois docs a citam como referência: a pressão de campo para a 4ª dimensão e a estratégia de distribuição. |
| `E_AUTO_MODE_NAO_ALCANCA_AS_SESSOES_EM_BYPASS` · `E_SINAIS_DO_DELTA_SEM_CONSUMIDOR_1017` | auto mode, worktree no git 2.56, reftable, `claude plugin`, MCP 2026-07-28, OTel, Read de imagem de 128 MB | Não tocam (medido). |

## Juiz

O juiz rodou em opus/high com mandato REFUTAR e critérios pré-registrados (`data/judge-verdicts.json`, CU1–CU5).
O `judge-verdict-check.sh` saiu rc 0: 1 negativo, 0 recusados. Dos 12 nós: **11 SUSTENTA, 0 EXAGERA, 1 REPROVA**,
e **0 omissões** de impacto ≥ 2.

- **REPROVA: o auto mode.** A 1ª redação dizia que as sessões do maestro rodam em auto mode porque o settings do
  usuário tem `defaultMode: auto`. O juiz leu a linha de comando dos processos vivos: são 5 sessões interativas
  com `--dangerously-skip-permissions` e uma de fundo em `bypassPermissions`. Nessas sessões o classificador não
  roda. O nó foi rebaixado e renomeado.
- **Correção no fork.** A saída em segundo plano depois do `query()` não é efeito do fork. O padrão de subagente
  em segundo plano já existia na 2.1.301, então a condição de fechamento da SAC-168 separa as duas coisas.
- **Deriva fora do delta.** O cabeçalho de `ops/cc-sdk-targets.tsv` ainda dizia 0.3.301. Foi curado nesta branch.
- **Refutador do diff (opus).** Achou 4 pontos, todos curados aqui:
  - o nó superado na r12 ainda estava `confirmed` e passou a `superseded`, como a r12 fez com o seu;
  - a SYNTHESIS não tinha nó que a citasse (REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com catraca));
  - o REPROVA apontava o id antigo do nó de auto mode, que agora fica registrado na narrativa;
  - o contrato de custo contava só o juiz.

A Aufhebung que o juiz decidiu foi SUPERSEDES de `E_SDK_0_3_301_EM_PRODUCAO_1016`. Desta vez o schema
`entrega|nenhuma` foi entregue ao juiz, como a r12 pedia, e ele respondeu `nenhuma` em todas as superações.

## NÃO-VERIFICADOS

- **Um turno admin real com fork pelo SDK.** Não se mediu custo, cópia de contexto nem a saída em segundo plano.
- **A variável no arquivo de ambiente do bridge.** Não se sabe se ele define `CLAUDE_CODE_FORK_SUBAGENT`, porque
  o arquivo não foi lido, por regra.
- **Um turno do /chat com a API real no CLI 2.1.302.** O verify prova o aperto de mão, não o turno.
- **O comportamento do revisor do CI no CLI novo.** O pin não foi trocado, e um PR que edita o workflow faz a
  action se auto-pular.
- **Os itens fora do core.** Cloud sessions, Claude Tag, Remote Control, Code Review, VSCode, Windows e
  PowerShell não têm superfície no core e não foram medidos.
