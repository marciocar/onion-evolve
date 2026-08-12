# Achado de adotante — segredos literais e binds públicos no compose do arandek

> **Status: NÃO COMUNICADO.** O recado abaixo está redigido e pronto; enviá-lo é ato do maestro, não
> meu. Uma sessão futura que pegar isto deve **primeiro perguntar se já foi enviado** — reenviar é
> ruído, e presumir que foi é pior.
>
> SSOT no grafo: `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` e
> `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` em
> [`docs/onion/graph/identidade-onion-vps-2026-08.kg.yaml`](../onion/graph/identidade-onion-vps-2026-08.kg.yaml).

## O que foi medido (2026-08-11)

Arquivo: `/home/marcio/onion-adopt-arandek/docker-compose.yml` — **rastreado por git**, remote
`https://github.com/ArandekBR/arandek.git`.

| # | achado | evidência |
|---|---|---|
| 1 | `--requirepass` literal | linha 60, no `command:` do serviço redis |
| 2 | 4 segredos literais no ambiente | linhas 147, 148, 210, 231 (`LANGFUSE_INIT_PROJECT_PUBLIC_KEY`, `LANGFUSE_INIT_PROJECT_SECRET_KEY`, `MINIO_ROOT_PASSWORD`, `MINIO_SECRET_ACCESS_KEY`) |
| 3 | portas publicam em `0.0.0.0` | MinIO `9090:9000`/`9091:9001`, Langfuse `3006:3000`, Milvus `19530:19530`/`19531:9091`, Postgres `${POSTGRES_PORT:-5438}:5432`, Redis `${REDIS_PORT:-6379}:6379` — nenhuma com prefixo de bind |

**Valores dos segredos ficam fora deste documento por decisão.** O core não guarda segredo de
adotante; quem for agir lê no arquivo dele. As linhas bastam para localizar.

O Redis vivo responde `NOAUTH Authentication required` — a senha **está ativa**. O defeito não é
ausência de senha, é a senha ser pública no histórico do repo.

## Por que o bind importa mais do que parece

Porta publicada por Docker atravessa **DNAT/FORWARD** e não passa pelo `INPUT` do `ufw` — logo
`ufw INPUT DROP` **não a protege**. Isso foi medido nesta VPS e é a mesma mecânica que expôs dois
Redis sem senha aqui (SSOT: [`onion-vps-network-exposure-2026-08.md`](onion-vps-network-exposure-2026-08.md)).

Nesta VPS os 15 containers `onion-adopt-arandek-*` estão em `127.0.0.1` **só** por causa do overlay
`/home/marcio/onion-adopt-arandek-local/compose.local.yml`. Sem ele, nasceriam públicos.

## O que NÃO foi medido

**A infra do arandek.** Se ele sobe atrás de NAT ou com firewall de nuvem, o risco real é menor. O
recado está redigido como *"no teu repo, num host público"* — que é o que se sabe. Não arredondar
para "você está exposto".

## Recado, pronto para enviar

> Achei duas coisas no `ArandekBR/arandek` rodando teu ambiente aqui, e as duas estão no
> `docker-compose.yml` **commitado** — quem clona o repo tem, independente de rede.
>
> **1. Segredos literais no arquivo.** O Redis sobe com `--requirepass <valor>` escrito direto no
> comando (linha 60), e mais quatro no ambiente: `LANGFUSE_INIT_PROJECT_PUBLIC_KEY`,
> `LANGFUSE_INIT_PROJECT_SECRET_KEY`, `MINIO_ROOT_PASSWORD` e `MINIO_SECRET_ACCESS_KEY` (linhas 147,
> 148, 210, 231). Trocar por `${VAR:?}` + `.env` fora do git resolve — mas **trocar os valores também
> é preciso**, porque eles já estão no histórico.
>
> **2. As portas publicam em `0.0.0.0`.** MinIO (9090/9091), Langfuse (3006), Milvus (19530/19531),
> Postgres (`${POSTGRES_PORT:-5438}`) e Redis (`${REDIS_PORT:-6379}`) sobem sem prefixo de bind. Num
> host com IP público isso é internet, **e o `ufw` não segura**: porta publicada por Docker passa por
> DNAT/FORWARD, que não vê o `INPUT DROP`. Medi isso na VPS do Onion — foi assim que dois Redis sem
> senha ficaram expostos lá.
>
> A correção é prefixar: `- '127.0.0.1:9090:9000'`. Aqui eu rodo tua stack com um overlay que faz
> exatamente isso; sem ele, os 15 containers nasceriam públicos.

## A lacuna de mecanismo

Este achado saiu de `grep` **manual**. Por [`fix-must-become-mechanism`], achado que só existe porque
alguém olhou não se repete sozinho — e a guarda `vps-exposure-check.sh` cobre só o lado de cá
(container vivo nesta VPS), não um compose no repo de um adotante.

Candidato **não decidido, a não pré-cozinhar**: regra de lint que, em repo `role: adopted`, acuse
porta publicada sem prefixo de bind e segredo literal em compose rastreado. **Gatilho para decidir:
o segundo adotante com o mesmo defeito** — um caso é caso, dois é classe.

## Nota de método

O primeiro `grep` de portas voltou **vazio** e quase virou a conclusão *"ele não publica nada"*. O
padrão não cobria **aspas simples** (`- '9090:9000'`). Terceira ocorrência no mesmo dia de defeito no
**vocabulário do filtro**, não na lógica — a mesma classe que já custou a guarda de branch, a de
palavras pt-BR e a de escopo de backup.
