---
title: "Mapa das guardas do Onion — agosto/2026"
date: 2026-08-03
status: baseline
tags: [guardas, lint, regras, mecanismo, anti-drift]
---

# Mapa das guardas do Onion — 2026-08-03

> **O que é:** o inventário consolidado de **tudo que guarda** este repo — as REGRAS numeradas do
> lint e as seis famílias que vivem fora dele. Serve de **baseline** para a próxima revisão: sem
> ele, cada rodada remapeia do zero e as conclusões morrem com a sessão.
>
> **Contagens medidas do filesystem em 2026-08-03**, não digitadas. Para re-medir, os comandos
> estão em cada seção.

---

## 1. Por que este mapa existe

As guardas do Onion **nasceram reativamente** — cada uma respondendo a um incidente de campo. Isso
é a doutrina funcionando ([`fix-must-become-mechanism`]), e produziu um conjunto que **pega coisas
reais**: só nesta sessão, a guarda anti-fail-open do shell interrompeu 5 erros de leitura-de-sinal-
derivado, e o lint reprovou uma edição manual num artefato gerado.

Mas o crescimento reativo cobrou um preço mensurável, e ele **não é o formato** — é **cobertura e
visibilidade**:

| Sintoma medido | Onde |
|---|---|
| Guarda **HARD ativa e invisível** no registro (header sem número) | `check_site_inventory_sync` → hoje REGRA 50 |
| Guarda **SOFT ativa e invisível** (sem número e sem `previne:`) | `check_branch_agent_distinction` → hoje REGRA 51 |
| Guarda que **ninguém executava por cadência** | `kg-radar.sh` → hoje REGRA 52 |
| Superfície **sem guarda nenhuma** | `.claude/rules/` → hoje REGRA 53 |
| Guarda que existe e **não cobre onde o drift aparece** | inventário: cobria `CLAUDE.md` e o site, **não** `docs/INDEX.md` nem a KB de identidade — e foram exatamente esses dois que driftaram (PR #517) |

**A régua deste mapa:** *uma guarda que ninguém vê e uma guarda que ninguém roda falham do mesmo jeito.*

---

## 2. As REGRAS numeradas — 53

```bash
grep -cE '^# REGRA [0-9]+ —' .claude/validation/lint-artifacts.sh     # 53
bash .claude/validation/rules-registry.sh                             # gera lint-rules.md
```

**SSOT navegável:** [`.claude/validation/lint-rules.md`](../../.claude/validation/lint-rules.md) —
documento **gerado** por `rules-registry.sh` a partir dos docstrings. Nunca editado à mão; a
REGRA 39 mantém a paridade.

| Severidade | Regras |
|---|---:|
| `[HARD]` | 42 |
| `[SOFT]` | 6 |
| `[HARD + SOFT]` | 5 |

Numeração **sem lacunas e sem duplicatas** (1–53). A ordem física no arquivo **não** é numérica —
as regras estão agrupadas por afinidade temática.

### 2.1 As 5 catracas de clareza do gerador

O `rules-registry.sh` falha com **exit 2** — regra nova não entra muda:

1. número de REGRA **duplicado**
2. regra **sem categoria** no array `CATEGORIES`
3. regra sem **`# previne:`** (o modo-de-falha)
4. regra com **severidade que não resolve** (`—`)  ·  *nasceu 2026-08-03*
5. regra **sem o tag `[SEV]`** no header  ·  *nasceu 2026-08-03*

> As duas últimas nasceram de uma pergunta do maestro — *"então a tag `[SEV]` não é cosmético?"*.
> **Não era.** Medição: as REGRAS 43 e 44 têm **zero** `violation "HARD"` literal no corpo (delegam a
> script externo com `violation "${sev}"`), então para elas o tag é a **única** fonte de severidade;
> já as 7 regras que não declaravam tag (1,2,3,5,12,13,14) têm 1–4 literais, e por isso passavam.
> Havia uma regra implícita — *"quem delega precisa do tag"* — valendo por **disciplina**. Agora é
> mecânica. Os 7 tags foram preenchidos com o que o corpo **realmente emitia**, e o registro gerado
> ficou **byte-a-byte idêntico**: prova de que foi padronização, não mudança de contrato.

### 2.2 Limite conhecido da derivação de severidade

O parser associa a cada regra o **primeiro** `nome() {` após o header. Em regras cujo header
antecede um *helper*, ou que **delegam** a script externo, a severidade vem do tag, não do corpo.
Medido em 2026-08-03: **as duas fontes concordam em todas as 53**; nenhuma sai indefinida.
Sem dano observado → `gated-until-trigger`: corrigiu-se a **promessa** do cabeçalho, não o parser.

---

## 3. As 6 famílias fora das regras numeradas

```bash
find .claude/rules   -name '*.md' | wc -l     # 1
find .claude/hooks   -name '*.sh' | wc -l     # 6
find .claude/validation -maxdepth 1 -name '*.sh' | wc -l   # 37
```

| Família | Onde | Aciona em | Bloqueia? |
|---|---|---|---|
| **Regras path-scoped** | `.claude/rules/` (1) | contexto do modelo, por glob `paths:` | não — **cognitiva** |
| **Hooks do harness** | `.claude/hooks/` (6) | eventos do Claude Code | 1 de 6 (`exit 2`) |
| **Git hook** | `.githooks/pre-commit` | `git commit` | sim — opt-in, contornável com `--no-verify` |
| **Helpers do lint** | `.claude/validation/*.sh` delegados por REGRA | lint local + CI | sim |
| **Scripts soltos** | `.claude/validation/*.sh` sem REGRA | **manual apenas** | não |
| **CI** | `.github/workflows/` | PR | `onion-validate` sim · `onion-review` não |

### 3.1 A fronteira cognitiva × mecânica

`.claude/rules/` e as REGRAS **não são redundantes — são camadas**:

| | `.claude/rules/` | REGRAS do lint |
|---|---|---|
| Natureza | muda o que o modelo **sabe** | muda o que o repo **aceita** |
| Momento | **antes** de escrever | **depois** de escrever |
| Escopo | glob de arquivo | repo inteiro, toda vez |
| Alcance | o indecidível por script (gramática, semântica) | o decidível por script |
| Falha | não falha — orienta | HARD bloqueia merge |

**A tensão, declarada:** instrução que depende do julgamento do ator é o eixo que o corpus desta
casa já mediu falhando ([`posttooluse-exit-2-is-the-only-channel`],
[`shell-guard-paid-four-times-same-axis`]). Como **ponte para um mecanismo** — que é como
`kg-grammar.md` está escrita, terminando em `kg-radar.sh → exit 0 obrigatório` — funciona. Como
guarda autônoma, o próprio corpus prevê que não. Foi por isso que a REGRA 52 **promoveu** essa
convocação a mecânica, sem remover a rule.

### 3.2 Guarda com o maior alcance fora de cadência

O `kg-radar.sh` era o caso extremo até 2026-08-03 (fechado pela REGRA 52). **Seguem manuais:**
`pin-integrity-check.sh --audit-vendor` · `trust-topology-check.sh` · `federation-radar.sh` · os 3
scripts de métrica (`context-freshness-metric`, `cycle-completion`, `session-velocity`).

---

## 4. Sobreposições — por desenho vs. acidente

O repo tem a **disciplina de declarar** sobreposição no docstring (a R33 se diz "irmã da R30 com
threat model DIFERENTE"; a R31 cita "mesma classe das REGRAS 8/21/24"). As famílias:

| Família | Regras | Natureza |
|---|---|---|
| **Catracas de proveniência/frescor** | 26 → 29 → 42 → 43 → 49 → **52** | por desenho; mesma mecânica de baseline, threat models distintos |
| **SSOT gerada × superfície derivada** | 8, 19, 21, 24, 25, 31, 34, 38, 39 | mesma mecânica "regenera p/ temp e compara" |
| **Contagem hardcoded × SSOT** | 9, 16, **50** | particionadas por arquivo |
| **Projeção & privacidade** | 30, 33, 36 (+ 35, 45 p/ link morto) | por desenho, fronteiras declaradas |
| **Links quebrados** | 22, 45, 48 | recortes complementares |
| **Dialeto de tool** | 12, 13, 14 | mesmos tokens, três superfícies |
| **Frontmatter obrigatório** | 1, 2, 23 | candidatas declaradas a fusão |
| **Outbox ↔ members** | 28, 46 | as duas pontas do mesmo par |

**Sobreposição nova, declarada em 2026-08-03:** REGRA 52 × REGRA 43. A R43 já roda
`kg-radar --integrity` nos grafos citados em `kg:` — **18 dos 51**. A R52 é superset: o ganho real
são os **33 grafos** que ninguém cita. Um grafo citado é checado duas vezes; custo aceito, porque a
R43 morre com a migalha que a invoca e a R52 não depende de ninguém citar nada.

---

## 5. Estado das catracas — a métrica de saúde é o número DIMINUINDO

```bash
for b in kg-coverage doctrine-freshness kb-vendored-link kg-verification; do
  printf '%s: %s\n' "$b" "$(grep -vcE '^[[:space:]]*(#|$)' .claude/validation/${b}-baseline.txt)"
done
```

| Baseline | Entradas hoje | Leitura |
|---|---:|---|
| `kg-coverage` (R29) | **0** | passivo liquidado |
| `doctrine-freshness` (R42) | **0** | passivo liquidado |
| `kb-vendored-link` (R45) | **0** | **nasceu com 101** — a catraca pagou até o piso |
| `kg-verification` (R49) | **53** | **o único passivo vivo** — só cai rodando `/meta:kg-freshness` |
| `automation-ladder-registry` (R44) | 15 | registro de classes, não passivo |

> ⚠️ **Docstrings envelhecem junto:** o da R45 ainda diz "nasce com 101 links". Está correto como
> **história**, e é enganoso como **estado**. Ver §6.

---

## 6. Cobertura de teste

```bash
grep -vcE '^#|^$|^kind' .claude/validation/fixtures/manifest.tsv    # 57 fixtures
ONION_SELFTEST_STRICT=1 bash .claude/validation/lint-selftest.sh    # 542 asserções
```

O `lint-selftest.sh` roda **542 asserções**; no CI com `ONION_SELFTEST_STRICT=1`, um **skip por
tooling ausente** vira falha (asserção de capacidade — runner sem `jq` passaria em verde sem
validar nada).

**Limite honesto:** o STRICT **não** verifica se toda REGRA tem fixture. Não existe hoje um gate
"regra sem teste". Das 53, o `manifest.tsv` cobre um subconjunto — as demais são exercidas por modos
dedicados do selftest ou não são exercidas.

---

## 7. Backlog MEDIDO — o que a revisão adversarial de 2026-08-03 achou e não fechou

Três revisores percorreram as 53 regras (22 + 15 + 16). O que segue **não é opinião** — cada item
tem número medido e caminho verificável. Ordenado por valor.

### 7.1 Cobertura falsa: a REGRA 45 é 1/9 do que precisa ser

A R45 (link vendorizado → caminho core-privado) varre **só** `docs/knowledge-base`. As outras **8
raízes vendorizadas** têm o mesmo modo de falha, sem guarda:

> **46 links markdown VIVOS para caminho core-privado, em 21 arquivos vendorizados** fora de
> `docs/knowledge-base` — ex.: `.claude/skills/onion/SKILL.md`, `.claude/commands/meta/adopt.md`,
> `.claude/agents/meta/onion.md` → `../../../docs/analysis/…`, `…/docs/applying/rescue-prompt.md`.
> **Todos 404 em qualquer adotante.** Ninguém cobre: a R22 não varre `.claude/`; a R48 só pega
> backtick; a R45 só pega KB.

O ponto duro: **a R45 drenou 101 links da KB e deixou 46 da mesma classe na porta ao lado — e o
baseline em 0 declara vitória.** É `declarado ≠ verificado` na métrica de saúde de uma guarda.

### 7.2 A REGRA 43 tem um `kg:` pendurado vivo e invisível

A R43 varre só `.claude/diary` + `docs/analysis` + `docs/evolution/research`. **9 arquivos declaram
`kg:` fora desse escopo**, e um deles aponta para um grafo inexistente:

```
docs/evolution/inbox/_processed/2026-07-27-sinal-plane-vs-procedencia-e-evaporacao.md:9
kg: docs/onion/graph/promocao-main-elenxo.kg.yaml     ← NÃO EXISTE
```

É exatamente o `MISSING-PATH` HARD que a R43 existe para emitir — vivo, e ninguém vê. A R52 também
não pega: ela itera sobre grafos que existem, não sobre citações.

### 7.3 Double-firing: R28 classe (1) × R46

As duas detectam a **mesma** condição ("diretório de outbox que não resolve a nenhum id"). Um dir
órfão com 3 anúncios emitiria **4 violações SOFT para um fato só**. **Não fundir** — os modos de
falha têm donos e curas diferentes. O corte: **amputar a classe (1) da R28** (~10 linhas), deixando
a R46 dona (é estritamente mais geral: conta recursivamente, inclui `_processed/`). Bônus: o título
da R28 — "membro SEM canal de recepção" — passa a ser verdadeiro, o que hoje não é.

### 7.4 Quatro clones byte-idênticos

REGRAS **21, 38, 24, 25**: corpos idênticos após normalizar literais (18 linhas cada, diferindo em
~5 strings). A cadeia de "Espelha X" nos docstrings é a assinatura do copy-paste documentado.
Helper `_check_generated_artifact_sync` economizaria **~69 linhas (73%)** e — mais importante —
daria **um** lugar para consertar o `2>/dev/null` que hoje engole erro de gerador em 5 sítios.
**Fora do helper:** R19, R31, R34 — cada uma tem um segundo modo de falha próprio (`tree_sha`,
`--assert-parity`, exit-code) que o helper não modela. *(A premissa de "9 regras iguais" era falsa.)*

### 7.5 Docstrings que envelheceram para `declarado ≠ verificado`

| Regra | Diz | Realidade medida |
|---|---|---|
| R45 (`:1814`) | *"Nasce com 101 links de passivo"* | baseline com **0** — drenado em `165e1e1` |
| R44 (`:1791`) | *"Nasce silencioso (tudo em HUMAN hoje)"* | **15 classes**: 6 HUMAN, 6 STRUCTURAL, 1 MONITORED, 2 MOAT |
| R29 (`:1617`) | cita `docs/evolution/inbox/2026-07-20-…md` | o arquivo está em `_processed/` |

### 7.6 Fronteiras declaradas só numa direção

Levantamento das referências cruzadas: **a fronteira é sempre declarada na regra NOVA, nunca
retro-anotada na velha.** A R30 é o hub de privacidade (33 e 36 derivam dela, do mesmo
`projection-safety.sh`) e **não menciona nenhuma**. Quem chega com um caso novo lendo a R30 não
descobre que existem 33 e 36.

### 7.7 Menores, com caminho

- **R36 engole adotantes namespaced**: o filtro `^onion-` (criado para `onion-mini`/`onion-standalone`)
  também isenta `onion-pedro`/`onion-arthur`, que são adotantes reais. E `lint-selftest.sh:5988`
  carrega o **primeiro nome** de um adotante em superfície vendorizada — as duas superfícies irmãs já
  foram higienizadas, esta escapou.
- **R44 miscategorizada** em "KG & proveniência" (`rules-registry.sh`) — é escada de automação, não KG.
  É também a única regra sem a linha `# ===` de fechamento.
- **R31 tem 1 lente em 51 grafos**; se ela sumir, a paridade de parser deixa de ser verificada em
  qualquer lugar, silenciosamente. A R52 **não** cobre isso (roda `--integrity`, não o parser da lente).
- **R3 é denylist de 1 item** (`gpt-4`) para um campo que é allowlist de fato — `gpt-5`, `o3`,
  `claude-3-opus` passam limpos hoje.
- **R4 só se defende de si mesma**: o token `mcp_onion-orchestrator` não existe em nada vivo, e a
  guarda precisa de 3 exclusões auto-referenciais para não se acusar. Remover ou generalizar.
- **Fixtures ausentes** nas HARD mais antigas (R1, R2) e na de lógica mais complexa (R20).

---

## 8. O que este mapa deixa em aberto

1. **Nenhum gate "regra sem fixture"** — §6. Candidato natural a 6ª catraca do registry.
2. **Docstrings com número histórico** que hoje lê como estado (R45 "101", R49 "53") — §5.
3. **Critério escrito "rule vs skill"** — `.claude/rules/` e as skills `onion-patterns`/
   `onion-validation` usam o **mesmo** mecanismo `paths:`; a divisão é histórica, não principiada.
4. **`.claude/rules/` não entra no payload do `/meta:adopt`** — a camada cognitiva não é distribuída.
5. **Guardas sem cadência** — §3.2.
6. **Ponteiro morto declarado como fonte canônica:** `onion-working-method.md:134,141,177` cita
   `~/.claude/rules/working-discipline.md`, que **não existe**; nenhuma das 3 guardas de link o pega.
7. **Números hardcoded nas skills:** `onion-patterns` duplica "51 agentes" (SSOT já guardada);
   `onion-validation` **se contradiz** (400/300 numa seção, 500/800 e 1200/1500 na tabela).

---

## Referências

- SSOT das regras: [`.claude/validation/lint-rules.md`](../../.claude/validation/lint-rules.md) (gerada)
- Gerador + catracas: `.claude/validation/rules-registry.sh`
- Implementação: `.claude/validation/lint-artifacts.sh`
- Auto-teste: `.claude/validation/lint-selftest.sh` + `.claude/validation/fixtures/manifest.tsv`
- Escada de automação: [`graduated-automation-ladder.md`](../knowledge-base/concepts/graduated-automation-ladder.md)

[`fix-must-become-mechanism`]: ../knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md
[`posttooluse-exit-2-is-the-only-channel`]: ../../.claude/diary/2026-08-02-posttooluse-exit-2-is-the-only-channel.md
[`shell-guard-paid-four-times-same-axis`]: ../../.claude/diary/2026-08-03-shell-guard-paid-four-times-same-axis.md
