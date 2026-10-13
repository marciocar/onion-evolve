---
title: "Processo de PR, CI e merge do core — A → C → D → B, selado; o ímã é o gargalo que nenhuma fila cura"
date: 2026-10-13
kg: docs/evolution/research/merge-process-onion-2026-10/merge-process-onion-2026-10.kg.yaml
run_id: wf_48596b33-657
tokens: 7308993
agents: 105
duration_min: 22.4
genre: decision
mode: decision
review_after: 2026-11-12
---

# Processo de PR, CI e merge do core

> **Projeção** do grafo (64 nós escritos pelo run + 1 nó de selo, radar `--integrity --schema` exit 0).
> Divergiu, o grafo ganha. Decisão **`D_MERGE_PROCESS_ONION_2026_10`** e
> **`D_REQUIRED_CHECKS_RULESET_MAIN`**, ambas **seladas pelo maestro em 2026-10-13** por pergunta com
> opções (`kg-decide-seal.sh`, rc 0).

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 7.308.993 (medido pela ferramenta) |
| Subagentes disparados pelo run | 105 |
| Parede | 22,4 min |
| Votação | 21 claims confirmadas, 4 refutadas |
| Elenxo | 46 objeções julgadas, 27 sobreviventes, 27 modeladas como `E_OBJECAO_*` |

## O que se mediu no core (tier 10)

`E_MEDICAO_PROCESSO_ATUAL_2026_10_13`: 60 PRs em 2,4 dias, mediana de 33 min da abertura ao merge;
**`docs/onion/testing-state.md` em 59 de 60 PRs**; bancada com mediana de 14,8 min e 2 execuções por PR;
14 ou mais auto-rebases invisíveis. O repo é público, de dono **User**, sem proteção de branch, com
merge por rebase linear e PRs paralelos de agentes numa sessão só.

## O que o mercado oferece, e por que não serve agora

- **Fila nativa do GitHub**: só em repo público de **organização** (`gated-features/merge-queue.md`,
  github/docs). O core é de usuário. E a fila teve o incidente de 23/04/2026 (reversão silenciosa em
  grupos com mais de 1 PR, 3h33 sem detecção), com um relatório que se contradiz sobre o rebase.
- **Mergify Open Source / Trunk Free**: grátis no papel. A instalação em conta pessoal não foi
  verificada, e o App mergeia fora do caminho que o hook exit-2 vigia.
- **bors-ng**: arquivado em 04/04/2024. **Graphite**: o próprio guia diz que time pequeno não precisa
  de fila. **funador/claude-code-merge-queue**: fila FIFO local numa máquina, com lock durante a suíte
  inteira (menos de 20 landings/h com suíte de 3 a 4 min).
- **Merge driver de `.gitattributes`**: só roda em conflito não trivial e só no merge local. O servidor
  do GitHub não executa driver custom (conhecimento prévio, não medido nesta rodada).

**Achado central do Elenxo:** o gargalo é o **arquivo-ímã**, e nenhuma fila o resolve, porque a fila
tira o PR em conflito (`E_OBJECAO_ANY_QUEUE_BLOCKED_BY_MAGNET`).

## Selos (2026-10-13)

| Nó | Escolhida | Descartadas |
|---|---|---|
| `D_MERGE_PROCESS_ONION_2026_10` | **A → C → D → B, em ordem** | Só A e C agora · A, C e B; D fica · Pesquisar antes |
| `D_REQUIRED_CHECKS_RULESET_MAIN` (novo, liga em `C_OPCAO_E_REQUIRED_CHECKS_RULESET`) | **Sim, sem histórico linear** | Não, fica só o veto local |

Ordem selada:
1. **A, curar o ímã.** Executado no mesmo PR deste grafo (ver abaixo).
2. **C, `merge-serial` em `ops/`.** O helper sai do scratchpad, o lock vale só no rebase e no merge, e
   cada auto-rebase deixa rastro no PR.
3. **D, bancada em dois níveis sem fila.** No PR rodam as famílias tocadas (+ `ci:full`), e a bancada
   completa roda no push ao main, com alarme e PR de revert.
