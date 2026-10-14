---
title: "Passo B — escritor único das projeções pós-merge: Fase 0 executada, B1 gated depois do dogfood"
date: 2026-10-14
kg: docs/evolution/research/postmerge-projection-writer-2026-10/postmerge-projection-writer-2026-10.kg.yaml
run_id: wf_e26bb266-4aa (decision) + wf_6babcd2c-1d8 (primaries)
tokens: 6813879
agents: 124
duration_min: 29.5
genre: decision
mode: decision
review_after: 2026-11-13
---

# Passo B — escritor único das projeções pós-merge

> **Projeção** do grafo `postmerge-projection-writer-2026-10.kg.yaml` (103 nós: 93 escritos pelas duas
> rodadas, mais 10 do empacotamento, do dogfood e do selo delegado; radar `--integrity --schema` exit 0, `kg-contract-check.sh` rc 0).
> Se esta prosa divergir do grafo, vale o grafo.
> Pergunta: `Q_POSTMERGE_PROJECTION_WRITER_2026_10`, que é o Passo B de `D_MERGE_PROCESS_ONION_2026_10`.
> Em vez de cada PR commitar as projeções geradas, um escritor único as regenera no main depois do
> merge. Vale a pena? E como fazer?

## 1. A decisão e as fases

**`D_POSTMERGE_PROJECTION_WRITER_2026_10` foi selada pelo maestro em 2026-10-14** por pergunta com
opções no `/meta:decide`, gravada pelo `kg-decide-seal.sh` com rc 0. A escolha foi **«Fase 0 já + ler
primárias antes do B1»**. Foram descartadas «Selar Fase 0 + B1 agora», «Só a Fase 0» e «Não mexer».

| Fase | O quê | Estado |
|---|---|---|
| **0** | A cura contrarian C (`C_OPCAO_C_CONTRARIAN_STRICT_LOCAL`): o caminho verificado exige que a base do PR seja a ponta do main (strict local) e regenera as projeções na árvore combinada. O merge-sem-CI do #1081 fica condicionado a isso. | **EXECUTADA** no PR #1101, mergeado (`E_FASE0_STRICT_LOCAL_EXECUTADA_PR_1101`) |
| **primárias** | Ler as docs de rulesets, bypass e status checks e as fontes contrarian antes de selar o B1 | **FEITA** em `wf_6babcd2c-1d8`: 8 fontes lidas e 24 claims ancoradas (`E_LACUNAS_PRIMARIES_POSTMERGE_WRITER_2026_10_14`) |
| **1 (B1)** | Escritor único sem bypass (`C_OPCAO_B1_SINGLE_WRITER_NO_BYPASS`): um job regenera, confere com `porcelain`, dispara os checks por `workflow_dispatch` e faz fast-forward do SHA verde no main | **GATED** (`D_B1_GATED_VARIANTE_CHECKRUN_REGISTRADA`, selo delegado). O dogfood refutou o desenho e mediu uma variante viável, ver §5 |
| reserva | B2, um PR rolante único com token de App | segue reserva. O dogfood mediu que um PR aberto pelo `GITHUB_TOKEN` exige aprovação humana a cada run |
| rejeitadas | B3 (App com bypass `always`), B4 (PAT do maestro no CI), U (não versionar) | Elenxo: rejeitar |

**O que a Fase 0 mediu** no #1101. A bancada passou 93/93 e depois 94/94, com 9 casos novos (s1–s8 e
s7b). O s5 reproduz o incidente 478/479. Os 6 mutantes reprovaram. Nos 50 últimos merges, **5
estavam atrás do main e 3 desses esperariam o CI** do head novo, a ~15–25 min cada. Esse é o preço da
cura no ritmo. O próprio PR declara o que não mediu: nenhum merge real e nenhum compare ao vivo.

## 2. O mercado — e a ressalva

`E_MERCADO_POSTMERGE_WRITER_2026_10`: **não há sinal de capital.** Não apareceu rodada, M&A nem
analista sobre arquivos gerados e escritor pós-merge. O GitLab (issue 26290, só uma proposta, que se
admite vaga) trata a composição do gerado como **recurso de fila**, o merge train. A prática real de
bot é a do release-please, do Renovate e do changesets: o bot **abre PR**, não empurra no main.

