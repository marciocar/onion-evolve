---
title: 'Resíduo — o sinal apontou um caso, a varredura achou 9 de 19'
date: 2026-09-15
branch: fix/adopter-gate-hookspath-string-compare
reviewed_diff_sha256: acae318dc1bdb1987e1496c6a9c8686cb54916035a63bb0de7f422ad9385000d
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  O refutador foi um ADOTANTE. Ele mediu que não estava no registro da federação, depois de ser
  adotado e receber o relatório, e reportou por sinal de campo. Nenhum gate desta casa havia acusado
  — e ao mecanizar a verificação o número saltou de 1 para 9 de 19.
---

# A guarda que faltava perguntava pelo que DEVERIA estar lá

## O achado, e ele veio de fora

Um adotante escreveu ao core: foi adotado em 2026-09-15, recebeu o relatório no `inbound/`, e
**nenhuma entrada do `members.yaml` apontava para o `local_path` dele**. Instalar e registrar são
passos independentes, e o segundo é **esquecível sem consequência visível** — a definição de falha
silenciosa.

## Por que nenhum gate acusou, e é a lição

A reconciliação `outbox × inbound` do `/meta:co-evolve` cruza `outbox/<id>/_processed/` contra o
`inbound/` do alvo. Para um membro que **não existe** no registro, não existe `outbox/<id>/` — então o
`comm -13` compara **dois conjuntos vazios** e sai limpo.

> Toda guarda desta casa pergunta pelo que **está**. Esta precisava perguntar pelo que **deveria
> estar** — e para isso precisou de uma fonte independente: o disco.

A lição de campo de 2026-07-21 (7 anúncios entregues no checkout errado) tinha uma **irmã não
coberta**: o anúncio que não vai para checkout nenhum.

## A consequência concreta

Sem entrada no registro, o core não resolve o `--target` do `/meta:co-deliver`. Todo anúncio futuro do
CHANGELOG fica **sem destinatário** — e o adotante segue verde, porque o hook dele conta o que
**chegou**, não o que deveria ter chegado.

## O número que a mecanização revelou

O sinal apontou **um** caso. A varredura apontou **nove**:

```
19 adotantes no disco (stamp .onion-version, role != source)
 9 FORA do registro — 47%
   resíduo: onion-pedro-old · onion-pedro-hub-bak · onion-adopt-granaa-ai (worktree)
   reais:   aura · gustavo-pulga · rhilo-metagamify · poc-venda-direta-pdi
            venda-direta-pdi · venda-direta-pdi-entrega
```

Um caso é descuido; 47% é **classe**. E a distinção entre "lixo a podar" e "registro a fazer" exige
julgamento (NDA, id, papel) — por isso o mecanismo **mede e não corrige**.

## Um mecanismo, dois pedidos do sinal

O sinal pedia (2) o `/meta:adopt` registrar como parte da adoção e (3) uma guarda de cruzamento. São a
mesma falha vista de dois pontos, e um helper cobre os dois:

- `check-member-registered.sh` — chamado **no fim do `/meta:adopt`**, o instante em que a informação
  existe e é esquecível. Compara **caminho canônico**, não string: `~/x`, `/home/u/x/` e `/home/u/./x`
  são o mesmo alvo, e registro correto não pode ser lido como ausente por uma barra a mais.
- `ops/audit-adopters-registry.sh` — o parque inteiro, para quem já driftou.

**Avisa, não aborta** (`rc=3`): a adoção está correta e completa; o que falta é um ato de **registro**,
que envolve julgamento humano. Abortar puniria o alvo por pendência do core.

## Por que `ops/` e não regra do lint

Porque a varredura depende de `$HOME`, e uma regra HARD assim **reprovaria no CI**, onde
`/home/marcio` não existe. Guarda que só passa na máquina de uma pessoa não é guarda — é armadilha
para todo mundo. Fica core-only, como o `verify-adopter-gate.sh`.

## Detalhe de desenho que o dogfood impôs

O marcador de adotante é o **stamp** (`.claude/.onion-version` com `role != source`), não o nome do
diretório. Nome de pasta é declaração; o stamp é o que o transporte escreveu — e foi assim que
worktrees de adoção (`onion-adopt-*`) apareceram corretamente na lista em vez de serem ignoradas por
convenção de nome.

## Gate

```
dogfood no vivo : 19 adotantes varridos, 9 acusados (rc=3)
radar/integrity : exit 0 (36 nós)
REGRA 5         : adopt.md em 800 linhas (no teto, sem crescer)
commit          : SEM --no-verify
```

## O que fica ABERTO, e é do maestro

Registrar os 9 — ou podar os que são resíduo. Exige julgamento que o mecanismo não tem: quais são
lixo, qual id, e **nome neutro** para os que forem de cliente sob NDA.
