---
title: "Revisao — versiona o Caddyfile do site em ops/ (config-as-code)"
date: 2026-08-26
branch: feat/ops-version-caddy-config
reviewer: "self-review (autor) — plano curado por pesquisa (interna+externa); guardas provadas por comportamento; aplicado na VPS"
reviewed_diff_sha256: 793dd1063e963f60831c5af95186588274a3f954bc653a1d7295242740baba22
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 6000
duration_min: 55
---

# Residuo — REGRA 56 (self-review; artefato de ops, aplicado na VPS)

O maestro pediu versionar o Caddyfile em ops/ apos pesquisa externa curada. O `/etc/caddy/Caddyfile`
vivia SO na VPS (backups a mao `/root/Caddyfile.bak-*`) — a anomalia que `ops/bridge-backup.sh:11-14` e a
doutrina de `ops/gpg-protect-key.sh:13-14` condenam. Plano aprovado em plan mode; pesquisa interna
(padrao ops/) + externa (estado da arte Caddy 2026, com fontes) fundamentou as escolhas.

**O que entrou:**
- `ops/caddy/Caddyfile` — a config versionada (3 vhosts + `import conf.d/*.caddy`).
- `ops/install-caddy-config.sh` — instalador idempotente espelhando `ops/deploy-site.sh` (pre-voo
  `caddy validate`, backup timestamped, reload gracioso + rollback, verificacao comportamental; modos
  `--check`/`--selftest`).
- `.claude/validation/lint-selftest.sh` — registra `run_install_caddy_config_selftests` (gate CI).

**Achados REAIS pegos e curados nesta sessao (findings_real:3 — todos provados por comportamento):**
1. **`no-store` matava o 304** — o header que eu tinha aplicado ao vivo (`no-cache, no-store,
   must-revalidate`) e auto-contraditorio: `no-store` proibe o cache e elimina o 304 via ETag. A pesquisa
   externa (Simon Hearne, toolhq, Caddy docs) confirmou: para HTML publico o certo e **`no-cache` puro**.
   Corrigido na fonte versionada E no ar (curl agora mostra `cache-control: no-cache`). Assets `immutable`:
   confirmado otimo, mantido.
2. **Recursao infinita no selftest** — nomeei a funcao `install()`, que sombreava o binario `install`
   coreutils; com `SUDO_CMD=""` no sandbox, `$SUDO_CMD install ...` chamava a propria funcao → hang (timeout
   2min, provado). Renomeei para `apply_config` + troquei por `cp`+`chmod`. 11/11 verde depois.
3. **`set -f` quebrou a assercao de glob** — a bancada checava `ls *.bak` sob noglob → falso "backup nao
   criado". Troquei por `find`. E `SB` local nao era alcancado pelo trap de EXIT (`unbound variable`) →
   tornei global. Ambos provados: 11/11, sem erro de exit.

**Verificacao por COMPORTAMENTO (nao declaracao):**
- `bash ops/install-caddy-config.sh --selftest` → **11/11 pass, rc 0** (validate-falha-nao-toca,
  backup-criado, idempotencia, drift-acusa, reload-falha-faz-rollback, fonte-ausente-die).
- `caddy validate --config ops/caddy/Caddyfile` → "Valid configuration".
- Aplicado na VPS: `curl -sI https://onionevolve.com/` → **`cache-control: no-cache`** (sem no-store);
  3 vhosts respondem (200/200/302); `/_astro/*.css` → `immutable`.
- `bash ops/install-caddy-config.sh --check` → rc 0 (vivo == versionado, sem drift).
- Bancada inteira: **839 pass**, incluindo `install-caddy-config: 11 pass`.

**Teto declarado (o que NAO cobre):** o `--check` compara o hash do arquivo (pega edicao a mao de
/etc/caddy), NAO o estado vivo no processo via Admin API (`caddy adapt` × `GET :2019/config/`) — deixado
como follow-up (drift-timer) por ser mais ruidoso (politicas TLS auto-adicionadas). Migrar o vhost para
`conf.d/onionevolve.caddy` (isolar do bridge/logto) tambem e refino futuro nomeado no plano.

**Veredito: APROVADO** — config-as-code com guardas provadas, aplicado e verificado; conserta de quebra o
defeito de cache que estava no ar. O Caddyfile deixou de ser "temporario na VPS".