> ⚠️ **O padrão do mercado é o OPOSTO do B1.** Templ, Trezor, OpenTitan, CPython e o gettext
> (política "sempre commitar") mantêm o gerado **commitado no PR**, com uma catraca de sincronia por PR.
> O resto do mercado resolve vendendo uma fila nativa (org/Enterprise), que o core, de dono User, não
> tem. **A justificativa do Passo B não vem do mercado. Vem de medição no core:** 149 dos últimos 300
> commits do main são de projeção (`E_MEDICAO_RULESET_E_PROJECOES_2026_10_14`); o ruleset 25001643
> usa `strict=false`, então a catraca por PR, que é a REGRA 62 (Projeção GERADA em sincronia com a
> fonte), passou PR a PR e a combinação reprovou mesmo assim (478 contra 479); e a cadência é de 60
> PRs em 2,4 dias. O mercado serve de **evidência a favor da Fase 0** (contrarian) e de **precedente de
> direção** para o B1, não de prova de que o B1 é viável.

## 3. As objeções que sobreviveram

O Elenxo de `wf_e26bb266-4aa` julgou 52 objeções e 34 ficaram de pé, todas modeladas como
`E_OBJECAO_*`. O de `wf_6babcd2c-1d8` julgou 17 e 13 ficaram de pé. **7 objeções do tipo "fonte não
lida" passaram a `superseded`** com as leituras, e nada foi apagado. As que restringem o B1:

- **O main continua versionando** (`E_OBJECAO_MAIN_MUST_KEEP_VERSIONING`). Gerar o índice custa
  7.722 ms, contra 8 ms para consultá-lo. Portas e adotantes não têm o gerador. A opção U morre aqui.
  O gettext confirma o custo do regime "nunca commitar" (`E_GETTEXT_NEVER_COMMIT_NEEDS_TOOLS`).
- **O SHA verde por fast-forward é a afirmação-chave**, e ela segue sem primária que a decida
  (`E_OBJECAO_GREEN_SHA_FAST_FORWARD_IS_KEY`). A doc que fala em "push direto depois dos checks" é da
  branch protection **clássica**, não de ruleset (`E_PROTECTED_BRANCH_PUSH_DIRECT_AFTER_CHECKS`).
- **O GH013 é a condição de contorno** (`E_OBJECAO_GH013_IS_BOUNDARY_CONDITION`): o SHA tem de
  carregar os checks antes do fast-forward.
- **O bypass é tudo ou nada** e vale por ator, não por caminho (`E_OBJECAO_BYPASS_ALL_OR_NOTHING`,
  `E_OBJECAO_APP_BYPASS_BREAKS_INVARIANT`). Por isso o B3 é rejeitado por invariante, não por
  impossibilidade (`E_OBJECAO_APP_TOKEN_PUSH_PATTERN_DOCUMENTED`).
- **O admin só tem bypass via PR** (`E_OBJECAO_ADMIN_BYPASS_ONLY_IN_PR`). O escritor não pode herdar
  esse papel, e o B4 é rejeitado (`E_OBJECAO_MAESTRO_PAT_LOSES_AUDIT`).
- **A defasagem que importa é a da branch** (`E_OBJECAO_HOOK_STALENESS_IS_THE_BRANCH`). O hook lê a
  árvore local, então o B1 exige regeneração local preguiçosa, com cache pelo hash dos `.kg.yaml`.
- **Um PR de regeneração por merge dobra a fila** (`E_OBJECAO_REGEN_PR_PER_MERGE_DOUBLES_QUEUE`). O
  B2 só vale como PR rolante coalescido.
- **A catraca pós-regeneração** é a do OpenTitan, `check-generated` com `porcelain`
  (`E_OBJECAO_OPENTITAN_GATE_IS_POST_REGEN_DESIGN`, `E_OPENTITAN_PORCELAIN_NOT_DIFF`).
- **Ficaram de pé por falta de leitura:** `E_OBJECAO_BOT_AS_BYPASS_ACTOR_UNREAD`, tenki, edenai, opam
  e tessl.

## 4. As perguntas `Q_B1_*`

