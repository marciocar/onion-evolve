---
branch: fix/pr-merge-head-pinned
pr: 635
date: 2026-08-19
reviewed_diff_sha256: ede2ff0ba8092aaf16e011f4516918210f9aeddf85afe3de8660d875a12046bf
findings_total: 4
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CONFORME-ANCORA-PROVADA-NOS-DOIS-SENTIDOS-E-UM-FURO-DE-PAGINACAO-CURADO
reviewer: passada adversarial manual (3 ataques dirigidos) + prova positiva/negativa contra o vivo; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `fix/pr-merge-head-pinned`

**Origem:** auditoria pós-merge do #634 achou a corrida — merge às 16:32:55, check-runs do head
final nascidos às 16:32:54; o helper leu os checks do commit **anterior** e mergeou com o CI do
head em `in_progress`. Sem dano (o lint do head passou 42s depois), mas era a porta exata que o
helper existe para fechar. `fix-must-become-mechanism`: a cura entrou no helper, não em disciplina.

## A cura

Âncora ADITIVA no `headRefOid`: `gh api commits/<sha>/check-runs` — zero runs (a janela) → recusa;
run não-`completed` → recusa; `failure/cancelled/timed_out` → recusa. A leitura antiga permanece.

## Achado 1 — paginação truncava a leitura (REAL, curado no mesmo PR)

O ataque *"check-runs paginados?"* achou: o default da API é `per_page=30` — um head com >30 runs
seria lido **parcial**, e um run pendente na página 2 passaria batido (erro para o lado aberto,
o pior lado para uma guarda). Curado com `per_page=100` (máximo observado no repo: 4; folga 25×).
Limite declarado: >100 runs num só SHA voltaria a truncar — cenário sem precedente aqui, e se um
dia existir, a cura é paginar de verdade, não subir o número.

## Os 2 ataques que não acharam nada

- **(a) Fork-PR:** `OWNER_REPO` vem de `headRepositoryOwner`+`headRepository` — o repo do HEAD,
  correto para fork; em PR interno, idêntico ao base.
- **(c) `skipped` reprovaria?** Não: o awk só recusa `failure|cancelled|timed_out`; `completed`
  com `skipped`/`neutral` passa — provado com fixture de uma linha nos dois sentidos.

## Prova

- **Positiva:** a âncora lê os 4 check-runs do head do #632 — todos `completed/success`.
- **Negativa (a janela é real e reproduzível):** o HEAD de `main` (commit de rebase, sem PR) tem
  **ZERO check-runs** — a guarda nova morre com "ZERO check-runs registrados" onde a antiga seguiria.
- Bancada completa no pre-commit (o commit toca `ops/`): verde.
- **Dogfood declarado:** este PR será mergeado pelo próprio helper curado.

## Ressalva declarada

O helper não tem selftest na bancada (é `ops/`, exercitado por uso real e pelo caso `status-factor
(h)` que cobre só a recusa destrutiva). A prova aqui é por execução contra o vivo, positiva e
negativa — não por fixture. Se a classe reincidir, selftest próprio vira o próximo degrau.
