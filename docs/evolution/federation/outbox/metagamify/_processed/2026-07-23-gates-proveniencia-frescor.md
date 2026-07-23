---
title: 'Gates novos no lint: REGRA 29 (proveniência) + REGRA 42 (frescor) — ambos com catraca'
date: 2026-07-23
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-23 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — dois gates novos chegam no `--update`: proveniência + frescor (com catraca)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no próprio `inbound/`.

## O que chega

Duas regras de lint novas, vendorizadas junto com `.claude/validation/` no próximo `/meta:adopt --update`:

- **REGRA 29 — proveniência invertida** (`kg-provenance-coverage.sh`). A pergunta espelho do
  `kg-radar.sh`: não "o grafo está consistente?", mas **"este documento existe no grafo?"**. Um relatório em
  `docs/analysis/*.md` ou `docs/evolution/research/**/*.md` está coberto quando algum nó de algum `.kg.yaml`
  do repo o cita em `trace:`/`evidence:`. Doutrina de origem: **conhecimento nasce NO grafo, não fora dele**.
- **REGRA 42 — frescor doutrinário** (`doctrine-freshness.sh`). Irmã temporal da 29: não checa contra o
  grafo, checa contra o **tempo**. Não bate na web em CI (não tem rede) — cobra que afirmações world-facing
  em KBs carreguem `verified_at:` + fonte, dentro de um TTL (default 90 dias). Nível A é HARD e enumerável;
  Nível B é SOFT (rede léxica, convenção).

Doutrina completa: `onion-guardrails.md` §7 (catraca) e §8, mais `knowledge-graph-sdaal.md` — chegam junto
no `--update`.

## Por que isto não deve quebrar o CI de vocês

Ambos os gates nascem com **catraca**: passivo existente é tolerado via **baseline versionado** (SOFT); só
**documento novo** fora do grafo, ou **doutrina nova** sem `verified_at`, vira violação HARD. E o baseline só
pode **encolher** — se ele crescer, isso também é HARD (regressão). Isto é o que torna o gate adotável em vez
de um "big bang" que reprova o repo inteiro no primeiro dia.

## ⚠️ Ação necessária — sem isto o gate nasce reprovando o SEU passivo

**Sem baseline semeado, os dois gates degradam FAIL-CLOSED** (ausência de baseline não é lida como "sem
passivo" — é tratada como regressão). Depois do `--update`, antes do próximo commit:

```bash
bash .claude/validation/kg-provenance-coverage.sh --emit-baseline > .claude/validation/kg-coverage-baseline.txt
bash .claude/validation/doctrine-freshness.sh --emit-baseline > .claude/validation/doctrine-freshness-baseline.txt
git add .claude/validation/kg-coverage-baseline.txt .claude/validation/doctrine-freshness-baseline.txt
```

Depois de semeado, a métrica de saúde é o baseline **diminuindo** — cobrir um relatório antigo no grafo, ou
re-verificar uma KB velha e remover a entrada correspondente, é o sinal certo (não "manter o baseline igual
para sempre").

## Crédito

A REGRA 29 nasceu de um sinal de campo de um adotante: uma avaliação orquestrada (dezenas de agentes, dezenas
de achados confirmados) foi produzida e **nada dela foi ingerido no `.kg.yaml`** — evidência auto-incriminadora
de que a doutrina KG-SSOT só tinha *forcing function* na leitura, nunca na escrita.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinaliza como 📥 inbound).
- Classe **COMPATÍVEL**, sem update obrigatório imediato — mas ao rodar `/meta:adopt --update`, **semear os
  dois baselines é o passo que evita HARD-fail no primeiro commit seguinte** (ver comando acima).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-23-gates-proveniencia-frescor.md /home/marcio/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
