---
branch: docs/close-settings-sandbox-q
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 6134f451e8cf7c51f95d43d2015f582e9897a41b81ed70e07c77e69a9b0e8bfc
reviewed_code_sha256: f03c9e68a0446084e5b63f51bda3962ca21b2922ddc2834bdfe6e29ca46f5fa7
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 6
findings_fixed: 1
verdict: FIXED
elenxo: true
reviewer: sessão do core (passada própria, refutando a afirmação central)
nota: "tokens 0 = não medido; passada feita pela sessão que escreveu, contra a medição no git"
---

# Passada adversarial: `docs/close-settings-sandbox-q`

## O que muda

Fecha `Q_MD_SETTINGS_UPDATE_UNDER_SANDBOX_1108` com a evidência `E_MD_SANDBOX_UPDATE_1552_MEASURED_1112`, que junta a medida da curadoria (escrita negada e reset e restore por SSH) ao vínculo medido no core entre o pin aplicado e o #1552.

## Achados

1. **Real, corrigido.** A primeira redação dizia que `04fb54e37129` era o "commit de merge" do #1552. Medido: o merge foi por rebase; o commit é a ponta do PR na main (`gh pr view 1552 --json mergeCommit`) e não muda o `settings.json`. As entradas do deny (filter-branch, rm recursivo da raiz, leitura de `.env`) nasceram nos sete commits do PR, conferido pelo diff do `settings.json` desde o pai do primeiro deles. A narrativa e o `verified_against` foram reescritos assim.

## Mutantes

Não se aplica: mudança só de grafo, sem código. O radar `--integrity --schema` e o contrato ficam em 0 depois da correção.

## Limites declarados

- A metade da curadoria (a escrita negada sob o sandbox) é relato da sessão dela, registrado como nó no grafo de lá; o core não reproduziu o sandbox.