| Nó | Estado | O que pergunta |
|---|---|---|
| `Q_B1_GREEN_SHA_FF_NEEDS_DOGFOOD` | **selada** em 2026-10-14: «Dogfood num repo descartável» (descartadas «Só Fase 0, B1 gated» e «Selar B1 e provar no dogfood do próprio core»). **Respondida** pelo dogfood (§5) | Um SHA verde por `workflow_dispatch` entra por fast-forward com `GITHUB_TOKEN`? E um SHA sem checks é **recusado**? |
| `Q_B1_RULESET_BYPASS_ACTORS_NOT_EMPTY` | **superseded** por `E_DOGFOOD_B1_WRITER_CHECKRUN_FF_ACCEPTED_NO_BYPASS` (T6: bypass = 0) | `bypass_actors` não está vazio (admin, `pull_request`). "Sem bypass" vale para o escritor, não para o ruleset |
| `Q_B1_NON_FF_RACE_REDISPATCH` | **superseded** por `E_DOGFOOD_B1_NON_FF_RACE_CONVERGES_WITH_CAP` (T5) | Se o main anda entre a regeneração e o push, é preciso novo SHA e novo disparo. Qual o custo e a convergência da retentativa? |
| `Q_B1_SILENCES_MAIN_ON_PUSH_WORKFLOWS` | **superseded** por `E_DOGFOOD_B1_ON_PUSH_SILENCED_AND_CURED` (T4: confirmada, e a cura foi testada) | O push com `GITHUB_TOKEN` silencia **todo** workflow `on:push` do main. Quem fica mudo? |

As perguntas respondidas viraram `superseded` por aresta `SUPERSEDES`. Nada foi apagado.

**Primeiro o dogfood ficou bloqueado** (`E_DOGFOOD_B1_BLOQUEADO_PRIVADO_E_GUARDA_DE_MAIN`, mantido
como histórico). Um ruleset em repo **privado** na conta Free devolve HTTP 403, *"Upgrade to GitHub
Pro or make this repository public"*. E a guarda `pretooluse-merge-gate.sh` veta a escrita no main de
**qualquer** repo, porque casa pelo nome e não pelo repositório. O desbloqueio foi tornar o sandbox
**público** e usar como branch padrão a `trunk`. O ruleset vale para `~DEFAULT_BRANCH`, então o teste
é equivalente, e a guarda não foi desligada. A pergunta **`Q_GUARDA_DE_MAIN_CASA_PELO_NOME`** segue
open: casar pelo nome é intencional, porque protege também o main de adotante e o I3? Ou a guarda
deveria isentar um sandbox descartável do próprio maestro?

## 5. O dogfood do B1 (T1–T6) e a decisão delegada

Foi medido no sandbox público com o ruleset 25048413, uma cópia do 25001643. Os runs e as rule-suites
estão nos nós `E_DOGFOOD_B1_*`.

| T | Esperado | Observado | Nó |
|---|---|---|---|
| T1 | Push direto do admin sem checks: recusado | **Recusado** (GH013, rule-suite 4511883675) | `E_DOGFOOD_B1_NOCHECKS_REJECTED` |
| T2, prova por `workflow_dispatch` (o B1 como desenhado) | SHA verde entra por fast-forward | **Recusado**, com os 2 checks `completed:success` (app 15368). Recusado também para o admin, e um SHA verde só por dispatch foi recusado 2× | `E_DOGFOOD_B1_DISPATCH_CHECKS_DO_NOT_SATISFY_RULESET` |
| T2, check run publicado pelo escritor | — | **Aceito**, rc 0, fast-forward pelo `github-actions[bot]` (run 38506709399) | `E_DOGFOOD_B1_WRITER_CHECKRUN_FF_ACCEPTED_NO_BYPASS` |
| T2, PR aberto pelo `GITHUB_TOKEN` | — | Os runs nascem `action_required` e só ficam verdes depois da aprovação do admin. **Não é autônomo** | `E_DOGFOOD_B1_PR_BY_GITHUB_TOKEN_NEEDS_APPROVAL` |
| T3 | SHA sem checks: recusado | **Recusado** para o bot (rule-suite 4512026189) | `E_DOGFOOD_B1_NOCHECKS_REJECTED` |
| T4 | O push do escritor não dispara `on:push`, e a cura dispara | **0 runs** `on:push`. A cura por `workflow_dispatch` e por `repository_dispatch` rodou no SHA certo | `E_DOGFOOD_B1_ON_PUSH_SILENCED_AND_CURED` |
| T5 | A corrida de não-fast-forward converge | 2 intrusos: **3 ciclos**. 3 intrusos com teto 2: **gave-up**, ou seja, o teto para | `E_DOGFOOD_B1_NON_FF_RACE_CONVERGES_WITH_CAP` |
| T6 | Sem bypass | `rule_suite_result=bypass` → **0** | `E_DOGFOOD_B1_WRITER_CHECKRUN_FF_ACCEPTED_NO_BYPASS` |

