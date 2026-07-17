---
title: 'Bug: kg-radar.sh reporta VERDE (exit 0) num grafo que não conseguiu ler — gate de integridade vacuoso no CI'
date: 2026-07-17
from: granaai (consumidor / adopted @ fb08cc6be4ad, regulated)
to: core (onion-evolve)
type: field-signal-bug
flow: upstream (consumidor→core / sinal de campo)
severity: HARD (falso-verde: gate de CI regulado passa sem validar nada)
re: complementa 2026-07-17-redogfood-kg-sdaal-validation-gaps (aquele é sobre TRACES_TO órfão; este é sobre o radar não parsear o grafo)
---

# Bug — `kg-radar.sh`: grafo ilegível é indistinguível de grafo saudável

## Sintoma

`bash .claude/validation/kg-radar.sh docs/technical-context/graph/granaai.kg.yaml` reporta:

```
✅ schema_version 1 (bate com o radar)
✅ sem contradições estruturais ( nós, 0 arestas)
(camada domain ausente — grafo puramente epistêmico/audit)
(nenhum nó com frescor rastreado — nada a verificar)
```

**Exit code de `--integrity`: 0 (PASS).**

Só que o arquivo tem **2779 linhas** e declara em `stats:` **144 nós / 332 arestas**, com
`meta.layer: domain` e `TRACES_TO: 29`. O radar parseou **zero** nós e mesmo assim passou verde —
inclusive negando a camada `domain` que o `meta` declara.

## Teste de controle (o radar em si funciona)

```bash
# fixture canônica do core → parseia normalmente
$ kg-radar.sh .claude/validation/fixtures/kg-domain/good-domain.kg.yaml
  ✅ sem contradições estruturais (6 nós, 7 arestas)

# KG do granaai → zero nós, mesmo veredito verde
$ kg-radar.sh docs/technical-context/graph/granaai.kg.yaml
  ✅ sem contradições estruturais ( nós, 0 arestas)   # ← note o campo vazio antes de "nós"
$ echo $?
0
```

## Causa raiz — duas causas empilhadas

### 1. Gramática divergente (o radar não reconhece a forma emitida)

O `kg-radar.sh` (awk, l.61-93) espera **nós como LISTA**, com `node_type` e `- from:` **indentado**:

```awk
section == "nodes" && /^[[:space:]]+- id:/      # l.65 — exige "- id:" COM espaço à esquerda
section == "edges" && /^[[:space:]]+- from:/    # l.86 — idem "- from:"
section == "edges" && /edge_type:/              # l.92 — exige "edge_type:"
```

Fixture canônica (`fixtures/kg-domain/good-domain.kg.yaml`):
```yaml
nodes:
  - id: EN_ORDER
    node_type: entity
    layer: domain
    plane: PROD
    impact: 4
    confidence: 1.0
    status: confirmed
```

O `.kg.yaml` do granaai (gerado pelo dogfood `kg-ssot-sdaal` via Workflow nativa):
```yaml
nodes:
  domain:antecipacao-recebiveis:     # ← MAPA, não lista → l.65 nunca casa
    type: domain                     # ← `type`, não `node_type`
    label: Antecipação de Recebíveis
    evidence:
    - docs/business-context/features/antecipacao-recebiveis.md
edges:
- from: capability:registro-recebiveis   # ← coluna 0, sem indentação → l.86 nunca casa
  type: REALIZES                         # ← `type`, não `edge_type`
  to: domain:antecipacao-recebiveis
```

Três incompatibilidades: **mapa vs lista**, **`type` vs `node_type`/`edge_type`**, e **indentação zero
no `- from:`** (o `/^[[:space:]]+/` exige ao menos um espaço). Também ausentes os campos
`impact`/`confidence`/`status` que alimentam o radar de atenção — daí a seção "atenção" sair vazia.

### 2. Fail-open (esta é a parte que dói)

