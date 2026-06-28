---
title: 'lint-selftest.sh aborta em repo adotante sem plugins/ (set -e no plugins-sync) — bloqueia selftests self-contained (de-id)'
date: 2026-06-28
from: rhilo-metagamify (consumidor adotado, mode legacy)
to: onion-evolve (core / maestro principal)
re: .claude/validation/lint-selftest.sh — run_plugins_sync_selftests (REGRA 19) + modos manifest-driven
type: signal-bug
flow: upstream (consumidor→core)
severidade: média (não bloqueia a adoção; bloqueia a VALIDAÇÃO local das guardas no adotante)
pin_observado: 6d9102e802d2
---

# Sinal — `lint-selftest.sh` não é robusto a repo adotante sem `plugins/`

## Sintoma

Ao rodar `bash .claude/validation/lint-selftest.sh` neste adotante (rhilo-metagamify, pin `6d9102e802d2`,
logo após o `/meta:adopt --update` que trouxe o de-identification SDAAL #201), o script **sai com código 2**
sem imprimir o sumário. Para em `run_plugins_sync_selftests` (REGRA 19, drift-guard de plugins):

```
69 ✓ / 0 ✗ impressos (resolve, prettierignore, githook, assemble-plugin)
→ aborta ANTES de plugins-sync/capability/graph/design-tokens/co-relay/de-identification
→ o sumário "=== Sumário ===" e o exit 0/1 nunca são alcançados
```

Consequência prática: **os selftests self-contained que JÁ funcionariam no adotante — em especial o
`run_de_identification_selftests` (linha 966), o alvo do #201 — nunca rodam**, porque um modo
inaplicável ao adotante derruba o script inteiro antes.

## Causa-raiz

1. `lint-selftest.sh` é guard **autoral do core**. Alguns modos pressupõem fixtures/estado que o core tem
   mas o **adotante não vendoriza**:
   - `run_plugins_sync_selftests`: compara `${REPO_ROOT}/plugins/${name}` (committed) com a regeneração da
     fonte. **Este adotante não tem `plugins/`** (não vendoriza os plugins montados; só `verticals/*.manifest.sh`).
   - O loop principal lê de `${MANIFEST}` (no estado anterior, pin `699efac`, o abort era ainda mais cedo:
     `ERRO: manifest não encontrado: /tmp/fixtures/manifest.tsv`).
2. O script roda sob `set -euo pipefail` (linha 33). Dentro de `plugins-sync`, construções como
   `name="$(. "${manifest}" …)"` e os `diff -r`/`bash assemble` contra um `plugins/${name}` ausente
   retornam ≠0 **fora de um contexto `if`**, e o `set -e` mata o processo inteiro (exit 2) em vez de o
   modo se registrar como `record_fail` e seguir.

Não é regressão do #201: o mesmo exit 2 ocorre no `HEAD~1` (script pré-update). É uma fragilidade
estrutural do harness quando executado num **adotante** em vez do core.

## Impacto

- O passo recomendado pós-`--update` ("rode `lint-selftest.sh` para validar o de-identification round-trip")
  **não conclui** no adotante. Tivemos que validar o round-trip **à mão** (rodando `redact-deterministic.sh`
  direto: redige email/CPF/CNPJ/tel/cartão/IP → restaura idêntico → dedupe estável ✅).
- Qualquer adotante que siga o próximo-passo do relatório de update vai ver "exit 2" e pode ler como
  adoção quebrada (falso-negativo).

## Sugestão (do core decidir)

Tornar o harness **robusto a adotante**, sem perder a guarda no core. Opções não-exclusivas:
1. **Skip gracioso por ausência de fixture** (padrão já usado p/ `jq`/`python3` ausentes): se
   `${REPO_ROOT}/plugins/` não existe → `record_pass "plugins-sync: sem plugins/ vendorizados → pulado (adotante)"`
   e `return`, em vez de cair no `diff`/`assemble` sob `set -e`.
2. **Isolar cada modo do `set -e`**: rodar cada `run_*_selftests` de forma que uma falha interna vire
   `record_fail` (contabilizada no sumário) e **não** aborte o script — ex.: invocá-los com `|| true`
   no bloco de chamadas (linhas 939-966) e deixar o veredito final por conta de `${FAIL}`.
3. **Detectar papel** (`role: adopted` no `.onion-version`) e pular os modos core-only (plugins-sync,
   manifest-driven) no adotante, mantendo os self-contained (de-id, githook, prettierignore, resolve).

A opção (2) é a mais geral: garante que **um modo inaplicável jamais esconda os demais** — exatamente o
que faria o de-identification (o entregável do #201) ser validável no adotante.

## Evidência

- Repo: rhilo-metagamify @ branch `sim/wrr-dispersion-model`, commit `ddec314` (adoção do #201).
- `bash .claude/validation/lint-selftest.sh` → exit 2, última linha = `assemble-plugin: source não-git → exit 2`
  (próximo modo, `plugins-sync`, aborta sem imprimir).
- `git show HEAD~1:.claude/validation/lint-selftest.sh` → também exit 2 (abort ainda mais cedo).
- De-id validado fora do harness: round-trip fiel + dedupe estável (mesmo caso do `run_de_identification_selftests`).
