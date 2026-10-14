---
title: 'Resíduo — o degrau AUTOMATE do /meta:drive nasce com as objeções e o merge desligado'
date: 2026-10-14
branch: feat/drive-automate-rung
reviewed_diff_sha256: d4ca9b949b7702cb078fbb09f3a63f8f59900c779fdebc2a0e7ff9da637b6c0a
reviewed_code_sha256: 38f3b7e6434da1f453ecad5a2b5b51150ed8704a307925767f546c8e85b8c821
findings_total: 15
findings_real: 14
findings_fixed: 11
tokens: 420000
duration_min: 150
verdict: REPROVADO_E_CURADO
elenxo: sim
elenxo_isolado: sim
nota: >-
  Execução da decisão D_AUTO_DRIVE_DEGRAU_AUTOMATE (selo do maestro de 2026-10-12, «Forjar com as
  objeções», merge desligado por padrão). Forjado pelo /meta:forge (peças 2, 3 e 7): o executor
  drive-automate.sh, o fragmento common:prompts:drive-doctrine e a família run_drive_automate_selftests.
  Census da forja: drive 2/7 antes, 5/7 depois. O Elenxo, por agente separado com mandato de refutar,
  reprovou a 1ª versão com 15 achados, 2 bloqueadores; 11 curados no mesmo PR com caso e mutante, 3
  declarados no teto e 1 hipótese não reproduzida. Bancada 79/79; 71 mutantes, 70 mortos. Tokens e
  duração são estimados (o Elenxo sozinho mediu 200 mil tokens). REGRA 87
  (PR que EDITA um .kg.yaml enxergou os confirmed dele): confirmed vistos em auto-drive-2026-10:
  E_LEVA_CONDUZIDA_ATE_O_MERGE_POR_ORDEM, E_OPINIAO_EXPANSAO_AINDA_NAO_CONFIAVEL,
  E_OPINIAO_CARIMBO_PELO_QUE_FOI_LIDO, E_OPINIAO_RISCOS_QUE_FALTAVAM, E_DOGFOOD_POR_COMANDO_REAL;
  nenhum contradiz a evidência nova, que os cita por TRACES_TO.
---

# Resíduo — `feat/drive-automate-rung`

## O que foi medido antes de escrever

- **Census da forja** (`FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown`):
  `drive` saía **2/7** (só a superfície e o destino). Depois: **5/7** (doutrina, contexto injetado e
  bancada). As peças 4 (workflow) e 6 (lente) ficam fora desta versão da forja, como ela declara.
- **O grafo** `auto-drive-2026-10` lido inteiro. As quatro arestas `CONSTRAINS` sobre o D são o requisito.
  A doutrina do drive (§0) dizia "no AUTOMATE o merge é POR PADRÃO", e isso contradizia a pergunta selada
  ("--merge desligado por padrão"). A KB e o comando foram corrigidos para o selo.
- **O contrato do KG-SSOT** que a objeção 1 pedia já está vendorizado (v4.7.3, acima do v3.0.0 pedido).
  Ciclo em `DEPENDS_ON` e pai/filho ele ainda não define, e o executor passa a definir (`x_drive_parent`).

## Passada adversarial (Elenxo, agente separado)

As quatro perguntas obrigatórias, respondidas com reprodução em sandbox próprio:

