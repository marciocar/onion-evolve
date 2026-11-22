# 📱 adapter — WhatsApp pelo WAHA (`provider: waha`)

> O 1º adapter do contrato [`onion.chat/v1`](../interface.md). **Escopo:** só canais internos e com os sócios; a
> conversa com cliente final vem depois pela Cloud API oficial do WhatsApp Business, com o mesmo contrato e outro
> adapter (`D_WAHA_INTERNAL_ONLY_OFFICIAL_FOR_CUSTOMERS_1121`). O WAHA não é oficial: o número pode ser banido, e o
> contrato exige que a fila sobreviva à perda do canal.

## Onde roda

**Não no core.** O executável mora na peça de mensageria, que opera o canal e lê a chave do WAHA pela própria
unidade; o agente nunca vê a chave. Hoje a peça tem:

- **envio**: `tools/notify-partner` (código em `tools/notify/remind.py`), por apelido da lista fechada, com quem
  pediu em cada envio, teto por destino e dia com linha pending, guarda de vazamento e anexo conferido;
- **recepção**: o vigia (`watcher/`) confere o HMAC do webhook do WAHA e põe na fila durável (`queue/`) um
  CloudEvent 1.0 com o corpo bruto; a fila deduplica e tem `ack`, reentrega e dead-letter.

A declaração do que cada parte cumpre está em [`waha.capabilities.tsv`](waha.capabilities.tsv), medida por leitura
do código em 2026-11-22 (a `origin/main` do repo da peça, conferida por `git ls-remote`). Nada foi rodado contra o WAHA.

## O que falta para ficar conforme (lado da peça)

Medido com `conformance.py capabilities adapters/waha.capabilities.tsv --strict`: 3 de 17 capacidades
obrigatórias implementadas. A ordem abaixo segue o 1º entregável que o Delphi pediu (os 5 campos, o mapa de
identidade e a recepção durável):

0. **A chave do WAHA sai do arquivo privado para o credstore da unidade** (`LoadCredential`), acréscimo que o
   Delphi pôs no 1º entregável.
1. **Normalizar a recepção**: do CloudEvent com o corpo bruto do WAHA para o `message.received` com os 5 campos, e
   rodar `conformance.py check` sobre essa saída na bancada da peça, com o WAHA simulado e mutantes.
2. **Mapa de identidade** (`identity.resolve`): id do WhatsApp para pessoa e papel; sem pessoa, papel `unknown`.
3. **Dedupe pelo id da mensagem do WhatsApp**, não só pelo sha256 do corpo assinado (`rule.dedupe_provider_id`).
4. **Audiência por conversa antes de responder** (`audience.list`), com a lista de participantes do grupo.
5. **Responder no fio** (`message.reply_thread`), o **passo «serviu?»** (`served.ask`) e a **latência** (hora do pedido
   e hora em que o agente viu).
6. **Retenção** dos corpos e mídias como dado de terceiros (prazo, fora do backup externo ou cifrados), **auditoria
   da recepção** com quem pediu, **marca de quem leu**, e a **perda do número** medida sem perder a fila.
7. **Fechar as parciais**: a guarda de vazamento reconhecer dado de quem não está na audiência, o ritmo por conversa,
   e medir se o log do vigia (texto da exceção) pode levar número ou dado.

## Mapeamento WAHA → contrato (o que a peça precisa ler)

| campo do contrato | de onde vem no WAHA |
|---|---|
| `provider_message_id` | o id da mensagem no evento `message` do webhook |
| `requested_at` | o carimbo da mensagem no WhatsApp (assinado no corpo), não a hora de recebimento |
| `requester.provider_id` | o remetente (no grupo, o participante; não o grupo) |
| `place.id` / `place.kind` | o chat (`@g.us` = `group`, `@c.us` ou LID = `direct`) |
| `thread.reply_to` | a mensagem citada, quando houver |
| `audience.members` | os participantes do grupo; na conversa direta, as duas pontas |

> Os nomes exatos dos campos do WAHA não estão pinados aqui, de propósito: a versão do WAHA é da peça, e o
> mapeamento se prova na bancada dela, não nesta prosa.
