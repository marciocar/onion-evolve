---
name: build-project-manual
description: Montar o manual de UM PROJETO — a página que o usuário final dele abre — quando esse projeto é servido por agente + servidor MCP + atalhos.
allowed-tools: Read Write Bash(git *) Bash(ls *) Bash(find *) Bash(grep *)

parameters:
  - name: projeto
    description: Sigla e nome do projeto, o cliente, e onde vivem o agente, os atalhos e o servidor MCP
    required: true

category: docs
tags:
  - client-facing
  - agent-mcp
  - documentation

version: "1.0.0"
updated: "2026-09-30"

output_path: docs/business-context/site/

related_commands:
  - /docs:build-business-docs
  - /meta:create-knowledge-base

related_agents:
  - storytelling-business-specialist
---

# 📘 /docs:build-project-manual — o manual que o usuário do projeto abre

> ⚠️ **Não é o manual deste framework.** É o manual de **um projeto seu** (ou de um projeto que você
> entrega), para quem vai usá-lo. O nome anterior era `build-client-manual` e podia ser lido como
> material do framework para quem o adota — exatamente a leitura errada, apontada pelo maestro antes
> do commit.

Monta o manual de um projeto que é **servido ao cliente por um agente** ligado a um servidor MCP e a
atalhos. É superfície **fina**: a lente vive num fragmento e a forma num esqueleto — este comando
conduz, não redefine.

- **Doutrina (tom, ordem, critério de exemplo, rótulos):** [`client-material-doctrine.md`](../common/prompts/client-material-doctrine.md) — leia antes de escrever uma linha
- **Esqueleto:** [`agent-project-manual-template.html`](../common/templates/agent-project-manual-template.html)
- **Fatos da plataforma (decaem por versão):** [`librechat-agent-mcp.md`](../../../docs/knowledge-base/tools/librechat-agent-mcp.md)

## Fronteira, declarada primeiro

Este comando produz material **client-facing**, e por isso ele **não** publica sozinho e **não**
inventa exemplo. Duas coisas são humanas por desenho: a conferência das seções `[DOMINIO]` e o teste
de cada pergunta de exemplo com dados reais. O que ele automatiza é o resto.

## Etapas

1. **Ler a doutrina** (o fragmento acima). Ela decide a ordem das seções e o tom; nada aqui a repete.
2. **Medir a instância, não lembrar dela** — e cada item sai de uma fonte viva:
   | o que | de onde (nunca de memória) |
   |---|---|
   | nome e ferramentas do agente | o arquivo do agente versionado no projeto + a lista do servidor MCP |
   | atalhos e seus comandos | o YAML de prompts que o seed projeta |
   | passos de acesso, textos de botão, política de MFA | a configuração do provedor de login e as telas reais |
   | o caminho principal | o fluxo que gera o valor para **este** cliente |
3. **Copiar o esqueleto** para `docs/business-context/site/manual-<projeto>.html` e trocar os
   marcadores. As seções `[DOMINIO]` são **reescritas**; as `[SEMIGENÉRICO]` ajustadas; as
   `[GENÉRICO]` conferidas.
4. **Separar os dois leitores** (cláusula 2 da doutrina): achados sobre limites, falhas e percentuais
   vão para um documento **interno** — nunca para esta página. A página traz "como tirar o melhor" e
   "dúvidas frequentes".
5. **Testar as perguntas de exemplo** com dados reais do cliente **antes** de incluí-las, cada uma com
   "o que você recebe". Exemplo não testado é promessa que falha na frente do cliente.
6. **Conferir renderizado**, em largura de desktop e de telefone. Render não se supõe — e se a página
   virar Artifact, o navegador do Claude não alcança o frame dele: use navegador headless.
7. **Espelhar em texto, se o agente lê o manual** por ferramenta: mesma substância num `.md`, nunca
   uma segunda verdade que vai divergir.
8. **Publicar mantendo o mesmo link** a cada versão, para que o link que o cliente guardou continue
   valendo.

## 🔗 Referências

- Sinal de campo que originou o formato: `docs/evolution/inbox/_processed/2026-09-29-librechat-project-manual-template.md`
- Irmãos: [`/docs:build-business-docs`](build-business-docs.md) · [`/meta:create-knowledge-base`](../meta/create-knowledge-base.md)
