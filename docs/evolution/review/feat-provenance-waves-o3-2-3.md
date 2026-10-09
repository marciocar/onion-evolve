---
title: "Revisão — ondas 2 e 3 da O3 da migração de provenance (SAC-73): 615 linhas julgadas aplicadas em 91 grafos"
date: 2026-10-09
branch: feat/provenance-waves-o3-2-3
reviewer: "passada adversarial com o mandato de achar linha REPROVADA aplicada, label acima de 280, label antigo apagado, refutado contraditório, nó fora da planilha alterado ou flip fora do selo. Fiz a conferência mecânica das 618 linhas contra os 91 arquivos finais, uma amostra de 15 aplicados (semente 20261009) com o nó aberto, a idempotência e a bancada kg_migrate_v3 12/12 com LC_ALL=C, com 6 mutantes no caso (k)"
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 2
verdict: CORRIGIDO
tokens: 0
duration_min: 120
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

As ondas 2 e 3 da O3 do SAC-73. O `kg-migrate-v3.py --apply-judged` passou a aplicar `corrigir-label`,
`refutar` e `dev-dúvida` com fonte, e ganhou `--promote-unverifiable`. Rodei a ferramenta sobre
`o3-wave2-juiz.csv` (306 linhas, 38 grafos) e `o3-wave3-juiz.csv` (312 linhas, 53 grafos). Os dois
conjuntos de grafos não se sobrepõem. A aplicação segue os selos do maestro de 2026-10-09.

## Achados

1. **REAL, curado no mecanismo antes da aplicação: a recusa não era atômica.** No `--apply-judged` da
   onda 1, uma linha recusada podia deixar no nó parte do que já tinha sido aplicado. Com o
   `corrigir-label`, isso significaria escrever a provenance e deixar no nó um label que o juiz desmente.
   **Cura:** a recusa agora devolve o bloco original. O caso (k) prova isso com `E_K_LONG`: o
   `label_final` tem 281 caracteres, e o nó fica sem provenance, sem narrative e com o label intacto. O
   mutante `label-longo-aceito` reprova o caso.
2. **REAL, curado no fixture da bancada: o caso (k) nasceu verde-vazio no radar.** Na 1ª versão, o caso
   exigia radar ≠ 0 antes e 0 depois. O radar dava 1 nas duas medições, por nós órfãos do fixture, e não
   pela contradição. Assim a reconciliação não ficava provada. **Cura:** os nós do fixture foram ligados.
   O único defeito que sobra antes da aplicação é o REFUTES entrando em nó confirmed. O mutante
   `refutar-sem-flip` reprova o caso.
3. **Declarado, não é defeito: `E_MARKET_SCAN` foi aplicado à mão.** O juiz trocou a proposta para
   `testemunho` com o `source_final` vazio, e a ferramenta recusou a linha (source vazio), como deve.
   Usei como source a origem que o próprio `locator_final` do juiz nomeia, "sessão de 2026-07-11 (commit
   82c85e3f)". O locator e o method são os da planilha.
4. **Declarado, decisão do maestro: o `testimony-in-prod` subiu de 34 para 36 GRAFOS.** É efeito da
   contagem por grafo. Os NÓS PROD com `method` testemunho caíram de **107 para 103** nos 91 grafos
   tocados. Os 11 grafos que passaram a contar vêm de testemunho em PROD selado pelo maestro em
   2026-10-09: o dev-dúvida mantido em PROD com fonte e o testemunho com origem explícita no lugar de DEV.
   A queima segue o insumo `testimony-in-prod` do v4.1. Os 7 grafos que saíram da conta são aqueles em
   que o dev-óbvio levou o testemunho para DEV. A base foi travada com `--accept-regression`, e esse
   motivo ficou gravado nela.

## Amostra (15 aplicados, semente 20261009, conferidos no arquivo final)

Três linhas entraram por estrato: o único `refutar`, um flip `unverifiable→confirmed` e um `dev-dúvida`.
As outras 12 são sorteadas.

