---
title: "granaai — exposição de compose (classe arandek, 2ª instância)"
date: 2026-08-30
status: ENVIADO-2026-08-31 (via carteiro-local, inbound da granaai)
kg: docs/onion/graph/identidade-onion-vps-2026-08.kg.yaml
---

# ⚠️ MATERIAL DE COMUNICAÇÃO — NÃO ENVIADO. O envio é decisão do maestro.

> Mesma regra do achado arandek (`arandek-repo-exposure-2026-08.md`): este doc existe para o
> maestro **poder** comunicar, não comunica por si. O nó público do grafo
> (`E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO`) é deliberadamente redigido; os específicos
> vivem só aqui, no core privado.

## O achado (medido no censo, 2026-08-30, run `wf_2349bf29-ea0`)

O `docker-compose.yml` **rastreado no git** da granaai (`/home/marcio/granaai`, confirmado por
`git ls-files`) contém:

1. **Portas sem prefixo de bind** — linha 12: `- 5435:5432` (Postgres) · linha 22: `- 6379:6379`
   (Redis). Sem prefixo, o Docker publica em **todas as interfaces** (`0.0.0.0`) por default — e
   o Docker **fura o ufw** (medido nesta VPS; ver `onion-vps-network-exposure-2026-08.md`).
2. **Segredo literal como fallback** — linha 10: `POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres123}`.
   Sem `.env`, sobe com `postgres123`.

## Severidade medida — e o que a REDUZ

- **Nesta VPS a exposição NÃO está viva** (medido 2026-08-30): nada escuta em `:5435`; os Redis
  presentes estão todos em `127.0.0.1`; o `onion-vps-docker-firewall` (DOCKER-USER default-deny)
  está ativo desde 08-05.
- **Contexto do maestro (2026-08-31): a produção roda na AWS, em outra conta** — a cópia daqui é
  espelho. Isso recalibra as duas metades do risco:
  - **Portas sem bind**: na AWS, *security groups* ficam FORA do host — o bypass Docker-vs-ufw não
    os fura. A exposição lá depende da SG estar fechada (a conferir por eles, 1 minuto no console).
    Em dev local/outros hosts sem SG, o risco original vale integral.
  - **Fallback `:-postgres123`**: viaja **intacto** para qualquer ambiente, AWS incluída — sobe
    com senha conhecida onde quer que o `.env` falte. É a metade que a SG não cobre.

## Por que é CLASSE, não caso

É a 2ª instância medida do mesmo padrão (1ª: arandek, 2026-08). O gatilho nomeado em
`Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` — *"um caso é caso, dois é classe"* — **disparou**.
A cura de classe candidata (regra de lint de compose para repo com role de adotante: exigir
prefixo `127.0.0.1:` e proibir fallback literal de segredo) agora tem 2 instâncias que a
justificam — decisão de mecanismo do maestro.

## Sugestão de mensagem (1 parágrafo, pronta para adaptar)

> No `docker-compose.yml` do repo, as portas `5435:5432` e `6379:6379` estão sem prefixo de bind —
> o Docker publica em todas as interfaces e ignora o firewall do host. Sugiro `127.0.0.1:5435:5432`
> e `127.0.0.1:6379:6379` (uma linha cada), e trocar o fallback `:-postgres123` por variável
> obrigatória (`${DB_PASSWORD:?defina no .env}`) — sobe falhando alto em vez de subir com senha
> conhecida. Se o Postgres/Redis precisarem ser alcançados de fora, o caminho é túnel/SSH, não
> bind público.