4. **B, projeção regenerada depois do merge.** Tem Elenxo próprio, porque mexe nas catracas HARD das
   REGRAS 39, 62, 80, 81 e 84.
- **E**: ruleset de required checks **sem** "require linear history", porque essa regra barraria o
  `--merge-commit` do SAC-80. Ligar o ruleset é ato do maestro no GitHub.
- **F e G ficam GATED** (fila de terceiro; transferir o repo para uma organização). **H, I, J e K
  foram rejeitadas.**

## Passo A executado (este PR)

O `testing-state.md` versionado deixa de carregar os contadores que todo PR muda. As seções 1 e 4
(resíduos da REGRA 56, asserções, famílias, regras) imprimem a célula `↻ ao vivo` com o comando ao
lado, e o número sai na hora em `bash .claude/validation/testing-state.sh --live`. A REGRA 81 segue
byte a byte contra `--markdown`: versionar o `--live`, ou digitar um número numa célula `↻`, reprova,
e agora com o motivo nomeado. Simulação de dois PRs paralelos que acrescentam um resíduo cada um:

| | PRs que tocam o painel | Rebase do 2º sobre main + 1º |
|---|---|---|
| antes (origin/main) | 2 de 2 | **CONFLITO** em `docs/onion/testing-state.md` |
| depois | 0 de 2 | limpo, com o painel em sincronia |

As outras projeções (`testing-inventory.md`, `backlog.md`, `kg-read-index.tsv`…) **não foram tocadas**:
isso é o passo B.

## NÃO-VERIFICADOS (declarado)

- **Refutadas na votação (4)**: (1) rulesets em repo público Free sem plano mínimo, refutada **por
  comodismo**; a metade verdadeira virou `E_OBJECAO_RULESETS_FREE_HALF_DISCARDED` e sustenta o selo E.
  (2) 40,2% dos repos com pares de agentes co-ativos (arXiv 2607.04697, não transfere). (3) "trunk-based
  exige build completo antes do push", também refutada por comodismo; virou
  `E_OBJECAO_CONTRARIAN_DISCARD_HID_REASON`. (4) conflito de 41,7% contra 19,8%, contradito pelo perfil
  local de projeções.
- **Não coberto**: a disponibilidade atual da fila nativa para dono User na doc primária vigente;
  Mergify, Graphite, **Aviator** (nenhuma claim confirmada) e Trunk em repo de usuário com rebase
  linear; se o merge do servidor respeita o driver do `.gitattributes`, inclusive o `merge=union` já
  declarado para `.claude/session-lifecycle.jsonl`; a aquisição da Graphite em 2025 (prior não
  verificado).
- **Cortado por orçamento**: 30 fontes e 32 claims, entre elas strict × loose (eixo central, que virou
  objeção), CI em dois níveis sem fila (evgunter/cad#1887, hivecommons/hive#10884, bernstein#5793) e
  geração no merge (lingo.dev, oneuptime, tessl).
- **Falta fonte externa** sobre o escritor único depois do merge, e é ela que gateia o passo B.
- **Integridade da entrada**: a recomendação chegou truncada ao escritor ("quase tod"). O texto inteiro
  foi recuperado do journal do run e está na narrative de `D_MERGE_PROCESS_ONION_2026_10`.

## valeu-a-pena

7.308.993 tokens ÷ 64 nós ≈ **114k por nó**. Fica abaixo da varredura comparável de 2026-09-13 (≈291k
por nó) e acima do modo `primaries` (≈42k). O que se comprou:
- a **re-hierarquização do problema**: ímã antes de fila, sustentada por evidência do próprio forge;
- o **descarte fundamentado** de cinco ferramentas;
- duas metades verdadeiras resgatadas de refutações por comodismo, uma das quais virou o selo E.

Sem a rodada, o próximo passo provável seria procurar uma fila, que não resolveria o gargalo medido.
Reabertura barata: o selo E e os gatilhos de F e G são medições de `gh api`, não outra rodada.
