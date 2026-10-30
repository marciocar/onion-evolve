---
title: Radar E3 r21 — o delta do Claude Code 2.1.314 contra o Onion
date: 2026-10-30
kg: docs/evolution/research/radar-E3-2026-10-30-r21/radar-E3-2026-10-30-r21.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão, com um juiz subagente independente)"
tokens: 194427
agents: 1
duration_min: 55
review_after: 2026-11-29
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** `tokens` conta só o juiz: 194.427 tokens em 51 chamadas e 9,3 min, medidos pelo
> harness. A rodada rodou como subagente da sessão, e os tokens dela não ficaram expostos a ela. `agents: 1` é o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.314, com 119 itens em 122 linhas. A baseline era 2.1.312, e disco e processo estão em
2.1.314. O CHANGELOG não tem seção 2.1.313.

- **O revisor do CI alcançou o host.** O pin v1.0.265 (`6d5ae526`, PR #1439) instala o CLI 2.1.314.
- **Quem serve segue atrás.** O /chat do bridge continua no SDK 0.3.310 (CLI 2.1.310), três versões publicadas atrás. O npm
  já tem o SDK 0.3.314. A rodada registra isso; a subida é do maestro, pelo `ops/update-bridge.sh`.
- **O sinal `claude-opus-4` do censo** vem da linha 43, que cita a grafia com ponto `claude-opus-4.8` atrás de gateway de
  LLM. A casa não roda atrás de gateway, então o sinal não liga nada no core.
  - Achado lateral: o corpo do `claude-code-specialist` (linha 208) ainda recomenda `claude-opus-4-7`. Fica fora da
    allowlist do E6 (o eixo de fronteira de modelos do radar, com a escada de modelos da sessão) e fora de frontmatter, onde a REGRA 3 (Campo model: restrito à allowlist sonnet|opus|haiku|fable) não
    olha.
- **Guarda de deriva de binário:** a `cited_directive` segue verde na 2.1.314, com rc 0 e 6/0/0.

## O que toca a casa

- **Linha 35: os vetos do Bash passam a alcançar o Monitor**
  (`E_VETOS_DO_BASH_ALCANCAM_O_MONITOR_NA_2_1_314_1030`).
  - **Sonda ao vivo no processo 2.1.314:** um `cat` de `.env` num diretório inexistente foi barrado pelo env-guard tanto pelo
    Bash quanto pelo Monitor. O juiz repetiu a sonda e viu também o merge-gate barrar pelo Monitor.
  - **Antes:** o Monitor era um desvio dos vetos de exit 2.
  - **O que não mudou:** o PostToolUse `bash-empty-result-guard.sh` **não** roda no Monitor (medido pelo juiz e re-medido
    pela rodada).
  - **Lacuna:** nada na casa prova essa cobertura.
  - Ação: `Q_A_COBERTURA_DO_MONITOR_VIRA_CASO_DA_BANCADA_1030` (**SAC-263**, a tarefa de decidir se a cobertura do Monitor vira caso da bancada).
- **Linha 3: `permissions.blockWritesOutsideWorkingDirectories`**
  (`E_BLOCKWRITES_FORA_DO_DIRETORIO_SEM_USO_1030`).
  - É um veto nativo que vale sob `bypassPermissions`, o modo em que o host roda.
  - A casa não o usa e escreve fora do diretório por desenho: worktrees, scratchpad e memória.
  - Ação: `Q_AVALIAR_BLOCKWRITESOUTSIDE_NA_CASA_1030` (**SAC-264**, a tarefa de avaliar o veto nativo de escrita), medir num sandbox antes de ligar.
- **Versões de quem serve** (`E_HOST_E_REVISOR_NA_2_1_314_BRIDGE_NA_2_1_310_1030`). Ação:
  `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_314_1030` (**SAC-262**, a tarefa de subir o SDK do bridge para 0.3.314), por paridade. A SAC-261 (a tarefa da r20 de subir o SDK e o pin do revisor) foi comentada: a metade do pin está
  feita, e o alvo do SDK passou para a SAC-262.
  - A linha 36 (`--setting-sources`) **não tem o que vazar** no /chat de hoje, medido como a conta do serviço.
  - A linha 62 (host stream-json) é candidata, sem efeito medido.
- **Linha 25, o index lock tomado pelo harness.** A correção tira um contendor da disputa que a bancada (`_archive_staged`,
  `lint-selftest.sh` linhas 1549 a 1573) e os materializadores já nomeiam.
- **Linha 9 da 2.1.312, nome de comando inválido.** A correção agora chega ao revisor do CI (2.1.314), e só o bridge segue
  sem ela.
- **Sem efeito no core, medido:**
  - **Linha 24 (PreCompact):** o hook da casa não emite saída.
  - **Linha 8 (`claude -p` sai 1):** o `review-verdict.sh` já não confiava no rc.
  - **Linha 89 (`which`):** o `grep` segue função na shell do agente.
  - **Extensão do VS Code:** segue na 2.1.306, sete versões atrás, e os itens dela não a alcançam (SAC-260, a tarefa de decidir se a extensão entra no censo ou sobe).
  - **Sem superfície:** ultrareview, o gateway de apps, Bedrock e afins, `FORCE_HYPERLINK`, o `if` com Monitor, Claude Tag
    e as sessões na nuvem.
  - **Só no host:** Remote Control e os `.trash`.
- **Aufhebung:** cinco SUPERSEDES sobre a r20.
  - o nó das versões de quem serve;
  - a pergunta da subida;
  - a extensão do VS Code;
  - o nó do nome de comando;
  - o do `core.hooksPath` absoluto.

## Juiz

O juiz foi **independente**: um subagente `general-purpose`, modelo opus, effort high, não-fork, com mandato REFUTAR. Os
critérios CU1 a CU5 foram gravados antes do lançamento em `data/judge-verdicts.json`.

**Resultado: 21 SUSTENTA, 1 EXAGERA e 5 REPROVA** em 27 vereditos, com 6 superações. O `judge-verdict-check.sh` saiu com
rc 0 e 0 recusados.

- **Cópia do CHANGELOG:** `cmp` contra a oficial sem diferença; as linhas citadas conferem.
- **EXAGERA:** a pergunta da subida usava a linha 36 como razão além da paridade, e não há o que vazar no /chat. A pergunta
  foi reescrita, e o nó do `--setting-sources` caiu para impacto 1.
- **REPROVA, duas superações da r20 que faltavam:**
  - o nó do nome de comando, porque o revisor subiu;
  - o do `core.hooksPath`, que não tinha sido re-medido.

  Os dois viraram nós novos, com SUPERSEDES.
- **REPROVA, três omissões:**
  - a bancada `_archive_staged` como superfície do index lock;
  - o PostToolUse que não roda no Monitor;
  - a linha 62 no /chat, que é host stream-json.

  As três foram absorvidas nos nós.
- **Superações:** cada uma virou um nó `C_SUPERACAO_20261030_*`, com `TRACES_TO` ao nó julgado.
- **Re-medição antes de aplicar:** a rodada re-mediu as alegações centrais do juiz:
  - o PostToolUse silencioso pelo Monitor;
  - o `find` dos settings do /chat como a conta do serviço;
  - o `core.hooksPath` local relativo;
  - as issues 85039 e 88747 abertas;
  - as linhas da `_archive_staged`.

## NÃO-VERIFICADOS

- **Linha 35:** se outros vetos, além do env-guard e do merge-gate, reagem pelo Monitor. Não se testou protect-main,
  moat-gate, direct-provider nem kg-read-leg.
- **`core.hooksPath`:** se a 2.1.314 ainda o regrava para absoluto ao criar worktree de agente. Nenhuma worktree do harness
  nasceu sob a 2.1.314.
- **Linha 62:** o efeito no /chat, que exige uma sessão real.
- **Linha 25:** se alguma falha passada da casa veio do lock tomado pelo harness.
- **Linha 3:** o comportamento do veto nativo com as escritas legítimas declaradas, que é o objeto da SAC-264.
- **Linhas de tela, de nuvem, de VS Code e de Claude Tag** sem superfície no core: não foram medidas uma a uma.
- **Contagem defasada da r20:** as 15 worktrees de agente citadas lá hoje são 19. A substância dos nós da r20 segue, e eles
  não foram re-medidos aqui.
