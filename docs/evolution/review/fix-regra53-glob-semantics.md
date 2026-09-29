---
title: 'A guarda media com a régua do git onde o harness usa outra, e eu curei um de dois ramos'
date: 2026-09-29
branch: fix/regra53-glob-semantics
reviewed_diff_sha256: 6876eacf9099b532a30e3caef58a9cf6af4d72f47b21d5ec2580e4fc5a6427ac
elenxo: nao
findings_total: 3
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e o motivo é declarado: as duas divergências foram MEDIDAS contra o binário (lentes-sonda + o log instructions-loaded.jsonl) antes de qualquer cura, e cada cura tem fixture nas DUAS pontas com o caso que a derruba. Quem me reprovou aqui foi a BANCADA, não leitura — ela achou que eu havia curado só um dos dois ramos do helper. Refutador mediria o mesmo que as fixtures já medem.'
---

# Resíduo — `:(glob)`, braces, e o ramo que a bancada mede

## As duas divergências, medidas contra o binário

Sondas em `.claude/rules/` + o log `.claude/sessions/instructions-loaded.jsonl` (que registra
`path_glob_match` com o arquivo que disparou):

| forma | harness | `git ls-files` nu (o que a guarda usava) | efeito |
|---|---|---|---|
| `*` nu | **não cruza `/`** | **cruza** — `docs/*.md` → 1074 hits, **1072 profundos** | **lente morta ABSOLVIDA** (fail-open) |
| `{a,b}` | **expande** | **0 hits**, nem com magic | **lente viva ACUSADA** (falso positivo HARD) |

## As curas

- **`*`**: o pathspec passa a ser `:(glob)<g>` — o git **já tem** a semântica certa embutida. Medido:
  `docs/*.md` cai de 1074 para **2 hits, zero profundos**; `**` segue cruzando nos dois. Sem
  dependência nova, sem lista de casos.
- **braces**: expansão de **um nível** antes de consultar o git, casando por **qualquer** alternativa —
  que é o que o harness faz. Braces aninhadas ou com `/` dentro ficam **de fora, de propósito**:
  inflar o casamento trocaria um falso positivo por um fail-open, que é o pior dos dois.

**Prova do fail-open na forma exata:** `.claude/validation/fixtures/*.md` tinha **83 hits** pelo
pathspec nu (a guarda absolvia) e **0** com `:(glob)` — e 0 é o que o harness veria. O helper curado
**acusa**.

## O achado que só a bancada podia dar: eu curei UM de DOIS ramos

`_rule_glob_matches` tem ramo **git** e ramo **NÃO-GIT**. A sandbox de fixtures é montada com `tar`
(sem `.git`), então **a única cobertura ponta-a-ponta que existe exercita o ramo não-git** — exatamente
o que eu não tinha tocado. As três fixtures novas reprovaram, e não por estarem erradas: elas mediram
o caminho certo.

É `testar-no-caminho-errado-e-nao-testar` **invertida** — eu curei o caminho que eu **media** (o git, no
repo real, onde provei 83 → 0) e deixei intacto o que a bancada mede. Se eu tivesse só lido o código,
commitaria meia cura com três fixtures novas dando a impressão de prova.

O ramo não-git recebeu as mesmas duas semânticas: `-maxdepth 1` quando o glob não tem `**` (o `*` fica
num nível, como o harness) e a mesma expansão de braces antes do `find`. O comentário no código diz
**por que** esse ramo existe e **que é ele** que a bancada vê — para o próximo que cure metade não
repetir.

## As fixtures, nas duas pontas

`bad-star-only-deep` (o fail-open exato) · `good-brace-live` (viva com braces tem de passar) ·
`bad-brace-dead` (braces cujas alternativas nenhuma casa tem de ACUSAR — é o mutante da minha própria
expansão). A REGRA 53 vai de 8 para **11 fixtures**.

## Gates

- `lint-selftest.sh --families fixtures` → **102 ✓ / 0 ✗**, com as 11 da REGRA 53 verdes
- `lint-artifacts.sh` → 0 HARD (a confirmar no SHA final)
- `/meta:realign` → ALINHADO nos grafos, `--check` rc=0

## Declarado aberto

- **Braces aninhadas ou com `/` dentro** seguem pelo caminho literal, nos dois ramos. Não é
  esquecimento: é a fronteira que impede a expansão de virar fail-open. GATILHO: a primeira lente
  legítima que use uma dessas formas e seja reprovada.
- **A paridade entre os dois ramos não tem guarda.** Hoje ela existe porque eu escrevi as duas
  semânticas nos dois lugares; nada impede que a próxima cura toque um só — foi literalmente o que
  aconteceu nesta leva. GATILHO: a próxima divergência de semântica entre git e harness, ou a
  primeira vez que uma fixture passe no repo e falhe na sandbox (ou o inverso).
