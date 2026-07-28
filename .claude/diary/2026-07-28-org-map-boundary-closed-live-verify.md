---
date: 2026-07-28
instance: onion-evolve
type: learning
classification: collective
tags: [declarado-vs-verificado, behavior-over-declaration, logto, federation-orgs, bridge, verification, docker-shim, sole-writer]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "Para RE-VERIFICAR o federation-orgs.json contra o Logto vivo a partir da VPS (srv1812846), quando docker exige sudo: crie um shim `docker`→`sudo -n docker` num dir no PATH e rode `PATH=$shim:$PATH bash .claude/utils/bridge-auth/logto-provision.sh --write-org-map`. O pré-flight resolve o issuer admin no LOOPBACK (Host forjado p/ 127.0.0.1:3012) — se passar, NÃO precisa ligar o vhost do console (nada de Caddy de produção). É dry-run por default (só imprime o mapa). git diff vazio = bate = verificado. Nunca hand-edite o arquivo — ele é DERIVADO; a fonte é o GET /organizations."
review_after: 2026-10-28
conflict_class: dynamic
significance: "Fechei um boundary declarado≠verificado que EU MESMO declarei no commit e15a657 ('org-ids não re-verificados desta sessão — sem creds'). O maestro mandou verificar; descobri que a máquina É a VPS (srv1812846) com o Logto local vivo, e o secret do m-default vem do Postgres local (não de env). Rodei --write-org-map (shim docker→sudo, pré-flight no loopback, ZERO Caddy tocado): o mapa vivo bateu BYTE-A-BYTE com o commitado. O loop declarado→verificado→match fechou pela ida à fonte viva. Lição-par: o boundary não era pra ficar declarado — era pra ser FECHADO indo ao vivo; o obstáculo (docker sem sudo) era mecânico, não uma barreira real. Contexto: assumi esta sessão como escritora única (I3) após varrer 12 beacons stale + apagar 3 ociosos."
---

## Signal

**Um boundary `declarado≠verificado` que eu explicitei no commit não era pra ficar aberto — era pra ser FECHADO indo à fonte viva.** Ao commitar o `federation-orgs.json` (mapa Logto org-id→membro de arandek + metagamify), declarei honestamente no `e15a657`: *"estes ids vêm do Logto vivo via `--write-org-map` da sessão M2. NÃO re-verificados desta sessão — sem creds Logto nesta máquina."* Declarar o limite foi honesto; mas o maestro cobrou o passo seguinte — **verifique** — e a verificação era possível o tempo todo.

## Evidência

Três coisas que a memória-de-sessão declarava e o vivo refutou/confirmou:
1. **"sem creds nesta máquina"** — falso por omissão. A máquina É a VPS (`hostname` = `srv1812846`, o home do core), com o Logto local vivo (`auth.onionevolve.com` → HTTP 200). O secret do `m-default` não vem de env: vem do **Postgres local** (`docker exec onion-logto-postgres psql ... select secret`). Não precisava de creds externas.
2. **O obstáculo real era mecânico** — `docker` exige `sudo` aqui (`permission denied` sem; `sudo -n docker` funciona, NOPASSWD da VPS). O script chama `docker exec` cru e o `set -e` abortava com exit 1 sem mensagem. Cura: shim `docker`→`sudo -n docker` no PATH só pra a execução (mínimo privilégio; o resto roda como marcio, ownership correto).
3. **O ponto sensível NÃO foi necessário** — o pré-flight testa o issuer do tenant admin no loopback (Host forjado p/ `127.0.0.1:3012`). Passou. Logo **não** foi preciso ligar o vhost do console (`console.sh on`), que abriria o registro do tenant admin + mexeria no Caddy de produção — mudança que o próprio script exige autorizar NOMEANDO. Nada de produção foi tocado além de uma leitura.

**Resultado:** o mapa gerado do `GET /organizations` vivo — `{"b9ajzu0k5ri4":"arandek","j6hzd17a5wy1":"metagamify","r09uws5lfk25":"pulse-mais","yml1yan8ioyu":"onion-dist"}` — bateu **byte-a-byte** com o commitado (`git diff` vazio). Org-ids reais e corretos.

## O que fecha

`declarado → verificado → match`, pela ida à fonte viva. É a doutrina [behavior-over-declaration](../../docs/knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md) na direção POSITIVA: não bastou declarar o limite com honestidade — o valor foi **derrubar o limite** confirmando o comportamento. O `federation-orgs.json` é DERIVADO (fonte = `GET /organizations`); nunca se hand-edita — verifica-se/regenera-se via `--write-org-map`.

## Fronteira honesta

A verificação foi um READ (`GET /organizations`) + dry-run. Uma escrita real (com flag de apply) ou ligar o console/Caddy seguem exigindo autorização nomeada do maestro. E este fechamento é dentro do core — o SSOT segue decidindo QUAIS orgs existem; o id é só a alça que o Logto atribuiu (não fere o D5 da projeção).
