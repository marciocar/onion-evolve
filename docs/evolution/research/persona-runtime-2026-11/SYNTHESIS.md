---
title: O runtime da persona de serviço roda onde o veto do adotante roda
date: 2026-11-06
kg: docs/evolution/research/persona-runtime-2026-11/persona-runtime-2026-11.kg.yaml
run_id: wf_ad5d1e07-29a
tokens: 7896195
agents: 106
duration_min: 28.8
review_after: 2026-12-06
type: research
mode: decision
---

# O runtime da persona de serviço roda onde o veto do adotante roda

> Projeção do grafo: quem manda é o `.kg.yaml`. O contrato de custo acima é o do run do `/onion-research`
> (`wf_ad5d1e07-29a`, 1.726.608 ms, 106 agentes, 0 com erro). O retorno inteiro do workflow está em
> `data/workflow-result-wf_ad5d1e07-29a.json`.

**A pergunta** (`Q_PERSONA_RUNTIME_2026_11`): qual runtime serve a persona de serviço do Company Brain de um
adotante: A, um bot próprio no Claude Agent SDK hospedado no onion-bridge com o kg_mcp; B, o assistente
nativo do chat (Claude Tag no Slack); ou C, um bot de mercado de terceiro? É o compromisso
`Q_PS_PESQUISA_DO_RUNTIME_1110` do grafo `docs/onion/graph/persona-servico-2026-11.kg.yaml`, com prazo em 10/11.

**A decisão** (`D_PERSONA_RUNTIME_2026_11`) está **aberta para o maestro selar**. O Elenxo (o método de refutar antes de selar), um agente só e sem
votação, recomenda **A como núcleo, com B só como ponte nomeada (A+ponte B)**, sob 7 condições.

## As opções

| Opção | O que é | Por que fica ou sai |
|---|---|---|
| **A** | Bot próprio no Agent SDK, no runner do bridge (DynamicUser), kg_mcp fora da fronteira, um app Slack **interno** por adotante | Única em que o veto do adotante roda no runtime: os hooks do `.claude/settings.json` carregam pelo `settingSources` padrão e o PreToolUse devolve deny, ask ou defer. A leitura do KG fica local, por stdio. |
| **B-hospedado** | Claude Tag no ambiente da Anthropic | Isola bem os segredos (sandbox efêmero, Agent Proxy injeta a credencial), mas não tem hook do adotante, está em beta, guarda transcrições e memória do lado da Anthropic sem retenção automática, e não serve a ZDR, CMEK nem HIPAA. Só lê o KG se o kg_mcp virar endpoint público. |
| **B-self-hosted** | Claude Tag com runner na rede do adotante | O runtime fica local, mas os conectores do admin não funcionam ali: não cumpre ao mesmo tempo o núcleo local e a triagem dos canais. |
| **C** | Bot de mercado de terceiro | Classe Drift (Salesloft, ago/2025): o fornecedor concentra tokens OAuth de muitos clientes. Fora do Marketplace, fica limitado a 1 requisição por minuto e 15 objetos no histórico. Lock-in sem ganho de capacidade. |
| **A+ponte B** | A como núcleo e B como ponte opcional nomeada para adotante não regulado | É a recomendada. Cumpre a regra de não depender de serviço externo (`D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`). |

## As 7 condições da recomendação (objeções que sobreviveram)

1. **Veto que bloqueia quando falha.** Subir o SDK do bridge de 0.3.303 para 0.3.317 ou mais, armar os vetos com `onFailure: 'block'` e provar com mutante que um callback que lança bloqueia a ferramenta.
2. **O exit 2 não é fronteira de segurança** (`D_EXIT2_COUPLING_WORDING_2026_11`). O post no Slack é uma ferramenta própria atrás de deny/ask, e o modo rascunho com aprovação do maestro é o controle real do piloto.
3. **Um app Slack interno por adotante**, nunca um app distribuído pelo core: só o app interno escapa do limite de taxa novo do Slack.
4. **Isolamento pelo runner do degrau 2 já em produção** (DynamicUser, ProtectHome, IPAddressDeny), sem bwrap nem Docker nesta VPS.
5. **Credenciais fora da fronteira:** Slack, e-mail e task manager entram por ferramenta ou broker fora do agente, porque o bridge já teve um `.env` lido por um convidado (`E_SONDA_ENV_CONVIDADO_LIA_PRODUCAO`).
6. **Identidade:** o bot token do Slack é a identidade de serviço. O claim `act` da RFC 8693 só existe se o operador rodar um emissor de token exchange sobre a raiz de confiança A2A do bridge; nenhuma opção o entrega hoje, e isso fica como lacuna aberta.
7. **Matriz corrigida antes do selo:** B tem identidade de serviço em canais; a auditoria de B é parcial porque não registra quem pediu cada ato e deixa de fora o tráfego git e MCP; a escada de B é expressável em parte por host, caminho e método no Agent Proxy.

Se B for usado como ponte: DMs desligadas (no DM o Claude Tag age na conta de quem enviou), resposta automática
desligada, restrito à organização, busca só nos canais em que está, e credenciais só em canais privados.

## Mercado e capital

Sinal só de produto, sem rodada, M&A ou relatório de analista. A Anthropic lançou o Claude Tag em beta em
2026-06-23 como "funcionário virtual" no Slack, o que pressiona mais os bots de terceiro (C) do que o bot próprio (A).
O caso Salesloft/Drift é o sinal de risco de cadeia de suprimentos. Desde 2025-05-29 o Slack aperta os apps
comerciais e preserva os internos. Confirma `E_MERCADO_MAESTRO_PERSONA_1105`: sem sinal de capital sobre persona de agente.

## Medido pelo fechamento, fora do run

- **O bwrap não funciona nesta VPS para usuário sem privilégio.** Medido em 2026-11-06: `kernel.apparmor_restrict_unprivileged_userns = 1` e `bwrap --ro-bind / / true` sai com `setting up uid map: Permission denied`. Isso sustenta a condição 4. Também pesa sobre o sandbox do Claude Code (bubblewrap) que a sessão da curadoria ia ligar no reinício: a curadoria precisa medir se o sandbox sobe ou se falha.

## NÃO-VERIFICADOS

- **Refutadas (9):** entre elas, a de que o SDK já injeta credenciais por proxy (é decisão de desenho do adotante, não recurso pronto) e várias formulações sobre a identidade do Claude Tag (por fonte fraca; a primária reinstalou a identidade de serviço em canais). A lista inteira está no retorno, campo `refuted`.
- **Fora da verificação por orçamento:** 40 claims (`notVerifiedByBudget`) e 42 cortadas antes (`budgetDropped`), com `maxFetch` 15 e `maxVerify` 25.
- **Perguntas abertas:** se o Claude Tag tem gancho antes do ato; como o token do bot se liga ao par ator/titular no log do Onion; se `Q_CHAT_AGENT_ISOLATION_2026` cobre um agente persistente de triagem com escrita; e o custo medido por mês de A contra B.

## Valeu a pena

7.896.195 tokens para 90 nós: ≈ 88 mil por nó. É o custo de uma varredura (a rodada da persona de 2026-11-05 ficou
em ≈ 70 mil por nó). A rodada seguinte, se houver, vai por `mode: 'primaries'`, porque as lacunas agora têm nome.
