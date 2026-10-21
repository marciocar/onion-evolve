---
title: Dissecação da Intelligent UI do ChatGPT (GPT-6) — o que costurar no Onion
date: 2026-10-21
kg: docs/evolution/dissect/intelligent-ui-2026-10/intelligent-ui-2026-10.kg.yaml
run_id: wf_95b7868c-c7d
tokens: 917783
agents: 13
duration_min: 11
review_after: 2026-11-20
type: dissect
mode: primaries
---

> **Projeção do grafo, nunca fonte.** O veredito `D_INTELLIGENT_UI_1021` está **open**, e quem sela é o
> maestro. A escada foi conduzida pela sessão e pelo motor de pesquisa no modo primárias, porque o motor
> não conhece níveis (declarado no `/meta:dissect`).

## O que se sabe

- **N0, o objeto em si: NÃO VERIFICADO.** A fonte da OpenAI sobre o GPT-6 ficou inalcançável, e nenhuma
  claim a ancora (`Q_INTELLIGENT_UI_GPT6_NOT_VERIFIED_1021`). Por isso este grafo disseca o **mecanismo
  aberto** equivalente.
- **N1, a capacidade: é convergência de mercado.** A Anthropic lançou visuais inline em 2026-03-12: o
  modelo decide quando ajudam, eles têm botões e sliders, e são efêmeros. O LibreChat renderiza artifacts
  (React, HTML, Mermaid) na v0.8.8.
- **N2, o mecanismo aberto: MCP Apps, Stable desde 2026-01-26.** Ele é HTML com perfil fixo
  (`text/html;profile=mcp-app`, URI `ui://`) numa sandbox de origem distinta, conversando com o host por
  JSON-RPC sobre postMessage nos dois sentidos. O Apps SDK da OpenAI trata o conteúdo como entrada não
  confiável. O MCP-UI (Apache-2.0) implementa o padrão.
- **N3, o que transfere:** o conceito transfere; o host não. O terminal do Claude Code não é host MCP Apps.
  O host interativo que o core já tem é o **Artifact** do Claude Code, com estado. O brain só ganha MCP Apps
  quando o LibreChat estável trouxer o recurso (hoje ele está na canary, com opt-in).

## Veredito proposto: costurar (não absorver)

| Peça (N4) | Alvo | Peças | Estado do alvo (forge-census) |
|---|---|---|---|
| Painel interativo opcional do `/meta:decide`, como Artifact com estado, selado pelo mesmo selador | `decide` | 2, 3, 7 | as 3 existem, e o forge as altera |
| Recurso `ui://` do onion-kg para o brain (gated: LibreChat estável com MCP Apps) | `novo:onion-kg-ui-resource` | 1, 7 | alvo novo |

Opções no nó: A (as duas) · B (só o painel) · C (só o recurso ui://) · D (parquear até a fonte da OpenAI
ser lida). Nenhuma peça usa o nome "Intelligent UI" nem a marca OpenAI/GPT.

## NÃO-VERIFICADOS

- A Intelligent UI do GPT-6 inteira: existência, componentes, critério de uso e streaming antes do fim do
  raciocínio.
- O sandbox e o protocolo do Apps SDK, rebaixados na ancoragem.
- O render de MCP Apps no brain v0.8.8.
- O eixo de mercado e capital, que ficou vazio (`E_OBJECAO_16`).
- 7 claims rejeitadas na ancoragem.

## valeu-a-pena

917.783 tokens ÷ 28 nós ≈ 33k por nó, com 13 agentes em ~11 min. O ganho principal foi negativo e barato:
descobrir que o objeto não tem fonte legível, e que o mecanismo aberto já existe e é Stable.
