---
title: "Revisao — F0 da reforma do site: deploy vira mecanismo (adversarial, 3 rodadas)"
date: 2026-08-25
branch: feat/site-reform-f0-deploy
reviewer: "branch-code-reviewer adversarial (sandbox proprio, shim de sudo, teste de mutacao) — 3 rodadas: REPROVADO -> REPROVADO -> APROVADO"
reviewed_diff_sha256: a50514ce064157b21a432ad05e9e0c680a21570fdb9f051541443eb36603261a
findings_total: 21
findings_real: 12
verdict: APROVADO
tokens: 383000
duration_min: 31
---

# Residuo — REGRA 56 (revisao adversarial em 3 rodadas, com refutacao por execucao)

PR #671 — `ops/deploy-site.sh` (deploy fonte→webroot do onionevolve.com) + repatriacao de
`site/federacao/`. A revisao foi o dogfood que o lint nao faz: sandbox com shim de sudo,
ataques reais, teste de mutacao na bancada.

## Rodada 1 — REPROVADO (3 reais de 14 achados)

- **R1** 🔴 symlink no topo do webroot: `rsync --delete` seguia o link e DESTRUIA o alvo —
  inclusive `mini/` e a PROPRIA FONTE (provado: working tree apagada no sandbox). E o
  `--check` rotulava o symlink de "DRIFT" — o conselho da verificacao ERA a acao destrutiva.
- **R2** 🔴 fonte vazia: hash-do-vazio identico dos dois lados — "deployei certo" e "apaguei
  tudo" indistinguiveis, com veredito verde. O cenario exato do futuro `site/dist` (F1/Astro).
- **R3** 🔴 `site/federacao/` consagrada como fonte sendo artefato GERADO sem gerador, 46 dias
  rancoso — e religar o gerador publicaria membros sem visibilidade publica (incl. cliente
  sob NDA). REGRA 30 nao pegaria (so caca nome comercial).
- Menores R4-R14: .bak-diretorio abortava o deploy no meio; check morria mudo em dir ilegivel;
  hash cego a symlink/dir-vazio; locale no sort; README com prosa divergente; NADA invocava o
  script; no do KG nao carimbado; allowlist sujeita a pathname expansion; --help exit 2.

## Rodada 2 — REPROVADO (1 bloqueador NOVO, introduzido pela cura de R4)

- **NOVO-1** 🔴 a limpeza de .bak trocou `find -delete` por parsing de `find -print`: nome com
  NEWLINE virava dois alvos (`evil.bak\nmini` destruiu `mini/` no sandbox, rodando de dentro
  do webroot). A cura reabriu a invariante-ancora.
- **NOVO-2** 🟡 injecao via TMPDIR no trap do selftest (valor expandido na montagem).
- **NOVO-3** 🟡 a cura de R3 pos a governanca interna (members.yaml, docs/onion/) NO AR.
- **NOVO-4** 🟡 congelamento por declaracao sem mecanismo — exigiu no de backlog com gatilho.
- Curas da rodada 1 CONFIRMADAS por execucao (R1/R2/R5/R6/R7/R11/R12/R13) + mutacao provou a
  bancada real (guarda removida → selftest vermelho especifico).
- **Achado nosso confirmado pelo revisor**: quick-check do rsync (`-a`, mtime 1s + tamanho)
  PULAVA arquivo alterado no mesmo segundo — o cenario de build regenerando dist/. `--checksum`.

## Rodada 3 — APROVADO

- NOVO-1 caiu sob o proprio ataque do revisor + 6 variantes hostis extras (newline→pulse-mais,
  DIRETORIO com newline, dash-inicial `-rf.bak`, `*.bak` literal, espaco, .bak aninhado): zero
  intocavel perdido. Mutacao re-provou a rede (parsing reintroduzido → 14/2 vermelho).
- NOVO-2: TMPDIR malicioso → rc=0, INJETADO: NAO, zero orfaos. NOVO-3: 0 termos de governanca
  no curl do vivo. NOVO-4: `Q_FEDERACAO_VISIBILITY_GATE` com gatilho nomeado (visibility: no
  members.yaml + regra de lint ANTES de religar), radar rc=0.
- Follow-ups da rodada final JA APLICADOS neste diff: preambulo antigo do federation-map.md
  cortado (servia instrucoes OPOSTAS ao publico) + guarda no find de limpeza (nao aborta mais
  entre rsync e verificacao) + caso R1b na bancada (symlink no topo da FONTE).

## Estado final (provado)

`--selftest` **18/18** (bancada = os ataques das 3 rodadas congelados) · `--check` no vivo
**6/6 verde** · vivo serve **104 comandos/12 skills** · 0 `*.bak*` publicos · injecao TMPDIR
inocua · radar do grafo de identidade rc=0 (88 nos/103 arestas) · `run_deploy_site_selftests`
registrado na bancada do lint · lint 0 HARD (fora este residuo, que este arquivo cura).

## Dividas registradas (nenhuma bloqueou o merge)

- `Q_FEDERACAO_VISIBILITY_GATE` (grafo de identidade): visibility: no members.yaml + regra de
  lint — GATILHO: religar/refresh de /federacao/. Ate la o snapshot congelado E o estado seguro.

**Veredito: APROVADO** — 2 REPROVADOS antes do verde, cada bloqueador refutado por execucao e
congelado como caso de bancada. O deploy deixou de depender de o maestro lembrar.