A divergência de gramática é só drift. **O bug é o radar não saber que não sabe.** Zero nós parseados
produz exatamente a mesma saída que um grafo íntegro: `✅ sem contradições estruturais`. Não há
contradição possível num conjunto vazio — a asserção é **vacuosamente verdadeira**, e o gate confunde
"nada errado encontrado" com "nada encontrado".

Pior: o `schema_version: "1"` **passa** (`✅ bate com o radar`). O selo é auto-declarado no `meta` e o
radar valida o **carimbo**, não a **forma**. Um arquivo pode declarar conformidade com uma gramática
que não segue, e o único check que existiria para pegar isso é o que confia no carimbo.

## Impacto neste repo (regulated)

Plugamos o gate de integridade do KG no **pre-commit e no GitHub Actions** (nosso commit `a8d2faa1e`,
`ci(kg): plug KG integrity gate into pre-commit and GitHub Actions`). Ou seja: **temos um gate verde em
CI guardando exatamente nada** há vários commits. Todo o trabalho da branch `feat/kg-100pct-traceability`
(144 nós, 332 arestas, rastreabilidade end-to-end para auditoria) está **não-validado por ferramenta
determinística** — validado apenas por LLM (`kg-validation-report.json`, `validation_pass: true`), que é
precisamente o que o gate determinístico existe para não precisar acreditar.

Num consumidor `regulated`, "o gate de rastreabilidade estava verde" é uma frase que aparece em
auditoria. Ela não deveria poder ser dita por um script que não leu o arquivo.

## Parentesco — mesma classe do bug `jq` (2026-07-01)

Este é o **mesmo padrão de falha** do sinal `lint-graceful-skip-sem-jq` que vocês trataram em 2026-07-10:
uma guarda que, ao não conseguir fazer seu trabalho, **falha na direção do silêncio**. Lá o `|| return`
derrubava o script (fail-closed acidental, barulhento — a gente percebeu no mesmo dia porque bloqueou
commit). Aqui é **fail-open** (silencioso) — e por isso passou despercebido muito mais tempo. O fail-open
é a versão cara do mesmo erro: ninguém reclama.

## Recomendação ao core

1. **Radar deve reprovar (ou berrar) quando parseia zero nós.** `nodes: 0` num arquivo não-vazio é
   patológico por definição — nenhum KG legítimo tem zero nós. Sugestão mínima: se `nodes == 0 &&`
   arquivo tem seção `nodes:` não-vazia → `✗ REPROVA` com "gramática não reconhecida", exit ≠ 0.
   Isto sozinho já converte o falso-verde em erro alto.
2. **Validar a forma, não o carimbo.** O check de `schema_version` deveria ser consequência de parsear
   com sucesso, não um `grep` no `meta`. Enquanto o selo for auto-declarado e verificado isoladamente,
   ele atesta a intenção do gerador, não a conformidade do artefato.
3. **Cobrir no `lint-selftest.sh`** uma fixture `bad-grammar.kg.yaml` (nós como mapa / `type` em vez de
   `node_type` / `- from:` na coluna 0) esperando **exit ≠ 0**. Hoje as fixtures só exercitam a gramática
   correta — a cegueira é a mesma que vocês fecharam no marketplace com o `run_adopted_role_selftests`:
   o selftest não testa o caso em que a entrada é estranha.
4. **Questão de gramática (precisamos da decisão de vocês):** qual forma é canônica? Se a lista
   (`- id:` + `node_type`) é a SSOT, o gerador do `/meta:kg` está emitindo fora da gramática e nós
   regeneramos aqui. Se o mapa também deve ser aceito, o radar precisa das duas. **Não vamos regenerar
   até saber** — regenerar contra a gramática errada só troca o falso-verde de lugar.

## O que NÃO fizemos

Nenhum fix local aplicado (diferente do caso `jq`). Não sabemos qual lado é a fonte da verdade, e chutar
aqui produziria drift que vocês teriam de reconciliar. Aguardamos o veredito de (4) para agir.
