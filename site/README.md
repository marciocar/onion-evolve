# site/ — fonte do onionevolve.com

**Projeto Astro** (desde o cutover F2 da reforma, 2026-08-25 — executa o D1 do ADR
`onion-adr-blog-publication-generator-2026-07`): a fonte é `src/` + `public/` + `historia/migalhas/posts/`
(coleção); a derivação é `dist/` (**gitignored**, nunca commitada — REGRA 34) e o webroot
`/var/www/onion-landing/` é derivado do dist pelo deploy. Importado do vivo em 2026-07-06
(a landing nasceu via Onion-Bridge); virou Astro em 2026-08-25 sem reescrever a copy.

```
src/ + public/ + posts/  ──build──►  dist/  ──ops/deploy-site.sh──►  /var/www/onion-landing/
      (FONTE, git)                (derivação local)                  (derivação servida)
```

**O mapa da fonte:**
- `src/pages/` — home (com as seções "Uma demissão de distância" e "Superfícies vivas"), `/historia/`
  (11 capítulos + curva de commits), `/historia/migalhas/` (+ provas + feed, da coleção),
  `/doutrinas/` e `/maquinaria/` (**pt + `/en/`**), `/estado/`, `/grafo/`
- `src/lib/stamp.ts` — números derivados da SSOT em build time, com as 3 classes declaradas
  (inventario-vivo / congelado-no-tempo / estado-de-programa) — nunca hand-coded
- `historia/migalhas/posts/*.md` — a fonte do diário (coleção `migalhas`; manual em
  `historia/migalhas/README.md`)
- `public/fonts/`, `public/images/` — assets (Fraunces variável self-hosted; foto do maestro)
- `public/grafo/<slug>/` — consoles de grafo navegáveis (HTML self-contained do `kg-console.sh`)
- `public/federacao/` — **snapshot CONGELADO de 2026-07-10** da projeção pública da federação.
  NÃO é regenerado: o gerador real (`graph.sh --map`) projeta a SSOT interna de `docs/onion/`, que
  hoje contém membros sem visibilidade pública. **Religar o gerador para cá exige antes o campo
  `visibility:` no `members.yaml` + regra de lint** — gatilho nomeado no nó
  `Q_FEDERACAO_VISIBILITY_GATE` (grafo de identidade).
- **Aposentados no cutover**: `/convite/` (absorvida por `/maquinaria/#experimente`) e
  `/historia/grafo/` (absorvida por `/maquinaria/`) — redirects 301 no Caddy.
- `/mini/` e `/pulse-mais/` têm fonte nos SEUS repos (onion-mini `site/`, pulse-mais `materials/`)
  — fora do build e fora da allowlist do deploy, por construção.

**Deploy** (após commit na main): `ops/deploy-site.sh` — NA KVM 8, sem argumento. O script é a
única via: allowlist de entradas (mini/ e pulse-mais/ inalcançáveis por construção), `--check`
verifica drift fonte×vivo (builda por dentro; escreve só site/dist, nunca o webroot), `--selftest` roda a bancada em sandbox. O
procedimento manual de rsync que vivia aqui foi **aposentado em 2026-08-25** (PR #671): era prosa
divergente da prática e deixou o vivo mentir por um mês — a revisão adversarial do PR tem a
história (`docs/evolution/review/feat-site-reform-f0-deploy.md`).

> **Acesso remoto** (se um dia precisar deployar de FORA da KVM 8): o alias `onion-vps` usa
> **`Port 2222`** no `~/.ssh/config` (2026-07-10; lição no diário `2026-07-10-ssh-alt-port-2222`).
> O script hoje é local-only por desenho — ele mora onde o webroot mora.

Créditos do site: **by Marcio Carvalho** (definitivo desde 2026-07-06; substituiu "Sacola de Ideias").
