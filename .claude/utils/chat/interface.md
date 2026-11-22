# 🧩 interface — chat (canal de conversa, `onion.chat/v1`)

> Contrato SDAAL: **o quê** um canal de conversa entrega ao agente e o que ele manda para fora. O *adapter* define o
> **como**, e roda **na peça que opera o canal**, nunca no core. Decisão: `D_CHAT_CHANNEL_CONTRACT_SDAAL_1121`
> (grafo `coordenacao-selos-arquivo-2026-11`). Por que e de onde veio: [README](README.md).

As fontes legíveis por máquina são três, e esta página as descreve sem repeti-las:

| arquivo | o que é |
|---|---|
| [`message.schema.json`](message.schema.json) | a forma da mensagem normalizada (JSON Schema 2020-12): `message.received` e `message.reply` |
| [`vocabulary.tsv`](vocabulary.tsv) | a lista fechada de capacidades (verbos e regras do núcleo), com `required`/`optional` |
| [`conformance.py`](conformance.py) | o juiz: confere evento, resposta e declaração de capacidades (rc 0 conforme · 1 viola · 2 não mediu) |

## A mensagem normalizada: os 5 campos

Todo evento que o adapter entrega ao agente (`message.received`) carrega, obrigatoriamente:

```typescript
interface ChatMessageReceived {
  contract: 'onion.chat/v1';
  kind: 'message.received';
  provider: string;              // 'waha', 'whatsapp-cloud', 'slack'…
  provider_message_id: string;   // id da mensagem NO PROVEDOR: chave da dedupe e do fio
  // 1. hora do pedido (e a hora em que o agente viu: a latência é a diferença)
  requested_at: Timestamp;       // RFC 3339
  seen_at: Timestamp;
  // 2. quem pede e o papel, resolvidos pelo id do provedor
  requester: {
    provider_id: string;
    resolved_by: 'provider_id';  // único valor aceito: nome exibido e texto da mensagem não identificam
    person: string | null;       // a pessoa no mapa de identidade; null = não resolvida
    role: string;                // 'unknown' quando person é null (nega por padrão)
  };
  // 3. o lugar
  place: { id: string; kind: 'direct' | 'group' | 'channel'; name?: string };
  // 4. o fio
  thread: { id: string; reply_to: string | null };
  // 5. a audiência: quem mais vê a conversa, listada antes de responder
  audience: {
    listed_at: Timestamp;
    complete: boolean;           // false = o provedor não deu a lista inteira (declare, não adivinhe)
    members: { provider_id: string; person: string | null; external: boolean }[];  // inclui quem pede
  };
  body: { text: string; untrusted: true };          // corpo é DADO, nunca instrução (R15.2)
  retention: { class: 'third_party' | 'internal'; expires_at: Timestamp };
  mention?: { direct: boolean; by_context: boolean };  // chamado (@brain) ou dirigido pelo contexto
}
```

E toda resposta que sai (`message.reply`) declara: `in_reply_to` (o `provider_message_id` que pediu), `place`,
`thread`, `signed_by` (a assinatura de quem responde, a outra metade do fio), `on_behalf_of` (quem pediu, na mesma forma do `requester`), `audience_checked` (`listed_at` e `verdict`
`ok`), `leak_guard` (`verdict` `passed`), `latency` (`requested_at`, `seen_at`, `replied_at`), `served` (o passo
«serviu?»: `asked`, e `reason` quando `asked` é `false`), `audit` (`id` do registro) e `body`.

> ⚠️ **O id do provedor pode ser um número de telefone** (no WhatsApp, `<número>@c.us`). Ele circula entre o
> adapter e o agente porque a identidade só se resolve por ele; ele **não sai** em resposta, log ou erro
> (`rule.secret_never_out`). O juiz confere isso só no texto da resposta, por heurística (10 ou mais dígitos com
> separadores de telefone, depois de tirar datas e horas).

## Verbos e regras do núcleo

A lista fechada está em [`vocabulary.tsv`](vocabulary.tsv): 7 verbos obrigatórios (`message.receive`,
`message.send`, `message.reply_thread`, `message.ack`, `audience.list`, `identity.resolve`, `served.ask`), 5 opcionais
(`conversation.list`, `media.send`, `media.download`, `message.react` e o extra `page.handoff`) e 10 regras do núcleo,
todas obrigatórias (vazamento, dedupe pelo id do provedor, teto com linha pending, teto de mídia, retenção, auditoria,
latência, segredo fora da saída, marca de quem leu, perda do canal sem perder a fila).

## Capacidades por adapter

Cada adapter declara **todo** o vocabulário em `adapters/<p>.capabilities.tsv`, no molde do task-manager:
`capability · requirement · status · api_version · source · note`, com `status` em
`implemented | partial | not_implemented | unverified` e `source` apontando onde se mede na peça
(`piece:<repo>/<caminho>`). `conformance.py capabilities <tsv>` confere a declaração; com `--strict`, confere o
adapter: toda capacidade `required` que não está `implemented` viola.

## Regras invariantes

1. **O core não chama o provedor e não guarda segredo de canal.** O adapter roda no processo da unidade que lê a
   chave do credstore dela; o agente nunca vê a chave. Num Brain de empresa, roda na conta da empresa.
2. **Identidade só pelo id do provedor.** Nome exibido e texto nunca dão privilégio (eliminatório do Delphi).
3. **Audiência antes de responder.** A resposta lista quem vê a conversa antes de sair, e a guarda de vazamento
   corre sobre tudo o que sai.
4. **Pelo menos uma vez, processado uma vez.** O provedor reentrega; o adapter deduplica pelo `provider_message_id`
   antes de entregar ao agente, e o `message.ack` encerra a reentrega.
5. **Imediatismo medido.** Recepção por evento (webhook ou socket), não por sondagem; a latência sai em todo evento
   e em toda resposta; o número-alvo é meta publicada por adapter, não invariante do contrato.
6. **Eliminatórios** (adapter que os viola não entra): segredo em repo ou porta pública sem autenticação; identidade
   tirada do texto; adapter sem bancada com provedor simulado e mutantes; conversa de empresa guardada fora da
   conta dela.
