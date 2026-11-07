---
branch: chore/registry-pins-1107
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: f2b5468e36700a56b83766f949e936c3decb325b1512be9ffb1a8105f70747ae
reviewed_code_sha256: 63dd815e3ce51eac4e0f23b070486d081e94201c22aab34137a452bae06c2eb3
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: onion-evolve (sessão principal)
nota: "tokens 0 = não medido; passada feita pela própria sessão, sem revisor independente, porque o diff são 5 linhas geradas pelo registry-pins --seal"
---

# Passada adversarial: `chore/registry-pins-1107`

## O que muda

Cinco linhas `onion_version` do `members.yaml`: brain-granaai, arandek, onion-curation, onion-messaging e
consultoria-analise-de-caso. Todas foram gravadas por `ops/registry-pins.sh --seal`, que só carimba pin lido do remoto.

## Achados

Nenhum. Conferi duas das cinco pelo `gh api` no carimbo remoto (`.claude/.onion-version`, campo `source_commit`):
onion-curation `4e488f2fef65` e onion-messaging `e4c954ebad47` batem com o diff. As outras três vêm da mesma
leitura de remoto do script.

## Mutantes

Não se aplica: nenhum código mudou.

## Limites declarados

- As três linhas restantes (brain-granaai, arandek, consultoria) não foram reconferidas à mão; vale a leitura do script.
