---
branch: fix/merge-verified-repo-without-ci
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: ff5ba9090c1b1152150d32053269b5ed7aeebb51a76bd80e24a9341db2a039f4
reviewed_code_sha256: 16fa79f267aec4b47318c8e4024bb9ab166da18b4284927246228ae0cfb17580
findings_total: 6
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 25
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido."
---

# Passada adversarial: `fix/merge-verified-repo-without-ci`

## O que muda

- `ops/pr-merge-verified.sh` separa três estados quando o head do PR tem ZERO check-runs (SAC-302), pela
  sonda `actions/workflows` (`total_count`, lida uma vez):
  1. **leitura falhou** (rc da API ≠ 0, ou `total_count` ilegível): recusa nomeada, fail-closed;
  2. **repo sem workflow** (`total_count` 0, lido): modo declarado "repo sem CI". Exige que a árvore de onde o
     comando roda seja o clone do repo do PR (origin = alvo), esteja NO head do PR e sem mudança rastreada; roda
     o gate local (o do Onion, `lint-artifacts.sh` + `lint-selftest.sh`, o mesmo do `--ci-inoperante`; sem ele,
     o `ops/local-gate.sh` que o repo declara; sem nenhum, recusa); registra no PR, ANTES do merge, que não havia
     CI e o que foi exercido. Nunca vale para o core (alvo = origin do próprio script, ou árvore com
     `ops/pr-finalize.sh`);
  3. **repo com workflow** e zero check-runs: o ramo de antes (espere / `--ci-inoperante`).
- O auto-rebase não espera runs que nunca nascem num repo sem workflow.
- O `--ci-inoperante` separa rc de vazio no `gh run list`: zero runs lidos é "nenhum run", não "não consegui
  LER" (era a mensagem enganosa do defeito).
- O corpo do gate local virou a função `_run_local_gate`, usada pelos dois caminhos sem CI.
- Bancada: (nc1)–(nc8) com os três estados, gate vermelho, árvore fora do head, sem gate / gate declarado,
  core, e o `--ci-inoperante` com zero runs; mutantes (ncm1) trata 2 como 1, (ncm2) aceita 2 sem gate local,
  (ncm3) aceita 3 como 2, todos mortos; (ncm0) a cópia limpa no mesmo arranjo sobrevive aos três matadores.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o gate local do `--ci-inoperante` roda na árvore de quem chama, em qualquer commit: no modo novo isso julgaria outro commit ou outro repo | real | curado: origin = alvo, HEAD = head do PR e árvore limpa, cada um com recusa nomeada e caso (nc5) |
| 2 | rodar do clone do core com `--repo <adotante>` cairia no teste "a árvore tem `ops/pr-finalize.sh`" e diria "nunca vale para o core", diagnóstico errado | real | curado: a checagem de origin vem antes da do motor do core |
| 3 | o bridge não tem `.claude/validation/`: só com o gate do Onion ele seguiria travado | real | curado: o gate declarado do repo (`ops/local-gate.sh`, rc 0 = verde), com caso (nc6) |
| 4 | o `gh run list` vazio com rc 0 virava "não consegui LER" (o sintoma exato do SAC-302 no escape) | real | curado: rc e vazio separados, caso (nc8) |
| 5 | o PR pode alterar o próprio gate (`lint-artifacts.sh`, `ops/local-gate.sh`) e se aprovar | limite | declarado: o registro no PR nomeia o arquivo de gate que o PR altera. No CI de `pull_request` vale o mesmo (o workflow do head roda) |
| 6 | repo com workflows todos DESATIVADOS lê `total_count` > 0: cai no estado 3 e espera para sempre | limite | não curado: fora do escopo medido; o `--ci-inoperante` também não cobre (não há `startup_failure`) |

## Teto

- O gate do modo "repo sem CI" é o que o repo tem. No adotante é o lint e a bancada vendorizados; no bridge
  será o `ops/local-gate.sh` que ele declarar. O script mede o rc, não a qualidade do gate.
- A revisão semântica não é medida em repo sem CI (não há `onion-review-verdict`); o registro no PR diz isso.
