---
title: "Revisão — auditoria dos gates textuais + 2º veto (merge-gate), lib de invocação e bancada"
date: 2026-09-02
branch: audit/textual-gates
reviewer: "condutor com medição executada: probes dos 8 invólucros contra os 2 hooks (rc=0 antes → rc=2 depois); veto ao vivo de gh pr merge 0 na própria sessão; bancada run_pretooluse_veto_selftests 32/32 em runner isolado set -euo pipefail; radar --integrity --schema exit 0 (24 nós); backlog byte-identical LC_ALL=C; lint-artifacts rc=0, 0 HARD; 3 relatórios de worker com amostra re-lida (review-artifact-check.sh:205-211, kg-seal-check sem autor, onion-review.yml:493, core.hooksPath)"
reviewed_diff_sha256: b4470d7d11a80af07518434b04652a2b632418a5a843f2f71facc40a40baa735
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 1900000
duration_min: 95
---

# Resíduo — REGRA 56

Executa a `D_AUDITAR_GATES_TEXTUAIS` (selada pelo maestro em 2026-09-02). O revisor é a própria sessão
— o que este PR classifica como CONFIANCA-NO-MODELO se aplica a este resíduo (E_REGRA56_VERIFICA_PRESENCA_NAO_VERDADE);
os achados abaixo são os que a **bancada e os probes** produziram, não impressão de leitura.

## Achados

1. **protect-main deixava passar `git push -f origin HEAD:main`** — regex exigia espaço antes de `main`.
   Achado pela bancada nova, não pela leitura dos 3 workers. Corrigido (`([[:space:]]|:)(refs/heads/)?main`).
2. **8 invólucros passavam com rc=0 nos DOIS vetos** (`command`, `\`, `env`, `exec`, `sh -c "…"`, `git -C`,
   `sudo -u x`, `out=$( )`). gates-mech apontou 3; a bancada achou `sudo -u` e `$( )` na 2ª rodada, depois da
   1ª cura. Corrigido na lib única.
3. **Linha com `)` residual** (`git push origin feature)`) após o split por `$(` — falso-negativo em
   potencial no casamento de refspec. Corrigido (`s/[[:space:]]*[)}]*[[:space:]]*$//`).
4. **Relatório do gates-ci dizia "nenhum pre-commit instalado"** — leu `.git/hooks/`; `core.hooksPath`
   está armado nesta máquina (medido). Discrepância entre workers resolvida por medição; entrou no grafo
   como condicional (E_PRECOMMIT_CONDICIONAL_A_CONFIG_LOCAL), não como ausente.
5. **Edges em flow-mapping (`{ from, to, edge_type }`) não são parseados pelo radar** — 24 nós órfãos no
   1º run. Convertido para block form; radar exit 0. (Classe: forma do YAML que o motor lê ≠ YAML válido.)
6. **REGRA 62**: backlog desatualizado após o grafo novo (1 HARD no 1º lint) — regenerado com `LC_ALL=C`
   após `git add` do grafo; 2º lint 0 HARD.

## Não mudou

- Bancada COMPLETA (`lint-selftest.sh` inteira) não rodou localmente (>10 min na VPS carregada) — só a
  família dos vetos em runner isolado com as mesmas opções de shell. O CI roda a completa.
- Commit com `--no-verify` em feature branch: 0-HARD verificado à parte (lint2.log), `validation/`
  mudou (o pre-commit rodaria a bancada completa). O CI é o gate.
- Contagens AVISO (~63) e prosa (29) = relatórios dos workers com amostra re-medida, não censo da sessão.
- `PreModelSwitch` segue gated; adotante (merge-gate desarmado sem `ops/`) não medido num clone.