| pergunta | resposta na 1ª versão | depois da cura |
|---|---|---|
| Dá para ligar o merge sem a flag? | **SIM**: trocar `merge: "desligado"` por `"ligado"` no YAML, ou escrever a passada à mão sem `begin` | selo da passada (segredo fora da árvore versionada; toda escrita re-sela): `PASSADA-ADULTERADA` (e1, e1', e1'') |
| Um nó MOAT escapa? | **SIM**: decision fechada por PR na allowlist, `members.yaml`, grafo fora do ROOT, head trocado durante a espera do CI, 12 de 15 frases de deploy | `PR-MEXE-EM-DECISAO`, federação fora da allowlist, grafo fora do projeto recusado, política relida pós-merge (`POS-MERGE-FORA-DA-POLITICA`), vocabulário ampliado como rede secundária |
| Budget estourado para? | para; o **teto de nós** furava por `x_drive_pr` à mão ou herdado | `ITEM-FORA-DA-PASSADA`; o teto conta o que a passada vincula |
| Retomada depois de uma queda? | a passada retomava, mas o merge sem CI após rebase deixava o nó aberto e o lote dizia "nenhum mergeado" | merge registrado antes do carimbo; carimbo com os runs do head julgado; `end` relê o forge |

| # | achado | classe | destino |
|---|---|---|---|
| 1 | merge liga editando o grafo; passada escrita à mão aceita | escape, bloqueador | **curado**: selo da passada (e1) |
| 2 | head julgado ≠ head mergeado | escape, bloqueador | **curado em parte**: política relida no estado final, sem carimbo (e2); o `--match-head-commit` dentro do caminho verificado fica no teto |
| 3 | ordem topológica só no `next` | escape | **curado**: `PREDECESSOR-ABERTO`/`PAI-COM-FILHO-ABERTO` em todo passo (e3) |
| 4 | teto de nós furado por `x_drive_pr` à mão ou herdado | escape | **curado**: `ITEM-FORA-DA-PASSADA` (e4) |
| 5 | superfícies sensíveis dentro da allowlist | escape | **curado**: `PR-MEXE-EM-DECISAO` e federação fora (e5) |
| 6 | grafo fora do ROOT desarma o PR-DO-CONTROLE | escape | **curado** (e6) |
| 7 | o carimbo não reaplicava a política | escape | **curado** (e7) |
| 8 | carimbo impossível no merge sem CI após rebase; o lote mentia | robustez | **curado** (e8) |
| 9 | estouro matava só o filho; o rc mentia | robustez | **curado**: grupo de processos, teto de 10 h e o forge decide (e9) |
| 10 | vocabulário MOAT pegava 3 de 15 | escape | **ampliado e declarado** como rede secundária; a defesa do merge é a allowlist |
| 11 | escrita sem trava e não atômica | robustez | **curado**: `flock` e `os.replace` (e11) |
| 12 | StatusContext legado pendente passava | escape | **curado** (e12) |
| 13 | 12 de 15 mutantes sobreviviam; casos decorativos | decorativo | **curado**: um caso por parada nomeada (e13a–h), `mergedAt` ≠ hoje, rótulos honestos em i-merge3 e i-moat5 |
| 14 | pré-condição 1 do ADR e `/engineer:*` por item só em prosa | prosa | **declarado** no fragmento §4 |
| 15 | `begin` numa retomada ignorava `--root` calado | menor | **curado**: aviso nomeado |

Hipótese não reproduzida: num rename do grafo de controle, `files` do forge só listaria o caminho novo.
O controle não depende disso (o `PR-DO-CONTROLE` compara o caminho atual do grafo).

## Bancada e mutantes

`LC_ALL=C bash .claude/validation/lint-selftest.sh --families drive_automate`: **79/79**.

Mutantes: **71**, um por parada nomeada. Cada um rodou a família inteira numa cópia descartável da
árvore, nunca na árvore viva. **70 mortos.** O vivo é `N02` (aceitar gasto negativo): a checagem existe,
mas o selo da passada pega a mesma edição antes dela. É uma camada redundante, e fica declarada assim.

| mutante | o que ele desliga | caso que tem de reprovar | resultado |
|---|---|---|---|
| M01 | ciclo calado | `(o1b)` | MORTO |
| M02 | item sem no calado | `(o1c)` | MORTO |
| M03 | subtarefa sem no calada | `(o1d)` | MORTO |
| M04 | no sem item calado | `(o1e)` | MORTO |
| M05 | pai divergente calado | `(o1f)` | MORTO |
| M06 | tm ilegivel vira vazio | `(o1g)` | MORTO |
| M07 | carimbo sem exigir MERGED | `(o2b'')` | MORTO |
| M08 | carimbo fecha decision | `(o2c)` | MORTO |
| M09 | epico com filho aberto fecha | `(o2d)` | MORTO |
| M10 | carimbo sem run de CI | `(o2e)` | MORTO |
| M11 | locator do que foi feito | `(o2a)` | MORTO |
| M12 | CI vazio aceito | `(o3a)` | MORTO |
| M13 | check exigido ausente aceito | `(o3a')` | MORTO |
| M14 | vermelho aceito | `(o3j)` | MORTO |
| M15 | pendente aceito | `(o3j')` | MORTO |
| M16 | elenxo uma voz aceito | `(o3c)` | MORTO |
| M17 | elenxo reprovado aceito | `(o3d)` | MORTO |
| M18 | insumo vencido aceito | `(o3e)` | MORTO |
| M19 | merge ligado por padrao na passada | `(i-merge1)` | MORTO |
| M20 | merge sem --merge na chamada | `(i-merge3)` | MORTO |
| M21 | gate sem --merge vira MERGE-OK | `(o3f)` | MORTO |
| M22 | retomada zera a passada | `(o3h)` | MORTO |
| M23 | retomada liga merge | `(i-merge2)` | MORTO |
| M24 | next ignora o item em voo | `(o3h')` | MORTO |
| M25 | gate mergeia decision | `(o3g)` | MORTO |
| M26 | decision aberta na cadeia segue | `(o2c')` | MORTO |
| M27 | merge por gh pr merge | `(o4b` | MORTO |
| M28 | task manager por API direta | `(o4a)` | MORTO |
| M29 | checkpoint escrito a mao (sem close-lot) | `(o4c)` | MORTO |
| M30 | allowlist desligada | `(i-moat1)` | MORTO |
| M31 | allowlist vira denylist | `(i-moat1')` | MORTO |
| M32 | PR do controle aceito | `(i-moat2)` | MORTO |
| M33 | repo alheio aceito | `(i-moat3)` | MORTO |
| M34 | cap de diff desligado | `(i-cap)` | MORTO |
| M35 | merge sem caminho verificado | `(i-path)` | MORTO |
| M36 | vocabulario MOAT calado | `(i-moat4)` | MORTO |
| M37 | marca x_drive_moat ignorada | `(i-moat4')` | MORTO |
| M38 | sem passada inventa passada | `(i-pass)` | MORTO |
| M39 | teto zero aceito | `(i-teto0)` | MORTO |
| M40 | teto de nos no track desligado | `(i-nos)` | MORTO |
| M41 | budget desligado | `(i-budget2)` | MORTO |
| M42 | charge nao para no estouro | `(i-budget1)` | MORTO |
| M43 | checkpoint pendente ignorado | `(i-ckpt)` | MORTO |
| M44 | relogio no script | `(i-relogio)` | MORTO |
| M45 | status do provedor fecha o no | `(o3i)` | MORTO |
| N01 | selo da passada ignorado | `(e1)` | MORTO |
| N02 | gasto negativo aceito (camada atras do selo) | `(e1')` | VIVO |
| N03 | politica pos-merge desligada | `(e2)` | MORTO |
| N04 | predecessor aberto aceito | `(e3)` | MORTO |
| N05 | gate aceita pai com filho aberto | `(e3')` | MORTO |
| N06 | PR do no sem vinculo vale | `(e4)` | MORTO |
| N07 | decision mexida aceita | `(e5)` | MORTO |
| N08 | federacao volta a allowlist | `(e5')` | MORTO |
| N09 | fork aceito | `(e5'')` | MORTO |
| N10 | grafo fora do projeto aceito | `(e6)` | MORTO |
| N11 | carimbo sem a politica | `(e7)` | MORTO |
| N12 | carimbo sem passada | `(e7')` | MORTO |
| N13 | carimbo ignora o head julgado | `(e8)` | MORTO |
| N14 | rc do merge-serial vence o forge | `(e9)` | MORTO |
| N15 | sem trava | `(e11)` | MORTO |
| N16 | pendente legado aceito | `(e12)` | MORTO |
| N17 | draft aceito | `(e13a)` | MORTO |
| N18 | base nao-main aceita | `(e13b)` | MORTO |
| N19 | residuo pendente aceito | `(e13c)` | MORTO |
| N20 | sem elenxo aceito | `(e13d)` | MORTO |
| N21 | next sem frescor | `(e13e)` | MORTO |
| N22 | next sem teto | `(e13f)` | MORTO |
| N23 | track aceita decision | `(e13g)` | MORTO |
| N24 | verified_at = hoje | `(o2a)` | MORTO |
| N25 | merged nao registrado antes do carimbo | `(e2)` | MORTO |
| N26 | SHA do merge nao exigido | `(e13h)` | MORTO |

## Dogfood

- `plan --root SAC-74` contra o **Linear real**, por `tm.sh`: o grafo com só SAC-74 e SAC-114 parou
  nomeando SAC-111, SAC-112 e SAC-113 (`ITEM-SEM-NO`). Com as cinco, saiu `PRONTO` em ordem topológica.
- `begin` → `next` → `track` contra um grafo dentro do projeto; `stamp` contra o **PR #1101 real**
  (mergeado, toca `.claude/`): `PATH-VENDORIZADO`. O carimbo automático não fecha nó de PR que o
  AUTOMATE não poderia mergear.
- A passada editada à mão no grafo real: `PASSADA-ADULTERADA`.

## Limitações (teto)

- Quem digita `--merge` não é provado; o selo é forjável por quem lê o segredo e recalcula o hash.
- A janela entre o gate e o merge só fecha com o head amarrado dentro de `ops/pr-merge-verified.sh` (core-only).
- Budget em tokens é declarado pela sessão (`charge`); `elenxo_isolado: sim` é auto-atestado.
- As travas ficam como arquivos `.lock` no diretório do repositório (não versionado).
- Nenhum PR de código entra em AUTOMATE com merge: a allowlist do ADR só admite `docs/analysis`,
  `docs/evolution`, `docs/discussions`, `docs/onion` e `docs/backlog.md`. É o desenho do ADR, não um defeito.
