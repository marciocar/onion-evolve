---
branch: research/a2a-empresa-rodada-primarias
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 69303c19d2afdf37d71211f61b33e200311502673ac6b2281c025616be9bdddb
reviewed_code_sha256: 69b23d4f021680066a36849f469bf75fa25d9975e37c651297dc73907f64418a
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: "a sessão que escreveu o PR, conferindo 6 nós novos contra a fonte primária por WebFetch (sem subagente)"
nota: "tokens = 0 de workflow: a passada foi feita pela própria sessão, sem run nem subagente medido. Dos 3 achados, 2 foram curados no PR (descartadas inventadas no selo do Q_AAIF_G4_SUPERSEDE_PROPOSAL_1027; código curto G4 na narrativa de dois nós) e 1 fica como achado aberto para a próxima rodada (a objeção 33 tem o texto na fonte)."
---

# Passada adversarial: `research/a2a-empresa-rodada-primarias`

## O que muda

- O grafo `a2a-empresa-adotante-2026-10.kg.yaml` recebe a rodada de primárias (`wf_bd8f7f49-808`, de 72 para
  119 nós, só acréscimo) e os quatro selos do maestro de 2026-10-27, todos pelo `kg-decide-seal.sh`.
- O grafo de federação `federation-research-2026-06-reconciled.kg.yaml` ganha `E_AAIF_HOSTS_A2A_SINCE_2026_08_17`,
  que SUPERSEDES `G4_AAIF_A2A_SEPARATE` (agora `superseded`, com `x_valid_to: "2026-08-17"`).
- A AAIF entra no roster `docs/onion/radar-sources.yaml` num grupo novo `padroes-agentes`.
- A SYNTHESIS.md ganha a rodada e os selos; o manual `inter-session-channels-a2a.md` troca "Em estudo" pela
  direção selada.

## Conferência contra a fonte (6 nós, WebFetch em 2026-10-27)

| Nó | Fonte | O que o texto diz | Veredito |
|---|---|---|---|
| `E_A2A_SPEC_CARD_SIGNING_MAY` | a2a-protocol.org/latest/specification §8.4 | "Agent Cards MAY be digitally signed using JSON Web Signature (JWS) as defined in RFC 7515" | confere |
| `E_A2A_SPEC_CARD_VERIFY_SHOULD` | a mesma spec, §8.4.3 | "Clients SHOULD verify at least one signature before trusting an Agent Card" e "Expired or revoked keys MUST NOT be used for verification" | confere |
| `E_CC_ISOLATE_PEER_MACHINES_BYPASS_ONE_WAY` | code.claude.com/docs/en/cross-session-messaging | "even in `bypassPermissions` mode"; "a checked-in project file can turn the requirement on but not off"; "doesn't prompt for messages between sessions on the same machine" | confere |
| `E_CC_CHANNELS_PERMISSION_RELAY_APPROVER` | code.claude.com/docs/en/channels, Security | "Anyone who can reply through the channel can approve or deny tool use in your session" | confere |
| `E_MANAGED_AGENTS_SERVER_SIDE_NO_ZDR_BAA` | platform.claude.com/docs/en/managed-agents/overview, Beta access | "not currently eligible for Zero Data Retention or HIPAA Business Associate Agreement (BAA) coverage"; "You retain control over this data: you can delete sessions" | confere |
| `E_AAIF_HOSTS_A2A_SINCE_2026_08_17` (novo, federação) | aaif.io/blog/a2a-joins-aaif | post datado de 2026-08-17, "is joining the Agentic AI Foundation (AAIF) as a hosted project" | confere; o texto não dá outra data de entrada, e o nó diz isso |

## Achados

1. **Real, curado.** Na 1ª escrita do selo de `Q_AAIF_G4_SUPERSEDE_PROPOSAL_1027` passei descartadas que eu
   inventei, porque o selador exige `--rejected` e o pedido não trouxe as opções oferecidas ao maestro. Era
   testemunho fabricado. O grafo voltou ao estado de antes dos selos e os quatro foram refeitos; o descarte
   agora diz "nenhuma opção registrada", com o motivo.
2. **Real, curado.** O lint de nomes (`kg_vocab.py lint --root .`) acusou o código curto "G4" na narrativa de
   `E_OBJECAO_39_AAIF_DATE_AND_G4_CONTRADICTION` e de `Q_AAIF_G4_SUPERSEDE_PROPOSAL_1027`, vindos do grafo do
   scratchpad. A narrativa pré-selo foi corrigida para o id completo e os selos refeitos por cima; o lint
   ficou com zero achado no grafo.
3. **Real, aberto.** `E_OBJECAO_33_ORG_DISABLE_UNQUOTED` diz que o desligamento da organização pelo admin
   não tem citação. A página de cross-session tem o texto: "Administrators can turn both sides off for an
   organization in managed settings, combining the deny rules with the `refuse`", com o JSON. A lacuna fecha
   com uma re-ancoragem; fica para a próxima rodada, porque este PR não reabre a ancoragem do run.

## Limites declarados

- A passada foi da própria sessão que escreveu o PR, não de um revisor independente.
- `x_valid_to` é extensão: o contrato v4 não tem `valid_to`, e o contrato reprovou a chave sem prefixo.
