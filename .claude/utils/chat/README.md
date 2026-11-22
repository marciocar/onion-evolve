# 💬 chat — contrato SDAAL de canal de conversa (`onion.chat/v1`)

Um contrato, um adapter por ferramenta (WhatsApp, Slack, Teams, Telegram). O agente responde e age **na hora**
quando é chamado (`@brain`) ou quando entende pelo contexto que é com ele, dentro do privilégio de quem pede; para
isso todo canal entrega a mesma mensagem normalizada e cumpre as mesmas regras do núcleo.

| peça | arquivo |
|---|---|
| contrato (a forma e as regras) | [`interface.md`](interface.md) · [`message.schema.json`](message.schema.json) · [`vocabulary.tsv`](vocabulary.tsv) |
| juiz de conformidade | [`conformance.py`](conformance.py) |
| exemplos conformes | [`examples/`](examples/) |
| adapters (declaração e prosa) | [`adapters/waha.md`](adapters/waha.md) · [`adapters/waha.capabilities.tsv`](adapters/waha.capabilities.tsv) |
| onde cada adapter é cobrado | [`enforcement.tsv`](enforcement.tsv) (REGRA 107 (Adapter SDAAL declara onde o seu contrato é cobrado)) |

## A decisão

- **`D_CHAT_CHANNEL_CONTRACT_SDAAL_1121`** (grafo `coordenacao-selos-arquivo-2026-11`): o maestro selou em
  2026-11-21 a síntese de um Delphi de 4 sessões, unânime. Contrato e testes de conformidade no core; o adapter roda
  na peça que opera o canal, com a chave lida só pela ferramenta; 5 campos; 1º adapter WhatsApp; sem Matrix/Synapse.
- **`D_WAHA_INTERNAL_ONLY_OFFICIAL_FOR_CUSTOMERS_1121`**: o WAHA (não oficial) só nos canais internos e com os
  sócios; o cliente final vem depois pela Cloud API oficial do WhatsApp Business, mesmo contrato, outro adapter.

- **Decisões do core de 2026-11-22, reversíveis** (lacuna apontada pela sessão da mensageria antes do merge):
  (1) todo identificador que sai do adapter é pseudônimo (`<provider>:<HMAC-SHA256 16 hex>` ou apelido), porque o id
  cru do WhatsApp é o número e contradiz `rule.secret_never_out`; (2) o papel de quem pede é vocabulário fechado,
  `internal | partner | external | customer`, com `customer` reservado ao canal oficial com cliente final e quem não
  está no mapa como `external` com `person: null`. Detalhe em [`interface.md`](interface.md).

**Por que não há `factory.md` nem `detector.md` aqui**, ao contrário do task-manager: o core não escolhe nem chama
o adapter. Quem roteia é a peça que opera o canal. O core guarda o contrato e o juiz.

## Como usar o juiz

```bash
python3 -I -B .claude/utils/chat/conformance.py check saida-do-adapter.jsonl     # eventos e respostas
python3 -I -B .claude/utils/chat/conformance.py capabilities adapters/<p>.capabilities.tsv [--strict]
python3 -I -B .claude/utils/chat/conformance.py --vocabulary
```

rc 0 conforme · 1 viola (uma linha `VIOLA` por achado, com código: `SEM-ID-DO-PROVEDOR`, `ID-COM-NUMERO`, `PAPEL`, `IDENTIDADE-FORA-DO-ID`,
`SEM-AUDIENCIA`, `DUPLICADO`, `VAZAMENTO`, `LATENCIA`, `RETENCAO`, `SERVIU`, `FIO`, `FORMA`…) · 2 não mediu (arquivo
ausente ou vazio, `jsonschema` ausente). A peça roda o juiz na própria bancada, sobre a saída do adapter com o
provedor simulado; a bancada do core (`run_chat_conformance_selftests`) tem um caso para cada código de falta e
prova, com mutantes do próprio juiz, que os casos mordem.

**Limite declarado:** o juiz confere forma e regras que cruzam campos. Não sabe se o id do provedor é verdadeiro,
se a identidade resolvida é a pessoa certa, nem se a guarda de vazamento da peça funciona; lê o veredito que ela
declara. Um adapter que escreva `resolved_by: provider_id` tendo tirado a pessoa do texto passa aqui: isso só a
bancada da peça, com mutantes, pega. Também não confere: o frescor da audiência (só a ordem em relação à resposta), a
coerência entre quem pede e a mesma pessoa na audiência, a normalização do id na dedupe (a chave é exata: normalizar
é dever do adapter), campo extra fora do contrato (o schema é aberto no topo), nem a resposta sem o evento no mesmo
fluxo (aí o cruzamento com a mensagem respondida não roda). A heurística de número no texto da resposta é
heurística: telefone escrito com `:` ou `/` ou com traço tipográfico passa, e lista de números curtos pode reprovar.

## A síntese do Delphi (registro)

