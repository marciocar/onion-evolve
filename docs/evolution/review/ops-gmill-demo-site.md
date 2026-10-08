---
title: 'Resíduo — gmill.onionevolve.com: o 1º vhost de conf.d versionado, com segredo fora do git'
date: 2026-10-08
branch: ops/gmill-demo-site
reviewed_diff_sha256: 260f65308ef1adcb61bcffa522645ed3e3e2663e3020b84bb5a9816a75ab9ee7
reviewed_code_sha256: 2a90f09a138e011ac1fe35a335112fb0b5ac5b1c1ad24c978b6c45d89d78fd84
findings_total: 7
findings_real: 6
findings_fixed: 5
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial manual (sondas em Caddy descartável, mutantes pelo ops/mutate-and-restore.sh, medição no vivo); sem subagentes
REVISOU: true
nota: >-
  A ordem original (basic_auth puro na frente da demo) quebrava a própria demo, e isso só apareceu medindo:
  a web manda Authorization Bearer em todo /api/*. O maestro escolheu a opção B (cookie depois do Basic).
  A bancada do instalador rodava com errexit DESLIGADO, e a produção com ele ligado; dois defeitos meus
  passaram por ela antes de eu corrigir o harness.
---

# Resíduo — `ops/gmill-demo-site`

**Origem:** ordem do maestro (2026-10-08), a pedido da sessão `meugmill-vendas-6d`: expor a demo do
MeuGmill Vendas (`127.0.0.1:39081`) em `gmill.onionevolve.com`, atrás de senha.

## O que muda

- `ops/caddy/conf.d/gmill.caddy` — o 1º vhost de `conf.d` **versionado**. Os outros sete (vault, waha,
  chat…) seguem só no vivo, **não geridos**: o instalador não os altera nem remove.
- `ops/install-caddy-config.sh` passa a gerir `ops/caddy/conf.d/*.caddy`: estágio validado, marcadores
  `@@NOME@@` resolvidos de `/etc/caddy/secrets/<site>.env` (root 0600), carimbo de gerido na 1ª linha,
  0640 root:caddy, remoção de gerido órfão com backup, recusa de colisão com não gerido, `--check`
  cobrindo o `conf.d`, `# verify:` por vhost com espera de ACME.
- `ops/caddy-site-secrets.sh` — gera senha e cookie direto para o `pass` (só cifra, funciona com o gpg
  travado) e o hash e o cookie para o env root 0600. Sem eco e sem arquivo temporário.
- Nó `E_gmill_demo_route_caddy` em `vps-shared-tools-2026-07.kg.yaml` (radar exit 0).

## Achados

1. **REAL, decidido pelo maestro.** `basic_auth` puro barrava a API: a demo manda
   `Authorization: Bearer` (`apps/web/src/api/client.ts:85`), e o navegador não mistura o Basic guardado
   com um Authorization explícito. Medido no Caddy descartável: Bearer → 401. Saída B: cookie HttpOnly
   (`Path=/api/`, SameSite=Strict) emitido só depois do Basic; `/api/*` aceita cookie OU Basic.
2. **REAL, curado e provado por mutante.** Sem `route`, a ordem padrão do Caddy põe `header` antes do
   `basic_auth`, e o **401 levava o Set-Cookie**: bypass completo da API. Medido no mutante sem `route`:
   `Set-Cookie no 401 = 1`; com `route`: 0. Comentário no `.caddy` diz por quê.
3. **REAL, curado.** Cookie vazio no render viraria `*gmill_demo=*` e abriria a API. O render recusa
   valor vazio. Mutante que desliga a recusa: a bancada cai em 2 casos.
4. **REAL, curado.** `got=$(read_hash …)` de um conf.d ainda não instalado matava o `--check` **em
   silêncio**, com rc 1 (sha256sum rc≠0 sob pipefail+errexit). Medido no vivo.
5. **REAL, curado: a bancada não espelhava o runner.** O `t()` antigo rodava a função em contexto
   testado (`|| rc=$?`), onde o bash desliga o `set -e`. Por isso o achado 4 passava na bancada, e uma
   falha de pré-voo seguia "instalando" no sandbox. Agora `t()` roda com `set -e` dentro. Mutante do
   achado 4 com o harness novo: a bancada cai. A bancada foi de 11 para 31 casos.
6. **REAL, curado.** A verificação logo após o reload dava `000` (o cert ACME sai segundos depois). Agora
   ela espera até 90 s por vhost novo.
7. **Falso positivo / aceito.** O mutante que tira o `|| exit 2` depois do `stage_and_validate`
   sobrevive. Agora o `set -e` já cobre o caso, então o `|| exit 2` é redundância declarada.

## Incidente declarado (e curado)

Ao depurar o achado 4 com `bash -x`, o render imprimiu o hash e o cookie da 1ª geração no transcript.
**Curado por rotação** (`caddy-site-secrets.sh … --rotate`) antes da instalação: o vivo usa só os
segredos rotacionados, que nunca apareceram em saída nenhuma.

## Prova ao vivo (2026-10-08)

- `dig +short A gmill.onionevolve.com @8.8.8.8` → `179.197.65.94` (também @1.1.1.1 e no NS da
  Hostinger). Sem AAAA, como manda o padrão da casa. Zona 44 → 45 conjuntos, 0 perdidos/alterados
  (backup prévio em `~/onion-vps-waha/dns-backup/onionevolve-20261008-232540.json`).
- Cert: `CN=gmill.onionevolve.com`, emissor Let's Encrypt YE1, `ssl_verify_result=0`.
- `curl` sem credencial → **401**, sem Set-Cookie · `/api/health` com Bearer sem cookie → **401** ·
  cookie errado + Bearer → **401** · Bearer + cookie válido → **200** · página só com cookie → **401**.
- `install-caddy-config.sh` rc 0; `--check` sem drift no Caddyfile e no `conf.d/gmill.caddy`; os 7
  não geridos intocados (mtime e perm iguais).
- **Pendente:** 200 com a senha do Basic. O `pass` exige o gpg-agent destravado (pinentry em TTY), e a
  sessão de agente não tem TTY.

## Pendente-com-dono

- A stack `carteira` roda **sem** o override `compose.gmill.yaml` (`OIDC_ISSUER=http://localhost:39080/default`).
  Tokens emitidos pelo domínio terão `iss` divergente até a sessão `meugmill-vendas-6d` subir com o
  override. Isso é do repo da demo, não deste.

# Adendo (2026-10-08, depois do primeiro uso real pelo maestro)

- **Redirect com a porta interna.** Ao entrar com o usuário `gmill`, o navegador ia para
  `http://gmill.onionevolve.com:8080/demo/index.html`.
  - **Causa:** o nginx da demo escuta 8080 dentro do container e devolve redirect absoluto com a porta.
  - **Cura no vhost:** `header_down Location "^https?://[^/]+:8080/" "/"` nos dois `reverse_proxy`.
  - **Medido ao vivo com a credencial:** `location: /demo/index.html` e 200 seguindo o redirect.
  - **Cura de raiz:** `absolute_redirect off` no nginx da demo, a cargo da sessão meugmill-vendas.
- **Incidente de exposição de segredo (2º do dia).** Na prova do 200, o `-w '%{url_effective}'` do curl
  imprimiu a URL com a senha do Basic.
  - **Resposta:** a senha e o cookie foram trocados na hora (`caddy-site-secrets.sh --rotate` e reinstalação).
  - **Verificação:** a senha antiga dá 401 e a nova dá 200.
  - **Lição:** prova com credencial imprime só `http_code`, nunca `url_effective` nem `redirect_url`.
