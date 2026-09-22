---
title: 'Resíduo — curei um fail-open abrindo outro da mesma classe'
date: 2026-09-22
branch: docs/co-evolve-triagem-inbox
reviewed_diff_sha256: fa7b1564d102baba2286934d7f7a8b9ef67d8b5e7967b60e72552e83704cab32
tokens: 20161153
duration_min: 15
findings_total: 8
findings_real: 8
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Refutador opus em WORKTREE ISOLADA sobre a triagem do inbox e a cura dos dois furos do gate de
  design. REPROVOU com 8 achados reais — o primeiro é uma REGRESSÃO que eu introduzi ao curar.
---

# A cura abriu o buraco que fechava

Curei dois furos do `lint-design-tokens.sh` vindos de um sinal de campo. O refutador mediu e
**reprovou com 8 achados**. O primeiro é o que importa:

**A indexação de composite ESCREVIA direto no `TOK`, e o laço roda DEPOIS do escalar.** Uma
sub-chave derivada (`typography.heading.fontSize`) **apagava** um token escalar de path idêntico —
e com ele o alias órfão que o gate **já pegava**. Medido: `HARD: alias órfão` virou `exit 0`.

Fechei um fail-open abrindo outro **da mesma classe**. E o teste que escrevi para provar a cura não
pegava, porque testei o caso que imaginei e não o irmão.

Cura: **token declarado vence sub-chave derivada**, sempre (`[ -z "${TOK[path]+x}" ] || continue`).

## Os outros sete

| # | achado | cura |
|---|---|---|
| 2 | `$value` **array** (a forma DTCG do multi-shadow) não era coberto — e meu comentário **nomeava** `shadow`. Dois órfãos, zero HARD | `type=="object" or type=="array"` |
| 3 | a exclusão de `_candidates/` era **silenciosa** — SSOT inteira mal-colocada dava `OK ✓` sobre um arquivo | o gate **declara** o que não mediu |
| 4 | sem `LC_ALL=C` no `sort`, um gate que se diz **DETERMINÍSTICO** dependia do locale | `LC_ALL=C sort` |
| 5 | a metade "shadowing" do caso (g) era **inerte** — a fixture usava `semantic/`, que ordena depois | caso **(g3)** com foundation em `Base/`: sem a exclusão o contraste cai para **1,01:1** |
| 6 | **REGRA 81** introduzida por mim: inventário subiu 1145→1149 e o painel publicava 1145 | regenerado |
| 7 | **REGRA 84** não curada: o índice removeu 4 linhas e não acrescentou nenhuma | regenerado |
| 8 | citação pendurada na cópia do plugin (`commands/design/generate.md` não existe lá) | cita o comando, não o caminho |

## O comentário que eu escrevi estava errado

Afirmei que candidatas "só não vencem porque `_` ordena antes de letra no locale C". **Falso.** A
ordem real medida é `00-core/` < `Base/` < `_candidates/` < `atoms/` — a candidata **vence**
qualquer diretório de inicial maiúscula. O risco era maior do que eu declarei, não menor, e só
apareceu porque o refutador construiu a fixture que eu não construí.

## Também neste diff: um defeito da triagem anterior

Mover 3 sinais do inbox para `_processed/` **quebrou 4 `trace:`** do grafo
`compartilhamento-individuo-organizacao-2026-09` (REGRA 55). O protocolo manda mover e não avisa
disso. Curado, e a varredura do refutador confirma: **zero** `trace:` para `inbox/` sem
`_processed/`, **zero** apontando para `_processed/` arquivo que ainda está no inbox.

## Declarado

Não reproduzi o achado 4 com fixture própria — montei mal (os pares não referenciavam os tokens
duplicados). Confirmei a **causa** direto na fonte (zero `LC_ALL` no script) e curei. Isso é
confirmação de causa, não reprodução do sintoma, e a diferença fica registrada.

Bancada `design_tokens`: 13 → **21 casos**.
