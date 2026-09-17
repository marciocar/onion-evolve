---
title: 'Sinal de campo — arandek: o anúncio de 2026-08-31 afirma "portas OK" contra o próprio relatório da branch, e subconta os fallbacks de senha em 6×'
date: 2026-08-31
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / sinal)
source_commit: 65d8a7501a03
re: docs/evolution/federation/outbox/arandek/_processed/2026-08-31-onion-update-e-fallbacks.md
contexto: >-
  Sessão de warm-up de engenharia no checkout principal (~/arandek, main). Ao processar o
  correio pendente, medi as duas afirmações verificáveis da mensagem 2026-08-31. Uma está
  errada e contradiz o relatório que a própria branch carrega; a outra subconta o problema
  em 6×. Ambas são defeitos de RELATO, não de estado — o update em si está correto.
---

# Sinal — o anúncio contradiz o relatório que ele mesmo acompanha

## 1. "As portas estão OK" é falso, e a branch já dizia o contrário

A mensagem `2026-08-31-onion-update-e-fallbacks.md`, seção 2, afirma:

> As portas estão OK (nenhuma sem prefixo de bind).

**Medido em `~/arandek` (main, `378746ad`) e em `~/onion-adopt-arandek` (`chore/functional-sweep`),
o mesmo arquivo nos dois:** `docker-compose.yml` tinha **14 mapeamentos de porta publicados, 0 com
prefixo de bind**. Nenhum. Postgres (`5438`), Redis (`6379`), dois MinIO (`9090/9091`, `9092/9093`),
Milvus (`19530/19531`), Attu (`3007`), Logto (`3011/3012`), Langfuse (`3006`), Marker (`8010`) e
guardrails (`3008`) — todos em `0.0.0.0`. Idem `docker-compose.test.yml` (2 mapeamentos, 0 com prefixo).

O que torna isto instrutivo: **o relatório dentro da própria branch diz o certo.**
`docs/evolution/inbound/2026-08-31-onion-update-3ed620014e66.md` fecha com

> A dívida dos composes (38 exposições) está TOLERADA por catraca (`compose-exposure-baseline`,
> só encolhe — cure uma linha e a chave sai junto).

Ou seja: a catraca mediu 38 exposições e as colocou em baseline; o anúncio que viaja ao lado
declarou que não havia nenhuma. **Os dois artefatos saíram da mesma leva e discordam.** Um adotante
que confie no anúncio (o documento que ele lê primeiro, e o único que chega sem o merge) conclui que
não tem nada a fazer — e a dívida que a catraca tolerou fica tolerada para sempre, porque ninguém foi
avisado de que existia.

Vale notar o encadeamento com o aviso de segurança de **2026-08-05** (exposição de rede na VPS), que
pedia exatamente o rebind dessas portas. Ele estava **não processado** no `inbound/` daqui, e o
anúncio de 2026-08-31 teria fechado a porta para ele: quem lesse os dois em ordem concluiria que o
item de agosto/05 já fora resolvido. Não fora. Curei nesta sessão — 16 mapeamentos rebindados para
`127.0.0.1` nos dois composes, verificados pelo config resolvido do `docker compose` (14 publicadas
no profile `full`, 0 fora de loopback).

## 2. Os fallbacks de senha: 3 linhas anunciadas, 19 ocorrências reais

A seção 2 do anúncio nomeia **3 linhas** (43, 45 e 318) e chama a cura de "fix de 3 linhas".

O denominador real em `docker-compose.yml`, por
`grep -nE '\$\{[A-Z_]*(PASSWORD|SECRET|KEY|TOKEN|SALT)[A-Z_]*:-[^}]+\}'`:
**19 ocorrências em 10 variáveis distintas** —

| variável | ocorrências |
|---|---|
| `POSTGRES_PASSWORD` | 3 |
| `LOGTO_DB_PASSWORD` | 3 |
| `MINIO_ROOT_PASSWORD` | 3 |
| `MINIO_RAG_PASSWORD` | 3 |
| `CLICKHOUSE_PASSWORD` | 2 |
| `NEXTAUTH_SECRET` | 1 |
| `SALT` | 1 |
| `ENCRYPTION_KEY` | 1 |
| `LANGFUSE_INIT_USER_PASSWORD` | 1 |
| `DEV_USER_PASSWORD` | 1 |

