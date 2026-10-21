---
branch: docs/radar-e3-r15
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: bb774fabe4b32c892d41b8a8ec70877f2f309cfe9315b857f2b9666be119799e
reviewed_code_sha256: fd651a847b565b42f556475e8ad32088b413ead0fe0594fbc5eb1a5a13d73766
findings_total: 4
findings_real: 4
tokens: 160960
duration_min: 15
findings_fixed: 4
verdict: CORRIGIDO
elenxo: sim
reviewer: juiz da rodada (subagente opus/high pedido pela sessão; modelo declarado)
nota: "4 = 3 EXAGERA + 1 REPROVA, todos reescritos ou rebaixados; mais a Aufhebung esquecida da pergunta da r14, curada"
---

# Passada adversarial: `docs/radar-e3-r15`

## O que muda

- A rodada r15 do radar E3: 13 nós, a SYNTHESIS e o `data/`.
- Três nós da r14 viram `superseded`.
- A baseline do E3 em 2.1.307.

## Achados

1. O aviso de teto do WebSearch foi atribuído à 2.1.307, mas existe desde a 2.1.304, lido no binário.
   Reescrito, com o nó e a pergunta reancorados.
2. O painel do decide lê pelo ArtifactData, não pela leitura do Artifact. Rebaixado para impacto 1.
3. O servidor MCP do SDK não tem consumidor (REPROVA). Rebaixado para impacto 1 e reescrito.
4. A pergunta da r14 presa ao pin v1.0.256 não tinha sido superada. Curado com uma pergunta nova no v1.0.257
   e SUPERSEDES.

O `judge-verdict-check.sh` deu rc 0, com as 2 superações transformadas em nós.

## Mutantes

Não se aplica.

## Limites declarados

O modelo efetivo do juiz não foi medido.
