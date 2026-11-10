# Perfil de interconexão do Onion: Parte A, v1 (selado em 2026-11-10)

Autor: core, dono da arquitetura. Refutação: curadoria (bloqueios 7, 5, 3, 4 e 5 nas rodadas que precederam esta
redação, que cura a última delas). Selo: maestro, em 2026-11-10; as quatro decisões estão no grafo
[`interconnect-profile-2026-11.kg.yaml`](interconnect-profile-2026-11.kg.yaml) e na [SYNTHESIS](SYNTHESIS.md).
Versão pública: sem hosts, portas, IPs nem postura de segurança. O histórico das versões e das refutações fica fora
do repo. Referências `a2a-verify.sh:N` apontam o gate A2A do core em `origin/main` de 2026-11-10.

**Régua do maestro (10/11):** «o problema maior não é o esforço de construção, é a padronização, interconexão e evolução
com eficiência e eficácia».

## Tese
Não existe contrato único para as 32 ligações. Existe **um envelope único para tudo o que é sinal ou evento**: as quatro
vias de sinal entre membros (git-async, HTTP com aceite, fila com lease, pull HTTPS), o watcher e a campainha. O resto
segue o padrão próprio de cada camada.

## Escopo e modelo de confiança da Parte A
- A Parte A vale **sob o modelo de confiança de hoje**: registro e chaves públicas (`members.yaml`, `jwks/`) lidos do clone
  (`a2a-verify.sh:115,119`), em máquinas nossas, **sem proxy com inspeção TLS** no caminho.
- **A Parte B é pré-condição declarada** para qualquer máquina de cliente ou atrás de proxy com inspeção. Ela cobre
  raiz de confiança, registro assinado, cifra do corpo, transporte entre máquinas (P4) e pareamento.
- A Parte A **não** depende de nenhum código da Parte B.
- **Detector da pré-condição:** o `doctor` de cada máquina compara o emissor do certificado TLS que recebe do forge e do
  servidor com o esperado. Se for uma CA corporativa (proxy com inspeção), avisa que a Parte A não cobre aquela máquina.

