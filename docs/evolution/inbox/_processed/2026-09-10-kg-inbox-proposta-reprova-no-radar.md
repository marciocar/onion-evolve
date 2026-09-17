# Sinal ao core — uma proposta de UM nó em `kg-inbox/` nunca passa no `kg-radar`, e o CI a pega

Data: 2026-09-10 · Origem: jogo-da-vida (`perf/icons-and-inp`) · Tipo: contradição entre dois contratos do framework

## O que aconteceu

O nó `A_OPS_INP_HML_MEASURE` mandava "abrir fio se INP > 200 ms". O gatilho disparou. Como quem mede não sela, escrevi a
proposta onde o `docs/evolution/kg-inbox/README.md` manda — `inp-3g-above-200ms.proposal.kg.yaml`, com `meta.target` — e rodei
o radar antes de commitar:

```
$ bash .claude/validation/kg-radar.sh docs/evolution/kg-inbox/inp-3g-above-200ms.proposal.kg.yaml --integrity --schema
══ INTEGRIDADE ══
  ✗ nó órfão (grau 0): A_OPS_INP_3G_ABOVE_BUDGET
EXIT: 1
```

Não é o meu arquivo que está mal formado: é **estrutural**. A integridade do radar exige grau ≥ 1 em todo nó
(`kg-radar.sh`, `if (deg[id] == 0) { print "  ✗ nó órfão (grau 0): " id; problems++ }`), e uma aresta precisa de dois nós **no
mesmo arquivo**. Uma proposta de um nó só — que é o caso comum, e o que o README descreve — **nunca** pode passar. A alternativa
seria duplicar no arquivo de proposta o nó-alvo que já existe no grafo, o que cria um id duplicado entre arquivos.

O que torna isso um problema de verdade e não um detalhe: o job `kg-radar` do `ci.yml` deste repo (gerado na adoção) roda sobre
**todo** `.kg.yaml` versionado que não esteja em `fixtures/` —

```yaml
for g in $(git ls-files '*.kg.yaml' | grep -vE '/(__)?fixtures(__)?/'); do
  bash .claude/validation/kg-radar.sh "$g" --integrity --schema
```

— então commitar a proposta pelo caminho documentado deixa o CI **vermelho** até o dono selar. O contrato "proponha em
`kg-inbox/`" e o contrato "todo `.kg.yaml` versionado passa no radar" se contradizem.

Contornei entregando o nó pronto-para-colar num bloco YAML dentro de `docs/evolution/review/perf-icons-and-inp.md`. Funciona,
mas joga fora o que a fila existe para dar: um artefato tipado que `/meta:kg-inbox` sela sozinho.

## Pedido ao core

1. Isentar a fila do gate de órfão — o radar podia reconhecer `meta.target` (ou o sufixo `.proposal.kg.yaml`) e rodar em **modo
   proposta**: valida schema, tipos, planos e ids, mas não exige grau ≥ 1 nem resolve arestas para fora do arquivo.
2. Ou, se a fila deve mesmo ficar fora do gate, dizer isso no `ci.yml` que a adoção instala — acrescentando `kg-inbox` à
   exclusão do `git ls-files`, como já se faz com `fixtures/`.
3. Seja qual for a escolha, o `README.md` da `kg-inbox` deveria mostrar **um exemplo que passa no radar**. Hoje ele descreve o
   formato e o fluxo, mas nenhum arquivo de exemplo existe (`_sealed/` e `_rejected/` estão vazios neste repo), então o primeiro
   a usar a fila descobre o conflito por reprovação.

## Evidência

- `.claude/validation/kg-radar.sh` — regra de órfão na seção INTEGRIDADE
- `.github/workflows/ci.yml` — job `kg-radar`, varredura por `git ls-files '*.kg.yaml'`
- `docs/evolution/kg-inbox/README.md` — o fluxo proposto
- `docs/evolution/review/perf-icons-and-inp.md`, item 18 e a seção "Nó novo, pronto para selar" — o contorno
