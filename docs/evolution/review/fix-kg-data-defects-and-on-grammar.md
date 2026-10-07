---
title: 'Resíduo — defeitos de dado do .kg.yaml corrigidos, o radar cobra o alfabeto do id e avisa o valid_from sem aspas, e o gatilho de TRANSITIONS passa a ser trigger: (on: vira legado)'
date: 2026-10-07
branch: fix/kg-data-defects-and-on-grammar
reviewed_diff_sha256: 07c20bbed5345f9075271f0ea0d0fd15960cebb13bb86c8ee2e6f349621c87c3
reviewed_code_sha256: 98cab8ececccc1e2b6672596aa3ef86d7eb37206de8dfcdd3d72dc4632850507
findings_total: 4
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Triagem do sinal 2026-10-07-spike-schema-defeitos-de-dado-e-gramatica (maestro: corrigir o DADO e
  documentar o gatilho; depois o maestro decidiu ADOTAR trigger:, alinhado ao contrato selado no adotante).
  Medido por leitor tipado (yaml.safe_load) nos 138 grafos: 12 ids SYNTHESIS.md_* (29 ocorrências),
  6 valid_from inteiros em 4 grafos, 6 sem schema_version, 9 sem meta.id, 7 com schema_version
  inteiro. Depois: 0 em todas. Passada adversarial feita pela própria sessão (fork sem permissão de
  subagente), declarado: elenxo nao.
---

# Resíduo — `fix/kg-data-defects-and-on-grammar`

## Ids renomeados (REGRA 63 — o que saiu do grafo, nomeado)

Em `docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml`, os 12 nós foram **renomeados**,
não apagados (mesmo conteúdo, arestas atualizadas; nenhum outro arquivo do repo citava os ids velhos):

| id antigo | id novo |
|---|---|
| SYNTHESIS.md_A2A_LIVE_HANDSHAKE_OPEN | SYNTHESIS_A2A_LIVE_HANDSHAKE_OPEN |
| SYNTHESIS.md_A2A_RESILIENCE_PAIR | SYNTHESIS_A2A_RESILIENCE_PAIR |
| SYNTHESIS.md_BACKSTAGE_COST_REJECTED | SYNTHESIS_BACKSTAGE_COST_REJECTED |
| SYNTHESIS.md_CRDT_HYPOTHESIS_UNSOURCED | SYNTHESIS_CRDT_HYPOTHESIS_UNSOURCED |
| SYNTHESIS.md_FIRST_SLICE_ORDER | SYNTHESIS_FIRST_SLICE_ORDER |
| SYNTHESIS.md_GOVERNANCE_AHEAD_OBS_BEHIND | SYNTHESIS_GOVERNANCE_AHEAD_OBS_BEHIND |
| SYNTHESIS.md_GRAPH_SH_INGESTS_MEMBERS | SYNTHESIS_GRAPH_SH_INGESTS_MEMBERS |
| SYNTHESIS.md_REUSE_NOT_INVENTION | SYNTHESIS_REUSE_NOT_INVENTION |
| SYNTHESIS.md_SINGLE_SOURCE_MESH | SYNTHESIS_SINGLE_SOURCE_MESH |
| SYNTHESIS.md_TARGETING_SCHEMA_OPEN | SYNTHESIS_TARGETING_SCHEMA_OPEN |
| SYNTHESIS.md_TOOL_POISONING_STAT_DOWNGRADED | SYNTHESIS_TOOL_POISONING_STAT_DOWNGRADED |
| SYNTHESIS.md_VPS_SUFFICES | SYNTHESIS_VPS_SUFFICES |

Conferido por ausência: `grep -rn 'SYNTHESIS\.md_'` no repo = 0.

## Achados da passada adversarial

