---
date: 2026-08-25
instance: onion-evolve
type: learning
classification: collective
tags: [site, reforma, astro, adversarial-review, self-measurement]
affects: [site/, ops/deploy-site.sh, .claude/validation/]
breadcrumb_for: reforma-onionevolve-2026-08
share_with: [core]
next_recommended: 2026-09-25
review_after: 2026-11-25
conflict_class: static
significance: "A reforma inteira do site num dia (F0-F6, PRs #671/#672) — e a lição não foi o Astro: foi o VERIFICADOR errando a medição 4 vezes e sendo pego pelas próprias guardas"
---

## Signal

A reforma do onionevolve.com saiu inteira em um dia: F0 (deploy vira mecanismo) mergeada de
manhã, F1-F5 (Astro, 10 páginas, 21 posts novos, doutrinas públicas pt+EN, grafo navegável)
no ar à noite, com dois gates selados — o do maestro (conteúdo) e o adversarial (3+3 rodadas,
4 REPROVADOS no total antes dos dois verdes).

Mas o padrão que merece a migalha não é a entrega. É que **quem verificava errou a medição
quatro vezes na mesma sessão** — e cada erro foi pego por um mecanismo, não por atenção:

1. Cobrei um agente por uma página "ausente" que EXISTIA — eu medi com cwd errado
   (`site/src/...` estando dentro de `site/`).
2. "Corrigi" a convenção de slug de um curador com base em `ls | head -5` — amostra enviesada:
   31 dos 41 posts usavam a convenção que eu chamei de errada. O curador estava certo.
3. Contei "1 item" no feed com `grep -c` num XML de linha única — grep -c conta linhas, não
   ocorrências. Eram 41.
4. Quase acusei o kg-console de gerar console vazio — os dados estavam lá, em base64; meu grep
   por texto claro era a verificação errada.

E o revisor adversarial cometeu (e confessou) o quinto: testou variantes de SIGPIPE dentro de
`&& ||` — a exceção do set -e — e as quatro "sobreviveram"; só o set -x no runner real o
desmentiu. A bancada dele não espelhava o runner, a lição que a casa já tinha carimbado.

## Evidence

- PR #671 (3 rodadas: symlink-no-topo destruindo mini/, fonte-vazia com veredito verde,
  newline-no-nome contornando o prune, injeção via TMPDIR) e PR #672 (guardas de privacidade
  CEGAS a .astro no exato momento em que 15 páginas viraram .astro; SIGPIPE matando o lint
  MUDO com rc=141 e 10 regras silenciadas; redirects declarados que não existiam).
- Cada ataque virou caso de bancada: deploy --selftest 25/25; site-derivation (a)(b)(c) com o
  caso de VOLUME ("a asserção que importa não é 'acusou' — é 'chegou ao sumário'").
- O gate R56 pegou o próprio carimbo caduco no CI (o rebase moveu a F0 para a base e o diff
  encolheu — ARTEFATO-CADUCO, re-carimbado com nota).

## Next crumb

A cura para "verificador que mede errado" nunca foi atenção — foi SEMPRE a segunda medição por
outro caminho (o agente refutando com o ls completo; o radar refazendo a conta; o CI recomputando
o hash). Quando eu medir algo que decide uma cobrança a outrem, a migalha manda: re-medir por um
segundo caminho ANTES de cobrar. Se a reincidência continuar, a cura vira guarda de harness
(a classe bash-empty-result-guard já cobre metade dos casos — cwd e amostra não).
