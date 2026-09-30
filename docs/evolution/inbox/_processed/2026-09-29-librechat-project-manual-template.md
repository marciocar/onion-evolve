---
title: 'Template de manual para projetos servidos pelo LibreChat (agente + MCP + atalhos), nascido do SGE'
date: 2026-09-29
from: sge (adotante, role adopted, pin ba0d2d423c17)
to: core (onion-evolve)
type: feature
severity: medium
flow: upstream
---

# Template de manual para projetos no LibreChat — o que o SGE aprendeu em uso real

## Pedido do maestro

> "quero que este manual vire um template para manual de projetos como este para o LibreChat, conte tudo isso
> para o core"

O SGE (Sistema de Gestão de Editais, cliente HPE Automotores) é servido ao cliente por um **agente no LibreChat**
(chat.onionevolve.com), ligado a um **servidor MCP próprio** (30 ferramentas) e a **24 atalhos "/"**. O manual do
usuário foi construído e refinado com o maestro em 2026-09-29, em várias passadas de uso real. Ele serve de molde
para qualquer projeto no mesmo formato: agente + servidor MCP + atalhos + cliente externo.

## Os artefatos (no adotante `/home/marcio/sge`)

| Arquivo | O que é |
|---|---|
| `docs/templates/librechat-project-manual.html` | **o template**: HTML único com 14 marcadores (`{{PROJETO}}`, `{{AGENTE}}`, `{{SERVIDOR_MCP}}`, `{{PREFIXO}}`, `{{URL_CHAT}}`…), cada seção marcada GENÉRICO, SEMIGENÉRICO ou DOMINIO, e o guia de preenchimento no topo |
| `docs/business-context/site/manual-sge-hpe.html` | a referência preenchida (o manual do SGE), publicada como Artifact privado |
| `docs/business-context/manual-sge-chat.md` | o mesmo manual em texto, lido pelo agente com `read_report` |
| `mcp/agents/sge-hpe.md` | o agente (fonte versionada; o seed projeta no LibreChat) |
| `mcp/agents/sge-hpe-prompts.yaml` + `mcp/agents/seed_librechat_agent.py` | os atalhos e o seed que os projeta |

PRs do adotante com a história: #72 (manual + página única com acesso passo a passo), #73 (chat, agente e
ferramentas), #74 (caminho principal em destaque), #75 (atalhos pelo comando completo), #76 (achados sem códigos
internos).

## O que o uso real ensinou (o conteúdo que o template carrega)

1. **A ordem da página importa mais que o conteúdo.** Primeiro a v1 (acesso + referência), depois o maestro
   corrigiu três vezes até chegar a: **01 acesso passo a passo** (em destaque, com telas ilustradas) → **02 o
   caminho principal** (o fluxo que gera valor para o cliente, em trilhas "tem → conferir / não tem → gerar") →
   **03 atalhos** → **04 chat, agente, MCP e ferramentas** → o resto como referência.
2. **Tom de cliente.** "Não coloque problemas descaradamente, eles são clientes": nada de achados sobre falhas do
   próprio cliente, percentuais de acerto, bugs corrigidos nem jargão interno. Limites viram "como tirar o melhor";
   "quando algo não funciona" vira "dúvidas frequentes". Os achados para decisão ficam num documento interno.
3. **Acesso escrito a partir das telas reais.** Os textos pt-BR do provedor de login foram lidos da API pública
   de frases do Logto e a política de MFA da configuração (só leitura), em vez de escritos de memória. Achou
   divergência: o link é "Esqueceu **sua** senha?"; o MFA é `NoPrompt` (opcional); existe login por código.
4. **Atalhos: o "/" do LibreChat (v0.8.8-rc4) busca pelo NOME do prompt, não pelo `command`.** O manual ensinava
   `/situa` (palavra do nome). O maestro pediu o comando completo, sem acento. Solução: o seed compõe o nome
   começando pelo comando (`sge-situacao · Situação do caso`). Medido no chat: `/sge-situacao` traz o atalho em
   1º, e `/sge` lista todos. Um atalho de destaque (`/sge-validar-pacote`) faz o caminho principal num pedido só.
5. **Perguntas de exemplo são "momentos wow".** Cada uma entra só depois de testada com dados reais do cliente,
   com "o que você recebe". Exemplo medido: numa análise de engenharia, 10 perguntas marcadas QUESTIONAR já tinham
   resposta publicada pelo órgão; o agente as achou com a célula e a linha do esclarecimento.
6. **O agente escreve na língua do cliente.** No teste pelo chat vieram códigos internos (`MACHINE_DIVERGENCE`,
   `ADAPT_NOT_CHECKED`) e nomes de ferramentas na prosa. O agente ganhou uma tabela código → rótulo em português.
7. **Servidor MCP com cabeçalho por usuário conecta sob demanda.** Depois de reiniciar o LibreChat ou o servidor,
   o painel de servidores MCP mostra "desconectado" até a 1ª pergunta. É normal, mas o maestro estranhou; foi
   para as dúvidas frequentes.
8. **LibreChat v0.8.8 sem Redis:** o agendador não sobe ("scheduler NOT started") até o deploy declarar réplica
   única com `SCHEDULES_SINGLE_PROCESS=true`. Resolvido no stack, commit `7871626`.
9. **Página:** HTML único, tokens claro/escuro, índice fixo com a seção atual, busca que filtra seções, atalhos,
   ferramentas e glossário, "Copiar" com fallback, responsiva (conferida renderizada a 1440 e 390 px com o
   Chromium headless do servidor, porque o Claude in Chrome não alcança o frame do Artifact).

## Proposta para o core

- Absorver o template como **template do framework** (ex.: `.claude/commands/common/templates/`), com o guia, e um
  comando que o preencha a partir do agente, do YAML de atalhos e da lista de ferramentas do servidor MCP (ex.:
  `/docs:build-librechat-manual`), sempre com conferência humana das seções DOMINIO.
- Levar os achados 4, 7 e 8 para a KB de LibreChat/MCP do core: busca do "/" pelo nome, conexão MCP sob demanda,
  réplica única do agendador.
- Levar os achados 2 e 5 para a doutrina de material para cliente: tom de cliente e perguntas testadas.

Nada a fazer no adotante depois do relay: o template já está versionado aqui e segue em uso pelo SGE.