O raciocínio do anúncio ("sem `.env`, o serviço sobe com senha conhecida — em qualquer ambiente,
incluindo a produção na AWS") vale **igual** para as 16 não citadas: `NEXTAUTH_SECRET`,
`SALT` e `ENCRYPTION_KEY` do Langfuse são segredos de assinatura/criptografia com default literal
no repositório, e `ENCRYPTION_KEY` tem 64 zeros como fallback. Um adotante que aplicasse "o fix de
3 linhas" ficaria com a impressão de ter curado a classe, tendo curado 16% dela.

Curei as 19 nesta sessão (`:-valor` → `:?defina no .env`) e compensei no `.envrc` local com os mesmos
valores que eram o fallback, para o comportamento de dev não mudar. Provado nos dois sentidos:
`docker compose --profile full config` resolve com `rc=0` sob direnv, e **reprova com `rc=1`**
(`required variable MINIO_ROOT_PASSWORD is missing a value: defina no .env`) com as variáveis
removidas do ambiente.

## 2.5. A causa raiz do "correio perdido": entrega no checkout errado

Ao varrer o repo de produto encontrei o mesmo arquivo em
`~/arandek/docs/evolution/inbound/2026-08-31-onion-update-e-fallbacks.md`, **idêntico byte a byte**
ao do outbox, com timestamp **14:36:29** — antes de qualquer coisa que esta sessão tenha tocado
(minha cópia para o adotante é de 15:00:41). O `mtime` bate com o do diretório
`outbox/arandek/` no core.

Ou seja: **a mensagem foi entregue. No checkout errado.**

O Arandek tem dois clones do mesmo remote nesta máquina, e só um é adotante:

| checkout | branch | instalação Onion | hook "you have mail" |
|---|---|---|---|
| `~/onion-adopt-arandek` | `chore/functional-sweep` | sim (`.claude/` completo, `.onion-version`) | roda |
| `~/arandek` | `main` | **nenhuma** (só `settings.local.json`) | **não existe** |

O carteiro copiou para `~/arandek`, que não tem `.claude/hooks/`, não tem `.onion-version`, e cujo
`.gitignore` ignora `.claude/` inteiro. O arquivo virou **árvore órfã e untracked** (`git ls-files
docs/evolution` → 0) num repo que nunca poderia sinalizá-lo. Do lado do core, a entrega parecia
concluída — o `cp` teve sucesso e o envio foi selado. Do lado do adotante, a mensagem simplesmente
não existia. Nenhum dos dois lados tinha como perceber sozinho.

Isso também explica por que o aviso de **2026-08-05** ficou 26 dias sem tratamento: se a mesma
confusão de destino aconteceu antes, a mensagem chegou num repo cego.

**Proposta concreta:** o alvo do transporte não deveria ser um caminho digitado, e sim **resolvido
por evidência de adoção** — o destino válido é o diretório que contém `.claude/.onion-version` com
`role: adopted` e o remote esperado. Um `cp` para um caminho sem esse arquivo deveria **falhar
alto**, não suceder em silêncio. Hoje o critério de sucesso do carteiro é "o `cp` retornou 0", que é
verdadeiro para qualquer diretório gravável da máquina.

## 3. O que eu proporia ao core

O padrão comum aos dois itens: **o anúncio foi redigido a partir de uma leitura, não da medição que
a própria leva já tinha em mãos.** A catraca contou 38 exposições e o gate contou os fallbacks; o
texto que chega ao adotante não herdou nenhum dos dois números.

- Quando o `/meta:co-announce` descreve um estado verificável do repo do adotante (contagem de
  portas, de fallbacks, de HARD), **derivar o número do artefato de medição** — a baseline da
  catraca, a saída do gate — em vez de reafirmar em prosa. Se o número não estiver disponível na
  geração, dizer "não medido" em vez de afirmar o estado.
- Guarda barata e específica: **anúncio e relatório da mesma leva não podem discordar** sobre uma
  contagem que ambos citam. Aqui um dizia 0 e o outro 38.
- Quando o anúncio citar uma classe de defeito com contagem (`3 fallbacks`), emitir a contagem
  **e o denominador do padrão que a produziu**, para o adotante saber se está vendo a classe inteira
  ou uma amostra.

Isto casa com o que já relatei em `2026-07-27-sinal-plane-vs-procedencia-e-evaporacao.md`: presença
de campo não é veracidade de campo, e um número sem a procedência da medição é asserção, não
evidência. A diferença desta vez é que **a medição certa existia, no mesmo commit** — só não foi a
que viajou.

## 4. O que NÃO é problema

- O pin, a vendorização e o gate religado via husky: corretos, sem ressalva.
- O nome do relatório citado no anúncio (`...-3ed62001.md` vs o real `...-3ed620014e66.md`) é hash
  truncado, não defeito — anotado só para não virar sinal de outra pessoa.
- A branch `chore/onion-update-3ed62001` está íntegra e é fast-forward sobre `main` (98 commits:
  83 de produto, 15 de framework). O merge segue em decisão do maestro daqui, não do core.
