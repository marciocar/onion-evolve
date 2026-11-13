---
title: Agente multiusuário com o privilégio de quem pediu
date: 2026-11-13
kg: docs/evolution/research/agent-requester-privilege-2026-11/agent-requester-privilege-2026-11.kg.yaml
run_id: wf_45f0fcd2-079
tokens: 1537345
agents: 20
duration_min: 15
review_after: 2027-02-11
type: research
mode: primaries
---

# Agente multiusuário com o privilégio de quem pediu

> **SSOT:** [`agent-requester-privilege-2026-11.kg.yaml`](./agent-requester-privilege-2026-11.kg.yaml)
> (radar `--integrity --schema` exit 0, `kg-contract-check` rc 0; 68 nós, 108 arestas). Esta página é
> projeção: o que ela afirma tem nó, e o nó vence a página. Nada foi selado; a recomendação do Elenxo (a passada que refuta antes de selar) está em
> `C_ELENXO_RECOMMENDATION_1113`.

**Pergunta** (`Q_AGENT_REQUESTER_PRIVILEGE_1113`): como um agente de IA que atende várias pessoas de uma
organização (por exemplo, um bot de chat corporativo) age com o privilégio de quem pediu, em vez de um
privilégio próprio único, e o que uma auditoria pede como registro. Rodada em modo primárias: 8 fontes
lidas, 0 inalcançáveis, 35 claims ancoradas, 10 rejeitadas (todas EXAGERADA), 38 objeções, 15 sobreviventes
(5 bloqueiam), 13 superações (`E_LACUNAS_AGENT_REQUESTER_PRIVILEGE_1113`).

## O que sustenta

| Afirmação | Âncora | Nós |
|---|---|---|
| O modelo é **delegação, não impersonation**: o agente mantém identidade própria e age representando o solicitante (`sub` = solicitante, `act` = agente; `may_act` como pré-autorização). | RFC 8693 §1.1, §4.1, §4.4 | `E_RFC8693_IMPERSONATION_INDISTINGUISHABLE`, `E_RFC8693_DELEGATION_SEPARATE_IDENTITY`, `E_RFC8693_ACT_CLAIM_IDENTIFIES_ACTOR`, `E_RFC8693_MAY_ACT_PREAUTHORIZATION` |
| Na cadeia agente→subagente, só o ator corrente decide; a cadeia inteira vai para o log, porque o token não a torna vinculante. Validade e audiência ficam no token externo. | RFC 8693 §4.1 | `E_RFC8693_NESTED_ACTORS_INFORMATIONAL`, `E_RFC8693_ACT_NO_EXP_AUD` |
| O bot de credencial única é o **confused deputy**: um programa servindo a dois mestres com a autoridade de um. | Hardy (1988); AWS IAM | `E_HARDY_CONFUSED_DEPUTY_TWO_AUTHORITIES`, `E_HARDY_SERVES_TWO_MASTERS`, `E_AWS_CONFUSED_DEPUTY_DEFINITION`, `C_SUPERACAO_20261113_HARDY_EXPLICIT_DESIGNATION` |
| A OWASP nomeia o antipadrão (conta privilegiada, compartilhamento de identidade) e manda: executar no contexto do usuário, autorizar a jusante e não no LLM, aprovação humana no alto impacto. | OWASP LLM06 (2025), ASI03 (Agentic 2026) | `E_LLM06_PRIVILEGED_ACCOUNT_ANTIPATTERN`, `E_ASI03_IDENTITY_SHARING`, `E_LLM06_EXECUTE_IN_USER_CONTEXT`, `E_LLM06_COMPLETE_MEDIATION`, `E_LLM06_HUMAN_IN_THE_LOOP` |
| A trilha **por ato** vem do log à prova de adulteração, com linhagem de cada ato, não do token. | OWASP ASI08 item 10; T8 | `E_ASI08_TAMPER_EVIDENT_LINEAGE_LOGS`, `E_T8_SIGNED_IMMUTABLE_LOGS`, `C_SUPERACAO_20261113_ASI08_PER_ACT_LOG` |
| A base de governança do kit: papéis documentados, papéis humano-IA diferenciados, desligamento e revogação com responsável, política de uso aceitável para chatbots. | NIST AI RMF GOVERN 2.1, GOVERN 3.2, MANAGE 2.4; AI 600-1 GV-3.2-003 | `E_NIST_GOVERN_2_1_ROLES`, `E_NIST_GOVERN_3_2_HUMAN_AI_ROLES`, `E_NIST_MANAGE_2_4_DEACTIVATE`, `E_NIST_GV_3_2_003_CHATBOT_AUP` |
| Na plataforma de chat medida, o **user token é o acesso do usuário**: usá-lo é impersonation e apaga o agente na trilha. O bot não age em nome de ninguém sem user scope. | documentação da plataforma Slack | `E_SLACK_USER_TOKEN_SAME_ACCESS`, `E_SLACK_BOT_NEEDS_USER_SCOPE`, `C_SUPERACAO_20261113_SLACK_USER_WRITE_AS_USER`, `C_SUPERACAO_20261113_SLACK_BOT_TOKEN_TIED_TO_APP` |

## O que NÃO sustenta