Delphi `chat-channel-contract-1121`, 3 rodadas (posições independentes, crítica cruzada sem autor, convergência),
participantes: as sessões donas da mensageria, da operação dos serviços da VPS, do Company Brain e da curadoria, sobre a dissecação da categoria
«canal de conversa» feita pela curadoria em 2026-11-21 (veredito «perseguir»: nenhum dos seis frameworks abertos
confrontados entrega o pacote, e nenhum traz privilégio por quem pede). Até este registro, a síntese só existia no
estado do Delphi, fora do git. Texto da síntese levada à rodada 3, sem edição de conteúdo:

**Pergunta:** contrato SDAAL de canal de conversa (WhatsApp/WAHA, Slack, Teams, Telegram): (a) o contrato e o
executável moram no core (`.claude/utils/chat/`, molde do task-manager) e cada adapter na peça dona? (b) a forma de
cada adapter: construir, embrulhar ponte madura (Matrix/mautrix) ou servidor MCP? (c) a ordem dos adapters e o 1º
entregável com prazo curto? (d) regras transversais do esboço da curadoria: o que falta ou sobra?

1. **Onde mora:** o CONTRATO e os TESTES DE CONFORMIDADE no core (`.claude/utils/chat/`, molde do task-manager). O
   EXECUTÁVEL de cada adapter roda na peça que opera o canal, no processo da unidade que lê o segredo do credstore;
   o agente nunca vê a chave. Nos canais de um Brain de empresa, o adapter roda na conta da empresa (o segredo e os
   corpos são dela). A ponte do core não guarda segredo de canal.
2. **Forma:** adapter fino sobre a API/SDK oficial; MCP é interface da sessão (campainha), não forma do adapter;
   mautrix/Synapse recusado; ponte madura só se rodar inteira na conta da empresa.
3. **Mensagem normalizada com 5 campos obrigatórios:** hora do pedido; quem pede e o papel, resolvidos pelo id do
   provedor (mapa canal→Logto), nunca pelo nome exibido nem pelo texto; contexto do lugar; o fio (reply_thread +
   assinatura); quem mais vê a conversa (verbo de audiência ANTES de responder).
4. **Regras do núcleo:** guarda de vazamento sobre tudo o que sai; dedupe pelo id do provedor e idempotência
   (entrega pelo menos uma vez); ritmo por conversa e teto por destino/dia com linha pending antes do envio; teto de
   mídia; retenção de corpos e mídias como dado de terceiros (prazo, fora do offsite ou cifrada, na conta da empresa
   quando for Brain); log de auditoria com quem pediu; número e chave nunca em saída, log ou erro; marca de quem
   leu entre sessões; o contrato aguenta perder um canal (ex.: número banido) sem perder a fila.
5. **Imediatismo:** o contrato exige o campo de latência medido e exposto e o passo «serviu?»; o número-alvo é meta
   por adapter, publicada.
6. **Ordem:** 1º WAHA (já tem uso real e peça), cujo 1º entregável, em até 1 semana, já leva os 5 campos, o mapa de
   identidade e a recepção durável; depois Slack pelo @brain; Telegram e Teams só com pedido real.
7. **Eliminatórios:** segredo em repo ou porta pública sem autenticação; identidade tirada do texto; adapter sem
   bancada com provedor simulado e mutantes; conteúdo de conversa de empresa guardado fora da conta dela.
8. **Extra, não núcleo:** a saída para página (o canal manda o link, a página devolve ao agente).

**Pergunta aberta ao maestro** (não fechada pelo Delphi): o WAHA, não oficial, serve para conversa com cliente
final, ou só para canais internos e de sócios? → fechada pelo maestro em `D_WAHA_INTERNAL_ONLY_OFFICIAL_FOR_CUSTOMERS_1121`.

**Dissenso:** nenhuma sessão objetou na rodada 3. Acréscimos incorporados pelo condutor: a chave migra do arquivo
privado para o credstore (`LoadCredential`) no 1º entregável do WAHA; fila e mídias de terceiros fora do offsite
ou cifradas; latência com hora do pedido e hora em que o Brain viu.

**Confiança por rodada:**

| participante | rodada 1 | rodada 2 | rodada 3 |
|---|---|---|---|
| mensageria | 0.7 | 0.75 | 0.8 |
| operação da VPS | 0.65 | 0.7 | 0.8 |
| Company Brain | 0.7 | 0.7 | 0.8 |
| curadoria | s/conf | 0.78 | 0.85 |

**Como a síntese virou contrato aqui** (escolhas desta implementação, não do Delphi): os 5 campos viraram o
`message.received` do schema; as regras do núcleo viraram as 10 linhas `rule.*` do vocabulário, que cada adapter
declara; o «verbo de audiência antes de responder» é `audience.list` mais o `audience_checked` da resposta, com a
ordem das horas conferida; o «serviu?» é o verbo `served.ask` mais o campo `served` da resposta; a «saída para
página» é o verbo opcional `page.handoff`.
