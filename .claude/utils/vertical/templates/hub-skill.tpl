---
name: {{PROJECT}}
description: >
  Hub/orquestrador da vertical {{PROJECT_TITLE}}. Use quando o usuário precisar de
  orientação sobre por onde começar nesta vertical, qual comando/skill usar, ou como
  navegar o fluxo do projeto {{PROJECT_TITLE}}. Ative também quando a mensagem for
  essencialmente só a palavra "{{PROJECT}}" (invocação isolada). Roteia a partir do
  ESTADO OBSERVADO e da SSOT/book do projeto — nunca inventa. NÃO ative por menções a
  "{{PROJECT}}" dentro de frases (nomes de arquivo, código); apenas pela invocação isolada.
---

# 🧭 {{PROJECT_TITLE}} — Hub

Roteador da vertical **{{PROJECT_TITLE}}**. É o ponto de entrada: lê o estado vivo,
consulta a SSOT/book do projeto (via a skill `{{PROJECT}}-context`), e roteia para o
comando/skill certo. **Derive da SSOT viva; nunca embuta listas nem invente.**

## Como roteio

1. **Leio o estado** — branch git, sessões ativas, o que a SSOT do projeto já registra
   (delego a resolução à skill `{{PROJECT}}-context`, que localiza/valida o book).
2. **Roteio por intenção** — mapeio o pedido para o comando/skill da vertical
   {{PROJECT_TITLE}}. Para a lista viva de comandos, veja `/{{PROJECT}}:help` (deriva do
   inventário escaneado, não de uma lista embutida aqui).
3. **Nunca invento** — se a SSOT não tem a resposta, digo "não encontrei no book —
   operando sem ele" e sigo transparente (declarado ≠ verificado).

## Fronteira

- **Guardar/validar a SSOT/book** → skill `{{PROJECT}}-context` (resolver + contrato mínimo).
- **Ajuda contextual** (o que a vertical faz + próximos passos do estado vivo) → `/{{PROJECT}}:help`.
- Este hub **orquestra**; a execução mora nos comandos/skills da vertical.

> Gerado por `bootstrap-new-project.sh` (F1 do `/meta:create-vertical`). Ajuste o roteamento
> ao domínio real de {{PROJECT_TITLE}} — este é o esqueleto do padrão, não o teto.
