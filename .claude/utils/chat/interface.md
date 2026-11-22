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
    provider_id: string;         // PSEUDÔNIMO estável, nunca o id cru (ver «Identificadores» abaixo)
    resolved_by: 'provider_id';  // único valor aceito: nome exibido e texto da mensagem não identificam
    person: string | null;       // a pessoa no mapa de identidade; null = não resolvida
    role: 'internal' | 'partner' | 'external' | 'customer';  // 'external' quando person é null; 'customer' só no canal oficial
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

## Identificadores: pseudônimo, nunca o id cru

No WhatsApp o id cru é `<número>@c.us`, e o id de mensagem do WAHA também leva o número. Por isso **nenhum
identificador sai do adapter cru**: `provider_id` (de `requester`, de `audience.members[]` e de `on_behalf_of`),
`place.id`, `thread.id`, `thread.reply_to`, `provider_message_id` e `in_reply_to` são **pseudônimos estáveis**.
Forma recomendada: `<provider>:` mais os 64 primeiros bits do HMAC-SHA256 do id cru (chave privada da instância), um
nibble por letra de `a` a `p`, ou seja `<provider>:[a-p]{16}` (ex.: `waha:dpjkfaclboejdcgf`), sem nenhum dígito; o
apelido da lista fechada também serve. Hex não serve: cerca de 20% dos pseudônimos em hex têm 8 dígitos seguidos. A resolução do id cru para pessoa, e de volta
para responder no fio, acontece **só dentro do adapter**. O juiz recusa (`ID-COM-NUMERO`) identificador com 8 ou mais
dígitos (admitido um separador entre eles) ou com forma `local@domínio`, **sem exceção**.

Limites declarados da guarda de id: id nativo numérico (o `ts` de mensagem do Slack, o id de chat do Telegram) e
apelido com data ou com `@` reprovam, então todo id de mensagem e de lugar também tem de ser pseudônimo; e ela não
cobre `person`, `place.name`, `signed_by` nem `audit.id` (no WhatsApp, o nome da conversa direta costuma ser o número:
o adapter não o põe em `place.name`).

No texto da resposta, a guarda de número é heurística (10 ou mais dígitos com separadores de telefone, depois de
tirar datas e horas).

## Papel de quem pede: vocabulário fechado

`internal` (gente de dentro), `partner` (sócio), `external` (fora do mapa, ou contato de fora) e `customer` (cliente
final). Quem não está no mapa de identidade sai `external` com `person: null`. `customer` é reservado ao canal oficial
com cliente final: o juiz só o aceita do provedor `whatsapp-cloud` (lista fechada) e o recusa em qualquer outro,
inclusive no WAHA (`PAPEL`). O enum vive no schema e as linhas `role.*` do vocabulário; o juiz
recusa medir (rc 2) se os dois divergirem. Decisão do core de 2026-11-22, reversível.

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
