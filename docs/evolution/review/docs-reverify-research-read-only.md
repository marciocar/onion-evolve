---
branch: docs/reverify-research-read-only
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 6
tokens: 135767
duration_min: 9
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador (general-purpose, opus, só leitura)
nota: >-
  Diff só de grafo: 19 nós novos E_REVERIFY_1027_* em 16 grafos de pesquisa, cada um re-medindo no vivo
  um nó cujo method era leitura, mais o teto de 5 grafos subido com a razão no cabeçalho. Tokens e duração
  são os do refutador. As 2 notas menores (aresta do nó de plugins, grep do nó de progress) também foram
  aplicadas.
---

# Passada adversarial: `docs/reverify-research-read-only`

## O que muda

Ordem do maestro de 2026-10-27: o que foi só lido sobre a própria maquinaria se revisa. Cada nó lido
ganha, no mesmo grafo, um nó de evidência com `method: measurement`, `verified_at` 2026-10-27, o comando
e o observado verbatim, e uma aresta ao nó lido: SUPPORTS para CONFIRMED, SUPERSEDES ou CONSTRAINS para
deriva e CONSTRAINS quando só uma cláusula cai. O nó lido não é apagado nem tem o status mudado. Os tetos
de 5 grafos (guard-forge 13→15, hookspath 8→9, keep-current 10→11, passada-adversarial 57→58, r8 20→21)
sobem com a razão escrita.

## O que a passada tentou refutar

Um refutador novo, que não viu o meu raciocínio, re-mediu os 19 nós. Achados:

1. **REPROVA.** O nó do bridge dizia UNVERIFIABLE (o checkout do serviço nega leitura), mas existe um
   checkout de dev legível com o commit fixado. Curado: o código foi medido e o veredito passou a CONFIRMED
   (context.ts igual entre c91374da e a main de lá), com SUPPORTS.
2. **EMENDA.** keep-current: a cláusula "o fechamento rebaseia" não derivou, era falsa ao nascer (o
   `--rebase` é opt-in desde 842597dd8, anterior ao nó). Curado: o veredito passou a REFUTED da cláusula,
   com aresta CONSTRAINS, porque o resto do teto se sustenta.
3. **EMENDA.** radar 09-03: a conta "3 declarações model: em comando" errava. As 4 linhas são do template
   e de um exemplo, e em comando invocável há zero. Curado.
4. **EMENDA.** triagem: o locator do radar apontava a l.8 (RADAR); a lista de INTEGRIDADE segue na l.27.
   Curado.
5. Nota: no nó de plugins, o centro (os 531 refs) não foi medido, então SUPERSEDES dizia demais. Virou
   CONSTRAINS.
6. Nota: a frase do grep dos capabilities.tsv no nó de progress foi corrigida.

O lint achou mais um, HARD: a narrativa do nó da faixa citava o marcador literal do mutante, e a guarda
`mutante-esquecido` o tomou por mutante plantado. Curado com a descrição no lugar do marcador.

O contrato KG-SSOT do commit (o passo 4 do pr-finalize, o mesmo do CI) achou 3 códigos novos sem termo
na prosa: `E3` em dois nós e `F4` em outro. Curado escrevendo o nome por extenso (o eixo do ecossistema
Claude Code, a 4ª fase das portas); a forma `radar:E3` também reprovou, porque o esquema não resolve.

A REGRA 89 (Rodada de radar selada reconcilia o corpus que superou (Aufhebung), com catraca) também
pesou numa escolha. Um SUPERSEDES no radar-E3-2026-09-03 tirava a rodada da dívida (5→4) sem ela ter
reconciliado nada. A aresta virou CONSTRAINS e o total voltou a 5, igual ao baseline.

## NÃO MEDIDO

- Os 531 refs de comando no bundle montado dos plugins: medir exige um ensaio do `ops/publish-door.sh`.
- O log "4 servers 24 tools" do LibreChat, que mora no host do serviço.
- As lacunas 2, 3, 4 e 6 do radar E3 de 2026-09-03: pedem sessão nova e o runtime.
- O serviço vivo do bridge: foi medido o código, não o 403 servido.
