---
title: "Revisão — REGRA 62: catraca de projeção gerada (backlog)"
date: 2026-08-28
branch: feat/backlog-projection-ratchet
reviewer: "revisão adversarial de código com EXECUÇÃO e mutação (veredito inicial 🔴 vermelho) + dogfood do gerador + CI em runner distinto"
reviewed_diff_sha256: PLACEHOLDER
findings_total: 13
findings_real: 11
verdict: APROVADO_APOS_CORRECAO
tokens: 168000
duration_min: 52
---

# Resíduo — REGRA 56

Guarda **HARD nova com autofix**. O risco desta classe é assimétrico: um falso-negativo deixa
passar drift; um **falso-positivo reprova repo correto**, e um autofix errado **apaga conteúdo
bom**. A revisão foi desenhada em torno dos dois, e **encontrou os dois**.

## Veredito inicial: 🔴 VERMELHO — a 1ª versão foi reprovada, com razão

### Crítico 1 — a guarda **selava de verde a doença que existe para impedir**

O gerador chamava `kg-radar --open-tsv 2>/dev/null` dentro de *process substitution*: **stderr
descartado e rc nunca lido**. Reproduzido com comando:

- **um** grafo ingramatical → **27 itens somem** da projeção, o `--fix` **grava a perda**, e a
  REGRA 62 reporta **ZERO violações**;
- sem `lib/status-factor.awk` → `docs/backlog.md` vai de **39.469 → 785 bytes**, com `exit 0`.

Eu havia fechado a porta da falha destrutiva pelo lado do `git ls-files` — e **a mesma destruição
entrava intacta pelo lado do radar**. O `[ -s "$tmp" ]` não protegia: a saída destrutiva era
**plausível** (cabeçalho + "nada aberto"), não vazia.

**Cura:** rc do radar lido por grafo → QUEBRA (`exit 2`); grafo enumerado mas ausente do worktree
(sparse-checkout, submódulo, `rm` sem `git rm`) → QUEBRA em vez de `continue`; stderr do radar
repassado; e sanidade final **enumerados == processados**.

### Crítico 2 — o render era **locale-dependente**, e a catraca acusaria o ambiente

Eu escrevi, ao instalar o pré-requisito do `iconv`, que *"guarda que acusa o ambiente é pior que
guarda nenhuma"* — e deixei **seis `sort` sem `LC_ALL=C`** e um `printf '%.1f'` lendo `LC_NUMERIC`.

- em `en_US.UTF-8` dois nós empatados em 7.5 **trocam de ordem** → a guarda HARD **reprova repo
  correto**;
- sob locale de vírgula decimal o `printf` emite **`38,0`** no lugar de `38.2`, com 190 erros em
  stderr **e `exit 0`** — o `_gen_into` chama de sucesso, o diff dá drift, e a mensagem manda
  **regenerar**: quem obedece **grava a projeção corrompida**. O locale do maestro é `pt_BR`.

Os irmãos (`graph.sh`, `kg-view.sh`) já pinavam `LC_ALL=C`; **este era o único fora do padrão**.
**Cura:** `export LC_ALL=C`, verificada **no-op** no artefato atual.

## Demais achados reais corrigidos

| # | achado | cura |
|---|---|---|
| 3 | `--fix` **mutava arquivo rastreado e o relatório dizia que não mutou nada** — apagou 336 linhas e imprimiu "já em sincronia" | contabiliza em `FIXED_FILES`/`FIX_LOG` |
| 4 | o autofix estava **acoplado ao `return 0` do inventário** — falha alheia do `inventory.sh` e o autofix somia sem aviso | função própria `run_backlog_projection_fix`, chamada antes |
| 5 | bancada sem eixo de **locale** — justamente o que uma catraca byte-a-byte compra | caso (g), com skip honesto se não houver locale alternativo |
| 6 | bancada sem caso de **radar quebrado** | caso (h) |
| 7 | caso do `iconv` verificava `rc=2` **sem a razão** — um exit 2 de outra guarda passaria igual | casa a substring do stderr |
| 8 | caso da enumeração vazia podia **escrever fora do sandbox** se `TMPDIR` estivesse dentro de um worktree git | `TMPDIR=/tmp` fixo |
| 9 | mensagem de erro imprimia **"exit 0"** para falha real (`$?` dentro de `if !` é do próprio `if`) | rc capturado em variável |
| 10 | o nó do KG afirmava mais do que a entrega sustentava | `verified_against` reancorado no que foi de fato coberto |
| 11 | `previne:` multi-linha era truncado pelo gerador da tabela de regras | uma linha só (a casa já mediu que aceitar multi-linha pioraria 23 regras) |

**2 achados NÃO acatados**, registrados: o caso de paridade `--markdown`×`--write` é
quase-tautológico (mesma função `render`) — **mantido** como rede contra newline/redireção, com o
limite declarado; e o churn de `provenance.json`, que é comportamento conhecido do assembler, não
deste PR.

## Categorias atacadas em que o revisor NÃO achou defeito

- **Ordem `--fix` × guarda** — sem oscilação: o fix roda antes da checagem.
- **Consumidores de `docs/backlog.md`** — varridos; a mudança do cabeçalho sobre `owner:` não
  quebra nenhum, e as duas cópias (comando + plugin) estão em sincronia.
- **Arrays associativos, timezone, `git ls-files`, `basename`** — determinísticos aqui.
- **`--check` e o modo default** — preservados pelo `case` fechado.

## Verificação mecânica

- **Bancada `backlog-projection`: 8 casos, 0 falhas, 0 skips.**
- **Mutação — 5 mutantes, cada um reprovando no caso certo:** regra desligada · args fail-open ·
  guarda de enumeração removida (`mutou=SIM`) · **pinagem de locale removida** · **rc do radar
  engolido** (`mutou=SIM`).
- **CI em runner distinto:** o `lint` rodou fora desta máquina e a REGRA 62 **não disparou** — a
  prova direta contra o Crítico 2, feita pelo ambiente e não por mim.
- Suíte completa e `lint-artifacts` anexos ao PR.

## Nota de método

Os dois críticos foram achados por **execução**, não por leitura — e um deles (o do radar) só
apareceu porque o revisor **reproduziu com comando** o cenário que eu havia declarado fechado. É a
mesma lição do farol, no mesmo dia: *o que separa é medir.*
