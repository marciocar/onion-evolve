---
branch: feat/caddy-sandbox-ui-pilot
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 9dfdb4e98d660300f37b835663f1ec8c0337408106bc583f3260d239e4a2d1ae
reviewed_code_sha256: 0e9de1eb5ddab298778d170f372f5a5b44810f3d4c68f7840ab97a6618ab2e2c
findings_total: 4
findings_real: 3
tokens: 0
duration_min: 50
findings_fixed: 3
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: agente de execução (passada adversarial manual, sem subagentes; Caddy descartável em loopback, mutantes da bancada)
nota: >-
  A 1ª redação lia a origem do sandbox.html como root. O bridge servido é do onion, e trocar o arquivo
  por symlink depois do test -L publicaria na web um arquivo só de root. Agora a origem se lê como onion.
  O CSP não foi medido num navegador, e o vhost não foi instalado no vivo: as duas coisas são da sessão principal.
---

# Passada adversarial: `feat/caddy-sandbox-ui-pilot`

## O que muda

- `ops/caddy/conf.d/sandbox.caddy`: vhost novo de `sandbox.onionevolve.com`, a origem distinta do piloto
  ui:// render-only (`D_UI_PILOTO_RENDER_ONLY_NO_CHAT_1021`). Serve só o `/sandbox.html` de
  `/var/www/onion-sandbox` e responde 404 a todo o resto. Leva o CSP da vista, nosniff, no-referrer,
  Permissions-Policy e no-cache, como sugere o `deploy/sandbox/README.md` do onion-bridge (PR #83).
- `ops/caddy/Caddyfile`: o CSP do `app.onionevolve.com` ganha só `frame-src https://sandbox.onionevolve.com`.
- `ops/update-bridge.sh`, fase 7: depois da fase 6 provada (no update e no NOOP), publica
  `deploy/sandbox/sandbox.html` do bridge servido em `/var/www/onion-sandbox/sandbox.html`, root:root 0644,
  atômico, só se mudou. Recusa symlink na origem, no diretório e no destino. Sem o arquivo, avisa e segue.
- Bancada: casos u26 a u33 na família do update-bridge, cada um com mutante.
- Nó `C_UI_SANDBOX_ORIGIN_VERSIONED_NOT_LIVE_1022` (open) em `vps-shared-tools-2026-07.kg.yaml`, ao lado das
  outras rotas do Caddy, com aresta externa para a decisão no grafo da dissecação intelligent-ui. Esse grafo
  está no teto de nós declarado no `meta:` (REGRA 58 (O backlog cumpre as promessas do próprio `meta:`)
  reprovou a 1ª redação, que punha o nó lá).

## Achados

1. **REAL, curado: a origem era lida como root.** `sudo install "${src}"` lê como root um arquivo de uma
   árvore do onion. O test -L vem antes, e entre os dois o onion pode trocar o arquivo por um symlink para
   um arquivo só de root, que o `install` publicaria na web. Cura: a origem se lê com `sudo -u onion cat`,
   a cópia vai por `sudo tee` para o temporário, e a comparação também lê como onion. O pior caso agora é
   publicar o que o onion já lê, sem escalada. A bancada não distingue usuário (o sudo falso ignora `-u`),
   então esta cura **não tem caso com mutante**: está declarada abaixo como NÃO MEDIDA.
2. **REAL, curado: o NOOP nunca publicaria.** Com o passo só no fim do update, o 1º run depois do merge
   deste PR, com o bridge já em dia, cairia no NOOP para sempre. O passo roda também no NOOP, depois do boot
   vivo provado (caso u33).
3. **REAL, curado: "mudou" só por conteúdo.** Um 0666 deixado à mão sobreviveria. A comparação inclui
   dono e modo.
4. **NÃO É DEFEITO: o `verify 200` no vhost.** O instalador cobra cada `# verify:` depois do reload. Sem o
   arquivo publicado, `/sandbox.html` dá 404 (medido no Caddy descartável, diretório ausente), e o
   instalador reprovaria. O vhost leva só o `verify` do 404, e o cabeçalho diz quando acrescentar o 200.

## Prova

- `caddy validate` (v2.11.4) do Caddyfile mais o conf.d num estágio local, import reescrito como faz o
  `stage_and_validate` do instalador: `Valid configuration`. O `gmill.caddy` entrou com hash bcrypt de
  bancada no lugar do marcador. O `caddy adapt` mostra o `frame-src` no CSP do app.
- Corpo do vhost num Caddy descartável em `http://127.0.0.1:18899`: `/sandbox.html` 200, byte a byte o do
  PR #83, com os cinco cabeçalhos; `/qualquer`, `/`, `/outro.txt` (arquivo presente no root),
  `/sandbox.html/` e `/SANDBOX.html` dão 404; sem o diretório, `/sandbox.html` dá 404.
- `LC_ALL=C bash .claude/validation/lint-selftest.sh --families update_bridge`: 66 pass, 0 fail.
  `--families install_caddy_config`: 1 pass (a bancada embutida do instalador).

## NÃO MEDIDO

- O CSP num navegador. Falta confirmar que o `default-src 'none'` não barra o iframe `srcdoc` interno: é o
  passo 4 do README do bridge.
- O vhost no vivo (TLS, ACME, `install-caddy-config.sh`) e a fase 7 contra o sudo e o `/var/www` reais: os
  dois ficam para a sessão principal, depois do merge.
- A leitura como onion (achado 1) não tem caso na bancada.
- Os conf.d não geridos do vivo não entraram no estágio local: o pré-voo do instalador os inclui.
