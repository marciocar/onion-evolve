---
title: A forma da peça do backbone de comunicação — oito primárias, quatro lacunas e três selos
date: 2026-11-12
kg: docs/evolution/research/backbone-piece-shape-2026-11/backbone-piece-shape-2026-11.kg.yaml
run_id: wf_17bb85f9-d71
tokens: 1432479
agents: 20
duration_min: 11
review_after: 2027-02-10
type: research
mode: primaries
---

# A forma da peça do backbone de comunicação

**A pergunta** (`Q_BACKBONE_PIECE_SHAPE_2026_11`): que forma deve ter a peça do backbone de comunicação do Onion
(fila, gate A2A, conectores Slack e e-mail, sobre A2A 1.0, CloudEvents e MCP)? Três opções: **(A)** repo e sessão
próprios, semver e vendorização carimbada só do cliente e do gate nos consumidores, no molde do kg-ssot; **(B)**
núcleo no monorepo do core com repos publicados por staging, no molde do Kubernetes; **(C)** pacote publicado (npm ou
PyPI) consumido por versão. E onde fica a fronteira open-core e a licença, para que a governança seja a parte paga sem
trair a camada aberta. Vem dos selos `D_COMMS_BACKBONE_COMPOSED_1112` e `D_COMMS_BACKBONE_VALUE_TABLE_1112` e da
pergunta de padrões `Q_MESSAGING_STANDARDS_1106`.

Esta síntese é **projeção do grafo**; a fonte é ele. Onde os dois divergirem, vale o grafo.

## O que se mediu

`/onion-research` em **modo primárias**: oito fontes nomeadas, leitura integral, sem varredura. As oito foram
alcançadas. Cada claim passou por um verificador independente que exige citação literal e localizador; o que sobrou
passou pelo Elenxo (refutador com default reprovado).

| Etapa | Resultado |
|---|---|
| Fontes alcançadas | 8 de 8 |
| Claims ancoradas | 24 |
| Claims rejeitadas na ancoragem | 19 (15 exageradas, 4 afirmadas sem citação) |
| Objeções do Elenxo | 26, das quais 12 sobrevivem e 2 bloqueiam |
| Superações achadas | 17 (`C_SUPERACAO_20261112_*`) |
| Grafo | 63 nós, 74 arestas internas, 4 arestas externas; radar e contrato com rc 0 na escrita |

As fontes, todas tier 9 menos a CNCF (tier 8, parte da disputa que descreve):
`staging/README.md` do Kubernetes e o README do `publishing-bot`; o repo da especificação A2A e o anúncio da Linux
Foundation; a governança e as diretrizes de SEP do MCP; a governança e o README da especificação CloudEvents; o blog da
CNCF sobre o NATS e a licença do `nats-server`; a página de *stewardship* do GitLab; a referência de vendoring de
módulos Go. A oitava, a página da Temporal, foi lida mas **não ancorou nenhuma claim**.

## As quatro lacunas e o que cada fonte ancorou

**G1, onde mora o núcleo.** O molde B existe e está documentado: no Kubernetes, `staging/` é a única cópia
autoritativa (`E_K8S_STAGING_AUTHORITATIVE`), o repo publicado não aceita PR (`E_K8S_PRS_NOT_ACCEPTED_ON_PUBLISHED`)
e um bot reconstrói o histórico por filtro de commits (`E_K8S_BOT_PUBLISHES_STAGING`). O mesmo README admite que o
bot não tem testes automatizados (`E_K8S_BOT_NO_TESTS_AND_ISSUE_RISK`). A evidência externa **não decide** entre A e
B: os dois precedentes existem. O que pesa por A é interno (o `onion-messaging` já é repo e membro; o kg-ssot já
opera o molde), não desta rodada.

**G2, como o consumidor recebe.** Por vendorização com manifesto verificável. O Go registra a cópia em
`vendor/modules.txt` (`E_GO_VENDOR_MODULES_TXT_MANIFEST`) e erra quando o manifesto diverge de `go.mod`
(`E_GO_VENDOR_CONSISTENCY_CHECK`); o precedente interno é o carimbo de `vendor/kg-ssot/` (tag, commit e sha256 por
arquivo). Leitura: `C_G2_STAMPED_VENDOR_VERIFIABLE_MANIFEST`. Daí decorre que o gate A2A em duas cópias sem carimbo é
defeito a curar pelo mesmo carimbo. O carimbo `Kubernetes-sha` do bot **não** serve de análogo
(`E_OBJECAO_K8S_SHA_STAMP_NOT_CONSUMER_MANIFEST`): ele marca o repo publicado, não o consumidor.

**G3, fronteira open-core e licença.** A camada aberta usa licença OSI permissiva: Apache 2.0 no MCP
(`E_MCP_LICENSE_APACHE_CC_BY`), na especificação A2A (`E_A2A_SPEC_APACHE_UNDER_LF`) e no `nats-server`
(`E_NATS_SERVER_APACHE_LICENSE`); MIT no GitLab, com rejeição explícita da SSPL (`E_GITLAB_CE_MIT_NO_SSPL`). O corte do
pago é o **comprador provável** (`E_GITLAB_PAID_BY_LIKELY_BUYER`), com promessa pública de não mover o aberto para o
pago (`E_GITLAB_OPEN_NEVER_TO_PAID`, `E_GITLAB_EXISTING_FOSS_STAYS`), sem atraso fixo (`E_GITLAB_NO_FIXED_DELAY`) e sem
limites artificiais na base (`E_GITLAB_NO_ARTIFICIAL_LIMITS`). O caso NATS mostra que o risco de relicenciar um
transporte aberto existe e foi tentado (`E_NATS_SYNADIA_DEMANDED_DOMAIN_REPO`), e que a defesa usual é uma fundação
(`E_CNCF_FOUNDATIONS_PROTECT_LICENSE`, `E_LF_GOVERNANCE_KEEPS_A2A_NEUTRAL`). **O Onion não tem fundação**: a promessa
dele é unilateral, e a decisão deve dizer isso em vez de citar A2A ou MCP como modelo de neutralidade
(`E_OBJECAO_NO_FOUNDATION_NO_NEUTRALITY`). Leitura: `C_G3_PERMISSIVE_OPEN_LAYER_BUYER_CUT`.

