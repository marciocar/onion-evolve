---
name: cc-update
description: |
  Responde a uma atualização do Claude Code medindo o delta do CHANGELOG oficial contra a baseline do
  radar E3, julgando com um juiz que refuta e selando a rodada até o PR mergeado. Core-only.
category: meta
tags:
  - radar
  - claude-code
  - e3
  - forge
version: "1.0.0"
updated: "2026-10-08"
related_commands:
  - /meta:radar
  - /meta:forge
related_agents:
  - claude-code-specialist
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, TodoWrite
---

# 🔄 /meta:cc-update — a atualização do Claude Code como gatilho de re-medição

Quando o Claude Code muda de versão, a pergunta não é *"quebrou algo?"* e sim *"o que isto muda na
NOSSA maquinaria?"*. Este comando é a resposta padronizada: o **medidor** separa o delta, a **rodada**
liga item a superfície medindo o vivo, o **juiz** refuta, e tudo sela num PR mergeado. A doutrina
inteira (as 6 cláusulas e o que ela não promete) vive em
[`common:prompts:cc-update-doctrine`](../common/prompts/cc-update-doctrine.md). **Referencie, não copie.**

**Por que existe:** a rodada r8 do radar E3 (2026-10-08) foi feita à mão — delta por python avulso,
três ligações com o Onion reprovadas pelo juiz por falta de medição, duas dívidas de forma só vistas no
CI. Forjado pelo `/meta:forge` no mesmo dia; decisão e evidência em
`docs/evolution/research/forge-cc-update-2026-10/`.

## Degrau e limites

- **Core-only.** Maestro-invocado; o gatilho é o aviso de drift de versão (REGRA 65 (Radar de mundo
  com baseline DATADA por eixo) e o hook de drift da sessão).
