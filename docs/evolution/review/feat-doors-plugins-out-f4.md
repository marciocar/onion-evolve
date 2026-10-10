---
title: 'Resíduo — F4 das portas: o plugins/ montado sai do core'
date: 2026-10-10
branch: feat/doors-plugins-out-f4
reviewed_diff_sha256: pendente
findings_total: 16
findings_real: 16
findings_fixed: 12
tokens: 216125
duration_min: 22
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: "passada adversarial (branch-code-reviewer, default reprovado) achou 2 bloqueadores, 5 importantes e 9 menores; 12 curados no mesmo laço com caso de bancada e mutante; 4 menores declarados (pre-commit não reage a manifesto APAGADO, raiz lista onion-meta antes da 1ª publicação, guarda da raiz sem manifesto nenhum, registro das regras da publicação fora do lint-rules.md)"
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que o PR faz

É a F4 do plano das portas (SAC-93), pela matriz `D_MATRIZ_DE_PORTAS_2026_10`.

- **`plugins/` sai do core** (269 arquivos) e `/plugins/` passa a ser ignorado. Um PR que toca uma fonte
  bundlada não regenera mais nada: saíram o auto-fix do pre-commit e o ramo de `plugins/` do
  `pr-finalize --rebase`.
- **Versão do plugin vem do publicado.** O `assemble-plugin.sh` lê o anterior do plugin que já está no
  destino (o clone de `onion-plugins`) ou de `ONION_PLUGIN_PRIOR_DIR`. O `materialize-marketplace-repo.sh`
  parou de apagar o plugin antes de chamar o assembler.
- **Guardas de plugin julgam o bundle.** A REGRA 19 (Plugins de vertical sincronizados com as fontes) foi
  aposentada. As REGRAS 72, 73, 75, 77 e 79 saíram do lint de PR para o `plugin-bundle-check.sh`, que o
  `/meta:publish onion-plugins` roda no passo 5d sobre o que montou. A família de bancada `plugin_bundle`
  roda o mesmo checador sobre um bundle temporário montado das fontes vivas. A REGRA 61 (Fronteira de MOAT)
  fica no lint (manifestos) e ganha a metade do resultado no checador. A REGRA 74 (Caminho .claude/ NU
  dentro de plugin só resolve no core, com catraca) varre o bundle na publicação e guarda a catraca no lint.
- **REGRA 76 repensada.** No core, a raiz é projeção dos manifestos (`generate-marketplace.sh
  --from-manifests`) e cada `source` é `git-subdir` no repo público. Fora do core, o modo bundle de antes.
- **Meta-fábrica empacotada** no plugin novo `onion-meta` (9 comandos, 3 agentes, 3 templates). Ficam fora,
  declarados: `create-vertical` (depende do motor do marketplace, que a REGRA 61 segue tratando como moat)
  e `forge`/`forge-guard`/`cc-update` (os motores medem o harness, que plugin não carrega).

## Achados da passada adversarial, e o destino de cada um