**A leitura.** O B1 **como foi desenhado está refutado**: check run que nasce de `workflow_dispatch`
não satisfaz o ruleset, e a causa não foi explicada. A variante viável é o escritor rodar a bancada e
o lint no próprio job e publicar os check runs por `POST /check-runs`. Ela tem dois custos:

- **a garantia enfraquece**: passa a ser "um job do Actions publicou sucesso com esse nome";
- **cada ciclo da corrida paga a prova inteira**: no core, a bancada de ~14,8 min.

**Decisão: `D_B1_GATED_VARIANTE_CHECKRUN_REGISTRADA`**, um selo **delegado**. O maestro autorizou, no
período noturno de 2026-10-14, selar pelo `/meta:decide` escolhendo a recomendação. O histórico está
em `docs/evolution/decisions-delegated-2026-10-14.md`. A escolha foi **«B1 gated, variante check run
registrada»**. Foram descartadas «Executar a variante check run já» e «Testar antes a variante do check
run publicado pelo próprio workflow selftest despachado».

- **Por que gated:** a Fase 0 já cura a causa do 478/479.
- **Gatilho:** depois da Fase 0, o main quebrar por combinação de merges **OU** os commits de projeção
  seguirem acima de 25% do main em 2 semanas, medido.

## 6. NÃO-VERIFICADOS

- **Por que** o check run de `workflow_dispatch` não satisfaz o ruleset. Medido com 2 atores em 2
  momentos, mas sem explicação, nem primária, nem diagnóstico.
- A variante em que o próprio workflow `selftest` despachado publica um check run extra: não foi
  testada, e foi descartada no selo.
- O inventário dos workflows `on:push` do main do core que ficariam mudos: não foi feito.
- O custo real da variante check run **no core**: o sandbox usou checks de `echo`, não a bancada.
- Em conta User, se Integration, `github-actions[bot]` e DeployKey podem ser bypass actor. Só o admin
  foi medido, e o T6 mostra apenas que o escritor não precisou de bypass.
- A equivalência entre o compare do GitHub e o `merge-base` no #1101. A bancada usou remoto bare e um
  `gh` falso, sem merge real.
- Eixos sem claim: Bazel, Nx e Turborepo "generated files", `linguist-generated` e o leitor em
  runtime de índice defasado.
- Fontes cortadas por orçamento na 1ª rodada: 22 fontes e 25 claims. Ficaram de pé como objeção
  tenki, edenai, opam e tessl.
- Os títulos de quatro REGRAS de projeção citadas pelo Elenxo não foram verificados nas rodadas, e
  por isso esta síntese não as cita.

## 7. Valeu a pena?

| Run | Modo | Agentes | Tokens | Duração |
|---|---|---|---|---|
| `wf_e26bb266-4aa` | decision | 105 | 5.687.579 | ~20,5 min |
| `wf_6babcd2c-1d8` | primaries | 19 | 1.126.300 | ~9 min |
| **total** | | **124** | **6.813.879** | **~29,5 min** |

- **Tokens ÷ nós: 6.813.879 ÷ 93 nós escritos pelas rodadas ≈ 73.300 tokens por nó.** Contando os 103
  nós do grafo, são ≈ 66.200. Os 10 a mais vêm do empacotamento, do dogfood e dos selos. Eles são
  escrita determinística, fora do contrato de custo dos workflows, e o custo do subagente do sandbox
  não está somado.
- **Por rodada** (o teto do `meta:` registra 64 nós da 1ª e +29 da 2ª):
  - decision: 5.687.579 ÷ 64 ≈ **88.900** tokens por nó;
  - primaries: 1.126.300 ÷ 29 ≈ **38.800** tokens por nó, porque ler fontes já nomeadas custa menos
    da metade de descobri-las.
- **Sim, valeu.** A 1ª rodada achou a cura barata, a Fase 0, que já está no main, e mediu que ela
  custa 10% de rebases a mais. A 2ª rodada fechou 5 lacunas e, sobretudo, **recusou selar o B1 sobre
  fórum**: a pergunta central não tinha primária. O dogfood que ela exigiu **refutou** o desenho
  (check de `workflow_dispatch` não conta). Selar o B1 na 1ª rodada teria posto em produção um
  escritor que nunca entraria no main.
