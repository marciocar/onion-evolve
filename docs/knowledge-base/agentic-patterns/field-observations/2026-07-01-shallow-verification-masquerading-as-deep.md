---
date: 2026-07-01
subject: Verificação superficial travestida de verificação profunda — dois casos reais no mesmo dia
status: raw
---

# 2026-07-01 — Verificação superficial travestida de verificação profunda

## O que originou esta observação

Numa sessão trabalhando cross-repo (onion-evolve orquestrando investigação no
um adotante), o maestro pediu pra eu registrar os próprios erros — não só os fatos
certos — porque notou uma falha maior por trás: "descobrimos rajadas e outras coisas que
não sabemos o motivo e você não está empenhado em descobrir", e "não atualizamos o
mapeamento e validação da fila e dos sistemas internos e externos". A pergunta dele: existe
estratégia/framework do Onion pra isso não se perder (Transformer+adaptação, SDAAL
dogfooding, adapters, breadcrumbs)? Resposta curta: sim, é este trilho — só que eu não
estava alimentando ele até ser cutucado.

## Caso 1 — meu erro, na mesma sessão

Afirmei que um `pg_dump` estava íntegro porque `pg_restore -l <dump>` listou as 21 tabelas
e terminou "limpo" nas FK constraints. **Errado**: o processo tinha sido matado
(`SIGTERM`, timeout de ferramenta) no meio da última tabela. `pg_restore -l` só lê o
**TOC/catálogo** (escrito incrementalmente, sobrevive a um corte tardio) — não decodifica
os blocos de dado comprimidos de cada tabela. Só descobri o corte real ao tentar o
**restore completo**, que falhou com `could not read from input file: end of file`.

**Por que errei:** troquei "a estrutura que lista os dados está bem-formada" por "os dados
estão completos" — duas propriedades diferentes, e só a segunda importa. É o padrão
clássico de "checar o índice do livro em vez de ler o capítulo".

**Correção prática:** pra `pg_dump -Fc`, validação real = (a) checar o exit code do
`pg_dump` em si (não só do comando que o invocou) e (b) tentar o restore completo, não só
`-l`. Isso já é uma instância do princípio "testar os modos de falha, não só o caminho
feliz" (`working-discipline.md` §Validação) — não é uma regra nova, é uma confirmação cara
(quase corrompi a análise) de uma regra que já existia e eu não apliquei ali.

## Caso 2 — erro de uma sessão anterior (mais caro, achado ao ler o histórico)

Investigando a PR #75 (fix de gate do motor), li o relatório final da auditoria do burst de
30/06 (`docs/reports/wrr/auditoria-burst-versao-final-2026-06-30.md` no um adotante).
Uma sessão da MANHÃ tinha concluído "wrrLevel=null causou o burst" a partir de uma query
SQL ad-hoc que achou esse campo null em 3 firmas. Isso motivou um backfill em 186
participantes + guiou o fix da PR. Uma re-auditoria de FECHAMENTO (13 agentes, ~991k
tokens, ao longo do mesmo dia) **refutou** isso lendo o código real: o campo consultado
(`metadata.wrrLevel`) é órfão — nunca é lido em runtime. O motor real resolve nível via
`EarnedElement`, e as 3 firmas tinham nível válido lá. A causa real do burst continua
**desconhecida**.

**Por que a sessão da manhã errou (inferência, não constatei diretamente):** tratou um
resultado de SQL ad-hoc como prova causal sem rastrear se aquele campo específico é
efetivamente lido pelo código de decisão. O check que refutaria isso é barato (`grep` pelo
nome do campo no runtime) — muito mais barato que os 991k tokens gastos depois pra
descobrir o mesmo.

**Padrão comum aos 2 casos:** um sinal raso (TOC bem-formado; campo null numa query) foi
tratado como se provasse uma propriedade profunda (dados completos; causalidade real). A
diferença de custo entre "checar direto" e "descobrir tarde" foi de segundos pra 991k
tokens no caso 2 — a checagem barata que faltou é sempre a mesma forma: **rastrear até a
fonte primária** (o restore real; o código de runtime) antes de aceitar um proxy.

## O que fiz de concreto além de registrar isto

Durante a mesma sessão, ao invés de só reconhecer a crítica de "não empenhado em
descobrir", voltei ao dump fresco e achei que `WRRSelectionDecision` (a tabela que
provaria nível/flags reais usados nas decisões do burst, vazia nos dumps antigos)
**começou a gravar só às 12:00 UTC de 30/06** — a rajada foi 09:47–10:51 UTC. Isso não
resolve a causa do burst, mas **resolve o item "INCERTO" sobre por que a tabela estava
vazia**: não é lacuna de dump, é ausência real (logging não estava ativo ainda). Diferença
entre "não sei e paro de perguntar" e "não sei, mas sei por que não sei" — a segunda é
uma resposta, mesmo sem fechar a causa raiz.

## Ligação com o resto do framework

- Isto é exatamente o que os **breadcrumbs** (`ai-accommodates-absorbs-breadcrumb-taxonomy`,
  memória do core) deveriam prevenir na direção **harness→futuro-eu**: um comentário/nota
  no lugar certo (ex.: no próprio script de dump, "-l só valida TOC, não dados") pouparia
  o Caso 1 de se repetir.
- O Caso 2 é munição forte para o **Capability Contract**/dogfooding: "verificar causalidade
  contra o código real antes de agir" é candidato a virar um item de checklist reusável, não
  só uma lição isolada — mas isso é decisão do maestro (`status: raw`, não `assessed`).
- Conexão explícita pedida pelo maestro (Transformer/adaptação/SDAAL/adapters): eu (o
  Transformer, na economia de motores do Onion) sou o ponto que decide "isso é suficiente
  pra confiar?" — SDAAL/adapters abstraem o *transporte* (como eu falo com Postgres, com o
  host Windows, com o forge), mas não substituem esse julgamento de profundidade de
  verificação, que é comportamental, não arquitetural. Registrar aqui é o mecanismo pra esse
  julgamento melhorar entre sessões em vez de resetar a cada vez.