| # | Severidade | Achado | Destino |
|---|---|---|---|
| B1 | bloqueador | o branch reprovava o lint com 3 HARD de projeção defasada (REGRAS 62, 80, 84) | CURADO: `ops/pr-finalize.sh --push` regenera as projeções |
| B2 | bloqueador | a REGRA 76 exigia o modo dos manifestos em QUALQUER repo com manifesto: um standalone com plugin próprio levava HARD, e o `--write` sugerido apontaria o catálogo dele para o repo público do Onion | CURADO: o modo vem do papel (core = manifestos; outro repo com `plugins/` = bundle); caso `marketplace_root_sync (f)` + mutante |
| I1 | importante | a isenção `CONSUMER_TARGET_ROOTS` cobria toda ref de raiz declarada, inclusive `allowed-tools` e ponteiros de leitura mortos | CURADO: isenção estreita (raiz, categoria de 1 nível, placeholder; nunca `allowed-tools`); os 7 ponteiros de leitura viraram citação sem caminho na fonte; caso `plugin_bundle (b)` planta leitura no onion-meta + mutante |
| I2 | importante | a catraca da REGRA 74 tinha sumido de todo gate | CURADO: `check_plugin_bare_path_ratchet` no lint de PR (baseline × origin/main) e `--prev-baseline` na publicação (baseline do pin publicado antes); casos `plugin_bundle (b2)` e `(f)` + mutantes |
| I3 | importante | `ONION_PLUGIN_PRIOR_DIR` exportada contaminava a versão de todos os plugins | CURADO: o assembler ignora anterior de outro `name`; o materialize faz `unset`; caso `plugin_version_derived (e2)` + mutante |
| I4 | importante | nenhum gate de PR conferia que as fontes declaradas no manifesto existem (era a REGRA 19) | CURADO: classe `fonte-do-manifesto-ausente` na REGRA 76, sem montar nada; caso `marketplace_root_sync (e)` + mutante |
| I5 | importante | o nó Q nascia com o label do nó E | CURADO: label reescrito como pergunta, com gatilho |
| M1 | menor | `plugin-bundle-check.sh` sem bit de execução | CURADO |
| M2 | menor | a bancada não plantava defeito para 73, 77 nem `entrada-diverge` | CURADO: plantados no caso (b), cada um com mutante |
| M3 | menor | `ai-development-guide.md` listava a REGRA 19 como vigente | CURADO |
| M5 | menor | ~40 menções a REGRA sem título nos comentários novos | CURADO (titulação mecânica das linhas acrescentadas) |
| M8 | menor | `check_graph_sync` ainda pulava sem `jq` | CURADO: o `graph.sh` não usa mais `jq` e o gate saiu |
| M4 | menor | o `lint-rules.md` não registra as regras que moram só na publicação | DECLARADO: os títulos ficam nos cabeçalhos do checador, que o hook lê; um registro gerado da publicação fica para quem pedir |
| M6 | menor | apagar um manifesto não regenera a raiz nem o grafo no pre-commit (`onion_staged` filtra ACMR) | DECLARADO: o lint de PR acusa (falha ruidosa) |
| M7 | menor | a raiz lista `onion-meta` antes de ele existir no repo público | DECLARADO: some na 1ª publicação (`/meta:publish onion-plugins`, do maestro) |
| M9 | menor | a guarda da raiz sai 0 sem manifesto nenhum, mesmo com catálogo listando plugins | DECLARADO: sem manifesto o core não tem o que projetar; repo com `plugins/` cai no modo bundle |

## Bancada

Famílias tocadas sob `LC_ALL=C`: 300 casos verdes na 1ª leva (35 famílias) e 164 na 2ª (16 famílias,
depois das curas). 28 mutantes distintos por `ops/mutate-and-restore.sh`, todos reprovando o caso nomeado. A bancada
completa não rodou local: o CI é o gate.

## O que fica para o maestro

- `Q_CREATE_VERTICAL_E_O_MOTOR_DO_MARKETPLACE_NO_PLUGIN`: abrir o motor do marketplace aos plugins.
- A 1ª publicação do `onion-plugins` depois deste merge (o `onion-meta` passa a existir no público).

## Mudança depois da revisão (re-revisada)

O CI do #1009 reprovou a família `shell_pipefail_robustness` em dois sítios novos da bancada desta F4:
`sort | head -1` nos plantios do caso `plugin-bundle (b)` (fechador precoce sob pipefail) e dois
vereditos `produtor | grep -q` (casos `plugin-bundle (d2)` e `only-gate (ii)`). A cura é a forma que a
guarda pede — `sed -n '1p'` drena a lista, e o veredito lê a variável por here-string — e não muda o
que os casos julgam. Re-revisado no diff: só higiene de pipe, os mesmos predicados.
`shell_pipefail_robustness` 3/0 e `plugin_bundle` + `capability` 18/0, sob `LC_ALL=C`.
