---
title: "Revisao — reforma do site F1-F5: Astro, cutover, diario, doutrinas (adversarial, 3 rodadas)"
date: 2026-08-25
branch: feat/site-reform-f1-astro
reviewer: "branch-code-reviewer adversarial (fixtures proprias, repo-fixture git real, medicao no runner) — 3 rodadas: REPROVADO -> REPROVADO -> APROVADO"
reviewed_diff_sha256: cb5a4dbe8c9e6095c1847dcb7b46655b590213fc3499339fd2863fd2d5f0df25
findings_total: 12
findings_real: 6
verdict: APROVADO
tokens: 520000
duration_min: 45
---

# Residuo — REGRA 56 (reforma do onionevolve.com, F1-F5)

> Nota de carimbo: o sha original (839af560…) foi computado ANTES do rebase sobre a main
> com a F0 mergeada — o rebase moveu os patches da F0 do diff para a base e o diff
> efetivo encolheu (pego pelo proprio gate no CI: ARTEFATO-CADUCO). O conteudo revisado
> e IDENTICO (mesma arvore); re-carimbado para o sha do BASE..HEAD pos-rebase.

Diff grande (fundacao Astro + porte de 10 paginas + 21 posts + cutover de deploy + guardas
re-cabeadas). A revisao adversarial rodou em 3 rodadas com medicao no runner real, e o gate de
CONTEUDO foi selado pelo maestro a parte (aprovacao explicita do documento de gate: doutrinas,
capitulos, criticas, timeline, posts, secoes novas).

## Rodada 1 — REPROVADO (3 criticos, todos com prova executada)

- 🔴 lint 1 HARD: lint-rules.md (derivacao) editado a mao DENTRO do PR que reescreve a regra
  "a derivacao nunca vira fonte" — a ironia foi nomeada pelo revisor.
- 🔴 REGRAs 30/35 CEGAS a `.astro`: provado com fixture (mesmo termo privado em .html reprova,
  em .astro nem era aberto) — exatamente quando 15 paginas viraram .astro. Agravante: dist local
  faria a cobertura ser nao-deterministica ("verde variavel e pior que ausente").
- 🔴 redirects 301 declarados NAO existiam no Caddy — e o 1o deploy apagaria /historia/grafo/
  do ar (404 puro) e deixaria /convite/ como pagina fantasma fora da allowlist.
- 🟡 --check deixou de ser read-only e o cabecalho mentia; SIGPIPE latente na R34 (git|head
  invertia o veredito sob volume: N=800 HARD, N=1500 SOFT); run_build e R34 sem bancada;
  manual das migalhas meio-atualizado; formula do radar duplicada (fonte paralela);
  pluginsPublicados lendo dir mutavel (fixture de bancada viraria plugin fantasma).
- ⚪ VERDES verificados: selftest 18/18; build reproduz F0 byte a byte (fonts/images/federacao
  identicos); 62/62/62 posts/provas/feed; zero link interno quebrado; conteudo dos posts conferido
  contra o diario NUMERO A NUMERO (824/0/0, 49s, 65536, 15/8... todos literais); zero nome de
  adotante em conteudo novo; onion-plugins PUBLICO confirmado por API.

## Rodada 2 — REPROVADO (a cura do SIGPIPE regrediu para pior)

- 🔴 a "cura" MOVEU o pipe (git|head → printf|head): sob set -e o lint MORRIA MUDO com dist
  grande — rc=141, sem sumario, 10 regras silenciadas (medido em repo-fixture real: N=30 HARD,
  N=1500 morte muda). O revisor tambem confessou o proprio erro de metodo (testou variantes
  dentro de `&& ||`, a excecao do set -e — bancada que nao espelha o runner) e re-mediu.
- Cura B recomendada COM teste: here-string (`head -5 <<<`), sem processo escritor p/ SIGPIPE.
- 🟡 formulacao melhor p/ redirects: pre-voo COMPORTAMENTAL no proprio deploy (curl 301, die
  sem prova) + RETIRED_ENTRIES que o deploy remove e o check acusa — "as docs passam a ser
  verdadeiras porque o deploy nao roda de outro jeito".

## Rodada 3 — APROVADO (sha 0b819b69… sobre a working tree; o deste residuo e o do diff staged)

- SIGPIPE curado com a variante B e re-provado NO MESMO experimento que o pegou: N=1500 e
  N=6000 → exit 1, sumario presente, DERIVACAO-COMMITADA acusada.
- Redirects viraram MECANISMO: check_retired_routes (comportamental, 1o passo do pre-voo) +
  RETIRED_ENTRIES (deploy remove, check acusa) — provado no vivo: o /convite/ fantasma que era
  invisivel a allowlist virou acusacao do proprio --check.
- Pos-veredito, as ressalvas nao-bloqueantes TAMBEM entraram: CURL_CMD com stub na bancada
  (200→recusa / 301→prossegue), caso (c) de VOLUME na bancada da R34 (1500 arquivos → "chega
  ao sumario", nao so "acusa"), usage() honesto, provenance churn fora do commit.

## Estado final (provado)

deploy --selftest **25/25** · bancada do lint **835+/0/0 skips** · lint **0 HARD / 4 SOFT
passivas** · R30 morde .astro (RED provado) · build 10 paginas, 62 posts=62 provas=62 feed ·
numeros das paginas = SSOT por construcao (stamp) · gate de conteudo selado pelo maestro.

## Dividas registradas (gatilho nomeado)

- Formula do radar duplicada no RadarWidget (fonte paralela): parqueada p/ F6/backlog — gatilho:
  qualquer mudanca nos statusFactor do kg-radar.sh OU 1a divergencia observada.

**Veredito: APROVADO** — 2 REPROVADOS antes do verde; a rodada 2 derrubou a cura da rodada 1
por execucao, e a bancada agora carrega os ataques das tres rodadas como rede permanente.
