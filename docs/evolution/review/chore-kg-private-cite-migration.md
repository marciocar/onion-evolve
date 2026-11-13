---
branch: chore/kg-private-cite-migration
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 56b8db8239140bff77e7482e733753dd3c3aeb65ac4db28c6db355094935856c
reviewed_code_sha256: 6e8573b3798ba4ea7c4d5209591f24199d404fd78ca13437ac8085c208c32144
findings_total: 11
findings_real: 11
findings_blocking: 10
tokens: 0
duration_min: 0
findings_fixed: 11
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador independente do #1648 (3 bloqueios, depois 1 residual na re-refutação), sobre a passada do próprio executor (6 achados)
nota: "tokens e duração não medidos. Achados 1 a 6: passada do próprio executor, que não é independente. Achados B1 a B3: refutador independente, que reprovou a 1ª versão; os três foram curados no mesmo PR."
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
| B1 | (blocking) | sobravam 64 `private-cite:<id>@<commit>` (com `:caminho` ou `/caminho` em parte deles), que devolviam ao grafo o commit do repo privado; o gate não os via | `verified_against` e `method` levam o marcador no valor inteiro (o `method` mantém a classe); na prosa e nos comentários saem o `@sha`, o `:caminho` e o `/caminho`. Os 7 hex soltos que ainda resolviam para commit privado viraram `⟨commit⟩`. O `private-repo-cite-check.sh` ganhou o HARD `MARCADOR-COM-COMMIT`, com o caso (r) e 2 mutantes mortos |
| B2 | (blocking) | `C_CLASSE_NAO_CONFERIVEL_SEM_LEITOR` estava como `refuted`, mas o claim era verdade e deixou de ser (caso DRIFTED do `/meta:kg-freshness`) | o nó antigo voltou ao texto original com `status: superseded`. O nó novo `C_CLASSE_NAO_CONFERIVEL_E_O_MARCADOR_PRIVATE_CITE` ganhou a verdade atual e uma `SUPERSEDES` para o antigo, e cita o PR e o commit da main, não a branch |
| B3 | (blocking) | a catraca da REGRA 121 seguia com 255 entradas para um passivo real de 12 | o `--emit-baseline` a encolheu para 12 |
| B4 | (blocking) | re-refutação: em `E_HISTORICO_DO_REGISTRO_DOS_ADOTANTES` sobravam 2 commits de repo privado, um em `(… <hex>` e outro como argumento de flag. A guarda não os via, e a medida anterior só os conferia contra os repos já citados em cada grafo | os dois viraram `⟨commit⟩`, com o id do nó na tabela privada (e as trocas antigas ganharam o nó que tinham perdido). A guarda passou a acusar todo hex solto na linha do marcador (`(<hex>)`, `/blob/<hex>/`, em qualquer caixa), menos o commit deste repo (o core é público) e `dono/repo@<hex>` da lista pública. Isso trouxe mais 2 linhas: um commit do espelho público da kg-ssot, agora qualificado como `marciocar/kg-ssot@<hex>`, e um slug de workspace, agora `⟨slug de 16 hex⟩`. O caso (r) ganhou fixtures em maiúscula e as duas vizinhas que calam, e 4 mutantes morreram |
| B5 | (blocking) | o 1º CI do PR reprovou na REGRA 121 e no caso (b): a isenção «commit deste repo» lia o git local, que tinha 3 pins do core sem ref remoto (commit de PR squash). O clone do CI não os tem | a isenção passou a valer só para commit alcançável de um ref remoto ou de uma tag, igual ao CI. Os 3 pins são públicos (o GitHub do core os alcança) e foram qualificados como `marciocar/onion-evolve@<hex>`. O caso (r) ganhou a fixture do commit só local, e o mutante que volta ao git local morreu |

## Re-revisão (refutador independente)

Medido depois da cura:
- `private-cite:<id>@<hex>` no corpus: 0;
- hex nas linhas acrescentadas que resolvem para commit de repositório privado: 0. Foram 30 distintos: 26 são commits
  do próprio core, e os outros 4 foram conferidos pela API contra os 28 repositórios privados alcançáveis;
- linhas acrescentadas com padrão privado: 0;
- `--private-repos`: 0 campos;
- REGRA 121: rc 0 no tocado e no `--all`, baseline com 12;
- `kg-gate-ci.sh`: rc 0;
- família `private_repo_cite`: 47 de 47, com o caso (r) ampliado.

Ponto cego da medida: o hex só é conferido contra os repositórios privados que a `gh` alcança (28). Na guarda, a isenção
do commit deste repo lê o git local, e o CI tem a história inteira (`fetch-depth: 0`).

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
