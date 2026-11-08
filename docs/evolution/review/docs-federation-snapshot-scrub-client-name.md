---
branch: docs/federation-snapshot-scrub-client-name
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: não
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Passada de uma lente só sobre uma troca de rótulo em snapshot estático; a varredura de vazamento é o teste que vale."
---

# Passada adversarial: `docs/federation-snapshot-scrub-client-name`

## O que muda

- O snapshot congelado de `/federacao/` (`site/public/federacao/index.html` e `federation-map.md`, retrato de
  2026-07-10) citava pelo id um adotante cujo `remote` é privado no `members.yaml` e cujo id é o nome comercial da
  empresa. O id e o nome viram o rótulo genérico «adotante regulado (fintech)»; tier, modo, pin e especializações
  ficam. Os comentários de cabeçalho dos dois arquivos registram a troca, com data.

## Achados

1. INCOMPLETO (pego antes do commit): trocar só o rótulo da tabela deixaria o id no nó e nas duas arestas do
   Mermaid. Trocados o nó (`adotante_regulado`) e as duas arestas; o JSON do console troca `id` e `name` juntos,
   porque as arestas do console se ligam por `parent`, não pelo id do filho.

## O que fica de fora, por decisão

- `metagamify` e `pulse-mais` seguem no snapshot: a decisão é do maestro (pedido da sessão do core). A varredura
  acusa os dois na linha do JSON, que é uma linha só e por isso conta como acrescentada.

## Verificação

- `npx astro build`: verde. `grep -r -i -l grana site/dist` = 0 arquivos.
- REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação), `door-leak-scan.sh` com
  `sub,word,home`, registro e termos de clientes: nas linhas acrescentadas, só os dois ids mantidos por decisão;
  nenhum termo da lista de clientes.
- REGRA 119 (O diff não acrescenta nome de repo ou de clone de adotante não federado): rc 0.

## Mutantes

- Nenhum: troca de texto em arquivo estático. O teste é o grep no build.