**G4, especificação contra implementação.** O MCP não leva um SEP que muda comportamento observável a Final sem
cenário no repositório de conformidade, com rastreio de cada MUST/SHOULD (`E_MCP_SEP_CONFORMANCE_TRACEABILITY`); a
CloudEvents remete a uma tabela de suporte por SDK (`E_CE_SDK_FEATURE_SUPPORT_TABLE`). Leitura:
`C_G4_CONFORMANCE_TRACE_AND_SUPPORT_TABLE`, coerente com `D_COMMS_BACKBONE_VALUE_TABLE_1112` e com as fixtures de
conformidade que o kg-ssot já traz. A governança por pessoas do MCP (`E_MCP_GOVERNANCE_INDIVIDUALS`) e a regra de que
a especificação governa o SEP (`E_MCP_FINAL_SEP_FROZEN_SPEC_GOVERNS`) dizem quem decide e como o texto se ordena, não
como a spec governa a implementação; as objeções sobreviventes ficam no grafo.

## As decisões seladas

Selos do maestro em 2026-11-12, por `/meta:decide`:

| Nó | Decisão |
|---|---|
| `Q_BACKBONE_PIECE_SHAPE_2026_11` | **Forma A, medindo C depois.** Repo e sessão próprios, semver; o consumidor recebe só o cliente e o gate por vendorização carimbada (tag, commit e sha256 por arquivo), no molde do kg-ssot. A medida do pacote publicado (`Q_MEASURE_OPTION_C_PACKAGE_VS_STAMPED_VENDOR`) roda antes do empacotamento open-core e, se ganhar, substitui a entrega. Descartadas: medir C antes de selar; B. |
| `Q_GATE_A2A_OPEN_OR_PAID_LAYER` | **O gate A2A fica na camada aberta.** Verificação de identidade e assinatura é transporte; o pago é a governança (políticas, auditoria, SLA, conformidade). |
| `D_BACKBONE_OWNER_1112` | **O dono é o `onion-messaging`**, que adota o núcleo, o gate único vendorizado e os conectores do bridge, com **sessão Onion própria** no repo, como o kg-ssot. Resposta livre do maestro, fora das opções oferecidas. |
| `D_BACKBONE_OPEN_LICENSE_1112` | **A licença se decide no empacotamento**, depois do aceite de dogfood. A rodada recomenda OSI permissiva com promessa pública. |

Os dois `D_BACKBONE_*` moram no grafo `company-brain-non-devs-2026-11`, ligados a `D_COMMS_BACKBONE_COMPOSED_1112`.

**Fica aberto:** `Q_MEASURE_OPTION_C_PACKAGE_VS_STAMPED_VENDOR` (a opção C nunca foi medida; descartá-la sem medida
seria descarte por status quo) e as três opções e três leituras G2 a G4, que são claims da rodada, não selos.

## NÃO-VERIFICADOS

- **As 19 rejeitadas na ancoragem.** Quinze exageravam o texto e quatro não traziam citação. Entre elas: que o bot
  do Kubernetes resolve dependências do consumidor; o desfecho do caso NATS (acordo, sem fork) e a marca como causa
  raiz; o corte de N-1 versões dos SDKs da CloudEvents e a estabilidade do valor no fio; o build offline do vendor
  Go. Dezessete viraram superação (`C_SUPERACAO_20261112_*`) com a frase corrigida; nenhuma sustenta decisão.
- **Temporal: nenhuma claim ancorada.** As cinco foram rebaixadas, quatro sem citação e uma com o SCIM no plano errado.
  O precedente motor aberto contra nuvem paga não está no grafo.
- **A2A: especificação contra SDKs.** Que spec e SDKs vivem em repos separados com governança separada foi rejeitado
  como exagerado; só a licença e a casa da especificação ancoraram (`E_OBJECAO_A2A_SPEC_SDK_SPLIT_UNANCHORED`).
- **CloudEvents: SDK em repo próprio.** Rejeitado como exagerado; só o versionamento da spec e a tabela de suporte
  ancoraram (`E_OBJECAO_CE_SPEC_VERSIONING_NOT_SDK`).
- **Opção C.** Nenhuma claim ancorada a avalia (`E_OBJECAO_OPTION_C_UNMEASURED`).
- **O custo de B no Onion** não foi medido; o do bot do Kubernetes é de outra escala
  (`E_OBJECAO_K8S_BOT_COST_OTHER_SCALE`).

O registro completo está em `E_LACUNAS_BACKBONE_PIECE_SHAPE_1112`. Antes de usar qualquer uma dessas linhas,
reancore com citação e localizador.

## Valeu a pena

1.432.479 tokens para 63 nós: **cerca de 22,7 mil tokens por nó**, com 20 agentes em 11 minutos. A referência medida
do modo primárias é 42 mil tokens por nó (contra 291 mil da varredura, na mesma pergunta, em 2026-09-13). A rodada
pagou duas perguntas seladas no mesmo dia e mostrou o que a evidência **não** decide (A contra B, a licença), o que
impediu um selo apoiado em precedente externo onde o motivo real é interno.