- **Vai até o PR mergeado** (decisão do maestro, 2026-10-08), pelo caminho verificado.
- **Não implementa ações.** Cada ação proposta vira nó + issue (passo 8).

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`

!`bash .claude/validation/cc-delta-census.sh . --markdown 2>&1 || true`

> ⚠️ **As duas linhas acima são diretivas de injeção — bang seguido de crase —, e o harness executa
> TODA diretiva do arquivo**, inclusive uma escrita como exemplo. Por isso a forma literal não aparece
> em mais nenhum lugar daqui: é descrita, nunca escrita (lição paga pelo `/meta:forge-guard`). O
> `|| true` existe para que a carga do comando não morra quando o medidor sai rc 2: a mensagem dele
> (CHANGELOG inalcançável, baseline ilegível) chega no texto injetado, e isso **é** a medição.

Leia o veredito como ele se declara. O censo mede versões, o delta e o inventário das superfícies;
ele **não** diz que um item toca o Onion.

## Procedimento

1. **VEREDITO.** `NADA A MEDIR` → diga a versão medida e **pare**. Linha de erro do medidor (rc 2) →
   declare a lacuna e pare; nunca reconstrua o delta de memória. Aviso de processo ≠ disco → peça o
   restart antes de medir capacidade nova.
2. **ESQUELETO.** Rode o medidor de novo com `--write` apontando para o diretório da próxima rodada
   que ele mesmo imprimiu (derivado do `kg:` do eixo E3). Saem `data/<versão>.txt` (cópia byte a byte
   do CHANGELOG) e o `.kg.yaml` com 2 nós. Confirme: `.claude/validation/kg-radar.sh <grafo> --integrity --schema` e
   `.claude/validation/kg-contract-check.sh <grafo>`, os dois rc 0.
3. **RODADA.** Leia cada `data/<versão>.txt`. Para cada item que pareça tocar o Onion, **meça no vivo**
   (`grep` no core, leitura do hook, execução) e escreva o nó com a medição em `verified_against`.
   Sem medição → vai para NÃO-VERIFICADOS, não para o grafo (cláusula 3). Teto: 25 nós.
4. **JUIZ.** Lance um subagente **não-fork** (`subagent_type: general-purpose`, `model: opus`,
   `effort: high`) com mandato **REFUTAR**: conferir cada citação byte a byte contra o CHANGELOG
   oficial (URL no nó `E_DELTA_DA_RODADA`), medir cada ligação no vivo, julgar cada nó em
   SUSTENTA · EXAGERA · REPROVA e **listar o que a rodada deixou de ver**. Ele julga também a
   superação: `external_edges` SUPERSEDES (nomeando o nó superado) ou `x_supersedes_none` (com razão).
5. **APLICAR.** Reprovado → corrigido ou rebaixado (impacto 1); exagerado → reescrito; omissão de
   impacto alto → nó novo. Grave a decisão de superação: `external_edges` SUPERSEDES no topo (contrato
   v4.3; o gate confere o alvo) ou `meta.x_supersedes_none` com o prefixo `x_` — a forma sem prefixo
   reprova no contrato (cláusula 4) e a REGRA 89 (Rodada de radar selada reconcilia o corpus que
   superou (Aufhebung), com catraca) acusa a ausência. Re-rode radar exit 0 e
   kg-contract-check rc 0.
6. **SYNTHESIS.** `SYNTHESIS.md` ao lado do grafo, com o **contrato de custo** no frontmatter
   (`run_id` · `tokens` · `agents` · `duration_min`; sem run de Workflow, declare a ausência no
   `run_id`). Seções: o que mediu, o que toca a casa, juiz, NÃO-VERIFICADOS.
7. **SELAR** (cláusula 6, mesmo commit): em `docs/onion/radar-baselines.yaml`, no eixo E3,
   `last_run`, `cc_version`, `descartes` e `kg` apontando para o grafo novo.
8. **AÇÕES → NÓ + ISSUE** (cláusula 5). Cada ação proposta é nó `question` aberto (`Q_*`) e uma issue
   no Linear, projeto "Onion — core: próximas levas", time do `LINEAR_TEAM_ID` (lido por `env-check.sh --get`). Provider pelo helper
   (`bash .claude/utils/task-manager/env-check.sh --provider` e `--check linear`), nunca abrindo o
   `.env`; a criação segue `.claude/utils/task-manager/adapters/linear.md`. **Declare:** o adapter
   executável ainda é prosa (SAC-65). Provider diferente de `linear` ou chave ausente → avise em pt-BR,
   sugira `/meta:setup-integration` e deixe só o nó.
9. **FECHAR.** Regenere as projeções (o plugin onion não se regenera mais no core desde a F4 das
   portas: ele nasce na publicação, `/meta:publish onion-plugins`); `bash ops/pr-finalize.sh --push`; PR com corpo em pt-BR; merge **só** por
   `ops/pr-merge-verified.sh`, com a dispensa nomeada quando o revisor do CI estiver sem crédito.
10. **RELATAR.** Versão medida (baseline → instalada), quantos nós, o veredito do juiz, as issues
    criadas, o PR e o merge.

## Destino (peça 5)

O grafo da rodada em `docs/evolution/research/radar-E3-<data>-r<N>/`, com **radar exit 0** e
kg-contract-check rc 0 antes de qualquer prosa, a SYNTHESIS com o contrato de custo, e a baseline do
E3 selada no mesmo commit. Lente que carrega ao tocar esse diretório: `.claude/rules/research-lens.md`
(peça 6, já existente — nenhuma regra nova sem medir, REGRA 53 (Regra path-scoped declara `paths:`
que casa algo real)).

## Peça 4 (orquestração faseada) — AUSENTE por desenho, declarado

A rodada tem **um** juiz serial: medir, escrever, julgar, aplicar. Não há fan-out com independência
real, então um `.claude/workflows/*.js` seria coordenação sem nada a coordenar. A ausência é escolha
e fica escrita para que o censo marcando `—` na coluna 4 seja lido como **declarado**, não como dívida.
**Gatilho nomeado:** um delta grande o bastante para pedir juízes paralelos por versão (a r8 teve 6
versões e ~490 linhas com um juiz só) — aí a peça 4 nasce do caso medido.

## O que este comando NÃO faz

- Não decide se um item toca o Onion por palavra-chave; isso é da rodada, com o juiz.
- Não implementa a ação proposta, não muda hook, guarda ou regra.
- Não trata a doc oficial como fonte do delta: ela pode atrasar o CHANGELOG (r8: `onFailure`).
- Não roda offline: sem o CHANGELOG oficial, o medidor declara a lacuna e o comando para.

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:cc-update-doctrine`](../common/prompts/cc-update-doctrine.md)
- Medidor (peça 3): `.claude/validation/cc-delta-census.sh` · bancada (peça 7):
  `run_cc_delta_census_selftests`
- Lente (peça 6): `.claude/rules/research-lens.md`
- Molde: rodadas r7 e r8 do radar E3 e o [`/meta:radar`](radar.md)
