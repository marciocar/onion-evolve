---
title: 'trace: para arquivo da raiz (ex.: CLAUDE.md) fica fora do índice de leitura do KG'
date: 2026-10-08
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# Arquivo da raiz não é vigiado pela perna de leitura do KG

## O que foi medido (pin 7818b8a25ae6)

- `.claude/validation/kg-trace-resolve.sh:113`: a condição (b) exige `/` no alvo do `trace:`. Por isso
  `trace: "CLAUDE.md"` cai em `SKIP_NOTPATH` e não entra no `--emit-index`, nem é julgado pela REGRA 55.
- Com `trace: "./CLAUDE.md"` o resolve passa a julgar (julgáveis 3 → 5) e o índice ganha a linha
  `./CLAUDE.md`. Mas `.claude/hooks/kg-read-leg.sh:85` tira o `./` do caminho lido e casa `$1 == a`
  exatamente, então o hook continua mudo. Controle positivo: um Read em `onion-adoption.kg.yaml`
  disparou o aviso normalmente.
- A medição foi feita por uma passada adversarial numa cópia do repo, e eu conferi as duas linhas no código.

## Efeito

Em `docs/onion/graph/curation-domain.kg.yaml`, as regras do domínio estão ancoradas no `CLAUDE.md` por
`TRACES_TO` (nó `CLAUDE_MD` com `trace: "CLAUDE.md"`). Quem lê ou muda o `CLAUDE.md` não recebe o aviso
"o corpus já fala deste arquivo", e uma mudança de lugar do arquivo não é acusada. A âncora mais
importante de um adotante, o `CLAUDE.md`, é justamente a que fica cega.

## Pedido

Aceitar como caminho um alvo sem barra que **exista** como arquivo na raiz do repo, ou normalizar o `./`
dos dois lados (`--emit-index` e `kg-read-leg.sh`). Aqui não há o que corrigir localmente: a lacuna fica
registrada como `C_TRACE_ROOT_FILE_UNWATCHED`.
