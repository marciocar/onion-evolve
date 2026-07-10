# site/ — fonte do onionevolve.com

**Fonte única** das páginas servidas pelo Caddy do VPS em `/var/www/onion-landing/` (o webroot é
DERIVADO — fonte≠derivação). Importado do vivo em 2026-07-06 (a landing nasceu via Onion-Bridge).

- `index.html` — a autobiografia (home)
- `historia/index.html` — o capítulo novo (timeline 29 jun → 5 jul 2026)
- `/mini/` e `/pulse-mais/` têm fonte nos SEUS repos (onion-mini `site/`, pulse-mais `materials/`)

**Deploy** (após commit na main): `rsync -a site/index.html onion-vps:/var/www/onion-landing/index.html && rsync -a --delete site/historia/ onion-vps:/var/www/onion-landing/historia/`
(NUNCA `--delete` na raiz — apagaria mini/ e pulse-mais/.)

> **Acesso**: o alias `onion-vps` usa **`Port 2222`** no `~/.ssh/config` (2026-07-10 — redes que filtram
> a 22 de saída; a 22 segue aberta no servidor). Sessões rodando NA própria KVM 8 deployam com `cp`
> direto para `/var/www/onion-landing/` (sem rsync/ssh). Lição do incidente: diário
> `2026-07-10-ssh-alt-port-2222`.

Créditos do site: **by Marcio Carvalho** (definitivo desde 2026-07-06; substituiu "Sacola de Ideias").
