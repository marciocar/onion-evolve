---
title: 'Resíduo — o gate que eu criei negava defeito real, e a cura dele criou outro'
date: 2026-09-21
branch: feat/reviewer-findings-block
reviewed_diff_sha256: 5c18a5e39e303d7ee5e59e33379b975bbca41e83e054bf115ae4b742e8bec386
findings_total: 10
findings_real: 10
findings_fixed: 10
tokens: 11943079
duration_min: 18
verdict: REPROVADO_DUAS_VEZES_E_CURADO
elenxo: sim
nota: >-
  Passada adversarial (opus, mandato de refutar, default REPROVADO) em duas rodadas. A 1ª achou 5,
  dois deles fail-open que faziam a máquina NEGAR violação real. A cura desses dois INTRODUZIU dois
  defeitos novos, e a 2ª rodada os pegou — um bloqueava merge com número fabricado. O refutador
  também violou a instrução "não modifique nenhum arquivo"; o mecanismo que substitui a instrução
  está neste PR.
---

# O gate nasceu negando o defeito que veio bloquear

O parecer do `onion-review` era **advisory**. Medido em 33 pareceres: 10 apontaram violação, e três
delas seguiam em `main` semanas depois — apontadas, mergeadas, esquecidas. A ~US$ 0,80 o PR, pagava-se
pela descoberta sem recolher a entrega.

Este PR faz o achado **bloquear**. E a história de como ele quase fez pior está toda aqui.

## Rodada 1 — 5 achados, dois piores que o problema original

| # | defeito | entrada |
|---|---|---|
| 1 | `conforme` casado por **prefixo** | `VEREDITO: conforme, exceto por 2 violações` → `achados=0` |
| 2 | `tail -1` lia a **evidência**, não o veredito | parecer citando o formato **se auto-anulava** → `0` |
| 3 | âncora case-sensitive e intolerante a markdown | tudo caía em `-1` |
| 4 | linha `✓ (GATE)` impressa **fora** da condição | afirmava provado o que acabara de medir falso |
| 5 | mutante do ramo `-1` trocava só a mensagem | rc=0 no original **e** no mutante |

Os dois primeiros são **piores que o estado advisory**: antes o defeito era ignorado; ali seria
**negado pela máquina**.

O #2 é o mais instrutivo. Justifiquei `tail -1` dizendo *"o contrato é sobre o FIM da resposta"* — mas
o formato que o próprio `onion-review.yml` contrata põe **as evidências DEPOIS** do veredito. A linha
é a **cabeça** do bloco. Li o contrato pela minha memória dele, não pelo arquivo.

## Rodada 2 — minha cura introduziu dois defeitos novos

| # | defeito | entrada |
|---|---|---|
| N1 | número vinha de **qualquer lugar** da linha | `VEREDITO: conforme (REGRA 36)` → **36**, e o gate reprovava anunciando "36 violações" |
| N2 | fence ``` remove a indentação, única defesa da âncora | parecer com 2 violações citando o formato → `-1`, deixava de bloquear |

O N1 é falso-positivo que **bloqueia com número fabricado** — pior que o fail-open que veio curar,
porque tem cara de diligência.

**Desenho final**, com a precedência que resolve todos de uma vez: **contagem → `conforme` → `-1`**.
O número só é contagem com `viola…` colado, com teto de 4 dígitos. Fences descartados, BOM removido,
âncora na coluna 0 tolerando `**`/`#`/`- ` mas **não** `>` (blockquote é citação do veredito de outro,
e aceitá-lo permitia sequestro). Âncoras que **discordam** ⇒ `-1`, porque escolher em silêncio entre
vereditos contraditórios é inventar um.

## O defeito que teria quebrado TODO PR

Ao mover a decisão para `review-verdict.sh`, criei a **primeira dependência de arquivo** num job que
nunca teve árvore. Sem `actions/checkout`: `bash <script>` → **127** → `exit 1` → **todo PR reprovado**,
com mensagem culpando o código revisado. Virou **REGRA 88 (Job de workflow que EXECUTA arquivo do repo
faz checkout)**, HARD **com catraca** — porque a regra viaja para adotantes, e HARD nu sobre dívida
alheia é como se ensina alguém a desligar um gate.

## A telemetria errou o campo três vezes

`achados=-1` não bloqueia, por desenho. O preço é morte silenciosa: fiação quebrada ⇒ todo PR em `-1`
⇒ check **verde**. `ops/review-gate-health.sh` é a catraca disso, e chegar nela custou três erros:

1. lia `mergeCommit` — os check-runs vivem no **head do PR**; devolveu 0 classificações;
2. lia `.output.title/summary` — o GitHub **não** popula esses campos a partir do `GITHUB_STEP_SUMMARY`:
   são estruturalmente vazios, e a telemetria **nasceria inerte, dentro do script feito para detectar
   inércia**;
3. lia `annotations` — `::warning::` de step não vira anotação de check-run.

E numa dessas versões ela leu 12 PRs, classificou **zero** e imprimiu ✅. O desenho que sobrevive não
depende de campo decorativo: cruza o **parecer** (o que o revisor disse) contra a **conclusão do check**
(o que o gate fez). Controle positivo em dado real: achou o **`#846 — INERT (parecer=1, check=success)`**.

## O refutador escreveu onde foi dito para não escrever

O briefing dizia *"não modifique NENHUM arquivo"*. Ele escreveu em **seis**, incluindo o script de
merge. O conteúdo era bom — achou a REGRA 88 — e foi isso que tornou o caso instrutivo: **instrução em
prosa não é fronteira**. Descobri por acidente, com três casos de bancada que eu não escrevi ficando
vermelhos. A cura é mecanismo: refutador roda em `isolation: 'worktree'`, onde continua podendo
escrever e provar, mas não alcança a árvore principal. Registrado na skill de orquestração.

## Limite declarado

Este PR edita o próprio `onion-review.yml`, e a action **se auto-pula** nesse caso — então **o gate não
é exercitado por este PR**. A prova aqui é a bancada (37 casos); a prova no vivo é o primeiro PR depois
do merge, e o sinal está automatizado: `bash ops/review-gate-health.sh`. Se aparecer `INERT` ou
sequência cega, a fiação morreu.
