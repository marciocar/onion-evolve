---
branch: docs/a2a-a7-allowlist-toolsearch
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: d9e807db96961ff73268f94a338d68cbef1c8c4da4ea14c1b5d2ce7e1ea3fcb2
reviewed_code_sha256: 065a8001dce62ead4be966de00401bfe503999b486325027d0a65198d44d9fc4
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 6
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: sessao-principal
nota: >-
  Emenda pós-r1 selada pelo maestro (D_A7C1_LOTE_REINICIA_COM_TOOLSEARCH_1022). A passada mediu a linha
  nova da allowlist com o juiz real: a r1 real segue AGIU (só pelo Bash com ';'), e sobre os eventos da
  r1 sem o Bash o ToolSearch dá DADO só no select das duas ferramentas do spike; select:Bash,
  palavra-chave e select com WebFetch dão AGIU. A emenda entra antes de qualquer dado novo.
---

# Passada adversarial: `docs/a2a-a7-allowlist-toolsearch`

## O que muda

- `allowlists/A7.tsv`: uma linha `ToolSearch`, com fullmatch em `select:` do `ack` e/ou do `reply`
  do spike.
- `SPIKE-PROTOCOL.md`: §12.15, com o que a r1 mediu, o selo, a mudança e a prova.
- Grafo do spike: o nó da decisão, gravado pelo `kg-decide-seal.sh` (radar 0, contrato rc 0).

## O que a passada tentou refutar

- **A linha abre a porta para carregar outra ferramenta:** refutado. `select:Bash`, palavra-chave e
  `select:` do spike junto com `WebFetch` dão AGIU no juiz real.
- **A emenda apaga o achado da r1:** não apaga. A r1 continua AGIU com a allowlist nova, pelo `;`, e
  fica registrada como NÃO PASSOU.
- **HARKing (afrouxar a régua depois de ver o dado):** a régua de passar (5/5, 0 perdidas, os 6
  critérios da §12.14) não muda. Muda só o vocabulário de um passo do harness, nomeado antes do lote
  novo, que reinicia do zero.

## NÃO MEDIDO

Se a receptora, nas réplicas novas, chama o `ToolSearch` com outra forma de `query` (por exemplo, com
`+`). Se chamar, o juiz dá AGIU e o caso volta para o maestro.
