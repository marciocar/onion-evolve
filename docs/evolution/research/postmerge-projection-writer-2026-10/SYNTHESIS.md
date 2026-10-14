---
title: "Passo B — escritor único das projeções pós-merge: Fase 0 já (executada), B1 só depois de dogfood"
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

> **Projeção** do grafo `postmerge-projection-writer-2026-10.kg.yaml` (96 nós: 93 escritos pelas duas
> rodadas, mais 3 do empacotamento; radar `--integrity --schema` exit 0, `kg-contract-check.sh` rc 0).
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
| **1 (B1)** | Escritor único sem bypass (`C_OPCAO_B1_SINGLE_WRITER_NO_BYPASS`): um job regenera, confere com `porcelain`, dispara os checks por `workflow_dispatch` e faz fast-forward do SHA verde no main | **NÃO selada.** A pergunta central foi para o dogfood, ver §4 |
| reserva | B2, um PR rolante único com token de App | só entra se o B1 falhar no dogfood |
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
| `Q_B1_GREEN_SHA_FF_NEEDS_DOGFOOD` | **selada** em 2026-10-14: «Dogfood num repo descartável» (descartadas «Só Fase 0, B1 gated» e «Selar B1 e provar no dogfood do próprio core») | Um SHA verde por `workflow_dispatch` entra por fast-forward com `GITHUB_TOKEN`? E um SHA sem checks é **recusado**? |
| `Q_B1_RULESET_BYPASS_ACTORS_NOT_EMPTY` | open | `bypass_actors` não está vazio (admin, `pull_request`). "Sem bypass" vale para o escritor, não para o ruleset |
| `Q_B1_NON_FF_RACE_REDISPATCH` | open | Se o main anda entre a regeneração e o push, é preciso novo SHA e novo disparo. Qual o custo e a convergência da retentativa? |
| `Q_B1_SILENCES_MAIN_ON_PUSH_WORKFLOWS` | open | O push com `GITHUB_TOKEN` silencia **todo** workflow `on:push` do main. Quem fica mudo? |

**O dogfood escolhido não rodou na sessão** (`E_DOGFOOD_B1_BLOQUEADO_PRIVADO_E_GUARDA_DE_MAIN`).
Houve dois bloqueios:

1. Um ruleset em repo **privado** na conta Free devolve HTTP 403, *"Upgrade to GitHub Pro or make
   this repository public"*.
2. A guarda `pretooluse-merge-gate.sh` veta a escrita no main de **qualquer** repo, porque casa pelo
   nome e não pelo repositório.

O seed e o T1 ficam com o maestro, fora da sessão, e o bloqueio abriu
**`Q_GUARDA_DE_MAIN_CASA_PELO_NOME`** (open). Esse casamento é intencional, porque protege também o
main de adotante e o I3? Ou a guarda deveria isentar um sandbox descartável do próprio maestro?

## 5. NÃO-VERIFICADOS

- **A pergunta central do B1**: o fast-forward de um SHA verde num ruleset só com
  `required_status_checks` (`strict=false`, integration 15368). Nenhuma primária a decide e o dogfood
  está bloqueado.
- Em conta User, se Integration, `github-actions[bot]` e DeployKey podem ser bypass actor. Só o admin
  foi medido.
- Se o bot pode ser bypass actor (as discussions 25305 e 43460 não decidem).
- A equivalência entre o compare do GitHub e o `merge-base` no #1101. A bancada usou remoto bare e um
  `gh` falso, sem merge real.
- O comportamento sob rajada de merges (convergência do escritor e janela de defasagem do hook).
- Eixos sem claim: Bazel, Nx e Turborepo "generated files", `linguist-generated` e o leitor em
  runtime de índice defasado.
- Fontes cortadas por orçamento na 1ª rodada: 22 fontes e 25 claims. Ficaram de pé como objeção
  tenki, edenai, opam e tessl.
- Os títulos de quatro REGRAS de projeção citadas pelo Elenxo não foram verificados nas rodadas, e
  por isso esta síntese não as cita.

## 6. Valeu a pena?

| Run | Modo | Agentes | Tokens | Duração |
|---|---|---|---|---|
| `wf_e26bb266-4aa` | decision | 105 | 5.687.579 | ~20,5 min |
| `wf_6babcd2c-1d8` | primaries | 19 | 1.126.300 | ~9 min |
| **total** | | **124** | **6.813.879** | **~29,5 min** |

- **Tokens ÷ nós: 6.813.879 ÷ 93 nós escritos pelas rodadas ≈ 73.300 tokens por nó.** Contando os 96
  nós do grafo, que incluem os 3 do empacotamento (escrita determinística e selos de 0 tokens de
  workflow), são ≈ 71.000.
- **Por rodada** (o teto do `meta:` registra 64 nós da 1ª e +29 da 2ª):
  - decision: 5.687.579 ÷ 64 ≈ **88.900** tokens por nó;
  - primaries: 1.126.300 ÷ 29 ≈ **38.800** tokens por nó, porque ler fontes já nomeadas custa menos
    da metade de descobri-las.
- **Sim, valeu.** A 1ª rodada achou a cura barata, a Fase 0, que já está no main, e mediu que ela
  custa 10% de rebases a mais. A 2ª rodada fechou 5 lacunas e trocou 7 objeções "fonte não lida" por
  leitura. E impediu um selo errado: a pergunta central do B1 **não** tem primária, e selar o B1 na
  1ª rodada teria sido selar sobre fórum. O custo que sobra é o dogfood, que é do maestro.
