---
title: "Revisão — onda O2 da migração de provenance (SAC-73): o trace como locator em 602 nós A2 sem verified_against"
date: 2026-10-09
branch: feat/provenance-wave-o2
reviewer: "passada adversarial com mandato de achar provenance INVENTADA ou trace que não sustenta o label: varredura mecânica dos 624 candidatos (suporte por termo, forma do trace), amostra de 20 escritos com o arquivo aberto, e bancada kg_migrate_v3 10/10 com LC_ALL=C e 8 mutantes do caso (i)"
reviewed_diff_sha256: 4f07dbee74623967be3392e1657f0118c88cbefd6aa0447b6ce36255ff19c55e
reviewed_code_sha256: d09493aadaad1dc4fe850ffd9dd015929ae3926d207e137f344b2a3a9f8e546c
findings_total: 4
findings_real: 3
verdict: REPROVADO_E_CURADO
tokens: 0
duration_min: 120
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O2 do SAC-73. Dentro do `--routing`, o `kg-migrate-v3.py` passa a escrever provenance no nó A1/A2
que tem `trace:` e não tem `verified_against`. O trace vira source e locator, com
`method: "derivado: trace do nó, sem registro de medição"`. A aplicação foi feita aos 138 grafos do corpus
do gate (os `--exclude` do CI mais `fixtures/` e `docs/materials/`).

## Achados

1. **REAL, curado: o universo pedido não era o universo medido.** Os 671 "sem fonte" A2 do
   `routing-v4.tsv` são 624 com trace e sem `verified_against`, mais 47 `run-local-va`. Esses 47 citam um
   journal `wf_*` no registro e não têm trace. A regra da O2 não se aplica a eles: ficam como "sem fonte
   recuperável" e vão para a O3, sem escrita.

2. **REAL, curado: citação textual não é locator.** Na 1ª aplicação, 14 nós ganharam como "locator" um
   trace que não aponta nada que exista, como `user memory onion-pessoal-app-state`, `síntese desta leva`,
   `arandek commits 1aa794f9 / 88d93f26` ou `git ls-tree … origin/main`. **Cura no mecanismo:** na O2, o
   trace só vira locator se tiver URL `http(s)`, caminho do host ou caminho do repo que existe a partir da
   raiz. Fora disso, sai "TRACE SEM LOCALIZADOR" e fica intocado. Mutante `sem-recusa-sem-localizador`.

3. **REAL, curado: trace que registra um comando é medição.** Com 17 nós, o trace é o próprio registro do
   que foi medido: `grep -rl allowed-tools .claude/commands/ → 98`, `ls / → sem whatsapp-sender`,
   `run 30861731536`, `PR #414` e `git log: d20918a`. Escrever "sem registro de medição" ali seria falso.
   Pela política 2, o destino é `medição: <comando>`, e isso é da O3. **Cura:** a regex `CMD_TRACE_RE`
   recusa e reporta "TRACE É REGISTRO DE COMANDO". Mutante `sem-recusa-comando`. A 1ª versão casava também
   o `→` solto, que deu 2 falsos positivos em descrição de cadeia (`empresa→time→pessoa`), e foi tirado.

4. **Não curado por mecanismo, de propósito: o trace é o artefato, e o label é uma execução sobre ele.**
   Em 6 nós escritos, o label diz o resultado de uma execução e o trace é o código executado:
   - `E_SELFTEST`: "465 passaram";
   - `E_FED_RADAR_BUILT`: "roda, exit 0";
   - `E_PERSONALITY_SYNC_BUILT`: "dogfoodado";
   - `C_STALE`: "reproduz no main";
   - `E_WIRE_IN_LIVE`: "wired em lint-artifacts";
   - `E_MECHANISM_ORPHAN`: ausência de comando `thread-*`.

   O arquivo não sustenta a afirmação. A regex que os pegaria (código no trace e termo de execução no
   label) casou 9 e errou 3 (`Q_CLICKUP_DELETE_PELO_MCP_NAO_MEDIDO`, `D_S2_ABSORBED`, `C_pausa_e_o_valor`,
   que a leitura sustenta). Apertar a regex até zerar seria regra ajustada a um caso. Ficam escritos, e o
   method não afirma que o arquivo sustenta. Vão para a O3 revisitar no `o3-universe.tsv`, com a dica
   `o2:trace-nao-sustenta`, junto com os 2 parciais da amostra.

