# Sinal ao core — segundo sink real da vertical de design: React Native (números, não css-vars)

Data: 2026-09-07 · Origem: jogo-da-vida (`feature/design-tokens-theme`, ADR-010) · Tipo: lacuna do framework + precedente reutilizável

## O que aconteceu
Adotamos a vertical de design do Onion inteira (brief → `/design:generate` com 4 `@brand-generator` → gate `lint-design-tokens.sh` → juiz → promoção)
num app **Expo universal** (web + iOS + Android). A SSOT DTCG e o gate serviram sem mudança (83 pares WCAG, claro e escuro). O que **não** serviu
foi o sink: `.claude/utils/design-sink/tokens-to-css-vars.sh` emite css-vars planas — React Native consome **números e objetos**
(`fontSize: 16`, `boxShadow`, molas do Reanimated) e precisa que o tema escuro mude de **valor sob o mesmo nome** (não um segundo nome).
O portal do método já tinha registrado a metade disso (`tokens-to-theme.sh` com os dois temas, sinal `design-sink-tema-duplo`).

## O que fizemos (reutilizável)
`apps/app/scripts/tokens-to-theme.mjs` (Node, sem jq/python): lê `docs/design-context/**/*.tokens.json` (exceto `_candidates/`), resolve
`{alias}` inclusive dentro de composites (`typography`, `shadow`, `spring`), separa foundation (literal) de papel (alias) e `color.dark.*`,
exige paridade claro/escuro, e emite `src/theme/tokens.gen.ts` com `const dark: typeof light` (paridade no tipo) + `theme-color.gen.json`
para o `app.config.ts`. Modo `--check` no `lint` do pacote = CI reprova SSOT desatualizada. O gate roda ANTES como pré-condição.

## Pedido ao core
1. O README do design-sink declara "adapter reutilizável pendente": este é o segundo caso real (o primeiro é o css duplo do portal). Vale um
   `tokens-to-ts.mjs` genérico no core com as três decisões acima (composites, foundation-vs-papel por literal-vs-alias, paridade dark).
2. O contrato worker↔gate do `/design:generate` diz "`green/blue/red/amber.500`" — os nomes de foundation são do PROJETO (aqui: `spark.*`,
   `area.<5>.*`, `brand.900`); o texto do comando deveria dizer "os nomes que o `semantic/` do projeto espera", não uma lista fixa.
3. `lint-design-tokens.sh` só valida `$value` escalar: composites (`typography`, `shadow`) passam sem checagem de alias órfão dentro deles.
   O sink nosso pega; o gate deveria pegar também.
4. O `Workflow` `onion-research` grava o `kgPath` relativo ao cwd do PROCESSO no momento do write: com a sessão trocando de worktree no meio
   (`EnterWorktree`), um KG caiu na worktree errada. Resolver o `kgPath` para absoluto na entrada do workflow.

5. `lint-design-tokens.sh` varre `docs/design-context/` INTEIRO, inclusive `_candidates/` (que o `/design:generate` manda usar como staging):
   um JSON quebrado numa candidata fora do build derruba o gate do projeto, e como o mapa de tokens é um dicionário preenchido na ordem do
   `find | sort`, as candidatas (mesmos paths `color.brand.500`…) só não vencem a foundation promovida porque `_` ordena antes de `f` no
   locale C. O gate deveria excluir `_candidates/` (ou o comando deveria fazer o staging fora da SSOT).
6. O sink do consumidor teve de tratar como FALHA o "PULADA" do gate sem `jq` (fail-open): sem jq, um tint a 1.38:1 virava tema com exit 0.
   Vale o gate sair ≠ 0 quando `docs/design-context/` existe e a ferramenta falta.

## Evidência
`docs/design-context/` + `apps/app/scripts/tokens-to-theme.mjs` + `apps/app/src/theme/theme.test.ts` (segunda medição WCAG em Node) no repo
jogo-da-vida, branch `feature/design-tokens-theme`; veredito das candidatas em `docs/design-context/_candidates/VEREDITO.md`.
