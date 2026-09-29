---
title: 'A forja nasceu sobre uma lacuna que eu inventei, e duas passadas adversariais a consertaram'
date: 2026-09-29
branch: feat/forge-pecas-2-3-7
reviewed_diff_sha256: 053b31a541e1de795ae98fa7c45201b845fbf5013d39860578dc3248ec23fd73
elenxo: sim
findings_total: 32
findings_real: 32
verdict: REPROVADO_E_CURADO
tokens: 475221
duration_min: 62
agents: 2
nota: 'DUAS passadas adversariais, ambas REPROVANDO, ambas opus em worktree ISOLADA. 1ª: 16 achados (6 BLOQUEIA). 2ª: 16 achados (4 BLOQUEIA), medindo se as curas pegaram — e ela mediu a BANCADA VERMELHA (1507✓/6✗), que nenhuma leitura pegaria. Todas as 10 bloqueantes curadas e re-medidas; bancada final 1513✓/0✗. A pior de todas foi minha e mudou uma decisão do maestro: eu afirmei que a lente estava desguardada SEM MEDIR, ele decidiu criar uma REGRA sobre isso, e a REGRA 53 já cobria o predicado, HARD, desde 2026-08-03.'
---

# Resíduo — a forja, as peças 2+3+7

## O que entrou

Execução da decisão `D_FORGE_META_COMANDO` (selada 2026-09-28, escopo 2+3+7, core-only):

| peça | artefato |
|---|---|
| **2** doutrina reutilizável | `.claude/commands/common/prompts/forge-doctrine.md` — 7 peças, 4 cláusulas, o que ela NÃO promete |
| **3** contexto medido injetado | `.claude/validation/forge-census.sh` — o medidor, fail-closed sem índice git |
| **7** bancada | `run_forge_selftests`, 9 casos |
| 1 superfície (veículo) | `.claude/commands/meta/forge.md` |
| — | 2 predicados fundidos na REGRA 53 · fixture `bad-empty-body.md` · `forge` nas exceções do `role-cut: (k)` |

## A pior: eu inventei uma lacuna, e o maestro decidiu sobre ela

Três artefatos meus afirmavam *"nada cobrava a lente"*. **A REGRA 53 (Regra path-scoped declara
`paths:` que casa algo real) cobria os três predicados de `paths:` desde 2026-08-03, é HARD, e tem 4
fixtures.** Eu a citei nesta mesma sessão, em outro contexto, e ainda assim afirmei a lacuna.

A regra que nasceu daí era **duplicata SOFT de uma HARD**, sem o fallback de sufixo que a 53 aprendeu
no PR #827, sem isenção por papel, e as duas **discordavam** sobre o mesmo arquivo: a 53 absolve quando
*um* glob casa, a minha exigia *todos*.

**A consequência que não é técnica:** o maestro decidiu *"REGRA nova junto da forja"* sobre premissa
minha errada. Foi informado, a duplicata morreu, e dos dois predicados genuinamente novos:
- **corpo não-vazio** → fundido na 53, com fixture nova;
- **lente rastreada** → TENTADO e RETIRADO: reprovou as cinco fixtures da própria 53, porque o harness
  injeta a fixture como untracked e o predicado curto-circuitava o que estava sob teste. Curar exigiria
  código de produção ciente de teste. Gap declarado no código, com gatilho.

A lição virou **cláusula 3 da doutrina**, não nota de conversa: *antes de emitir uma guarda, medir se
ela já existe* — `grep -n 'REGRA' lint-artifacts.sh` custa um segundo.

## Os defeitos que as curas introduziram (e é o padrão da leva)

| # | defeito que eu introduzi curando | como apareceu |
|---|---|---|
| 1 | o predicado de rastreamento curto-circuitava 5 fixtures da REGRA 53 | bancada, não leitura |
| 2 | `role-cut: (k)` vermelha — `forge-census.sh` cita `/meta:forge` e o comando não estava nas exceções | bancada, na 1ª corrida após o comando nascer |
| 3 | **reincidência da corrida EPIPE** em `_any_tracked` — a MESMA classe que eu curei horas antes noutro script | 2ª passada, medindo rc=141 |
| 4 | a doutrina afirmou o que meu medidor refutava — **a duas linhas da correção do mesmo achado** | 2ª passada |
| 5 | `--markdown` guardava o total e **não** o "N com 6+", que é o número que a doutrina cita | mutante da 2ª passada (punha 99 e passava verde) |
| 6 | contradição `forge.md` × doutrina: promessa de "conjunto completo" com 3 de 7 peças geradas | 2ª passada |

## Os números, e por que os anteriores estavam errados

Dois predicados meus mediam mal, e os números publicados vieram deles:

- **peça 5 inflada (23 → 17 de 57)**: a âncora `.kg.yaml` solta contava ponteiro de backlog
  (`fios-abertos.kg.yaml` citado como fio) e prosa didática como se fossem destino;
