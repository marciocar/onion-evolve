---
branch: chore/registry-pins-2026-10-20
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 0bdb69bc7c8190bbaf9f26342c635db807a9425cf4414842a9abb486f9de11ef
reviewed_code_sha256: dd7a3dce573138ce8dfda662321ffe6af94295d7f98ca24984bc294c8a3477ff
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo o --check antes e depois; sem subagentes
nota: ""
---

# Passada adversarial: `chore/registry-pins-2026-10-20`

## O que muda

Três `onion_version` no `docs/evolution/federation/members.yaml`, gravados pelo `ops/registry-pins.sh --seal`:
- brain-granaai: 0d0636f4ca74 → 59ebe7fe1288 (remoto `onion/develop`);
- sge: ba0d2d423c17 → 6aa5c567f579 (remoto `main`);
- onion-curation: 6687f0d532b8 → 6df1646b8c00 (remoto `main`).

## Achados

1. **Refutado:** "o --seal imprimiu DIVERGE, então não carimbou?" Carimbou: a linha mostra o estado lido antes da
   escrita. O `--check` logo depois dá 20 em dia, 0 divergente e 0 ilegível, e o diff tem exatamente 3 linhas.

## Mutantes

Nenhum: não há código. O `members-validate.sh` aceita (29 membros).

## Limites declarados

O papel de cada membro não muda: o `--seal` só grava o pin, por desenho (#1229).
