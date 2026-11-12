---
name: company-brain
description: >
  Hub da vertical Company Brain (company-brain-context): o conhecimento da empresa consultado
  por quem não é dev, por meio de uma persona de serviço com regras de voz e conduta aprovadas.
  Use quando o usuário precisar de orientação sobre por onde começar nesta vertical: carregar a
  persona, escrever ou revisar as regras dela, migrar regras locais em prosa. Ative também
  quando a mensagem for essencialmente só a palavra "company-brain" (invocação isolada). Roteia
  a partir do ESTADO OBSERVADO e da SSOT do adotante; nunca inventa. NÃO ative por menções a
  "company brain" dentro de frases (nomes de arquivo, estudos, código).
---

# 🧠 Company Brain — Hub

Roteador da vertical **company-brain-context**. Lê o estado vivo, resolve o contexto do adotante pela skill
`onion-company-brain-context` e aponta o passo certo. **Deriva do estado; não embute listas.**

## Como roteio

1. **Leio o estado**: a pasta do contexto (`bash .claude/utils/scope/resolve-context-dir.sh company-brain`),
   se há `voice-conduct.yaml` e se ele vale (`bash .claude/validation/voice-conduct-check.sh`).
2. **Roteio por intenção**:
   - "carregar / ligar a persona" → `/company-brain:persona` (para se as regras não valem);
   - "escrever / revisar / migrar as regras" → skill `onion-company-brain-context` (seções 3 e 4);
   - "o que a vertical faz / próximo passo" → `/company-brain:help`.
3. **Nunca invento**: sem SSOT, digo "não encontrei o contexto do Company Brain — operando sem ele".

## Fronteira

- Resolver o contexto e o contrato de voz e conduta → skill `onion-company-brain-context`.
- Ajuda contextual → `/company-brain:help`. Carregar a persona → `/company-brain:persona`.
- Este hub **orquestra**; a regra é do adotante, a conferência é do validador.
