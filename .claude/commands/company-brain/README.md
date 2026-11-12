# 🧠 Comandos `company-brain/` — vertical Company Brain

Comandos da **vertical company-brain-context**: o conhecimento da empresa consultado por quem não é dev,
por meio de uma persona de serviço com regras de voz e conduta aprovadas e conferidas por máquina.

> **Categoria de comando ≠ dimensão peer.** Como `design/`, esta categoria organiza comandos de um
> contexto; ela não afirma uma 4ª dimensão.

## Comandos

| Comando | Faz |
|---------|-----|
| [`/company-brain:help`](help.md) | O que a vertical entrega e o próximo passo a partir do estado vivo. |
| [`/company-brain:persona`](persona.md) | Warm-up da persona: resolve o contexto, valida as regras (`voice-conduct-check.sh --require`) e só então a carrega. |

## Próximo (declarado)

- **Gate pré-envio**: mede a mensagem (tamanho, marcações, assinatura, link testado) contra o `send_gate`
  do arquivo de regras e barra o envio que reprova.

## Fonte canônica

- Skill `onion-company-brain-context` (contrato e migração) · hub `company-brain`
- Estudo: `docs/evolution/research/company-brain-non-devs-2026-11/`
