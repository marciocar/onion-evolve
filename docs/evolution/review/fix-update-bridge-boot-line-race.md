---
branch: fix/update-bridge-boot-line-race
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (medição do journal da invocação real)
nota: "tokens 0 = não medido: sessão principal, sem subagente; sem família de bancada para o update-bridge (declarado)"
---

# Passada adversarial: `fix/update-bridge-boot-line-race`

## O que muda

O `ops/update-bridge.sh` espera a linha `auth: enforce` no journal da invocação (até ~20 s), em vez de ler o journal uma vez só logo depois do `/health`.

## Achados

1. O 6º deploy de 2026-10-15 saiu rc 1 com um boot são. Medido no journal da invocação: "no ar" às 16:35:08.65 e "auth: enforce" às 16:35:09.29, porque o self-check do JWKS é assíncrono e loga depois do `/health`. O deploy em si foi feito (clone e1e9ea08 = origin/main, serviço ativo, health 200), e o rollback foi só impresso. Curado com espera ativa, no molde da espera do `/health` logo acima.

## Mutantes

Não há família de bancada para o `update-bridge.sh`, porque ele dirige sudo, systemctl e journalctl reais. A prova é o próximo deploy real com bridge mudando. Declarado.

## Limites declarados

- O teto de ~20 s pode não bastar se o IdP estiver lento. Nesse caso o script falha como antes, apontando a mesma linha, e o boot pode ser conferido no journal.
