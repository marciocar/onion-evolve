---
paths:
  - "**/*.kg.yaml"
---

# Gramática do `.kg.yaml` — leia antes de escrever ou grepar um grafo

> **Por que esta regra existe (dano medido, 2026-08-02):** um estudo ia propor uma guarda que grepava
> `type: REFUTES`. O campo é **`edge_type:`** — o grep devolve **zero nos 14 grafos de pesquisa**, e a
> guarda teria nascido **verde-vazia**: passa sempre, guarda nada. Não foi descuido de quem escreveu;
> foi ausência de fonte única no momento de escrever. Esta regra carrega **só quando você toca um
> `.kg.yaml`** — que é exatamente quando ela importa.

## Os campos que se erram

| Campo | Valor | Erro comum |
|---|---|---|
| **`node_type:`** | `entity` `claim` `decision` `question` `evidence` `artifact` (audit) · `entity` `state` `event` `rule` `invariant` `policy` (domain) | escrever **`type:`** — o radar não lê |
| **`edge_type:`** | `SUPPORTS` `REFUTES` `SUPERSEDES` `CAUSES` `DEPENDS_ON` `TRACES_TO` (audit) · `HAS_STATE` `TRANSITIONS` `EMITS` `CONSTRAINS` `READS` `WRITES` (domain) | escrever **`type:`** |
| `layer:` | `audit` (default) · `domain` | — |
| `plane:` | `DEV` (código/branch) · `PROD` (artefato vivo) | `decision` só vira `done` verificada em **PROD** |
| `status:` | `open` `confirmed` `drifted` `unverifiable` `refuted` `superseded` `done` | ~~valores fora do enum passam sem gate — 11 circulando hoje~~ **FALSO, e medido: o motor REPROVA (fator −1 em `lib/status-factor.awk`), e o corpus vivo tem 4.021 `status:` com ZERO fora do enum** (2026-09-22; achado #8 do sinal de campo de 2026-09-10, que foi ler a doutrina para construir em cima dela). A linha velha fica riscada em vez de apagada: doutrina que afirmava o oposto do código é o defeito que esta casa persegue, e apagá-la transformaria a correção em propaganda. `drifted`/`unverifiable` são a SAÍDA de `/meta:kg-freshness` e existem desde 2026-08-06: sem elas, selar um drift só dava para **recusar** (exit 1) ou **mentir de `refuted`**, que zera a atenção do nó que acabou de provar que a realidade andou |
| `impact:` / `confidence:` | 1–5 / 0–1 | — |
| `verified_at:` / `verified_against:` | data + o que foi medido | ausente em nó `PROD` → `STALE-MISSING` |
| `valid_from:` · `source_tier:` (1–10) · `source_kind:` | opcionais em `evidence` — bi-temporal (o fato ≠ a verificação) e autoridade da fonte | confundir `valid_from` com `verified_at`; tier alto em blog de concorrente (`vendor-on-competitor`) |
| `meta.review_after:` | data de revisita (grafos de pesquisa) | ausente em grafo novo de pesquisa → SOFT; vencido → SOFT |

**Formato estrito:** o radar é `awk`, não parser YAML. Uma chave por linha; listas com `- id:` /
`- from:`. `id` em **inglês**, `label` em **pt-BR**.

## A regra que mais custa esquecer

**Nó que recebe `REFUTES` e continua `confirmed` é contradição estrutural — o radar reprova (exit 1).**
Ao adicionar a aresta, **reconcilie o status** para `refuted`/`superseded`.

E a distinção que o próprio radar ensinou: **dissent que MATA é `REFUTES`; dissent que LIMITA é
`CONSTRAINS`.** Modelar objeção sobrevivente como `REFUTES` cria contradição — a decisão sobrevive
ao dissent, por isso ele a *restringe*, não a derruba.

## Antes de fechar

```bash
bash .claude/validation/kg-radar.sh <arquivo>.kg.yaml    # exit 0 obrigatório
```

Descoberta de grafos (o glob hardcoded era **36% cego**):

```bash
git ls-files '*.kg.yaml' | grep -v '/fixtures/'
```

Doutrina completa: [`knowledge-graph-sdaal.md`](../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