| nó | grafo | tipo | conferido |
|---|---|---|---|
| `E_EXPERIMENT` | session-2026-07-18-evolve-review-triage | w2 refutar | `refuted`, provenance = CSV (medição dos runs), motivo na narrative |
| `E_MD_PICO_APRESENTADO_COMO_REGUA` | onion-market-kg-2026-08 | w3 corrigir-label | `unverifiable→confirmed`, label = CSV (271), "label anterior" na narrative |
| `E_FABLE_REVIEW` | perception-instruments-2026-07 | w3 dev-dúvida | segue PROD e confirmed, provenance = CSV, o caminho da fonte existe |
| `E_FABLE_REVIEW` | autonomous-thread-runtime | w2 corrigir | provenance = CSV, o caminho da fonte existe |
| `E_SKILLSYNC_DORMANT_V087` | librechat-2026-08 | w2 corrigir | provenance = CSV; o label (652) é dívida herdada, fora do corrigir |
| `C2_AUTOMATE_READY` | graduated-automation-elenxo-2026-07 | w3 dev-óbvio | `plane: DEV`, `refuted` intacto, sem provenance |
| `Q_F3_DECISOES_DE_ACABAMENTO` | bridge-produto-2026-08 | w2 dev-óbvio | `plane: DEV`, `open` intacto |
| `REC2_HUB_VS_PEER_REFERENTS` | federation-research-2026-06-reconciled | w3 corrigir | provenance = CSV, o caminho da fonte existe |
| `C_W6_PERITEM` | autonomous-thread-runtime | w2 corrigir | provenance = CSV, `superseded` intacto |
| `E_INTERFACE_FOLD` | constellation-dialogic-layer-2026-07 | w2 corrigir | provenance = CSV, o caminho da fonte existe |
| `C_DRIFT_44_PCT_NA_VPS` | m8-serial-2026-08 | w3 corrigir-label | label = CSV (263), "label anterior" na narrative |
| `E_KEY_SWAP_CURED` | session-2026-07-18-evolve-review-triage | w2 corrigir | provenance = CSV, o caminho da fonte existe |
| `C_NO_COMPOSTO_RECEBE_VEREDITO_ATOMICO` | identidade-onion-vps-2026-08 | w2 corrigir | provenance = CSV; o label (1292) é dívida herdada |
| `Q_R19_AUTOFIX_COM_RASTRO_CANDIDATO` | elenxo-mecanismos-lint-2026-08-13 | w2 corrigir-label | label = CSV (exatamente 280), "label anterior" na narrative |
| `X_REF_NANOCHAT_OBJ_CORRELATED_ERROR` | onion-slm-2026-10 | w2 corrigir | provenance = CSV, o caminho da fonte existe |

Resultado: os 15 batem com a planilha. "O caminho da fonte existe" quer dizer que o caminho do repo
abre. Não reli o conteúdo da fonte: quem a abriu foi o juiz.

## Provas mecânicas

**Aplicados por tipo (615 linhas):**
- **Onda 2 (306 de 306):** corrigir 174, corrigir-label 73, testemunho 40 (um deles à mão), dev-óbvio
  16, rebaixar 2, refutar 1.
- **Onda 3 (309 de 312):** corrigir 177, corrigir-label 50, testemunho 39, dev-óbvio 37, dev-dúvida 6.

**Totais:** 582 provenances e 123 labels corrigidos, com o anterior na narrative. Houve 53 mudanças de
PROD para DEV, 12 delas em nós `done`:
- da onda 2: `F0_ALICERCE_FIACAO`, `F2_ESPINHA_THREADS`, `F3_ROSTO_REDESIGN`, `F4_GOVERNO_ADMIN`,
  `F5_PRACA_DIVULGACAO`, `F_ID_1_ADOCAO_LIMPA`, `F_ID_2_CONTEXTOS_ORG`,
  `D_ESTUDAR_FAMILIA_ANTES_DE_CORRIGIR_0804` e `I_A1_A_MEDICAO_CAIU_A_CONCLUSAO_SOBREVIVEU`;
