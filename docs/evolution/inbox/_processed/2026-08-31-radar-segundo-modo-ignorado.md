---
title: "kg-radar ignora o segundo modo: `--integrity --schema` roda só o primeiro (9 sítios, 2 deles gates de passo 0)"
date: 2026-08-31
from: mvp-venda-direta-pdi
to: onion-evolve
type: bug
flow: upstream
---

# `--integrity --schema` roda só `--integrity` — e dois gates de passo 0 dependem disso

Achado durante um `/meta:realign` real neste adotante, no pin `219e9a5f365b`. O radar aceita
**um** modo posicional:

```bash
FILE="${1:-}"
MODE="${2:---all}"     # não existe $3
```

Logo, `kg-radar.sh <grafo> --integrity --schema` avalia **apenas a integridade**. O `--schema`
é descartado em silêncio.

## Medido, com controle

| Invocação | Saída |
|---|---|
| `--integrity` | `══ INTEGRIDADE ══` |
| `--schema` | `══ SCHEMA … ══` |
| `--integrity --schema` | **só** `══ INTEGRIDADE ══` |
| `--flag-inexistente` (controle) | **0 linhas, rc=0** |

O controle mostra que a família é a já conhecida: flag desconhecida não reprova, some. O
próprio cabeçalho do radar avisa da irmã dessa falha ("o radar passa a imprimir NADA com exit
0 … só a CONTAGEM de linhas de saída pega").

## Por que importa mais do que parece

O default `--all` roda os dois. Quem chama o radar nu está coberto. **Quem escreve os dois
modos explicitamente perde um** — e é exatamente o que os gates de passo 0 fazem:

- `.claude/validation/kg-realign-project.sh:41` — `bash "$RADAR" "$GRAPH" --integrity --schema >/dev/null 2>&1 || …`
- `.claude/validation/kg-drive-project.sh:41` — idem

Nos dois, o `>/dev/null 2>&1` esconde que só metade rodou, e o veredito sai do `rc`. Um grafo
com `schema_version` divergente **passa** no passo 0 de `/meta:drive` e de `/meta:realign` —
que são precisamente os dois lugares que existem para dizer "não se conduz grafo que o motor
não lê".

Mais 7 sítios de documentação prescrevem a mesma forma: `commands/meta/drive.md:35,76` ·
`kg-freshness.md:70,282` · `realign.md:37,54` · `kg.md:277` · `diary.md:290`.

## Sugestão

Duas correções que se somam:

1. **Iterar os modos**: varrer `"$@"` e rodar cada modo pedido, em vez de ler só `$2`. O
   contrato documentado nas 9 chamadas passa a ser o contrato executado.
2. **Deny-by-default para flag desconhecida**: sair 2 com mensagem, em vez de imprimir nada
   com rc 0. Hoje um typo (`--integrety`) devolve silêncio verde — e é o mesmo modo de falha
   que a REGRA 54 nomeia: varredura cega devolve zero violações, indistinguível de
   conformidade.

## Nota lateral — o sinal de 2026-08-27 segue aberto

Os defeitos 1 e 2 de `docs/evolution/inbox/2026-08-27-adopt-greenfield-tres-defeitos.md`
continuam vivos neste pin, duas atualizações depois:

- `.claude/utils/adopt/seed-adoption-graph.sh:67` — ainda `PIN="$(_f commit)"`, e o carimbo
  grava `source_commit:`. Todo adotante nasce com `pin: (não carimbado)`.
- `.claude/utils/adopt/seed-adoption-graph.sh:82` — ainda com crases **não escapadas** em
  prosa dentro de aspas duplas; o shell executa. (As outras 8 ocorrências do arquivo estão
  escapadas; a da linha 20 é comentário, inócua.)

## Verificação deste sinal

Medido neste repo com os três grafos versionados. Após as reconciliações desta sessão:
integridade e schema **rodados separadamente** saem 0 nos três (`domain` 203 nós/216 arestas ·
`project` 15/17 · `onion-adoption` 5/5).
