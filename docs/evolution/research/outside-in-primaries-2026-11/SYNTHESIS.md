---
kg: docs/evolution/research/outside-in-primaries-2026-11/outside-in-primaries-2026-11.kg.yaml
run_id: "wf_d23ecc85-e21 (workflow salvo .claude/workflows/onion-research.js, modo primaries)"
tokens: 2240751
agents: 27
duration_min: 22
verified_at: 2026-11-08
---

# Primárias de fora para dentro: core, kg-ssot e onion-messaging (projeção do grafo)

> **SSOT:** [`outside-in-primaries-2026-11.kg.yaml`](./outside-in-primaries-2026-11.kg.yaml). 108 nós: 101 da
> rodada e 7 do fechamento, um por item ATRÁS. Esta página deriva do grafo e não decide nada.
> A revisita vence em 2026-12-08 (`meta.review_after`, cadência de 30 dias: o tipo dominante é ferramenta).

## O que a rodada responde

Doze fontes foram pedidas e onze lidas. Das normas lidas saíram 46 claims ancoradas, e a ancoragem rejeitou
outras 18. O Elenxo do workflow julgou as 46 e chegou a 32 objeções sobreviventes, 13 delas bloqueantes,
porque quase toda claim descrevia o padrão e não media a casa. Os vereditos abaixo vêm dele
(`C_ELENXO_VERDICTS_BY_CHOICE_1108`) e são **posição de 1 agente**. Nenhum nó desta rodada sela nada.

Antes de virar compromisso, cada item ATRÁS foi medido de novo em 2026-11-08, contra os heads daquele dia. Os
sete continuavam reais nessa medida. **Eram 7 ATRÁS na rodada: 1 foi curado no mesmo dia, e 6 seguem abertos.** O grafo havia lido o vendor do kg-ssot em 4.44; o core já está em 4.46.0, e os itens
do kg-ssot foram remedidos nessa versão.

## Veredito por escolha

| # | Produto | Escolha | Veredito | Estado medido | Nós |
|---|---|---|---|---|---|
| 1 | core | `exit 2` com `onFailure` nas guardas | ALINHADO | 9 ocorrências de `onFailure` em `.claude/settings.json`; não comparadas ao total de guardas | `E_CC_HOOK_FAIL_OPEN_ONFAILURE` |
| 2 | onion-messaging | `channels` na campainha | ALINHADO | não remedido | `E_CC_CHANNELS_PREVIEW_ALLOWLIST` |
| 3 | onion-messaging, core | `prompts/list` só com a capability | ALINHADO | não remedido; os dois servidores declaram só tools | `E_MCP_PROMPTS_LIST_ONLY_WITH_CAPABILITY` |
| 4 | onion-messaging | verificador do Standard Webhooks no vigia | ALINHADO **só no PR #8** | PR #8 ainda aberto; o verificador oficial está no diff dele, não na main | `E_OBJECAO_WATCHER_RECEIVES_AND_IS_IN_OPEN_PR` |
| 5 | onion-messaging | janela de 300 s no vigia | ALINHADO **só no PR #8** | igual à linha 4 | `E_STDWEBHOOKS_TIMESTAMP_TOLERANCE` |
| 6 | kg-ssot | RDF 1.2 fora do contrato, ainda em CR | ALINHADO | não remedido | `E_RDF12_CR_REIFYING_TRIPLE` |
| 7 | onion-messaging | assinatura de mensagem por `kid`, perfil Onion | DIVERGE POR DECISÃO | não remedido | `E_A2A_CARD_SIGNATURE_OPTIONAL_JWS` |
| 8 | onion-messaging | dedupe com remetente | DIVERGE POR DECISÃO | não remedido | `E_CLOUDEVENTS_REQUIRED_ATTRS_SOURCE_ID_UNIQUE` |
| 9 | kg-ssot | gramática fechada contra o OKF | DIVERGE POR DECISÃO | não remedido; só a v0.2 do OKF foi lida | `E_OKF_TOLERATE_UNKNOWN_KEYS` |
| 10 | kg-ssot | arestas fora de `wasDerivedFrom` | DIVERGE POR DECISÃO | não remedido | `E_OBJECAO_PROV_DERIVATION_ANALOGY_REFUSED_BY_KG_SSOT` |
| 11 | core | Agent Card 0.3.0, `oauth2` em 404 | ATRÁS | **remedido, real** | `Q_CORE_AGENT_CARD_A2A_1_0_1118` |
| 12 | core | `main` sem bloqueio de force push e deleção | ATRÁS na rodada, **curado em 08/11** | ruleset com `non_fast_forward` e `deletion` desde 22:20Z | `Q_MAIN_RULESET_FORCE_PUSH_1112` |
| 13 | core | 12 actions sem pin por SHA | ATRÁS | **remedido, real** | `Q_CORE_ACTIONS_SHA_PIN_1116` |
| 14 | core | portas sem atestação | ATRÁS | **remedido, real** | `Q_DOORS_ATTESTATION_1130` |
| 15 | kg-ssot | `kg_vendor` sem verificar atestação | ATRÁS | **remedido, real** | `Q_KG_VENDOR_VERIFY_ATTESTATION_1130` |
| 16 | kg-ssot | PROV sem agente | ATRÁS | **remedido, real** | `Q_KG_PROV_AGENT_1208` |
| 17 | onion-messaging | `source` sem validação de URI-reference | ATRÁS | **remedido, real** | `Q_MESSAGING_SOURCE_URI_REFERENCE_1115` |

