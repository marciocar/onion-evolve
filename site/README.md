# site/ — fonte do onionevolve.com

**Fonte única** das páginas servidas pelo Caddy do VPS em `/var/www/onion-landing/` (o webroot é
DERIVADO — fonte≠derivação). Importado do vivo em 2026-07-06 (a landing nasceu via Onion-Bridge).

- `index.html` — a autobiografia (home)
- `historia/index.html` — o capítulo novo (timeline 29 jun → 5 jul 2026)
- `fonts/` e `images/` — assets (Fraunces variável self-hosted; foto do maestro)
- `convite/` — landing do experimento cold-adopter (órfã de nav; absorção prevista na reforma 2026-08)
- `federacao/` — **snapshot CONGELADO de 2026-07-10** da projeção pública da federação, repatriado
  do webroot em 2026-08-25 (PR #671). NÃO é regenerado: o gerador real (`graph.sh --map`) projeta a
  SSOT interna de `docs/onion/`, que hoje contém membros sem visibilidade pública. **Religar o
  gerador para cá exige antes o campo `visibility:` no `members.yaml` + regra de lint** — gatilho
  nomeado no nó `Q_FEDERACAO_VISIBILITY_GATE` (grafo de identidade).
- `/mini/` e `/pulse-mais/` têm fonte nos SEUS repos (onion-mini `site/`, pulse-mais `materials/`)

**Deploy** (após commit na main): `ops/deploy-site.sh` — NA KVM 8, sem argumento. O script é a
única via: allowlist de entradas (mini/ e pulse-mais/ inalcançáveis por construção), `--check`
verifica drift fonte×vivo sem efeito colateral, `--selftest` roda a bancada em sandbox. O
procedimento manual de rsync que vivia aqui foi **aposentado em 2026-08-25** (PR #671): era prosa
divergente da prática e deixou o vivo mentir por um mês — a revisão adversarial do PR tem a
história (`docs/evolution/review/feat-site-reform-f0-deploy.md`).

> **Acesso remoto** (se um dia precisar deployar de FORA da KVM 8): o alias `onion-vps` usa
> **`Port 2222`** no `~/.ssh/config` (2026-07-10; lição no diário `2026-07-10-ssh-alt-port-2222`).
> O script hoje é local-only por desenho — ele mora onde o webroot mora.

Créditos do site: **by Marcio Carvalho** (definitivo desde 2026-07-06; substituiu "Sacola de Ideias").
