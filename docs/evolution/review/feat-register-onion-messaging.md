---
branch: feat/register-onion-messaging
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: f71ef0abe7013ed6f95b36afb267c1791a408476d7daae24a5b2a60cdc12ed4f
reviewed_code_sha256: 55ee795c541a32adbdddba509cd07272595db4af5d31f40fae34ee92091dccd4
findings_total: 2
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; subagente vedado pelo brief)
nota: "tokens 0 = não medido. Registro de membro (OP-1) e o fecho de um nó do plano da mensageria; nenhum código muda."
---

# Passada adversarial: `feat/register-onion-messaging`

## O que muda

- `docs/evolution/federation/members.yaml`: membro `onion-messaging` (`role: standalone`, `kind: adopter`,
  `onion_version: 6760a7bede50`, privado, greenfield).
- `docs/onion/federation-map.md` e `docs/onion/federation-console.html`: projeções regeneradas (REGRAS 38 e 24).
- `docs/onion/graph/comms-stable-2026-11.kg.yaml`: `Q_CS_REPO_ONION_MESSAGING_CRIADO_1106` passa a `done`
  com `verified_against`.

## Achados

1. REAL, corrigido: a 1ª redação do `verified_against` dava o repo como pronto sem dizer que a `main` do
   remoto ainda não existe (a guarda de repo alheio negou o push à sessão). O critério do nó (repo criado e
   clonado, membro registrado) está cumprido; a ressalva entrou no próprio `verified_against`, para o
   leitor do grafo não concluir que os PRs do onion-messaging já têm base.
2. Refutado: suspeita de par de papel errado (registro `standalone` e carimbo `adopted`). É o par que a
   REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) aceita para adotante, o mesmo do
   `bomtexto` e do `onion-kg-ssot`; `members-validate.sh --json` → `valid: true`.

## Mutantes

- `pin-integrity-check.sh /home/marcio/onion-evolve /home/marcio/onion-messaging` → `pin-ok 6760a7bede50`
  (o pin escrito é o devolvido, não o do carimbo cru).
- `projection-safety.sh` → nenhuma superfície carrega termo sensível (86 arquivos).

## Limites declarados

- A passada é da própria sessão de execução, não independente.
- O CI do Onion no onion-messaging foi OFERECIDO (`offer-onion-ci.sh`: aplicável) e não aplicado; é decisão do dono.
