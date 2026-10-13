---
title: 'Resíduo — o alarme do main culpa só a primeira quebra: mesmas famílias só comentam, família nova nomeia suspeito'
date: 2026-10-13
branch: fix/main-bench-alarm-blames-first-break
reviewed_diff_sha256: 1c90340b6bb95c70c354c9eb5c85859838e09bb3dbca590c88c926df6031f1e0
reviewed_code_sha256: fda7b51b1f084c0869db7f74c8eb3e4980e5eba6b46e14e2174aaae5cea94416
findings_total: 9
findings_real: 8
findings_fixed: 5
tokens: 0
duration_min: 150
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Defeito medido em 2026-10-13: a bancada completa reprovou em ff5abe51 (merge do #1081), e o alarme
  abriu a issue #1086 e o revert #1085, o que estava certo. O commit seguinte, 825e93f6 (só projeções
  regeneradas, do #1084), herdou a quebra, e o alarme abriu um 2º revert (#1087) contra ele, que é
  inocente. A causa era o docs/backlog.md fora de sincronia (REGRA 62 (Projeção GERADA em sincronia com
  a fonte (docs/backlog.md))), consertado para a frente no #1088. Cura em ops/testing/main-bench-alarm.sh:
  a assinatura da quebra é o conjunto de famílias com falha, lido dos relatórios TSV das faixas. O job
  alarme-main baixa os artefatos e passa --reports-dir e --expect-reports. Com a issue aberta, as mesmas
  famílias só comentam; família nova nomeia suspeito e prepara o revert dele. A issue ou a assinatura
  ilegível leva à declaração, sem revert. No verde, a issue fecha e depois os reverts superados fecham.
  Família two_tier_bench: 22 casos verdes sob LC_ALL=C e 18 mutantes, todos reprovando. Na passada
  adversarial, 9 achados: 8 reais (5 curados, 3 declarados como teto) e 1 refutado.
---

# Resíduo — REGRA 56

## O que mudou

- `ops/testing/main-bench-alarm.sh`:
  - a **assinatura** da quebra é o conjunto de famílias com `fail>0`, somado dos `selftest-report.tsv` das faixas;
  - cada post da issue leva um **marcador** `<!-- onion-alarm v1 mode= result= sha= families= revert= -->`;
  - os **modos** são `first`, `same`, `new`, `older`, `illegible`, `unreadable-sig` e `not-failure`;
  - no verde, o alarme fecha os reverts superados;
  - ele carimba o verde numa issue fechada à mão;
  - ele funde duas issues concorrentes na de número menor.
- `.github/workflows/onion-selftest.yml`, job `alarme-main`:
  - ganhou o passo `actions/download-artifact@v4`, com o padrão `selftest-evidence-<run_id>-faixa*` e `continue-on-error`;
  - passa `--reports-dir` e `--expect-reports` (número de faixas do plano).
- `.claude/validation/lint-selftest.sh`, família `two_tier_bench`:
  - o `gh` falso passa a devolver JSON cru, e o filtro é do script;
  - casos novos (j1)–(j7), (j2b), (j2c) e (i4); os casos (i), (i2) e (i3) foram refeitos;
  - o (h) passa a exigir o download e as flags.
- Grafo `merge-process-onion-2026-10.kg.yaml`: nó `E_ALARME_CULPA_SO_A_PRIMEIRA_QUEBRA_2026_10_13`. O teto foi de 73 para 74, com o motivo declarado no `meta`.
- Doutrina `onion-drive-doctrine.md` §0: a regra nova.

## A regra (critério declarado)

| Situação | Ação |
|---|---|
| vermelho sem issue aberta (nem fechada à mão) | issue + revert, como antes |
| issue aberta, famílias ⊆ conhecidas | **só comenta**, sem revert |
| issue aberta, família fora das conhecidas | comenta, **suspeito novo**, **prepara revert** |
| idem, mas o commit é merge/commit de revert | comenta e nomeia, **sem** revert do revert |
| mesmas famílias, commit ANCESTRAL do culpado registrado | culpado mais velho, revert dele |
| issue ilegível (gh falha, sem marcador, ou já declarada ilegível) | declara, sem revert |
| assinatura atual ilegível (faixa sem relatório, sem TOTAL, nenhuma família reprovada) | declara, sem revert |
| verde | fecha a issue e **depois** os PRs `revert/<12 hex>` de autor `app/github-actions` com sha12 citado na issue |

**Conhecidas** são a união das famílias dos marcadores das reprovações (`result=failure`) da issue.

**Por que preparar o revert em vez de só nomear:**
- preparar é reversível e nunca mergeia;
- quando a 1ª quebra sair, a 2ª continua, e o revert dela já está pronto;
- medido no dia, o PR abre sozinho (`can_approve_pull_request_reviews: true`, #1085 e #1087 com autor `app/github-actions`), então o custo é zero de mão humana.

O preço declarado é que o CI desse revert fica vermelho enquanto a 1ª quebra não sair. O corpo do PR diz isso.

## Casos (família two_tier_bench, LC_ALL=C) — 22 de 22

Os casos (a) a (h) já existiam e seguem verdes. Os do alarme são estes:

| Caso | O que prova |
|---|---|
| (i) | 1º vermelho ⇒ issue com marcador `families=alfa`, revert que desfaz o merge, PR recusado declarado |
| (i2) | alarme aberto + `cancelled` ⇒ comenta, sem revert |
| (j1) | 2º vermelho com as mesmas famílias ⇒ só comentário, sem revert (o caso do #1087) |
| (j2) | família nova ⇒ suspeito nomeado, revert preparado |
| (j2b) | família nova em commit de revert ⇒ nomeia, sem revert |
| (j2c) | marcador forjado por terceiro não conta |
| (j3) | commit ancestral do culpado, mesmas famílias ⇒ culpado mais velho, revert dele |
| (j4) | issue ilegível em três formas ⇒ declara, sem revert |
| (j5) | faixa sem relatório ⇒ assinatura ilegível, sem revert |
| (j6) | issue fechada à mão ⇒ a nova herda as famílias, sem revert |
| (j7) | dois 1ºs vermelhos concorrentes ⇒ a maior vira comentário na menor e fecha |
| (i3) | verde ⇒ fecha a issue, depois só os PRs 11 e 12. Ficam abertos: o de autor humano, o de branch fora do formato e o de sha não citado. Sem alarme, não escreve nada |
| (i4) | verde depois de fechada à mão ⇒ carimba uma vez |

## Mutantes (ops/mutate-and-restore.sh, 2026-10-13) — 18 de 18 reprovados

| # | Mutante | Caso(s) que reprovou |
|---|---|---|
| M1 | `same` também prepara revert | (j1) (j6) |
| M2 | família nova não é detectada | (j2) (j2b) |
| M3 | issue sem marcador vira 1º vermelho | (j4) |
| M4 | ilegível deixa de ser pegajoso | (j4) |
| M5 | exceção do revert do revert removida | (j2b) (j4) |
| M6 | ordem por ancestral desligada | (j3) |
| M7 | `--expect-reports` ignorado | (j5) |
| M8 | issue fechada à mão ignorada | (j6) |
| M9 | filtro de autor dos PRs removido | (i3) |
| M10 | filtro de sha citado removido | (i3) |
| M11 | `fullmatch` → `match` na branch | (i3) |
| M12 | o verde não fecha os reverts | (i3) |
| M13 | o verde não carimba a fechada à mão | (i4) |
| M14 | a fusão de concorrentes desligada | (j7) |
| M15 | 1º alarme sem famílias no marcador | (i) |
| M16 | o workflow não passa os relatórios | (h) |
| M17 | família com `fail=0` conta como reprovada | (i) (j1) (j2) (j2b) (j3) (j6) |
| M18 | marcador de comentário humano passa a contar | (j2c) |

## Passada adversarial (refutador com o default reprovado)

1. **E se a issue foi fechada à mão?** (real, curado) Na 1ª versão, o vermelho seguinte virava 1º vermelho e revertia um commit possivelmente inocente. Agora a última fechada de título fixo sem marcador de verde vale como referência, e a nova issue herda os marcadores dela (j6). No verde seguinte, ela é carimbada uma vez para não envenenar o próximo 1º vermelho (i4).
   - **Teto declarado:** a fechada à mão **sem marcador** (versão anterior) é ignorada como referência. A referência é a de maior número (a criada por último), não a fechada por último.
2. **E se dois pushes rodam ao mesmo tempo?** O grupo do push é por sha, sem cancelamento. Três sub-achados:
   - (a) **1ºs vermelhos concorrentes** abriam duas issues (real, curado): a de número maior vira comentário na menor e fecha com `mode=dup` (j7). **Teto:** os dois reverts ficam preparados, e o do inocente só fecha no verde.
   - (b) **o mais velho termina depois** e era tratado como herdeiro (real, curado): com as mesmas famílias, um commit ancestral do culpado registrado vira o culpado (j3). **Teto:** o revert do mais novo fica aberto até o verde, e se o culpado registrado não está no `origin/main` buscado, a ordem não é medida (declarado no comentário).
   - (c) dois vermelhos com a issue aberta só comentam, e sem lock não há corrida destrutiva (refutado como defeito).
3. **E se o 1º revert foi mergeado e o main continua vermelho?** (real, curado) Com a versão anterior, o merge do revert viraria culpado novo e o alarme prepararia o revert do revert. Agora:
   - commit de revert com as mesmas famílias ⇒ comentário dizendo que a culpa está **refutada ou incompleta**, e que o conserto é para a frente;
   - com família nova ⇒ só nomeia (j2b);
   - o reconhecimento é pelo assunto: `Merge pull request #N from …/revert/…`, `Revert "…"` ou `revert: …`, que cobrem o merge commit, o rebase e o squash.
4. **Marcador forjado** (real, curado): o repo é público e qualquer conta comenta. Um `families=<tudo>` colado por terceiro calaria todo revert. Agora só contam posts com autor `app/github-actions` ou `github-actions`, lidos do forge (j2c e M18). A autoria foi medida na #1086.
5. **Granularidade família** (real, declarado): uma 2ª quebra **na mesma família** de uma já conhecida passa como herdada. Comparar caso é pior, porque o rótulo do caso carrega sha e caminho que mudam sem a quebra mudar. Fica como teto.
6. **Família instável** (real, declarado): uma flaky que falha num vermelho seguinte vira "suspeito novo" e gera um revert preparado. Ele é ruído, não dano: nada é mergeado, e o verde fecha o PR.
7. **Ilegível é pegajoso** (real, declarado): com a #1086, aberta pela versão anterior sem marcador, todo vermelho até o verde só comenta e não reverte. É o lado seguro: sem comparação não há revert às cegas.
8. **Download de artefato em re-run** (não verificado): não medi o que o `download-artifact@v4` devolve num run com tentativas repetidas. Se vierem relatórios a mais, a contagem diverge do `--expect-reports` e a assinatura fica ilegível. O resultado é declaração, nunca revert errado.
9. **O `#1081` passou pelo caminho sem CI?** (lacuna, não medido) Seria o gatilho de `Q_MERGE_LOTE_COM_BISSECCAO`. O nó aponta com `TRACES_TO` e diz que não conferi.

## Validação

- `LC_ALL=C bash .claude/validation/lint-selftest.sh --families two_tier_bench` ⇒ 22 passaram, 0 falharam.
- 18 mutantes por `ops/mutate-and-restore.sh`, 18 reprovados.
- `kg-radar.sh <grafo> --integrity --schema` ⇒ exit 0 (74 nós, 101 arestas).
- `kg-contract-check.sh` ⇒ rc 0.
- A bancada completa é do CI: o PR toca `ops/testing/*` e o workflow, então o próprio seletor manda a completa.
- **Não toquei** nos PRs #1085 e #1087 nem na issue #1086: são da sessão principal.
