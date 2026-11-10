---
title: Perfil de interconexão v1 (Parte A)
date: 2026-11-10
kg: docs/evolution/research/interconnect-profile-2026-11/interconnect-profile-2026-11.kg.yaml
run_id: "NÃO-APLICÁVEL (sem workflow: rascunho do core refutado pela curadoria em rodadas, selado pelo maestro por pergunta com opções)"
tokens: "NÃO MEDIDO"
agents: "NÃO MEDIDO"
duration_min: "NÃO MEDIDO"
review_after: 2026-12-10
type: research
mode: decision
---

> **Projeção do grafo, nunca fonte.** Quem manda é
> [`interconnect-profile-2026-11.kg.yaml`](interconnect-profile-2026-11.kg.yaml) (11 nós). O texto do perfil está
> em [`PROFILE.md`](PROFILE.md). Os quatro selos do maestro de 2026-11-10 foram gravados pelo `kg-decide-seal.sh`,
> com testemunho e plane DEV. Não houve run de workflow, por isso o contrato de custo declara `run_id` ausente.

## A tese (`C_INTERCONNECT_PROFILE_THESIS_1110`)

Não existe contrato único para as 32 ligações do Onion. Existe **um envelope único para tudo o que é sinal ou
evento** (as quatro vias de sinal entre membros, o watcher e a campainha); o resto segue o padrão da própria camada.
A Parte A vale sob o modelo de confiança de hoje: só máquinas nossas, sem proxy com inspeção TLS.

## As cinco seções

| Nó | Seção | Em uma linha |
|---|---|---|
| `C_INTERCONNECT_A1_ENVELOPE_1110` | A1 Envelope | CloudEvent 1.0.2 assinado por JWS compacto; iss, aud, iat, exp e jti obrigatórios |
| `C_INTERCONNECT_A2_VERSIONING_1110` | A2 Versão | major no `type`, schema por major, legado é a major 0, recusa explícita de major desconhecida |
| `C_INTERCONNECT_A3_BINDINGS_1110` | A3 Bindings | validade por canal (1 h vivo, 7 dias git), exp só no aceite, recibo de aceite, dedupe de 8 dias |
| `C_INTERCONNECT_A4_CLASSIFICATION_1110` | A4 Classe | `onionclass` assinado; `confidential` só no mesmo host até a Parte B |
| `C_INTERCONNECT_A5_STATES_OPS_1110` | A5 Estados | cinco estados por mensagem; mensagem é dado, nunca ordem; um comando de estado |

## Os selos de 2026-11-10

| Decisão | Escolhida | Descartadas |
|---|---|---|
| `D_INTERCONNECT_PROFILE_A_V1_1110` | Selar com os compromissos (Recomendado) | Esperar a Parte B · Quero ler antes |
| `D_INTERCONNECT_MAJOR0_EXIT_1110` | Por condição medida (Recomendado) | Data fixada agora |
| `D_INTERCONNECT_EXEC_ORDER_1110` | Arrumar o que existe primeiro (Recomendado) | Envelope v1 primeiro |
| `D_INTERCONNECT_PART_B_OPEN_1110` | Abrir agora (Recomendado) | Depois da Parte A |

## O que segue aberto

`Q_INTERCONNECT_PART_B_STUDY_1110` (dono: curadoria): cifra do corpo, raiz de confiança e registro assinado
(medindo TUF e sigstore), transporte entre máquinas e pareamento pela RFC 10027. A Parte B revisa
`D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106` (aresta externa no grafo). A curadoria conduz, o core decide a arquitetura,
o maestro sela.