- **peça 2 subdeclarada (1 → 4 de 57)**: o regex exigia caminho absoluto e a convenção deste repo é
  relativa — escondia três casos, **incluindo a doutrina da própria forja**. O `/meta:forge` não
  detectava a peça escrita para ele.

Medido em 2026-09-29, com os predicados corretos: **57 candidatos** · peça 2 em **4** · peça 3 em **1** ·
peça 4 em **2** · peça 5 em **17 (30%)** · peça 6 em **2** · peça 7 em **6** · **4** alcançam 4+ e
**1** alcança 6+. A decisão de escopo do maestro sobrevive e sai **mais forte**: as peças que faltam
não faltam em cinco candidatos, faltam em 53 a 56.

## O achado de produto do medidor, no primeiro uso

`onion-research` dava **5/7** por ter lente e bancada e **não citar nenhuma das duas** — quem lê a
superfície não as acharia. Citei; subiu a 7/7. É `fix → re-dogfood no mesmo loop`, e é o corolário da
cláusula 1: peça que o artefato não nomeia é peça que a sessão não acha.

⚠️ **Teto honesto, apontado pela 2ª passada:** o headline *"1 de 57 alcança 6+"* só é verdade por
causa dessa edição, feita na mesma leva.

## Gates

- `lint-artifacts.sh` → **0 HARD** / 16 SOFT (pré-existentes) · radar exit 0 no grafo
- `lint-selftest.sh --jobs auto` → **1513 ✓ / 0 ✗ / 0 abortos** (a 2ª passada mediu 1507✓/6✗ antes das curas)
- mutantes provados: (g) vermelho com o cabeçalho mentindo · (h) vermelho sem a varredura de
  `commands/meta/` · (a) nomeia a peça certa nos 6 predicados · (i) mata o fantasma 7/7
- ⚠️ **CI do repositório morto** desde 2026-09-26. ~~(cota de Actions)~~ **CAUSA CORRIGIDA em
  2026-09-29 — a atribuição original era HIPÓTESE MINHA NÃO MEDIDA**: o budget de Actions da conta tem
  `stop usage: No` e $50,19 de $65, logo não bloqueia (e sem "stop usage" o GitHub só notificaria). O
  `startup_failure` com ZERO jobs é **incidente de plataforma do GitHub**: relatos independentes de
  repositórios sem relação, publicados em 26–27/09/2026, com padrão idêntico (community #201113 e
  #208832). Consistente com o local: nenhuma mudança em `.github/workflows/` desde 25/09 16:06, os 5
  YAML parseiam sob loader ESTRITO (o `safe_load` anterior aceitava chave duplicada em silêncio),
  permissões `enabled`. A cobertura do merge não muda — era e segue o gate local. Merge pelo
  `--ci-inoperante`.

## Declarado aberto, com gatilho — NÃO silenciado

- **`git ls-files -- <glob>` ≠ picomatch**, que o harness usa para `paths:`. Contra-exemplos medidos
  pela 1ª passada: `*.kg.yaml` casa no git (o `*` cruza `/`) e não no picomatch → lente morta
  ABSOLVIDA; `docs/{a,b}/**` não casa no git → lente viva ACUSADA; `paths:` escalar ou flow-list são
  YAML válido e são acusados de "não declara paths:". Afeta a REGRA 53 (Regra path-scoped declara
  `paths:` que casa algo real), pré-existente, intocada por esta leva. GATILHO: a primeira lente
  legítima reprovada, ou a primeira morta absolvida em uso real.
- **rc de pathspec inválido vira `0`** em `_rule_glob_matches` (`|| _ls=""` engole 128) — a guarda
  ACUSA em vez de declarar que não sabe. Pré-existente. GATILHO: o mesmo da anterior.
- **A REGRA 53 não nomeia a própria regra nas mensagens**: `_rule_map_build` casa o docstring com a
  PRIMEIRA função definida depois dele, que é um helper, não `check_rules_pathscoped`. Pré-existente,
  mas esta leva **mudou a aposta** ao mover predicados novos para dentro dessa função. GATILHO: a
  próxima mensagem dela que chegar órfã ao operador.
- **Peça 3 segue forjável com uma linha digitada** (`**Hoje:` escrito à mão pontua). O predicado não
  sustenta a cláusula 1, e isso está declarado no docstring. GATILHO: o primeiro comando que pontue a
  peça 3 sem medidor de verdade.
- **`_any_tracked` é N+1 processos git** por caminho citado — 40 mil citações fazem o censo passar de
  600s. Sem consequência hoje; cura é `ls-files` em lote.
- **`head -12` esconde 45 de 57 candidatos** no markdown, sem dizer.
- **README de `common/prompts/` e de `commands/meta/` não listam os artefatos novos** — e não listam
  outros 17 pré-existentes. Sistêmico, fora desta leva.
