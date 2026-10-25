---
title: "Transporte agente-a-agente para o canal gated: parquear com gatilho no round-trip vivo; lidera a composição A2A do bridge + MCP stdio local na ponta"
date: "2026-10-25"
from: onion-curation
to: onion-evolve
type: proposal
kg: docs/evolution/dissect/agent-transport-2026-10/agent-transport-2026-10.kg.yaml
decision_node: D_AGENT_TRANSPORT_VERDICT
---

# Rascunho do sinal ao core (não relayado)

Estudo SAC-249, família `categoria`, destino `core`, critério `AGENT_TRANSPORT_STAGE0` v1 (commit `ad41693`).
A proposta é da curadoria. Quem sela é o core.

## Veredito proposto

**PARQUEAR com gatilho, no N1.** O pesquisador propôs costurar (placar 8), e o Elenxo rebaixou para parquear:
- o P4 cai para 1, porque a tool de envio ainda pede ajuste;
- o P5 cai para 0, porque o transporte não abre via de bilhetagem verificada;
- o placar fica em 6, na faixa de parquear;
- o N2 por leitura não mostrou onde moram a pinagem e a topologia (só informado), nem a ponta do Codex, e a
  composição não tem implementação de referência.

**A composição que lidera:** entre máquinas, o fio segue o HTTP A2A do bridge. Na ponta de cada sessão (Claude Code
ou Codex), um MCP stdio local fica a jusante do aceite, sobre os scripts neutros do core, com três tools:

1. ler a fila, emoldurada e marcada como não verificada;
2. propor aceite, que só grava a intenção (no molde do `propose_kg_write`);
3. enviar por `a2a-send`, com a chave do membro na máquina dele.

Aceitar nunca é tool. Isso confirma a hipótese do core e a perspectiva contrária da Etapa 0: o fio fica, e o que muda
é a ponta. O MCP é a única camada que o Claude Code e o Codex falam como cliente nativo.

**Gatilho:** o parque reabre quando o round-trip vivo Claude ↔ Codex for medido e registrado como superação de
`Q_N2_LIVE_ROUNDTRIP`. Pela régua, ele pode subir até perseguir.

**Antes de subir o N2 vivo, o Elenxo pede:**
- ler e rodar o `interlink-mcp` (assinatura Ed25519 por mensagem, allowlist, push só depois de verificar) como
  candidato a superar a ponta MCP;
- registrar o `claude mcp serve` (o Claude Code também roda como servidor MCP) no N0;
- medir no Codex se a tool de envio pede aprovação humana. No Claude Code, o A7-C1 já mostrou um Bash composto
  rodando sem diálogo.

## Evidência por nível

