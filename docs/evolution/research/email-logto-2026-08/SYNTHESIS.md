---
title: "Pesquisa F1 — Email: provider + conector do Logto 1.41 + deliverability em VPS"
category: research
date: 2026-08-01
status: sintese-ratificavel
method: "Elenxo orquestrado (fan-out-and-synthesize) — 4 workers: 3 research web-verificados (conectores Logto · providers · deliverability) → 1 síntese (opus/high)"
run_id: wf_c93e95b8-fdd
kg: docs/evolution/research/email-logto-2026-08/email-logto-2026-08.kg.yaml
---

# Email — síntese F1

> **Projeção do grafo.** SSOT: [`email-logto-2026-08.kg.yaml`](./email-logto-2026-08.kg.yaml).
> Contexto: F1-email da investigação de ferramentas VPS (catálogo).

## ⚑ Correção de premissa (o "gap" era menor do que se dizia)

A premissa registrada era *"a falta de conector de email TRAVOU o convite de organização"*. **Parcialmente falso:**
o Logto **cria o convite sem conector** — `POST /api/organizations/{id}/invitations` com `messagePayload: false`
retorna o `id` para entrega manual. Sem conector, só o **envio automático** falha (501 *"No email connector is
configured"*). **Email é acelerador de entrega, não pré-requisito do convite** — e o `--enroll` que o gap forçou
é o **modo degradado legítimo**, o "Null Object" nativo do canal. Não descartar depois.

## Veredito do Teste do Eixo: **SCRIPT, não SDAAL** — e falha nos dois níveis

**Boca (a) — conector do Logto:** a condição (a) *passa* (Resend/Postmark/SES/Brevo/Mailgun/Postfix são
intercambiáveis **por construção**, porque **o contrato já existe e se chama SMTP**). Mas **(b) falha** — a escolha
vive na config **dentro do Logto** (DB do tenant), não num `.env` nosso; e o Logto só admite **1 conector de email
ativo por tenant**, então não há seleção em runtime a abstrair. **(c) falha por vacuidade** — o consumidor é o
**Logto**, que não é nosso código e **já é cego**, por um contrato que não escrevemos. Envolver isso numa
interface+factory seria **re-embrulhar uma abstração existente**.

**Boca (b) — ferramenta de membro:** **(a) falha duro** — hoje há **zero** solução real. Ligar a primeira leva de
**0 → 1**. Teste do Gatilho: *1 real + N prometidos = script*.

**Nível-1 (`messaging`) também não gradua:** verificado no vivo — o ntfy é `curl` **hardcoded** em
`.claude/utils/co-evolution/mail-receiver.sh:59-66`, não um adapter; `.claude/utils/messaging/` não existe.
Somar um script de email dá **dois scripts, não dois adapters**. *"Aninhar não relaxa o gate — multiplica-o."*

**Gatilhos para reabrir:** (1) nível-2 — um consumidor **do Onion** + 2º provider real em uso por ambiente
diferente (ex.: core usa X, adotante regulado exige BYO-SMTP); (2) nível-1 — um consumidor que **precise** ser
cego ao canal (ex.: `notify()` que sai por push **ou** email conforme `.env`).

## Provider — a recomendação e o dissent que a contradiz

**Síntese recomendou:** Resend default (3.000/mês grátis, sem branding, logs 30d, webhooks ricos), Postmark como
2º ratificado, com regra de flip escrita antes de medir.

**🔴 O dissent (mais forte que a recomendação):** *"escolhi otimizando o free tier, e free tier é **economia** — não
eficácia."* A régua do maestro é **`efficiency-over-economy`**. Postmark custa **US$15/mês** — ~zero contra o risco
de um convite de auth perdido no spam. E há substância: **para email de autenticação, entregabilidade É o produto
inteiro**; a Postmark construiu a reputação toda em transacional e **recusa mala-direta** como negócio, o que mantém
os IPs compartilhados limpos. **A pesquisa não mediu que a Resend entrega tão bem quanto a Postmark.** O argumento
de volume ainda é **circular** — depende de habilitar sign-in por código, decisão não tomada; sem isso o volume real
fica **abaixo de 100/mês**, que o free permanente da Postmark cobre.

## Rejeitados, com número

| Opção | Por que não |
|---|---|
| **Brevo** | 300/dia grátis **com branding Brevo** (num email de IdP é inaceitável) + cota compartilhada marketing/transacional |
| **Mailgun** | free com **retenção de log de 1 DIA** (mata a forense de entrega) + IP compartilhado com relatos de problema em Yahoo/Hotmail |
| **AWS SES** | free tier de 62k **morto desde 2023**; nasce em **sandbox**; bounce via **SNS**, não webhook HTTP. Atrito desproporcional ao volume |
| **Self-host (Postfix/maddy)** | **Hostinger limita 5 emails/min**; IP de datacenter frio é estruturalmente desconfiado; **sem webhook de bounce** (só NDR a parsear). *Um convite de auth no spam é um convite silenciosamente quebrado* |

## O caminho crítico é **DNS**, não o Logto

SPF + DKIM obrigatórios; DMARC começando em `p=none`; **propagação 24-48h**; só então subir enforcement.
Config do conector leva **10 minutos**. Enviar de **subdomínio dedicado** (`mail.onionevolve.com`), não do apex —
isola reputação transacional e deixa o apex livre para MX humano.

## A lição do WhatsApp, reencenada no email

O Logto é **fire-and-forget** (Nodemailer, **sem ACK nativo** — hipótese não refutada). Logo **a prova de entrega
tem de vir do webhook do provider**, fora do Logto (`email.delivered`/`bounced`/`complained`, **com idempotência** —
o Resend pode duplicar evento). **Sem isso, "o convite foi enviado" é declaração, não medição.**
E o `Send test email` do console prova **só o aceite (SMTP 250)** — o teste real é o convite caindo na **inbox** de
duas caixas distintas (Gmail + Outlook).

## Gaps que exigem verificação **no deploy** (doc ≠ comportamento)

1. Conectores realmente pré-embutidos na imagem 1.41.0? (`docker exec onion-logto ls …/connectors` + console)
2. `usageType: OrganizationInvitation` existe em **1.41.0**? (a doc é "latest", não versionada)
3. **Qual o placeholder do link de convite?** A doc só documenta `{{code}}` — convite é **link**. Template errado passa no "test email" e entrega convite quebrado
4. O rate-limit de **5 msg/min** da Hostinger vale só p/ porta 25 ou p/ saída SMTP em geral? Testar `openssl s_client -connect smtp.resend.com:465` **antes**. Plano B: custom connector HTTP (sai por 443)
5. Estado atual do DNS (`dig TXT/MX`) — **nunca verificado**; SPF preexistente conflitante quebra tudo (só 1 SPF por domínio)
6. O Logto tem **retry** se o SMTP falhar, ou o convite se perde em silêncio? (o modo de falha mais perigoso)
7. CRUD de conector via Management API para IaC — consultar o **OpenAPI da própria instância**, não a doc pública
8. Para onde apontar o `rua=` do DMARC? Precisa de caixa que **realmente receba** — hoje não há MX
