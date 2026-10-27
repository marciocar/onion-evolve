---
branch: research/a2a-empresa-adotante
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: aed945d8ff9c1cc792f217f893cd59f740bbefb1eee44a2c3895ff99b592cced
reviewed_code_sha256: 9a54116d19373379f0f6859ac013e7c77a5292621e8773658458c8251ce97e20
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 25
findings_fixed: 3
verdict: APROVADO
elenxo: nao
reviewer: subagente do pós-run (conferência por amostragem com WebFetch)
nota: "tokens 0 = não medido: o subagente não lê o próprio custo; a passada é a conferência de 5 nós contra a fonte"
---

# Passada adversarial: `research/a2a-empresa-adotante`

## O que muda

O pós-run do `/onion-research` em modo decision "A2A para empresa adotante" (run `wf_25860bde-222`):
o grafo `a2a-empresa-adotante-2026-10.kg.yaml` (71 nós escritos pelo workflow, mais 1 do pós-run), a
`SYNTHESIS.md` como projeção, e o retorno integral do run em `data/`. A decisão
`D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` nasce `open`; ninguém a sela aqui.

## Conferência por amostragem (WebFetch, 2026-10-27)

| Nó | Fonte reaberta | Resultado |
|---|---|---|
| `E_XSESSION_MESSAGE_NEVER_APPROVAL` (e `E_OBJECAO_01_…`) | code.claude.com/docs/en/cross-session-messaging | **confere**: "It can't approve anything", "Commands don't run" e "Claude Code instructs the receiving Claude never to change permission settings"; com o receptor pedindo permissão, o default entrega a mensagem |
| `E_XSESSION_CROSS_MACHINE_VIA_ANTHROPIC` | mesma página, tabela e Availability | **confere**: "Through Anthropic servers, arriving over that machine's Remote Control connection"; na mesma máquina, socket, "never through Anthropic servers"; entre máquinas exige login claude.ai. Ressalva de nome: a página hoje fala "Google Cloud's Agent Platform" e "Claude Platform on AWS", e o label diz "Vertex"; o sentido não muda |
| `E_OBJECAO_16_ISOLATE_PEER_MACHINES_LOAD_BEARING` | mesma página, "Require approval for cross-machine messages" | **confere**: aprovação "even in `bypassPermissions` mode"; projeto "can turn the requirement on but not off" |
| `E_CLOUDFLARE_MCPAGENT_DEPRECATED_STATELESS` (e `E_OBJECAO_20_…`) | developers.cloudflare.com/agents/model-context-protocol/protocol/transport/ | **confere**: "new servers should use the stateless Streamable HTTP handler", "`McpAgent` is deprecated and feature-frozen", "RPC transport does not support authentication" |
| `E_A2A_150_ORGS_22K_STARS` | comunicado da Linux Foundation | **confere**: "over 150" contra "more than 50" (abr/2025), "surpassed 22,000 GitHub stars"; comunicado de 09/04/2026, coerente com `valid_from: "2026-04"` |

Extra: `C_SUPERACAO_20261027_A2A_JOINS_AAIF_2026_08_17` conferido em aaif.io/blog/a2a-joins-aaif (data
2026-08-17, "as a hosted project").

## Achados

1. **O enquadramento de `isolatePeerMachines` e `crossSessionInbound` como "fonte não lida" estava errado.**
   A página de cross-session, que o run leu, documenta os dois controles. O que o `maxVerify` cortou foram
   as claims. Corrigido no nó `Q_A2A_EMPRESA_RODADA_PRIMARIAS_1027` e na SYNTHESIS: a rodada complementar
   ancora as claims e lê a referência de settings, sem pagar de novo a página.
2. **O nó que cita a SYNTHESIS em `trace:` não existia.** Os 71 nós do workflow já tinham `trace:`, e a
   skill proíbe a segunda linha. A citação foi para o nó novo da rodada complementar, com o TETO do `meta`
   subido de 71 para 72 e o motivo escrito (REGRA 58, teto do grafo de backlog).
3. **Vocabulário de provedor defasado no label** (`Vertex` contra "Google Cloud's Agent Platform").
   Não corrigido: o label é a claim votada 3-0 no run, e a mudança é de nome, não de fato. Fica para a
   revisita (`review_after` 2026-11-26).

4. **Códigos curtos sem termo na prosa dos nós.** O contrato KG-SSOT do commit reprovou sete códigos
   (nomes de etapa de spike, `WSL2` e o nome curto do radar do CHANGELOG) em narrativas escritas pelo
   workflow. Trocados por prosa; `ops/kg-vocab-ci.sh` voltou a 0 código novo.

## Mutantes

Não se aplica: grafo de pesquisa e projeção, sem código.

## Limites declarados

- A amostra é de 5 nós em 72, todos de evidência confirmada. As 31 objeções e as 16 superações são
  afirmação de UM agente do Elenxo e não foram re-julgadas aqui.
- A aresta para `D_A2A_EMPRESA_PESQUISA_DECISION_1027` não foi criada: o nó não existia na `origin/main`
  no momento do pós-run.