- da onda 3: `Q_MAESTRO_VIVO`, `Q_postmark_pending_approval` e `D_LIMPAR_BASELINES_NO_PROXIMO_UPDATE`.

**Flips de status (8):**
- `E_EXPERIMENT`: de confirmed para refuted;
- `E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO` e `E_ITEM6_VERIFY`: de confirmed para unverifiable;
- `E_LACUNAS_DECK_PATTERNS_0924`, `E_LACUNAS_INFRA_VPS_1005`, `E_LACUNAS_DECLARADAS_OCR_0908`,
  `E_MERCADO_OCR_LOCAL_0908` e `E_MD_PICO_APRESENTADO_COMO_REGUA`: de unverifiable para confirmed, com
  o label corrigido.

**Reconciliação do refutado.** O relatório da ferramenta lista três arestas:
- `E_EXPERIMENT REFUTES C_MODEL_CAUSE`. O alvo segue `refuted`, e a causa real foi a chave 401;
- `E_EXPERIMENT SUPPORTS C_ACTION_CAUSE`. O alvo está `superseded`;
- `D_PIN` (`done`) `DEPENDS_ON E_EXPERIMENT`.

Nenhum nó `confirmed` se apoia nele. O radar não acusa contradição, e as arestas ficaram como
história.

**Conferência e idempotência:**
- A conferência mecânica da planilha contra os arquivos finais deu **0 divergências** e **0 nós fora da
  planilha alterados**. O meta e as arestas dos 91 grafos ficaram intactos.
- A 2ª aplicação com `--check` deu rc 0 nas duas planilhas.

**Radar, contrato e gate:**
- `kg-radar <g> --integrity --schema` deu exit 0 nos 91 grafos e no grafo do contrato.
- O `kg-contract-check` só acusou código novo `integrity.testimony-in-prod`, que é o achado 4. O grafo
  do contrato está conforme.
- Nós `confirmed` ou PROD sem provenance no corpus do gate: **564 → 6**. Os 6 são os 3 REPROVADOS e 3
  do demo cold-adopter.
- Rodei o `kg_gate.py` com os `--exclude` do CI:
  - MUST: **91 → 19** grafos;
  - SHOULD: label 112 → 111, verified_at 7 → 6, untraced-decision 19 → 14 e testimony-in-prod 34 → 36
    (achado 4).

  Nenhum SHOULD subiu por label novo. Todo `label_final` tem até 280 caracteres, conferido no arquivo.

**Bancada `kg_migrate_v3`:** 12/12 com `LC_ALL=C`. Seis mutantes reprovam o caso (k):
`label-sem-narrative`, `label-longo-aceito`, `refutar-sem-flip`, `relabel-nao-idempotente`,
`promote-ignorado` e `dependentes-calados`. Os casos (a) a (j) seguem verdes.

## Fora do escopo, de propósito

- **Os 3 REPROVADOS da onda 3 ficaram intocados, para revisão futura:** `E_LACUNAS_ONDA_DERIVADA_1001`,
  `E_VERIFY_APPROVED` e `E_VERIFY_RECIPIENT`.
- **Achados laterais dos juízes, que não toquei:**
  - o segredo restic em `chore-seal-queue-maestro.md` l.48, com a rotação parada por ordem;
  - o abort inerte do `mapfile` no `/meta:adopt`, reportado pela 3ª onda seguida;
  - o filtro antigo do `worklog-precompact-breadcrumb.sh`;
  - o trust-log do a2a fora do git;
  - os labels truncados no próprio grafo.
- **Labels longos herdados** em nós que só receberam provenance (ex.: 652 e 1292 caracteres) seguem como
  dívida SHOULD.

## Teto

A fonte de cada linha vem dos juízes, que são workers e um juiz-mestre da mesma família de modelo. A
aplicação confere a forma do `method`, o tamanho do label e a igualdade com a planilha. A verdade da
fonte ela não confere. O revisor desta passada é o mesmo autor da extensão da ferramenta. O merge
espera a amostra do onion-kg-ssot.
