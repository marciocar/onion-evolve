---
branch: docs/agent-neutral-channel-study
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/agent-neutral-channel-study`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: entram dois nós e duas arestas.
  - `E_SINAL_CANAL_NEUTRO_DO_AGENTE_1025`: a proposta da curadoria, com `trace:` para o sinal processado.
  - `D_CANAL_NEUTRO_VIRA_ESTUDO_DE_TRANSPORTE_1025`: o maestro não parqueou. O canal vira estudo de transporte
    (MCP, MCP Agent Mail, A2A com SDK oficial, ACP ou o mais adotado), com três linhas vermelhas.
  - As duas arestas ligam o D ao sinal e à `Q_CANAL_ENTRE_SESSOES_NEUTRO_DO_AGENTE_1025`, que segue aberta até o
    estudo fechar.
- `docs/evolution/inbox/_processed/2026-10-25-proposal-agent-neutral-channel.md`: o sinal, já triado.

## Achados

1. REAL, corrigido: o código `P5` aparecia solto na narrativa, e o lint de nomes o pegou (vocab.code-unresolved).
   Agora o texto diz o que ele é: o ponto da via de bilhetagem.

## Mutantes

- Nenhum: a mudança é só de grafo. O radar `--integrity --schema`, o contrato e o lint de nomes saem rc 0 depois
  da cura. Antes dela, o lint de nomes reprovava.

## Limites declarados

- O nó `D_AGENT_NEUTRAL_CHANNEL_VERDICT` mora no grafo da curadoria. Quem o fecha é a sessão de lá, com
  `x_dissect_sealed_by` (#1347) apontando para este D.
