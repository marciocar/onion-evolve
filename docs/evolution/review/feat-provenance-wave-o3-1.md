---
title: "Revisão — onda 1 da O3 da migração de provenance (SAC-73): --apply-judged e 264 nós julgados aplicados"
date: 2026-10-09
branch: feat/provenance-wave-o3-1
reviewer: "passada adversarial com mandato de achar linha REPROVADA aplicada, provenance empilhada ou divergente da planilha, flip fora do selo: conferência mecânica das 276 linhas contra o arquivo final, amostra de 10 aplicados (semente 20261009) com o nó aberto, idempotência, e bancada kg_migrate_v3 11/11 com LC_ALL=C e 6 mutantes do caso (j)"
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
verdict: CORRIGIDO
tokens: 0
duration_min: 90
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda 1 da O3 do SAC-73. O `kg-migrate-v3.py` ganhou o modo `--apply-judged <csv>`, que aplica a
planilha julgada `o3-wave1-juiz.csv` por linha, só nas linhas com veredito APROVADO ou CORRIGIDO. A
aplicação cobriu os 37 grafos da planilha. O selo do maestro de 2026-10-09 cobriu três pontos:

- a aplicação dos quatro tipos de proposta;
- `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` indo de PROD para DEV mesmo sendo `done`;
- `Q_TENANT_WRITE_DESTINATION` indo de PROD para DEV, com o label corrigido.

## Achados

1. **REAL, curado no mecanismo antes da aplicação: provenance empilhada passaria calada.** Seis nós da
   planilha já tinham a provenance derivada da O2, e o juiz manda corrigi-la. Anexar um bloco novo
   deixaria duas chaves `provenance:` no nó. O PyYAML aceita chave duplicada sem erro, então o
   `yaml.safe_load` de conferência não pegaria. O radar é awk e leria a primeira chave, a antiga.
   **Cura:** o `_put_provenance` substitui o bloco no lugar e, se o valor já é o da planilha, não toca.
   O caso (j) conta exatamente um `provenance:` no nó substituído, e o mutante `empilha-provenance` o
   reprova. Na aplicação real, 5 foram substituídas. A sexta, `E_WIRE_IN_LIVE`, é REPROVADO e segue
   com a provenance da O2.
2. **Declarado, não é defeito: `Q_TENANT_WRITE_DESTINATION` foi aplicado à mão.** A proposta final
   dele é `dev-dúvida`, e a ferramenta não aplica `dev-dúvida`: ela a reporta como "selo do maestro".
   O caso (j) e o mutante `sela-duvida` garantem isso. Selada pelo maestro, a mudança é semântica e não
   cabe na planilha:
   - o plano foi de PROD para DEV;
   - o label deixou de afirmar estado vivo (saiu o "Hoje toda proposta cai no core");
   - entrou uma `narrative` apontando `E_KG_INBOX_ROTEIA_POR_PAPEL_0905`, o nó que o juiz cita como
     dono do estado vivo, que já tem aresta `CONSTRAINS` para este.
3. **Conferido, não é defeito: duas fontes de host com method `leitura`.** São `E_FIELD_HALLUCINATION_KG`
   e `E_POC_MCP_HAS_KG_RUNTIME`, ambas com fonte `/home/marcio/poc-venda-direta-pdi@e9fe9a4`. A política
   4 selada diz que fonte no host vira testemunho, mas que fonte com commit noutro repo vira `leitura`. A
   fonte cita o commit e9fe9a4 do repo `marciocar/poc-venda-direta-pdi`, então `leitura` está conforme.
   As outras 5 fontes de host são `testemunho`.

## Amostra (10 aplicados, semente 20261009, conferidos no arquivo final)

| nó | grafo | tipo | conferido |
|---|---|---|---|
| `E_TREINO_OK` | colaboracao-onion-2026-07 | corrigir | provenance = CSV, 1 chave, fonte existe |
| `Q_TETO_DE_CONTEXTO` | plugins-en-compliance-2026-09 | corrigir | provenance = CSV, 1 chave (`medição: claude plugin details`) |
| `E_INDEX_LIVE_LENS` | guardrails-2nd-pr-state-2026-07 | corrigir | provenance = CSV, 1 chave, fonte existe |
| `Q_HELPERS_DO_UPDATE_SEM_TRAILER_DE_ASSINATURA` | gmill-update-547-2026-10 | corrigir | provenance = CSV, 1 chave, fonte existe |
| `E_timeout_is_load_bearing` | m2-bridge-logto-2026-07 | corrigir | provenance = CSV, 1 chave, fonte existe |
| `C_H2_08` | scope-inheritance-2026 | corrigir | provenance = CSV, 1 chave, fonte existe |
| `E_PLATAFORMA_ABSORVEU_DISTRIBUICAO_E_ISOLAMENTO` | claude-code-2.1-onion-2026-08 | corrigir | provenance = CSV, 1 chave, fonte = CHANGELOG oficial (URL dentro do texto) |
| `E_LACUNAS_INFRA_VPS_1005` | infra-vps-2026-10 | rebaixar | `status: unverifiable`, sem provenance |
| `E_R3_TST_EMAIL_PESSOAL_VS_CORPORATIVO` | compartilhamento-individuo-organizacao-2026-09 | rebaixar | `status: unverifiable`, sem provenance |
| `Q_RISCO_CONCORRENTE_MAIS_RIGOROSO` | claude-code-2.1-onion-2026-08 | dev-óbvio | `plane: DEV`, `status: open` intacto |

