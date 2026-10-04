---
reviewed_diff_sha256: 0facf1914a19a2576ed4d4529b3a1bdf76424ce45e20cf95150677f7b959e64a
findings_total: 14
findings_real: 14
tokens: 184628
duration_min: 17
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO: 184.628 tokens, 88
  chamadas, ~17 min. Placar dele: 3 aprovados (itens 1, 3, 4), 4 REPROVADOS (2, 5, 6, 7), 2
  não-verificados, 14 achados — 5 de 1ª classe e 2 fora da minha lista. Ele rodou os artefatos,
  refez os 4 mutantes com harness PRÓPRIO (confirmando que mordem) e acrescentou 2 que eu não tinha.
  Os achados de conteúdo (R2 cron, R3 "32 dias", R8 citação) foram RE-VERIFICADOS por mim na fonte
  antes de aceitar — veredito de subagente é hipótese. Os 14 estão curados nesta branch, com 8 casos
  de bancada e 8 mutantes mordendo; a única coisa que NÃO virou código é o R11 (guarda da classe),
  registrada como 4º candidato com defeito datado e passivo medido em ZERO, aguardando selo do
  maestro — eu não cunho REGRA numerada sozinho.
---

# Resíduo — `fix/medidores-que-cortam-em-silencio`

## A ironia é estrutural, e é o achado mais importante

Um PR cujo tema é *"medidor que corta em silêncio produz afirmação falsa"* entregou **um aviso que
declarava um corte falso**, **um nó que afirmava uma proibição falsa**, e **o corte silencioso intacto
exatamente onde o dano acontece**. O gate mecânico esteve **verde (0 HARD) nas duas rodadas** — e
nenhum dos cinco achados graves é detectável por lint. É precisamente o caso que o PR se propunha a
tratar.

## Placar e os cinco de 1ª classe

| # | Achado | Gravidade | Estado |
|---|---|---|---|
| **R1** | O `forge-census` tem **dois** cortes (o `head`, e rastreado-ausente-do-disco). Curei um e o aviso novo **mentia** sobre o outro — provado movendo um candidato do disco com `TOP=100000`: *"CORTADA: 58 de 59"* sem corte algum. E a rota de reparo era falsa: `--tsv` sofre o mesmo pulo | 🔴 | **curado** — compara contra `_rows_total` (o medido), e o descarte ganhou rótulo e lista próprios |
| **R2** | O nó `open` de maior atenção proibia cron citando MOAT W7 — **re-afirmando o não-sequitur** que o Elenxo citado pelo nó vizinho derrubou por medição, para excluir o candidato que aquela refutação chamou de *"resposta proporcional"* | 🔴 | **curado** — re-medi: zero menções a cron em `evolve.md`, **duas** entradas MOAT no registry (ambas de deploy). O (d) está na mesa |
| **R3** | *"32 dias sem rodar"* são **65** (07-30 → 10-03). O 32 era de 2026-08-31 | 🔴 | **curado** nos dois lugares |
| **R4+R5** | A lição foi para a migalha e **não** para `forge.md:28` (12 de 59) nem `onion-research/SKILL.md:23` (40 de 298). E minha cura **piorou** o segundo: um zero falso e **barulhento** virou um quarenta **quieto** e igualmente falso | 🔴 | **curado** — `forge.md` serve 59/59; o `kg-corpus-grep` ganhou `--top N` que **declara**, e a skill usa isso em vez de `head` |
| **R6** | A busca-frase morreu sem escotilha: `'o maestro'` passou de **396** nós precisos a **4114** | 🔴 | **curado** — `--phrase` restaurou os 396, e o aviso agora diz que separar **AMPLIA** |
| R7 | O aviso em stderr quebrava `--json` sob `2>&1` | 🟠 | **curado** — e a 1ª tentativa falhou: testar `JSON` no parse amarra à **ordem dos flags**. Buffer + emissor decide |
| R8 | Citação vestida de verbatim que não era: *"do eixo E2"* → *"no eixo da auto-evolução"*, *"loop"* → *"laço"* — substituição de conteúdo **dentro das aspas** | 🟠 | **curado** — verbatim, com o gloss fora |
| R9 | `FORGE_CENSUS_TOP=abc` → tabela vazia e **rc=0** | 🟡 | **curado** — recusa com rc=3 |
| R10 | A extração do `_tot` estava fora de `if` sob `set -euo pipefail`: **matava a suíte** em vez de reprovar o caso | 🟡 | **curado** |
| R11 | A **classe** segue sem guarda | 🟠 | **registrada** como 4º candidato (passivo = **zero**), gated no selo |
| R13 | Frase órfã na edição da migalha | 🟡 | **curada** |
| R14 | O caso (c) não cobrava o que importa (o zero virar achado) | 🟡 | **curado** — asserção `1 nó(s)` |

## Bancada: 8 casos, 8 mutantes

`run_silent_measurer_selftests` — (a) corte declarado · (b) **contraprova** (completa não avisa) ·
(c) frase separada **e o zero virou achado** · (d) zero explicado · (e) `--phrase` restringe e
separado amplia · (f) `--json` válido nas **duas ordens de flag** · (g) `--top` declara, cala e
recusa inválido · (h) ausente-do-disco com rótulo próprio.

M1–M8 mordem **exatamente** o seu caso, e os artefatos voltam **byte-idênticos** por `cmp` depois
de cada um.

## Dois defeitos meus no próprio conserto, porque são classe

1. **O caso (h) nasceu com `git archive HEAD`** — testaria o `forge-census` **commitado**, não o
   curado. Peguei antes de aplicar. A separação certa: a **população** vem do HEAD (é dado), o **SUT**
   vem da árvore viva.
2. **A cura do R7 falhou na 1ª tentativa por ordem de flag** — `'frase' --json` tem `JSON=0` na
   linha do parse. Decidir no parse amarra o comportamento à ordem; quem decide é o emissor, depois
   de todos os flags lidos.

## Teto declarado

Os dois nós sobre o harness de mutantes (`C_TERCEIRA_CAUSA_DE_MUTANTE_QUE_NAO_MORDE` e
`E_REPLACE_PRIMEIRO_ACERTOU_O_COMENTARIO`) descrevem um script que **não viaja no repo** — o Elenxo
os marcou **NÃO-VERIFICADOS** com razão. A lição é real (o harness dele, independente, ancorou no
prefixo justamente por isso), mas enquanto o molde de harness não for versionado, ela se sustenta em
declaração minha sobre código descartado. Fica nomeado em vez de resolvido.