- **Menor-entre agente e solicitante como norma.** Nenhuma fonte ISO, NIST ou OWASP ancorada enuncia a
  regra; a claim que a atribuía à OWASP foi rejeitada. Ela existe como **padrão de mercado** (Microsoft
  identity platform: "Both the client and the user must be authorized separately", e o app não acessa nada
  que o usuário logado não acessaria) e como regra de rebaixamento no rascunho WG `draft-ietf-wimse-aims`
  §10.6, não ancorado. No Onion ela entra como composição apoiada em mercado
  (`C_LESSER_OF_AGENT_AND_REQUESTER_1113`, `C_SUPERACAO_20261113_MS_LESSER_OF_MARKET`).
- **Aprovação por papel.** As fontes pedem aprovação HUMANA; o "por papel" é escolha de desenho do Onion
  (`C_SUPERACAO_20261113_ISO_5_15_FORMAL_APPROVAL`).
- **Kit de auditoria como "o que o auditor pede".** Não há texto normativo da ISO 27001 (5.15, 5.16, 5.18,
  8.2, 8.15) nem da ISO 42001. Os campos de log e o inventário de contas privilegiadas vêm de guia de
  vendedor; a lista de campos de 8.15 é orientação da 27002, não requisito do Anexo A
  (`C_AUDIT_KIT_NORMATIVE_BASIS_1113`).
- **Identidade pelo evento autenticado e `is_ext_shared`.** A claim sobre o campo `user` do evento
  `app_mention` foi rejeitada (a página só mostra exemplo, sem semântica), e `is_ext_shared` não aparece em
  nenhuma claim (`C_SUPERACAO_20261113_SLACK_APP_MENTION_PAYLOAD_EXAMPLE`).

## Objeções que bloqueiam

As cinco objeções sobreviventes com triagem `bloqueia` (cada uma com `CONSTRAINS` ao alvo no grafo):

1. **O token não é a trilha por ato** (`E_OBJECAO_TOKEN_IS_NOT_PER_ACT_TRAIL`): um token com `sub` e `act`
   serve a N chamadas. Sem log por chamada, a auditoria não acha qual das 40 chamadas fez a escrita
   destrutiva nem qual mensagem a pediu.
2. **O sucessor vivo da trilha IETF não foi ancorado** (`E_OBJECAO_WIMSE_AIMS_SUCCESSOR_NOT_ANCHORED`): a
   rodada ancorou dois rascunhos individuais (um expirado, um substituído) e só achou o
   `draft-ietf-wimse-aims-01` (WG Document, 2026-11-02) sem segundo agente.
3. **Os campos de 8.15 são orientação da 27002** (`E_OBJECAO_8_15_FIELDS_ARE_27002_GUIDANCE`): escrever "a
   ISO 27001 exige estes campos" seria atribuição errada.
4. **Menor-entre não é norma** (`E_OBJECAO_LESSER_OF_NOT_NORMATIVE`).
5. **Aprovação por papel e kit sem âncora normativa** (`E_OBJECAO_ROLE_APPROVAL_AND_KIT_UNANCHORED`).

As outras dez limitam o alcance (por exemplo: `may_act` diz quem pode ser ator, não o escopo; as chaves de
contexto da AWS identificam recurso e conta, não a pessoa; a citação de LLM06 pode estar truncada; versões
OWASP e NIST não conferidas contra revisão posterior a 2026-11).

## NÃO-VERIFICADOS

- `draft-ietf-wimse-aims-01` §4, §10.3, §10.5.1 e §10.6: lido numa passada do Elenxo, não ancorado.
- Texto normativo ISO/IEC 27001 Anexo A (5.15, 5.16, 5.18, 8.2, 8.15), ISO/IEC 27002 §8.15 e ISO/IEC 42001
  Anexo A: zero claims ancoradas; as quatro claims de guia sobre 5.15 e 8.x foram rejeitadas ou ficaram como
  interpretação de vendedor.
- Plataforma de chat: objeto conversation (`is_ext_shared`), segurança da Events API (assinatura do request
  e campo `user`), agentes nativos agindo com permissão do usuário. `is_restricted` e `is_stranger` só
  parafraseados.
- Mitigação canônica de Hardy por capability: a claim foi rejeitada como EXAGERADA; a superação reescreve a
  cura como designação explícita por ato.
- Atualidade das versões OWASP (LLM Top 10 2025, Agentic Top 10 2026) e NIST (AI 100-1 1.0, AI 600-1) em
  novembro de 2026.
- Nenhum descarte por orçamento (`notVerifiedByBudget` e `budgetDropped` vazios); 0 fontes inalcançáveis.

## Próxima rodada

Na ordem do valor, em modo `primaries` com as fontes nomeadas:

1. `draft-ietf-wimse-aims-01` (§4, §10.3, §10.5.1, §10.6) e a página Microsoft *permissions-consent-overview*,
   para fechar o lado IETF e mercado do menor-entre.
2. Texto oficial ISO 27001/27002/42001 para os controles acima. Se for inalcançável por ser pago, declarar o
   kit como **mapeamento Onion para controles**, não como exigência da norma.
3. Plataforma de chat: conversation object e `is_ext_shared`, segurança da Events API, documentação de
   agentes nativos.

## Valeu a pena

São 1.537.345 tokens, 20 agentes e cerca de 15 minutos para 68 nós: cerca de **22,6 mil tokens por nó**,
na faixa barata das rodadas de primárias. O ganho foi separar com âncora o que é norma (RFC 8693, NIST, OWASP)
do que é mercado (menor-entre) e do que é escolha Onion (aprovação por papel, kit), e achar o sucessor IETF
vivo que a pergunta não nomeava. O que falta é texto normativo pago e a doc da plataforma, não varredura.