1. **REAL, CORRIGIDO — falso positivo em 35 nós corretos.** A 1ª redação do aviso lia o `valid_from`
   já trimado, e o trim do radar tira as aspas: `valid_from: '2017'` parecia inteiro. O dogfood no
   corpus inteiro (REGRA 52) acusou 10 grafos sãos. Agora o radar guarda a forma crua; caso (h) da
   bancada e mutante que volta a ler o valor trimado reprova (h).
2. **REAL, CORRIGIDO — o radar morreu no parse (exit 2 em todo grafo).** O `gsub` com aspa simples
   quebrou o programa awk, que vive entre aspas simples do shell. Pego pela 1ª execução; comentário no
   código diz por quê.
3. **NÃO-ACHADO, declarado — HARD para valid_from inteiro.** Seria a catraca natural (core = 0), mas os
   adotantes clonados carregam 42 ocorrências em 7 grafos de 3 clones: o próximo `--update` deles
   nasceria vermelho por dado antigo. Ficou SOFT (REGRA 52 repassa `VALID-FROM-INTEIRO`).

4. **REAL, CORRIGIDO — a 1ª redação documentava `on:` na direção oposta ao contrato.** O contrato
   formal do `.kg.yaml` em curso selou perfil YAML 1.2 restrito, `on` proibido e o gatilho renomeado
   para `trigger`. O maestro decidiu adotar: `kg-radar.sh` e `kg-view.sh` leem `trigger:`; `on:` segue
   lido e acusado (`ON-LEGADO`, SOFT na REGRA 52, nomeando o arquivo); 7 arestas do corpus e 3 das
   fixtures migradas (`grep -rn '^ *on: ' --include=*.kg.yaml` = 0); gramática, `/meta:kg` e a KB
   atualizados. A saída `--triples` passou a escrever `trigger` no lugar de `on` (o único consumidor,
   `kg-drive-project.sh`, lê só os 3 primeiros campos). A chave `on` do JSON interno do `kg-view` ficou
   (não é YAML).

## Validação (ordem do maestro: pre-commit pulado)

- Commits com `--no-verify` (checkpoint, por ordem do maestro). Validação feita: família de bancada
  tocada `kg_radar_integrity` 10/10 com `LC_ALL=C`; cinco mutantes morderam — sem o parse de
  `trigger:` reprova (j) por evento órfão; sem o aviso de legado reprova (i); famílias que leem as
  fixtures migradas (`fixtures`, `kg_console`, `kg_freshness`, `kg_view`, `kg_census_parity`) 156/156; — desligar a cobrança do id
  reprova (e); ler o valid_from trimado reprova (h); tirar o repasse SOFT reprova (g). Gate final:
  `ops/pr-finalize.sh --push` (0 HARD) e CI completo verde antes do merge.
- Dogfood: REGRA 52 sobre o corpus do core = 0 achados; radar num grafo real de adotante = 15 avisos,
  rc 0 (não reprova).
- Cada grafo tocado (20): `kg-radar.sh --integrity --schema` exit 0.

- Re-revisão depois do 1º carimbo: o código que mudou foi a **regeneração dos plugins** `onion` e
  `onion-engineering` (REGRA 19) — cópias do mesmo `kg-radar.sh`/`kg-radar-integrity.sh` revisados —
  e o `trace:` do grafo da guarda, que apontava para o sinal ainda não rastreado no inbox (REGRA 55).

## Tetos

- A causa dos ids não tem gerador: nasceram de modelagem por sessão (commit `e0bf994a`). A cura de
  causa é a cobrança no radar.
- A causa do `valid_from` inteiro foi curada no **prompt** do `write(KG)` do `onion-research.js`
  (conselho ao agente), com o aviso do radar como rede. Não é veto.
- `valid_from: 2026-10-01` sem aspas (88 ocorrências) é **data** para leitor YAML 1.1: fora de escopo,
  é questão do perfil YAML do contrato.
- O helper da REGRA 52 rotula a reprova do id com a tag genérica `CONTRADICAO`; o detalhe nomeia
  `id fora do alfabeto`.