## A1. Envelope
- **Conteúdo:** CloudEvent 1.0.2 em JSON.
- **Assinatura:** JWS compacto com o CloudEvent em bytes como payload, sem canonicalização (A2A #2122). O DSSE do CE (PR
  #1386) fica de vigia.
- **Cabeçalho do JWS:** `typ` explícito, um algoritmo por chave, rotação por `kid` com sobreposição. RS256 hoje;
  `Ed25519` (RFC 9864) como rampa.
- **Claims obrigatórios:** `iss` (membro remetente), `aud` (membro receptor), `iat`, `exp` e `jti`, como o gate já exige
  (`a2a-verify.sh:393-396`; RFC 8725 §3.9).
- **Autoria:** só pelo JWS. O `jti` identifica a entrega; o `id` do CE identifica o evento.

## A2. Versão e evolução
- **Onde vive a versão:** a major no `type` (`dev.onion.<x>.v1`), com um JSON Schema 2020-12 por major em `dataschema` e
  10 a 20 casos de conformidade.
- **Legado = major 0, por binding:**
  - **HTTP e socket:** o envelope A2A de hoje, sem `type` (`a2a-verify.sh:468`).
  - **Git:** o sinal do doc-bridge **sem JWS** (0 de 86 locais têm). A autoria dele vem da revisão do commit no repo do
    destino (REGRA 113 (Sinal relayado a destino público só se commita revisado) e PR), e não de assinatura. A partir da
    `.v1`, o co-relay e o co-deliver assinam o sinal, e a major 0 do git sai na mesma regra de saída.
  - **Saída da major 0:** escolha do maestro (decisão 2). A catraca conta **emissores já atualizados que ainda emitem
    major 0**, número que tem de ser zero; o estoque legado é só informativo e não sobe a catraca.
  - A `classification` da major 0 não é assinada: ela vale sempre como `unclassified`, qualquer que seja o valor escrito.
- **O que o receptor aceita:** N e N-1, e a major 0 até a data de saída. Major desconhecida é recusa explícita; nunca
  melhor esforço, nunca queda silenciosa.
- **Campo desconhecido:** tolerado só dentro do payload assinado. Rótulos fora da assinatura (frontmatter, cabeçalho do
  inbox) são derivados de campos assinados, numa lista fechada. Isso preserva a defesa de forma fechada de
  `a2a-verify.sh:460-466`.
- **Sem `crit` na Parte A:** o gate de hoje veta `crit` (`:354`). Ele só entra quando houver extensão que o exija.
- **Migração:** rampa com duas majors e data de saída (extensão `deprecation`).
- **Duas cópias do gate (core e fila) mudam no mesmo movimento**, com conferência byte a byte no CI dos dois repos.
- **Leitor único antes do schema:** o `members.yaml` ganha schema e leitor únicos no core, no lugar dos 24 parsers, e o
  `version` passa a ser conferido.

## A3. Bindings, validade, dedupe e recibo
| Binding | Ligações | `exp` de entrega |
|---|---|---|
| HTTP vivo | bridge `/a2a`, relay futuro | ≤ 1 h (`MAX_TTL_CAP=3600`) |
| Linha JSON em socket Unix | fila, campainha (protocolo local escolhido pelo hub) | ≤ 1 h; re-assina a cada tentativa |
| Git-async e o pull HTTPS dele | inbox e inbound, `/federation/inbox/:member` | ≤ 7 dias |

- **O `exp` vale só no aceite.** Medido na curadoria: 10 de 35 sinais processados um dia depois ou mais.
- **Recibo de aceite:** no aceite, o receptor assina `iss`, `source`, `id`, `body_sha256`, `accepted_at` e o `kid` usado.
  - A verificação histórica (clone novo, pull do histórico) confere o recibo e o hash, nunca o `iat` do remetente.
  - Kid revogado antes do `accepted_at` é recusa; revogado depois não invalida o que entrou.
  - O `accepted_at` é testemunho do receptor, declarado.
  - Sinal antigo sem recibo fica marcado «histórico sem recibo».
- **Dedupe:** por (`iss`, `source`, `id`) no armazenamento do receptor (banco da fila, razão de aceite do doc-bridge). A
  retenção é de 8 dias, contados pelo teto do binding de chegada e pelo relógio do receptor, com poda. O `jti` vira
  proveniência; o arquivo só de append de `a2a-verify.sh:289,512` migra para essa dedupe.
- **Dialeto único do doc-bridge:** o frontmatter mapeia os atributos do CE. `origem`/`tipo` viram apelidos com prazo, e
  o `a2a-accept` passa a gravar o canônico.

## A4. Classe de confidencialidade (`onionclass`)
- **Onde vive:** atributo de extensão **dentro do CE assinado**, com os valores `public`, `internal`, `confidential` e
  `unclassified`. Deixa de ser campo não assinado (`a2a-verify.sh:80`).
- **Legado sem classe vale `unclassified`,** com a guarda de hoje: REGRA 113 (Sinal relayado a destino público só se
  commita revisado) e revisão. Nunca é mais fraca que ela. A classe é obrigatória a partir da major `.v1`, e uma catraca
  conta os `unclassified`, número que só pode cair.
- **`confidential` até a Parte B:**
  - só circula **no mesmo host**, pela fila (estado restrito ao dono, fora do git), entregue pela campainha;
  - **entre máquinas é recusado**: nunca vai em claro;
  - nunca vai por git-async: o gate veta no binding git, sem a exceção por repo privado de `a2a-verify.sh:76`, e uma guarda de lint
    recusa commit com `onionclass: confidential`;
  - o `a2a-accept` grava só um ponteiro (`source`, `id`, recibo), e grava **no razão de aceite local, fora do repo**,
    nunca no inbox público. Isso evita que `iss`, `source` e `body_sha256` vazem;
  - **retenção:** o corpo é apagado da fila no ack mais 8 dias; o recibo fica.

## A5. Estados e operação
- **Estados por mensagem:** enfileirada, entregue, lida (declarada pelo par: testemunho), processada e dead-letter.
- **Mensagem é dado, nunca ordem**, com as quatro condições: remetente autenticado, marcada como não-usuário, sem
  autoridade, portões mantidos.
- **Operação:** um comando para ver o estado, sem painel web.

## Parte B: estudo próprio, antes de qualquer código
- Cifra do corpo (JWE `ECDH-ES` ou HPKE-no-JWE).
- Raiz de confiança e registro assinado, com versão monotônica e validade contra rollback e freeze, limiar, raiz offline e
  rotação. Medir **TUF e sigstore/gitsign** contra o desenho manual. Hipóteses herdadas: assinatura destacada do conteúdo
  e pin fora de banda da raiz.
- Transporte entre máquinas: HTTPS de saída com proxy e CA corporativa, `private_key_jwt` + DPoP com nonce e `htu`
  externo. A borda confere o transporte, e o receptor verifica o JWS.
- Pareamento pela RFC 10027, escolhido pela sessão: code + PKCE com loopback quando há navegador local, device flow
  quando não há. Isso revisa `D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106`.
- Duas chaves por máquina, rotação de 90 dias, revogação com o pendente e recusa de rebaixamento.
- Condução: curadoria. Decisão de arquitetura: core. Selo: maestro.

## Gatilhos e não-escopo
- **Gatilhos:**
  - iroh: proxy na ligação Python, saída do alfa, ou o caminho próprio estourar a faixa;
  - DSSE: SDK em uso nas duas pontas;
  - HPKE-no-JWE: sair a RFC.
- **Exceção da campainha:** fica na revisão MCP anterior, porque o Claude Code não entrega canal na 2026-07-28. Sai por
  comportamento: uma bancada pós-`/meta:cc-update` confere se a campainha com SDK 2.x se registra como canal.
- **Não-escopo:** multi-relay e alta disponibilidade, federação entre organizações, SCIM, SOC 2.

## Decisões para o maestro

> **Seladas em 2026-11-10** (pelo `kg-decide-seal.sh`, testemunho do maestro): 1 → selar com os compromissos
> (`D_INTERCONNECT_PROFILE_A_V1_1110`); 2 → (a), por condição medida (`D_INTERCONNECT_MAJOR0_EXIT_1110`); 3 → (a),
> arrumar o que existe primeiro (`D_INTERCONNECT_EXEC_ORDER_1110`); 4 → abrir agora (`D_INTERCONNECT_PART_B_OPEN_1110`).
1. **Selar a Parte A como perfil de interconexão v1, com estes compromissos:**
   - `confidential` só no mesmo host até a Parte B;
   - o teto duro de validade do gate (`a2a-verify.sh:120-122`, hoje 1 h) passa a ser por binding, com 7 dias no git;
   - assinatura do sinal do doc-bridge pelo co-relay e co-deliver a partir da `.v1`;
   - as duas cópias do gate mudam juntas.
2. **Regra de saída da major 0:**
   - (a) quando a catraca de emissores atualizados ficar em zero por 30 dias, sem data fixa, alinhada à doutrina de
     prazo por pontos;
   - (b) data fixada por você agora.
3. **Ordem de execução da Parte A:**
   - (a) leitor único do `members.yaml` e dialeto único do doc-bridge primeiro, depois a `.v1` com `onionclass`, a
     dedupe e o recibo;
   - (b) a `.v1` primeiro.
4. Abrir a Parte B como estudo, com a curadoria conduzindo.