- **N0, atores achados por trajetória.** Cinco transportes vivos em três camadas: MCP (agente a ferramenta), ACP da
  Zed (editor a agente), A2A 1.0.0 (agente a agente), MCP Agent Mail (caixa local) e a injeção nativa de cada
  fornecedor. Os binários foram medidos:
  - o Codex CLI 0.164.0 tem `codex mcp` e `codex queue --thread --message` ("Queue a message for an existing
    session"), e nada de ACP ou A2A;
  - o Claude Code 2.1.310 tem `claude mcp add` com stdio, SSE e HTTP, e nada de ACP ou A2A.

  O MCP é a única camada que os dois falam como cliente nativo. Uma amostra do CORE-STATE foi conferida por comando
  e bate. Há uma divergência menor: o ACP da Zed tem 1 menção no core, num JSON de varredura (`C_CORE_STATE_ACP_ONE_MENTION`).
- **N1, a régua da §5.**

  | Ator | Eliminatório | Pontos |
  |---|---|---|
  | MCP stdio local sobre os scripts neutros | passa E1 a E3 | 8 |
  | A2A puro com SDK oficial | nenhum (a guarda compõe por cima) | 5 |
  | Injeção nativa por fornecedor | nenhum (só serve a jusante do aceite) | 3 |
  | ACP (cliente para agente) | nenhum (inverte a topologia) | 2 |
  | MCP Agent Mail | E3 (mensagem sem assinatura, sem pinagem, sem topologia) | eliminado |

  A A2A 1.0.0 assina só o Agent Card (§8.4) e não cada mensagem. A adoção foi datada em 2026-10-25: A2A com 26,3 mil
  estrelas, SDK TypeScript do MCP com 13,7 mil, ACP com 4,5 mil. O E4 não dispara.
- **N2, por leitura (sem rodar nada).**
  - Na spec MCP 2026-07-28, o humano no laço é SHOULD do cliente, as anotações de tool não são confiáveis e o stdio
    tira a credencial do ambiente. O E2 se sustenta e o E1 vale por ausência da tool de aceitar.
  - No core (`5c6a57e7`), cada garantia mora num script neutro:
    - assinatura RS256 por mensagem no `a2a-send.sh`;
    - reverificação e ato humano no `a2a-accept.sh`;
    - o channel do spike prova a ponta stdio, mas empurra por `notifications/claude/channel`, que só o Claude
      Code tem.
  - **Lacuna nomeada:** a tool de enviar fica ao alcance do modelo, e o diálogo antes dela depende de cada cliente.
    No Claude Code isso já falhou (A7-C1). No Codex não foi medido.
- **N3 não fecha.** A lista de peças está no grafo: o servidor de 3 tools, a porta de push por fornecedor a jusante
  do aceite (`codex queue` e o channel do Claude) e a bancada Claude ↔ Codex. O custo não foi medido.

## Próximo passo: emenda do N2 vivo

Pré-registrar o desenho do `Q_N2_LIVE_ROUNDTRIP` antes de rodar:

1. login do Codex 0.164.0;
2. servidor MCP de teste fora da árvore de trabalho;
3. ida pelo Codex com `a2a-send`, verificação e enfileiramento no bridge;
4. aceite humano com `a2a-accept`;
5. volta pela sessão Claude;
6. percepção com `codex queue` e o channel, só a jusante do aceite;
7. negativos: corpo que pede ação, envio sem diálogo em cada approval policy, ausência da tool de aceitar.

Se o round-trip passar, o total 8 com N2 medido sobe o veredito para perseguir.

## Superação

Não há superação integral. Ninguém entrega o canal entre fornecedores com a guarda do core melhor ou mais barato. As
superações são parciais: o MCP Agent Mail na coordenação local, eliminado aqui por E3, e o `codex queue` na percepção
do Codex, que entra como peça da composição. A busca foi feita no corpus (`kg_query` por "Agent Mail", "Codex" e "ACP")
e na web (uma WebSearch extended de trajetória, a página de agentes do ACP e a spec do A2A).

## Não verificado

- O round-trip vivo.
- A política de aprovação do Codex para tool MCP.
- O efeito do `codex queue` numa sessão viva.
- O estado da flag de channel no Claude Code 2.1.310.
- Se os clientes já falam MCP 2026-07-28.
- Os §7 e §7.6 da A2A, e o executor padrão do `a2a-python`.
- A governança do ACP.
- O crescimento em série temporal.
- Os itens do CORE-STATE que não foram amostrados.
- A via de bilhetagem.

A lista completa está em `meta.x_unverified`.

## Quem paga

O MCP e o A2A são projetos da AAIF (Linux Foundation), pagos por dues: o Platinum custa de US$ 350 mil a 370 mil e tem
8 vagas nomeadas (aaif.io/members). A spec do A2A anuncia "A2A joins the Agentic AI Foundation". O ACP e o MCP Agent
Mail não têm financiador nomeado. Ninguém vende o fio, e a composição é custo do core. A via de bilhetagem no Onion é
indireta e não verificada: operar um receptor ou relay hospedado para equipes que misturam Claude Code e Codex.
