---
branch: fix/merge-no-ci-workflow-in-tree
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: d217a15166545649c75588b2f72b1a3a47ac0ad02bcc5f74590927ae7863557b
reviewed_code_sha256: fa135903d1ab8ae490ffb751bc6f77cdedcebc3d0df7c2ace3366405d15cf2fa
findings_total: 4
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução (passada própria, não independente; o brief proibiu criar agentes)"
nota: "tokens 0 = não medido. Família pr_merge_verified 86/0 com 7 mutantes contados vivos e mortos; com a cura revertida, nc9, nc10 e nc11 reprovam."
---

# Passada adversarial: `fix/merge-no-ci-workflow-in-tree`

## O que muda

- A separação dos três estados (SAC-302) já estava na main desde o PR #1526. Este PR cobre o que sobrou.
- Zero workflows lido com workflow versionado no head é "CI que ainda não rodou": recusa nomeada. Antes do
  corte, o PR que cria o 1º workflow mergeava como "repo sem CI" e o registro afirmava que não havia CI.
- No modo "repo sem CI", o `ops/local-gate.sh` VERSIONADO vence o gate vendorizado. O `--ci-inoperante` não
  muda: segue julgando pelo gate do Onion. A recusa da bancada vendorizada nomeia esse caminho.
- O harness de mutante passa a usar ENVIRON e a exigir `bash -n`. Com `awk -v`, a barra final da troca sumia.

## Achados

| # | Achado | Veredito | Destino |
|---|---|---|---|
| 1 | `git status --untracked-files=no` não vê arquivo solto: um `ops/local-gate.sh` não rastreado venceria a bancada | real | curado: só o arquivo versionado vence (nc13, ncm7) |
| 2 | o glob `*` do pathspec casa `/`, e arquivo em subpasta de `.github/workflows` não é workflow | real | curado: `:(glob)` |
| 3 | o (ncm1) antigo morria porque o mutante não parseava: o `awk -v` comia a barra final | real | curado: ENVIRON e `bash -n` antes de contar a morte |
| 4 | repo com as Actions desligadas e workflow no head fica sem caminho até ligar as Actions ou tirar o arquivo | limite | a recusa diz os dois caminhos; não medi se a API lista zero nesse caso |

## Teto

- O gate que o adotante declara é o que ele declara: o script mede o rc, não a qualidade. O registro no PR
  nomeia qual gate rodou e avisa quando o PR altera o próprio gate.
- O PR #2 do adotante de consultoria segue aberto: `ops/local-gate.sh` não existe lá (404 medido em
  2026-11-09), e criá-lo é ato da sessão do adotante. Não foi exercido contra o adotante real: a bancada usa o `gh` de mentira.
- Causa de fundo não curada aqui: a bancada vendorizada não é satisfazível no adotante (medida no PR #1526).