As linhas 4 e 5 não valem como estado da main do onion-messaging até o PR #8 entrar. "Diverge por decisão" é a
leitura do Elenxo: as quatro linhas ainda não apontam, aqui, para um selo próprio de cada uma.

## Itens ATRÁS remedidos

**Prazo a calibrar.** As datas abaixo são provisórias: o core as propôs por importância, sem base. O prazo aguarda a calibração por story points e pelo histórico planejado contra executado no Linear (estimativa ligada no time em 2026-11-08; a base vem de uma amostra cega por categoria). O dono de cada item fica como está. O grafo é a fonte, e o Linear espelha.

| Dono | Prazo | Item | O que a medida mostrou | Pronto quando | Linear |
|---|---|---|---|---|---|
| maestro | feito em 08/11 | Ruleset da main | só `required_status_checks` na 1ª medida; curado às 22:20Z, com as três regras medidas às 22:41Z | `rules/branches/main` lista `non_fast_forward` e `deletion`: **cumprido** | SAC-360, em Done |
| onion-messaging | a calibrar (provisória: 15/11) | `source` da fila | `_clean_attr` aceita texto com espaço; os PRs #8, #9 e #10 não mudam isso; o par em `a2a-metrics.py` do core tem a mesma régua | recusa `source` que não é URI-reference, com caso negativo na bancada | SAC-361 |
| core | a calibrar (provisória: 16/11) | Pin por SHA | 7 por SHA, 12 por tag móvel, em 4 workflows, todas `actions/*`; sem `.github/dependabot.yml` | 0 `uses:` sem SHA, com atualização declarada e guarda | SAC-362 |
| core | a calibrar (provisória: 18/11) | Agent Card | `protocolVersion` 0.3.0, sem `supportedInterfaces`; A2A em v1.0.1; `authorizationUrl` e `tokenUrl` em 404 | versão 1.x ou divergência selada; nenhuma URL de `securitySchemes` em 404; esquema real declarado | SAC-363 |
| core | a calibrar (provisória: 30/11) | Atestação das portas | 4 portas: tags, 0 releases, sem workflow; 0 menções a attest no motor de publicação | `gh attestation verify` passa na última publicação de cada porta, ou divergência selada | SAC-364 |
| kg-ssot | a calibrar (provisória: 30/11) | `kg_vendor` | 0 menções a attest na 4.46.0; lê por `git archive` e carimba commit e sha256 | update recusa o que não verifica, com caso negativo; ou razão selada | SAC-365 |
| kg-ssot | a calibrar (provisória: 08/12) | PROV com agente | `kg_prov_export.py` emite Entity e Activity, com 0 ocorrências de agent | emite `prov:Agent` quando o nó nomeia o autor; ou razão selada | SAC-366 |