Resultado: 10 de 10 batem com a planilha. "Fonte existe" quer dizer que o caminho do repo abre. O
conteúdo da fonte não foi relido: quem a abriu foi o juiz.

## Provas mecânicas

**Aplicados por tipo (264 nós):**
- 248 provenances, sendo 223 `corrigir` e 25 `testemunho`. As classes: leitura 132, juízes 53,
  medição 35, testemunho 25 e derivado 3.
- 11 flips `confirmed → unverifiable`:
  - 9 em DEV: os quatro `E_R3_TST_*`, `E_LACUNAS_DECK_PATTERNS_0924`, `E_MERCADO_OCR_LOCAL_0908`,
    `E_LACUNAS_DECLARADAS_PODA_0903`, `E_LACUNAS_DECLARADAS_OCR_0908` e `E_LACUNAS_INFRA_VPS_1005`;
  - 2 em PROD: `E_MD_PICO_APRESENTADO_COMO_REGUA` e `E_LAND_EXPAND`.
- 5 flips `PROD → DEV`: os três `Q_RISCO_*`, `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` e
  `Q_TENANT_WRITE_DESTINATION`.

**Conferência e idempotência:**
- Pela checagem mecânica das 276 linhas contra os 37 arquivos finais, todo aplicado bate com a planilha
  e nenhum REPROVADO mudou.
- A 2ª aplicação com `--check` deu rc 0 e "nada a aplicar" nos 37 grafos.

**Radar, contrato e gate:**
- `kg-radar --integrity --schema` deu exit 0 nos 37 grafos e no grafo do contrato.
- `kg-contract-check`: nenhum grafo ganhou código MUST ou SHOULD que a HEAD não tinha.
  - 26 grafos perderam o MUST de provenance.
  - 13 seguem com rc 1 pela dívida herdada: REPROVADOS, nós fora desta onda e chaves sem `x_`.
- `kg_gate.py` com os `--exclude` do CI deu rc 0. O `--update` foi feito sem `--accept-regression`:
  - a base caiu de **114 para 91** grafos na dívida MUST;
  - a dívida SHOULD não mudou.
- Nós `confirmed` ou PROD sem provenance no corpus do gate: **820 → 561**.

**Bancada `kg_migrate_v3`:** 11/11 com `LC_ALL=C`. Seis mutantes reprovam o caso (j):
`aplica-reprovado`, `empilha-provenance`, `sela-duvida`, `sem-checagem-de-classe`, `rebaixa-sem-aspas`
e `dev-obvio-noop`.

## Fora do escopo, de propósito

- **Os 12 REPROVADOS voltam na onda de revisão:** `E_O_MANIFESTO_QUE_FALHA_COPIAVA_TUDO`,
  `E_WIRE_IN_LIVE`, `E_RESPAWN_JA_EXISTIA_E_A_CASA_NAO_SABIA`, `E_A_GUARDA_VETOU_O_PROPRIO_MAESTRO`,
  `C_V1`, `ENT_KB_CORE`, `C_ASYNC_REPO`, `E_W8_CONSOLE_AUTOOFF_VIVO`, `E_a2a_is_not_vaporware`,
  `E_PLANO_NASCEU_DE_TRES_MEDICOES`, `E_DOR_DOMINANTE_E_CONTEXTO_E_CUSTO` e
  `C_OBJECAO_ESTADO_PODE_NAO_BASTAR_EM_TIME_MINIMO`.
- **Os achados laterais do juiz** não foram tocados: o abort inerte do `mapfile` no `/meta:adopt` e o
  Logto com registro aberto.
- **O resto do universo da O3** (561 nós) e as 3.460 datas sem aspas também ficam para depois.

## Teto

A fonte de cada linha é do juiz, com 7 workers e um juiz-mestre da mesma família de modelo. A
aplicação confere a forma do `method` e a igualdade com a planilha, não a verdade da fonte. O revisor
desta passada é o mesmo autor da ferramenta.