## Amostra adversarial (20 nós escritos, semente 20261009, arquivo aberto)

Foram 16 do `federation-research-2026-06-reconciled` e 4 de outros três grafos. A conferência foi por
grep do termo do label e leitura da linha.

- **18 sustentam o label.** Alguns exemplos:
  - `G4-re-verify-downgraded.md` l.110 ("~2.000 servidores MCP … TODOS");
  - `onion-evolution-2026-06-15.md` l.75 (os 11 refutados com a mesma divisão D2/D3/D4);
  - `onion-a2a-federation-reconcile-2026-06.md` l.72 ("Nenhum eixo virou adoção cega");
  - `onion-parecer-whatsapp-sender-2026-07.md` l.3-5 (opção A executada via `git subtree split`);
  - `inference-mitigation.md` l.12-13 (Staab et al. 2024, 85% top-1);
  - `onion-guardrails.md` l.77 (o catálogo sem violar o ONION-R1);
  - `S2-sync-federation-models.md` l.53-55 (ApplicationSet generators).
- **2 sustentam só em parte:**
  - `C_single_artifact_ethos`: `kg-console.sh` l.11 mostra o Cytoscape vendorizado inline, mas o juízo
    comparativo "mais fiel ao ethos do que 3 libs" não está lá;
  - `SY5_strategy_trio_is_one_package`: o RFC-0002 l.5 traz o "+ 4 docs irmãos", mas a numeração Doc 2/3/4
    está nos docs, não nele.

**0 fontes inventadas:** todo arquivo existe e fala do nó. Teto: juiz único, o mesmo autor da ferramenta,
com suporte checado por termo e linha, não por releitura semântica completa. O suporte por termo é
grosseiro: label sem acento contra arquivo acentuado subconta.

## Provas mecânicas

- Escritos: 602 nós em 36 grafos, sendo 601 `derivado` e 1 `testemunho` de host
  (`/home/marcio/granaai/docs/evolution/inbox/_processed/`). Por plano: 388 DEV e 214 PROD.
- Recusas da O2, intocadas: 17 registros de comando e 5 sem localizador. Nenhum trace sumido sobrou, porque
  o routing já os tinha mandado para R. Os 6 circulares da O1 seguem recusados.
- Idempotência: `--check --routing` depois da aplicação deu rc 0.
- `kg-radar --integrity --schema` deu exit 0 nos 36 grafos tocados e no grafo do contrato (17 nós, 17
  arestas).
- `kg-contract-check`: nenhum grafo ganhou código MUST ou SHOULD que a HEAD não tinha. Deu rc 0 no que saiu
  da dívida e rc 1 nos 35 que seguem com o MUST de provenance herdado do resíduo.
- `kg_gate.py` com os `--exclude` do CI deu rc 0. O `--update` foi sem `--accept-regression`: a base foi de
  **115 para 114** grafos na dívida MUST. Saiu o `kg-console-rich-design-2026-07`, e o
  `doctrine-behavior-over-declaration-2026-07` perdeu o código de provenance. A dívida SHOULD ficou
  inalterada.
- Bancada `kg_migrate_v3`: 10/10 com `LC_ALL=C`. Oito mutantes reprovam o (i): `sem-onda-o2`,
  `sem-recusa-sumido`, `sem-recusa-comando`, `sem-recusa-sem-localizador`, `locator-inventado`,
  `method-sem-a-ressalva`, `escreve-no-R` (que reprova também o (h)) e `sem-politica-host-o2`.

## O que a O3 recebe

O `docs/evolution/research/contrato-kg-absorcao-2026-10/data/provenance-triage/o3-universe.tsv` traz 820
nós sem provenance (477 PROD, 343 DEV) e 8 escritos para revisitar. A coluna `bucket` é heurística minha
sobre as políticas seladas, não decisão:

- **rebaixar:** PROD sem fonte;
- **testemunho:** classe T, selo ou sinal no registro, host, medição de sessão sem comando, run `wf_*`;
- **óbvio:** correção mecânica, como PR/commit, run, URL no label, arquivo sem prefixo, caminho relativo ou
  registro de comando;
- **dúvida:** o resto, como suporte fraco, aponta-nó, grafo próprio, caminho sumido ou DEV sem fonte.

## Fora do escopo, de propósito

Ficam para depois:

- os 820 da O3 e os 8 para revisitar;
- 3.460 datas sem aspas;
- flips de status, que são selo do maestro.
