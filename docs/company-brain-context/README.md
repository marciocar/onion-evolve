# 🧠 Company Brain — Book (SSOT do contexto)

> Este é o **book/SSOT** da vertical company-brain-context: o contexto vivo do Company Brain do adotante,
> que a skill `onion-company-brain-context` resolve e valida e que o hub `company-brain` consulta para
> rotear. No framework esta pasta é o **molde** (só este README); no adotante ela recebe o contexto real.
> **Contrato mínimo** (o piso, não o teto): o que não estiver aqui é "declarado ≠ verificado".

## Estado / entidades

_(No adotante: a persona de serviço (nome, canal, runtime), as audiências e papéis que a consultam, os
grafos que ela lê e o arquivo de regras `voice-conduct.yaml` desta pasta.)_

## Decisões

_(No adotante: o que foi decidido sobre a persona e o Company Brain e por quê, com o id do nó no grafo.)_

No framework, as decisões que abriram a vertical estão no estudo
`docs/evolution/research/company-brain-non-devs-2026-11/` (`D_VERTICAL_COMPANY_BRAIN_CONTEXT_AGORA_1111`,
`D_PERSONA_VOICE_CONDUCT_PIECE_1111`).

## Convenções

- As regras de voz e conduta da persona moram em `voice-conduct.yaml` nesta pasta, no esquema
  `onion/voice-conduct/v1` (`.claude/utils/company-brain/voice-conduct.schema.yaml`), e só valem com
  `bash .claude/validation/voice-conduct-check.sh --require` em rc 0.
- Quem aprova é o dono; toda versão entra no `history`; a revisão periódica vencida reprova.
- Pedir e aprovar são listas separadas; a persona copia a voz, nunca a autoridade.

---
_Stub gerado por `scaffold-book-dir.sh` (F1 do `/meta:create-vertical`) e preenchido com o domínio. Mostre o diff antes de salvar edições; never-clobber._
