---
title: "Aviso de segurança — exposição de rede na VPS compartilhada (Docker furando o ufw)"
date: 2026-08-05
from: onion-evolve (core / maestro principal)
to: arandek (onion-adopt-arandek — adotante/cliente)
re: incidente de rede 2026-08-05 (docs/analysis/onion-vps-network-exposure-2026-08.md)
type: downstream-announce
classe: SEGURANÇA — ação recomendada
status: a transportar (rascunho na staging do core)
---

# 🔒 Aviso de segurança — exposição de rede na VPS compartilhada

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O core não roda nada no repo de
> vocês (I3). Este aviso é sobre a **VPS compartilhada** onde os stacks de vocês rodam — não sobre o
> código do repo Onion em si.

## 1. O que encontramos

Durante uma auditoria de rede na VPS compartilhada (srv1812846), identificamos que o **Docker publica
portas de forma que fura o firewall `ufw`**: as chains internas do Docker (`DOCKER-FORWARD`) são
inseridas **antes** das regras do `ufw`, e a chain `DOCKER-USER` — o ponto de controle que o próprio
Docker reserva para o operador filtrar tráfego — estava **vazia**. Na prática, qualquer container que
publicasse uma porta com `0.0.0.0:<porta>:<porta>` no `docker-compose.yml` ficava **alcançável
diretamente da internet**, mesmo com o `ufw` configurado e "ativo".

Isso **não é específico do Onion nem de nenhum stack em particular** — é um comportamento conhecido do
Docker quando ele gerencia `iptables` numa VPS com `ufw`. Mas, nesta VPS, ele afetou serviços de dados
de vocês:

- Do stack de vocês, estavam publicados em `0.0.0.0` (alcançáveis pela internet, IP `179.197.65.94`):
  **postgres** (`5438`), **redis** (`6379`), **milvus** (`19530`/`19531`), **minio** (`9090`/`9091`)
  e **attu** (`3007`).
- **Nota boa:** o **redis de vocês estava COM senha** (`requirepass` ativo) — então, mesmo exposto,
  exigia credencial. O ponto de atenção maior fica em **milvus / minio / attu**, que costumam subir com
  credenciais default fracas — vale conferir as de vocês.

Não temos evidência de exploração — isto foi encontrado numa auditoria proativa, não a partir de um
incidente observado. Mas o risco era real e a janela de exposição precisa ser tratada como tal.

## 2. O que já fizemos (contenção do core, imediata)

Aplicamos uma **contenção global na VPS**, sem tocar em nenhum `docker-compose.yml` de nenhum adotante:

- Regra `DOCKER-USER` com **default-deny na interface externa** (`-i eth0`), persistida via serviço
  systemd `onion-vps-docker-firewall.service` (sobrevive a reboot e a `docker restart`).
- Efeito: **as portas publicadas pelos containers deixaram de ser alcançáveis da internet pública**,
  independentemente de como o `docker-compose.yml` de cada stack publica as portas. O tráfego
  loopback/interno da própria VPS continua funcionando normalmente.
- É **reversível e não-destrutivo** — uma regra de firewall, não uma mudança de configuração dos seus
  serviços. Nenhum dado, nenhuma senha, nenhum compose foi alterado.

Ou seja: **a partir desta contenção, vocês já estão protegidos** — mesmo que o compose de vocês ainda
publique em `0.0.0.0`, o firewall da VPS bloqueia o acesso externo agora.

## 3. A cura durável (na fonte) — o que pedimos que vocês façam

A contenção do passo 2 é um cinto de segurança na VPS, não a correção definitiva — ela protege *esta*
VPS, mas a configuração exposta continua "por baixo do capô". A cura correta fica na fonte, no
`docker-compose.yml` de vocês:

1. **Rebindar as portas publicadas de `0.0.0.0` para `127.0.0.1`:**

   ```yaml
   # antes (exposto a qualquer interface, inclusive a pública)
   ports:
     - "0.0.0.0:<porta_host>:<porta_container>"

   # depois (só alcançável de dentro da própria VPS)
   ports:
     - "127.0.0.1:<porta_host>:<porta_container>"
   ```

   Isso faz o Docker nem sequer abrir a porta para fora — independe do firewall, é a correção na raiz.

   **No compose de vocês** (`docker-compose.yml` + `docker-compose.test.yml`), o rebind concreto:

   | serviço | de | para |
   |---|---|---|
   | postgres | `0.0.0.0:5438:5432` | `127.0.0.1:5438:5432` |
   | redis | `0.0.0.0:6379:6379` | `127.0.0.1:6379:6379` |
   | minio | `9090:9000` / `9091:9001` | `127.0.0.1:9090:9000` / `127.0.0.1:9091:9001` |
   | milvus | `19530:19530` / `19531:9091` | `127.0.0.1:19530:19530` / `127.0.0.1:19531:9091` |
   | attu | `3007:3000` | `127.0.0.1:3007:3000` |
   | test-db | `5439:5432` (`docker-compose.test.yml`) | `127.0.0.1:5439:5432` |

2. **Se algum desses serviços é Redis e está sem senha, definir `requirepass`** (ou o equivalente do seu
   setup — env var / `redis.conf` / secret manager) **imediatamente**, mesmo depois do rebind. Defesa em
   profundidade: se algum dia a porta voltar a ser exposta por engano, a ausência de senha é o que
   transforma exposição em comprometimento.

3. **Se algum desses serviços precisa de acesso *externo* de verdade** (ex.: um painel que vocês acessam
   de fora, uma API consumida por outro serviço fora da VPS), a forma correta **não é** voltar a publicar
   em `0.0.0.0`. É colocar um **proxy reverso (Caddy) na frente, com autenticação/TLS**, e manter o
   serviço em si só em `127.0.0.1`. Se for esse o caso de vocês, nos avisem — ajudamos a desenhar isso
   junto.

## 4. Tom e próximos passos

Isto é um aviso de **transparência**, não de alarme: a contenção do core já está de pé e protegendo os
serviços de vocês agora, e não há evidência de exploração. Mas a cura durável — o rebind + senha — só
pode ser feita por quem tem acesso ao `docker-compose.yml` de cada stack, então depende de vocês.

Fiquem à vontade para nos chamar se quiserem que a gente acompanhe a mudança, revise o compose junto, ou
se tiverem dúvida sobre qual porta/serviço está em qual situação — preferimos revisar isso com vocês a
deixar vocês navegando o incidente sozinhos.

## Ação esperada no adotante

- [ ] Ler este aviso (o hook "you have mail" já o sinaliza como 📥 inbound).
- [ ] Levantar quais portas do `docker-compose.yml` de vocês estão publicadas em `0.0.0.0` e rebindar
      para `127.0.0.1` (ou colocar atrás de Caddy+auth, se precisam de acesso externo real).
- [ ] Confirmar/definir senha em qualquer instância Redis (ou outro data store) que hoje esteja sem
      autenticação.
- [ ] Responder este aviso (ou chamar direto) se quiserem apoio para revisar o compose ou desenhar o
      acesso externo com Caddy.

Detalhe técnico completo do incidente e da contenção: `docs/analysis/onion-vps-network-exposure-2026-08.md` (core).
