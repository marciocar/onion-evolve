---
branch: fix/pr-finalize-accepts-reviewer-exemption
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 1667a0f57a2cc22111e8038f5bf95877b03c5f9cb2f42b33810da1b8d8806f18
reviewed_code_sha256: a3bbffd153945d93cab488052bbbef22d171304aacdd28913edf4687f6c06008
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com mutante; sem subagentes
nota: ""
---

# Passada adversarial: `fix/pr-finalize-accepts-reviewer-exemption`

## O que muda

O `_restamp` do `ops/pr-finalize.sh` passa a reconhecer a isenção `PR-edita-o-proprio-revisor(ovo-galinha)`,
que o `review-artifact-check.sh` declara para o PR cujo diff é exclusivamente `.github/workflows/onion-review.yml`.
Com ela, o motor não carimba nada, diz isso e segue. O caso (ovo) na família `review_artifact` prende o par ao
mesmo rótulo.

## Achados

1. **REAL (a causa):** ao subir o pin da action do revisor para v1.0.254, o `pr-finalize` parou com "a guarda do
   resíduo não deu hash nem ✅ no contexto de PR: ⊘ fora de escopo: PR-edita-o-proprio-revisor(ovo-galinha)".
   As duas guardas desencontravam: uma isenta e a outra exige. O pin anterior (v1.0.253) só passou porque viajou
   num PR com outros arquivos, e aí a isenção não se aplicava.
2. **REAL (curado antes do commit):** a 1ª inserção do caso (ovo) caiu na função errada. A família não o
   imprimia, nem verde nem vermelho: o `_family` dessa família fica longe da função. Movido para o fim de
   `run_review_artifact_selftests` e conferido que aparece.
3. **Refutado:** "a isenção abre um buraco?" Não abre. Ela só vale com o rótulo exato que a guarda emite, e a
   guarda só o emite quando o diff é exclusivamente o workflow, o que já foi apertado antes (o caso de 52
   arquivos). Qualquer outro "fora de escopo" segue recusado.

## Mutantes

O rótulo no motor divergindo do da guarda faz o caso (ovo) reprovar (morde). Família `review_artifact`: 18/18.

## Limites declarados

O caso é estrutural, no mesmo molde dos casos do pr-finalize na bancada. A prova de comportamento é o PR do pin
v1.0.254 passar pelo caminho novo depois deste merge.
