---
name: help
description: Ajuda contextual da vertical Company Brain — o que ela entrega e os próximos passos a partir do estado vivo do adotante.
allowed-tools: Read Bash(git *) Bash(bash .claude/utils/scope/resolve-context-dir.sh *) Bash(bash .claude/validation/voice-conduct-check.sh *)
category: company-brain
tags: [help, company-brain]
version: "0.1.0"
updated: "2026-11-12"
---

# 🧠 Company Brain — Ajuda

Sem argumentos: mostro **o que a vertical entrega**, seus comandos e os **próximos passos** derivados do
estado vivo do adotante.

## O que a vertical entrega

O **Company Brain para quem não é dev**: o conhecimento da empresa consultado por chat e pelo Claude desktop
por meio de uma **persona de serviço**. Nesta onda a vertical entrega o contexto (resolver + book), a
persona como sessão carregada por warm-up e a **peça de voz e conduta**: um arquivo de regras por adotante,
versionado e aprovado pelo dono, conferido por máquina antes de a persona falar.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| `/company-brain:help` | esta ajuda |
| `/company-brain:persona` | carrega a persona: valida as regras de voz e conduta e só então fala |

> **Prefixo por instalação:** o namespace pode aparecer como `/company-brain:` ou com prefixo de plugin;
> cite o prefixo real da instalação.

## Próximos passos (estado vivo)

1. Rode `bash .claude/utils/scope/resolve-context-dir.sh company-brain --source` e diga onde mora o contexto.
2. Rode `bash .claude/validation/voice-conduct-check.sh --require` e leia o rc:
   - **0** → as regras valem: próximo passo é `/company-brain:persona`;
   - **1** com `VC-FILE-ABSENT` → não há regra: bootstrap pela skill `onion-company-brain-context` (seção 1, passo 4);
   - **1** com outro código → regra inválida ou revisão vencida: o dono corrige e reaprova;
   - **2** → não pude julgar: diga o que faltou (python3, PyYAML, declaração de contexto).
3. Há regras em prosa noutro lugar? Siga a migração da skill (seção 4).

Nunca invente o estado: se o comando não rodou, diga.

## Troubleshooting rápido

| Sintoma | Ação |
|---------|------|
| "por onde começo?" | o hub `company-brain` roteia a partir do estado |
| `VC-REVIEW-OVERDUE` | o dono revisa, sobe a versão, registra no `history` e reaprova |
| `VC-APPROVER-NOT-OWNER` | só o dono aprova; corrija `approved_by` com a aprovação real, nunca à mão sem ela |

## Fonte canônica

- Hub: skill `company-brain` · Contexto e contrato: skill `onion-company-brain-context`
- Esquema: `.claude/utils/company-brain/voice-conduct.schema.yaml`
