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
| **`edge_type:`** | `SUPPORTS` `REFUTES` `SUPERSEDES` `CAUSES` `DEPENDS_ON` `TRACES_TO` `CONSTRAINS` (audit: limita sem derrubar) · `HAS_STATE` `TRANSITIONS` `EMITS` `CONSTRAINS` `READS` `WRITES` (domain) | escrever **`type:`** |
| `layer:` | `audit` (default) · `domain` | — |
| `plane:` | `DEV` (código/branch) · `PROD` (artefato vivo) | `decision` só vira `done` verificada em **PROD** |
| `status:` | `open` `confirmed` `drifted` `unverifiable` `refuted` `superseded` `done` | ~~valores fora do enum passam sem gate — 11 circulando hoje~~ **FALSO, e medido: o motor REPROVA (fator −1 em `lib/status-factor.awk`), e o corpus vivo tem 4.021 `status:` com ZERO fora do enum** (2026-09-22; achado #8 do sinal de campo de 2026-09-10, que foi ler a doutrina para construir em cima dela). A linha velha fica riscada em vez de apagada: doutrina que afirmava o oposto do código é o defeito que esta casa persegue, e apagá-la transformaria a correção em propaganda. `drifted`/`unverifiable` são a SAÍDA de `/meta:kg-freshness` e existem desde 2026-08-06: sem elas, selar um drift só dava para **recusar** (exit 1) ou **mentir de `refuted`**, que zera a atenção do nó que acabou de provar que a realidade andou |
| `impact:` / `confidence:` | 1–5 / 0–1 | — |
| `verified_at:` / `verified_against:` | data + o que foi medido | ausente em nó `PROD` → `STALE-MISSING` |
| `valid_from:` · `source_tier:` (1–10) · `source_kind:` | opcionais em `evidence` — bi-temporal (o fato ≠ a verificação) e autoridade da fonte. `valid_from` **sempre entre aspas** (`"2026"`, `"2026-10-01"`) | confundir `valid_from` com `verified_at`; tier alto em blog de concorrente (`vendor-on-competitor`); **`valid_from: 2026` sem aspas** é INTEIRO para todo leitor YAML tipado (o radar avisa `VALID-FROM-INTEIRO`, SOFT) |
| `id:` (nó) | só `[A-Za-z0-9_]` — o radar **reprova** (`--integrity`) id fora do alfabeto | prefixar com nome de arquivo **com a extensão** (`SYNTHESIS.md_X`): o ponto quebra quem endereça nó por caminho |
| **`trigger:`** (aresta `TRANSITIONS`, camada domain) | id do nó `event` que dispara a transição: `- from: ST_A` / `to: ST_B` / `edge_type: TRANSITIONS` / `trigger: EV_X` | apontar evento que não existe no arquivo — o radar **reprova** (`trigger aponta evento inexistente`) e conta a aresta como ligação do evento |
| ~~`on:`~~ (**PROIBIDO**, legado de `trigger:`) | — | escrever `on:` — o radar ainda lê, mas acusa `ON-LEGADO` (SOFT na REGRA 52) |
| `meta.review_after:` | data de revisita (grafos de pesquisa) | ausente em grafo novo de pesquisa → SOFT; vencido → SOFT |
| **datas** (`baseline`, `review_after`, `verified_at`, `valid_from`) | **sempre entre aspas**: `verified_at: "2026-10-08"` | sem aspas é DATA para leitor YAML 1.1 e STRING em 1.2 — o contrato acusa `yaml.unquoted-date` |
| **`provenance:`** (nó `confirmed` ou `plane: PROD`) | bloco com as três chaves, um nível a mais de indentação: `source:` (o que foi lido: URL, caminho@commit, comando) · `locator:` (onde: seção, linha, citação) · `method:` (como: leitura, medição, juízes) · e, opcional desde o contrato v4.2, `locality:` (onde a fonte MORA: `repo` · `web` · `host` · `pessoa`; `kg-migrate-v3.py --locality` a deriva do `source`) | **inventar a fonte para passar no contrato.** Sem fonte verificável o nó **não é** `confirmed` — deixe `open`. **E citar `caminho@<sha>` de commit da própria branch e mergear por rebase:** o rebase reescreve o sha e a fonte fica fora da main — o `ops/pr-merge-verified.sh` recusa e pede `--merge-commit` (SAC-80) |
| **`external_edges:`** (topo, desde o contrato v4.3) | aresta para nó de **OUTRO grafo**, um item por aresta, exatamente uma ponta externa `<caminho relativo à raiz>#<id>` e a outra um id deste arquivo; `from` ausente = o grafo inteiro: `- to: "docs/x/y.kg.yaml#C_VELHA"` / `edge_type: SUPERSEDES`. Tipos: `SUPERSEDES` `CONSTRAINS` `SUPPORTS` `REFUTES` `TRACES_TO` `DEPENDS_ON`. A ponta local conta como ligação (o nó não é órfão) | inventar o alvo: o gate confere arquivo e id contra **todos** os `.kg.yaml` rastreados (`integrity.dangling-external`) e o radar confere a ponta local; usar a chave própria antiga (`x_supersedes_external`, `x_constrained_by`): migre com `kg-migrate-v3.py --external-edges` (SAC-98) |
| **`label:`** + **`narrative:`** | `label` ≤ **280 caracteres**, só a afirmação curta; o porquê e o contexto vão em `narrative:` no mesmo nó. No `meta`, `note:` e `purpose:` são chaves conhecidas | label-parágrafo (o contrato acusa `form.range.node.label`); chave inventada no topo ou no `meta` (o contrato acusa `form.unknown-key.*` — extensão própria leva prefixo `x_`) |

> ⚠️ **Por que `on:` virou `trigger:` (2026-10-07):** um leitor **YAML 1.1** (o default do PyYAML,
> por exemplo) lê a chave `on` como o **booleano `True`**, não como a string `"on"`. O evento
> referenciado parecia órfão para esse leitor enquanto o radar (que lê texto) o aprovava: **dois
> leitores discordando do mesmo byte**. O contrato formal do `.kg.yaml` em curso fixa perfil
> **YAML 1.2 restrito** com a chave `on` proibida e o gatilho renomeado para `trigger`; esta gramática
> se alinha a ele. O corpus do core foi migrado (zero `on:` fora da bancada que prova o aviso). O
> radar segue **lendo** `on:` para não quebrar grafo antigo fora do corpus — lê, conta a ligação e
> avisa; quem lê o corpus com leitor tipado trata uma chave `True` numa aresta como `trigger` legado.

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
bash .claude/validation/kg-contract-check.sh <arquivo>.kg.yaml   # rc 0 obrigatório onde o contrato está vendorizado
```

> **Por que as três linhas do contrato v3 (2026-10-08):** o contrato formal do `.kg.yaml` (vendorizado por
> pin em `vendor/kg-ssot`, onde existe) tem um gate por grafo no CI que **reprova grafo novo** que suba a
> dívida SHOULD. O `kg-contract-check.sh` é o mesmo leitor, por arquivo, **antes** do commit — o gate do CI
> só enxerga arquivo rastreado. Grafo antigo não é cobrado pela dívida que já tinha: só por piorá-la.

Descoberta de grafos (o glob hardcoded era **36% cego**):

```bash
git ls-files '*.kg.yaml' | grep -v '/fixtures/'
```

Doutrina completa: [`knowledge-graph-sdaal.md`](../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
