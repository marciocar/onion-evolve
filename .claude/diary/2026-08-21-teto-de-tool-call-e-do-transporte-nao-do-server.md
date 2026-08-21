---
date: 2026-08-21
instance: onion-evolve
type: error
classification: collective
tags: [mcp, tool-call, limite, guarda-inalcancavel, declarado-vs-verificado, librechat, poc]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-21
conflict_class: static
significance: "Meu propose_kg_write (onion-exec) declarava limite de 200KB para o argumento kg_yaml — e o LibreChat corta ARGUMENTO de tool call em 65536 bytes ANTES de chegar ao server. O limite de 200KB era INALCANÇÁVEL: um agente nunca conseguiria enviar 200KB, o transporte cortava em 64KB com erro críptico. É a família guarda-inalcançável/declarado≠verificado, agora numa dimensão nova (o TETO de um MCP não é do server, é do transporte do cliente). A evidência veio de graça da sessão da PoC (edital de 65 pág estourou o mesmo teto)."
---

# O teto de um tool call é do TRANSPORTE, não do server — e o meu era inalcançável

**O que aconteceu.** A sessão da PoC bateu no erro `Streamed tool call arguments exceeded the
65536-byte safety limit` ao colar um edital de 65 páginas. Ela resolveu do lado dela (ingestão
por arquivo, não por texto). Mas o erro dela expôs um bug LATENTE no meu `propose_kg_write`
(onion-exec): eu validava `len(kg_yaml) > 200_000` no server — e o LibreChat corta o argumento
em **65536 bytes antes de chegar ao server**. Meu limite de 200KB era **inalcançável**: nenhum
agente conseguiria enviar tanto; o transporte cortava com erro críptico muito antes.

**A família.** É guarda-inalcançável (a guarda existe, está correta, e nunca roda porque algo a
montante a impede) numa dimensão que eu não tinha visto: **o teto de um MCP não é do server, é
do TRANSPORTE do cliente**. Um server MCP pode aceitar payloads grandes; o cliente que o chama
(LibreChat, aqui) impõe o teto real. Declarar um limite maior que o do transporte é declarado≠
verificado — mede o server, não o caminho.

**A cura.** Limite baixado para ~60KB (margem sob os 64KB para o resto do JSON-RPC) com mensagem
que ensina o caminho certo: proposta de grafo não passa disso; documento grande vai por
ingestão-por-arquivo, não por tool call de chat. E a lição transversal: **todo argumento de
qualquer tool dos MCPs do core (onion-kg/exec/framework) tem o mesmo teto de 64KB** — as tools
de LEITURA já respeitam (retornam, não recebem, e têm MAX_OUT de 60KB na saída); só o
propose_kg_write RECEBIA grande, e era o único exposto.

**Crédito onde é devido.** A evidência veio da sessão da PoC de graça — dogfood de fronteira: o
uso alheio achou o teto que o meu teste não tinha exercitado (eu testei propose_kg_write com um
grafo pequeno). Um adotante/vizinho é oráculo.
