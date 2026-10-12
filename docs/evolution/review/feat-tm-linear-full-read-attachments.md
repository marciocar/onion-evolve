---
branch: feat/tm-linear-full-read-attachments
date: 2026-10-12
reviewed_diff_sha256: pendente
reviewed_code_sha256: 8cffeceb0d5238622c7104fda6af8726b22e1897f459cdd8dbb2d3de45c8b2e1
findings_total: 6
findings_real: 6
findings_fixed: 4
tokens: 300000
duration_min: 120
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (subagente da sessão principal, sem revisor separado), default reprovado — gate mecânico: famílias task_manager_dispatcher (31, 12 mutantes novos), task_manager_executable (13), task_manager_capabilities (34), task_progress; dogfood ao vivo contra o Linear real (SAC-109, SAC-110, SAC-74, SAC-112)
---

# Ler a task por inteiro e baixar o anexo: o retorno prova o que diz, ou só ficou mais longo?

Default reprovado. A pergunta da passada: cada campo novo da leitura completa e cada `implemented` novo no
`linear.capabilities.tsv` tem medição por trás, e cada recusa de segurança tem um caso que reprova sem ela?

## Achado 1 — a 1ª página parecia a lista inteira (REAL, curado)

O `comment.list` lia `first:100` sem laço e devolvia `count` como se fosse o total. Cura: `_connection` segue
`pageInfo.endCursor` até `hasNextPage=false`, com teto de 40 páginas DECLARADO em `truncated`. Medido ao vivo
com `TM_LINEAR_PAGE_SIZE=1`: a SAC-109 devolveu os 4 comentários. Caso `page2` + mutante (`return` no lugar do
avanço do cursor) morde.

## Achado 2 — a ordem da conexão é a do mais novo (REAL, curado)

A leitura viva da SAC-109 trouxe os comentários do mais novo para o mais velho. A medição de 2026-10-11 dizia
"na ordem das escritas" com só 2 comentários — pouco para distinguir. Cura: ordenar por `createdAt` (comentários
e atividade), declarado no `linear.md`.

## Achado 3 — histórico vazio não é "nada mudou" (REAL, DECLARADO)

A SAC-109 tem `history` vazio apesar das transições Backlog → Todo → Canceled de 2026-10-11, feitas segundos
depois da criação. As mudanças de hoje na SAC-110 apareceram. Causa não ancorada; o `linear.md` e o tsv dizem
que histórico vazio não prova ausência de mudança. O `actor` também vem `null` em entrada de usuário, com
`actorId` preenchido: o executável expõe os dois.

## Achado 4 — redirecionamento levaria a chave para outro host (REAL, curado)

O `urllib` copia o `Authorization` num redirect. Um 302 do host de uploads para fora entregaria a chave do
Linear. Cura: `_AuthStripRedirect` tira o header quando o destino sai do host de uploads. Caso `redirect` (o
servidor de fora devolve 403 se receber a chave) + mutante morde.

## Achado 5 — mime declarado não é mime verdadeiro (REAL, curado)

Allowlist só por `Content-Type` deixaria passar um script servido como `image/png`. Cura: a assinatura dos
bytes é conferida contra o mime (PNG, JPEG, GIF, WEBP, PDF, OOXML, OLE; texto = UTF-8 sem NUL). SVG fica fora.
Caso `magic` + mutante morde.

## Achado 6 — consulta aninhada estoura a complexidade (REAL, DECLARADO)

Uma introspecção profunda devolveu HTTP 400 "Maximum allowed complexity: 10000". A leitura completa faz uma
consulta por conexão (comentários, histórico, anexos, filhos, mãe), não um aninhamento só. Custo: N+1 em
árvore de subtasks (uma consulta por nó), aceitável na escala medida (SAC-74: 4 filhas).

## O que fica fora, declarado

- **Respostas encadeadas** (comentário com `parent`): o campo vem no retorno, mas nenhuma issue medida tinha
  resposta — não medido se `issue.comments` inclui as respostas.
- `estimate` vem CRU no item.read completo (null em todas as issues medidas); `estimate.points_read` segue
  `not_implemented` até haver uma leitura não nula normalizada para `storyPoints`.
- `attachment.add --as-attachment yes` cria o Attachment (link) com a `assetUrl`; o caminho principal é o
  markdown. A URL assinada temporária (`public-file-urls-expire-in`) não é usada.
- O asset do 1º probe (antes do executável) ficou enviado e sem referência: o Linear não oferece remoção pela
  `assetUrl`, e a tarefa proíbe deletar.
- ClickUp (2ª fatia) e Zoho Projects (3ª) declaram as 5 capacidades `not_implemented`; Jira e Asana idem, sem
  executável até haver demanda.

## Passada pós-CI (2026-10-12, sessão principal)

O CI reprovou o `door-mini (a)` na faixa 3: o `linear-leitura-completa.md` viaja para a porta mini (que leva `utils/task-manager/` inteiro) e citava o caminho do fragmento de conteúdo não confiável, que o mini não leva. Medi as duas saídas:

- **Pôr o fragmento na allowlist:** arrastava `onion-untrusted-wrap.sh` e `onion-effect-gate.sh`, a cadeia de guardrails, para a porta didática.
- **Citar pela forma de namespace:** o verificador também a resolve, e com razão, porque o leitor do mini não a acharia.

A cura foi enunciar a regra R15.2 por inteiro no adapter, sem referência. As famílias `door_mini` e `task_manager_dispatcher` deram 44/44.