**Fica aberto para o maestro:** `Q_SANDBOX_DENY_LAYER_DECISION_1108`, só a camada de sandbox, em SAC-367 (a decisão
sobre o sandbox do core), sem data: o gatilho é a medida da curadoria terminar. A metade do deny foi decidida em
08/11, no selo `D_MD_DENY_MINIMUM_PORTABLE_1108` do PR #1550, ainda não mergeado. Nenhum `D_` nasce nesta rodada.

## O que a rodada ensinou sobre o método

- **Quase toda claim descreve a norma e não mede a casa.** O leitor de primárias responde o que o padrão manda.
  Dizer se a casa cumpre exigiu que o juiz medisse o repositório, e as 13 objeções bloqueantes nasceram daí. Sem
  essa passada, os vereditos sairiam errados.
- **A ancoragem rejeitou 18 claims.** Foram 15 exageradas, 2 afirmadas sem citação e 1 não encontrada. O padrão
  dominante foi fundir graus normativos, tratando SHOULD como MUST.
- **Um grafo envelhece no mesmo dia.** O vendor do kg-ssot andou de 4.44 para 4.46 entre a leitura e o fechamento.
  Por isso nenhum ATRÁS virou compromisso sem nova medida. E a medida também envelhece: o ruleset da main foi curado
  minutos depois de medido, antes do merge deste fechamento.

## Mercado

Sem sinal nesta rodada, por construção: o modo `primaries` lê fontes nomeadas e não varre mercado. A sobreposição
com projetos da AAIF foi rebaixada. O dissect de fora da curadoria virá depois, sem ler este grafo.

## NÃO-VERIFICADOS

**Fonte inalcançável:** `iso-42001`. O iso.org devolveu 403 com desafio do Cloudflare em 3 URLs, e nada se
afirma sobre a norma.

**Lacunas que continuam abertas (9), de `E_LACUNAS_OUTSIDE_IN_1108`:**

1. `a2a-spec`: nenhuma claim sobre o envelope, e a de push foi rejeitada.
2. `claude-code-channels-hooks`, parte sandbox: a claim foi rejeitada.
3. `slsa`: sem claim de nível por artefato nem da trilha Source.
4. `openssf-scorecard`: SAST rejeitado; o binário do Scorecard não foi rodado.
5. `nist-ai-rmf`: só o texto do padrão, sem comparação com a casa.
6. `iso-42001`: inalcançável.
7. `dora`: nenhuma métrica DORA medida na casa.
8. `aaif-projects`: só a existência de A2A, Skills e MCP está ancorada.
9. `okf-spec`: a v0.3 e o repo neutro dão 404; só a v0.2 foi lida.

**Rejeitadas na ancoragem:** as 18 estão, com o motivo do verificador, em `E_LACUNAS_OUTSIDE_IN_1108`; as 16 que
apontavam algo aproveitável viraram `C_SUPERACAO_20261108_*`. Nenhuma virou evidência.

**Orçamento:** o modo `primaries` não tem `maxVerify`; o retorno não traz `notVerifiedByBudget` nem `budgetDropped`.

**Não medido no fechamento:** a bancada do vigia, o binário do Scorecard, o nível SLSA L3, as linhas ALINHADO e
DIVERGE marcadas como não remedidas, e o gate real JWS do Agent Card, que continua sendo leitura do Elenxo.

## Valeu a pena

| Grandeza | Valor |
|---|---|
| Tokens | 2.240.751 |
| Agentes | 27 |
| Duração | 22 min |
| Nós da rodada | 101 |
| Tokens por nó | ≈22,2 mil |
| Tokens por claim ancorada (46) | ≈48,7 mil |

O custo por nó é metade dos ≈42 mil da rodada de primárias anterior, mas o número engana: só 46 dos 101 nós são
evidência, e o restante é objeção, superação e contabilidade. Pela claim ancorada, ficou próximo. Valeu: os 7 itens
ATRÁS resistiram à nova medida, um deles já curado no mesmo dia, e as 13 objeções bloqueantes impediram vereditos errados. Os 7 nós do fechamento
não entram no denominador.
