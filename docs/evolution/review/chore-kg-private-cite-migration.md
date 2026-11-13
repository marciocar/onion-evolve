---
branch: chore/kg-private-cite-migration
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: ac801339416b99b9619e7886d8ddd3f4b1c7af6e2b7b1fc890d9077dc0fc9c51
reviewed_code_sha256: 9cfbeb64b35b9759181e5fe1d922af34efca7df70c75edbfd9bd3f0368dfc2df
findings_total: 6
findings_real: 6
findings_blocking: 5
tokens: 0
duration_min: 0
findings_fixed: 6
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: passada adversarial do próprio agente executor, sem subagente (o brief proíbe spawnar), contra o contrato v4.22 e os gates
nota: "tokens e duração não medidos. A passada não é independente: quem migrou é quem revisou, e cada achado foi pego por um gate ou pela leitura do contrato, não por um segundo leitor."
---

# Passada adversarial: `chore/kg-private-cite-migration`

## O que muda

- Os grafos do corpus que citavam um repositório privado passam a citá-lo pelo marcador `private-cite:<id>` do
  contrato v4.22 (kg-ssot 4.51.0). Cada id saiu do `kg_trace.py private-cite-id`, um por citação, contada por nó e por
  repositório (203 ids). No `source` e no `locator`, o marcador substitui o valor inteiro. No `trace`, a forma é
  `private-cite:<id>#<id de nó>` quando havia um nó depois do `#`. Na prosa e no detalhe do `method`, só o nome muda.
- A resolução (id → repositório, commit, caminho, valor original) está numa tabela privada do dono, fora de todo
  repositório. Nenhum valor dela entra no core.
- A gramática (`.claude/rules/kg-grammar.md`) e o conselho do aviso da REGRA 121 passam a prescrever o marcador no
  lugar da classe em texto.
- `C_CLASSE_NAO_CONFERIVEL_SEM_LEITOR` fecha como `refuted`, por medição.

## Medido

| | Antes | Depois |
|---|---:|---:|
| `--private-repos` do porte (campos, 262 grafos) | 318 | 0 |
| `kg_gate.py --private-repos` (campos) | 313 | 0 |
| Nós com achado | 195 | 0 |
| Passivo da REGRA 121 | 255 | 8 |
| `provenance.source` com a classe em texto | 1 | 0 |
| `provenance.source` / `trace` contados como `private-cite` pelo `kg_trace.py` | 0 / 0 | 123 / 73 |

O `kg-gate-ci.sh` dá rc 0, e nenhuma linha adicionada no diff cita um padrão do arquivo privado (conferido por
contagem, sem ecoar nada).

## Achados

| # | Triagem | Achado | Cura |
|---|---------|--------|------|
| 1 | (blocking) | o `locator` real ficava no grafo quando só o `source` casava um padrão; o contrato manda o marcador nos dois | 112 locators trocados pelo marcador do `source` do mesmo nó |
| 2 | (blocking) | um nó com o marcador ainda tinha `provenance.node_sha256`, o hash adivinhável que o contrato tira | removido, com o valor guardado na tabela privada |
| 3 | (blocking) | `provenance.scheme: kg-node` com o `locator` virando marcador: a dívida do contrato subia (`form.pattern.node.provenance.locator` 0 → 1) | o `scheme` saiu, porque não há mais locator real para descrever |
| 4 | (blocking) | o marcador é mais longo que o nome, e um `label` passou de 280 caracteres (`form.range.node.label` 2160 → 2161) | o label foi encurtado sem mudar a afirmação |
| 5 | (blocking) | o `--touched` do gate acusou `integrity.bare-decision` numa decisão que a troca tocou | a decisão ganhou `narrative` com o porquê |
| 6 | (non-blocking) | a REGRA 121 viu 3 citações `nome (sha)` com o nome nu, nos nós tocados | o nome virou o marcador do nó |

## Limites declarados

- **Nome nu.** As menções a um repositório privado sem dono e sem `@` seguem como estão: cerca de 1600 nos grafos e
  3657 fora deles (em 967 arquivos). Nenhum padrão sem espaço as expressa, e elas fazem parte da narrativa pública do
  projeto. Migrá-las é outra decisão.
- **Valor inteiro.** No `source`, no `locator` e no `trace`, o valor inteiro vira marcador, e o que era público junto
  (um script do core, o host) sai do grafo. O original fica na tabela privada.
- **Valor com dois repositórios.** Dois valores inteiros citavam dois repositórios privados; cada um levou um marcador
  só, e a tabela guarda os dois.
- **Trace em forma de comando.** 11 traces com um comando (`grep … repo@sha:caminho`) viraram o marcador inteiro.
- **Ids depois do `#`.** Os 14 ids de nó de grafos privados que vinham depois de um `#` não foram renomeados. Nenhum
  contém um nome de cliente ou de repositório privado (conferido contra as duas listas privadas do dono). Só 2 ficam
  no grafo, no `trace`: `D_DESIGN_SETUP_PROPOSAL` e `C_WAVE1_WITH_GRAPH`. Os outros 12 estavam em `source` ou `locator`,
  que viraram o marcador inteiro.
