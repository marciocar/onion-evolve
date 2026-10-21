---
branch: feat/audit-evidence-expiry
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 4c159741e6606d3ad9fa806f25f6a95bb5d85164da8c41cbc211f6491ef0488d
reviewed_code_sha256: 69a1ae9367c55633b0d8d5fe85353e2322787baaf8e2cae2e7784fc4c5bb0aab
findings_total: 8
findings_real: 8
tokens: 93878
duration_min: 7
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: subagente refutador (code-reviewer) sobre o diff, curado pela sessão de execução
nota: "tokens e duração são do refutador; o achado 8 (reprodutibilidade) foi curado por declaração, não por override de data"
---

# Passada adversarial: `feat/audit-evidence-expiry`

## O que muda

- **`kg-radar.sh` ganha o STALE-EXPIRED** no FRESCOR. Grafo que cita `reverify_every:`/`reverify_on:`
  chama o `kg_validate.py --due <hoje> --format json` (kg-ssot.due/1) e o veredito SHOULD do mesmo
  leitor. O radar só traduz os dois JSON e imprime. Saem STALE-EXPIRED (vencido), CADENCE-UNSTAMPED
  (cadência sem carimbo), CADENCE-MALFORMED (forma recusada pelo contrato) e uma linha ℹ de contagem.
  Fica fora do veredito: nada toca `problems`. Quando não dá para medir, o fail-closed declara
  `STALE-EXPIRED NÃO MEDIDO` e diz o porquê. O `--freshness-tsv` não foi tocado.
- **Bancada (`run_kg_freshness_selftests`):** 9 casos novos e 2 mutantes, 40/40 com o vendor 4.15.0.
- **Gramática e KB:** `reverify_every`/`reverify_on`/`retain_for`/`owner` como campos DO CONTRATO e o
  vocabulário `x_` de auditoria do core (`x_evidence_type`, `x_oscal_method`, `x_source_norm`,
  `x_claim_class`), com as declarações seladas.
- **Dogfood:** `reverify_every: "P30D"` em `E_FEDRAMP_FRC_APP_FCP_7_DAYS_INITIAL_PACKAGE` e
  `E_OSCAL_CLI_V3_2_0_BINDINGS_1_2_1`, e o vocabulário `x_` completo no primeiro.

## Achados

O refutador rodou como subagente sobre o diff, com a 4.15.0 por `ONION_KG_DUE_VALIDATOR`. Os 8 achados
eram reais e foram todos curados, cada um com caso ou com medição:

1. **ALTA, quebrava o exit.** Um leitor que sai com rc≠0 e stderr vazio (SIGKILL, OOM) fazia o `grep -v`
   sair 1 sob `set -euo pipefail`, e o radar morria com rc 1 e saída zero. No `--all` sumiam também
   INTEGRIDADE e SCHEMA. **Cura:** `{ grep -v … || true; }`. **Caso:** `(d2-due)`. **Mutante medido**
   (tirar o `|| true`): rc 1 e 0 linhas.
2. **MÉDIA, quebrava o exit.** O relatório ia por ENVIRON, e o teto de 128 KiB por string derrubava o
   awk com rc 126 a partir de ~2.100 nós vencidos. **Cura:** o relatório vai por arquivo e o awk lê por
   `getline`. **Medido:** 5.000 vencidos, rc 0.
3. **MÉDIA, falha calada.** O `--due` descarta calado a cadência fora da forma (`"30 dias"`, `30`), e a
   contagem parecia completa. **Cura:** o radar lê `form.*.node.reverify_every` do veredito SHOULD do
   próprio kg-ssot (consome, não reimplementa) e avisa CADENCE-MALFORMED, um por nó. **Caso:**
   `(g-due)`. **Mutante medido** (sem a leitura): 0 avisos contra 2. Conferido nas 13 fixtures de
   conformidade de cadência do vendor: o radar concorda 1:1 com os avisos do contrato.
4. **MÉDIA, falha calada.** Um due/1 sem as listas saía ✅. **Cura:** faltar lista do schema ou o
   `as_of` divergir de hoje dá NÃO MEDIDO. **Caso:** `(e-due)`.
5. **BAIXA.** O pré-filtro é texto, e a linha do NÃO MEDIDO afirmava que "o grafo declara" cadência.
   **Cura:** a linha diz agora "o arquivo cita", e o comentário e a KB declaram o teto.
6. **BAIXA.** Os mutantes não distinguiam defeito de queda. **Cura:** o MUT-due-1 exige rc 0 e o
   FRESCOR impresso; o MUT-due-2 exige rc 1 exato.
7. **BAIXA.** O lado awk só tinha cobertura com o vendor novo. **Cura:** o `(g-due)` usa um stub due/1
   fixo e roda sempre.
8. **Doc.** A KB dizia "reproduzível com a data fixada", mas não há como fixá-la. **Cura:** declarado
   na KB que o veredito usa `date -u` e só se reproduz no mesmo dia.

O refutador também tentou e NÃO quebrou: aspas simples no awk, o modo composto, ids e status entre
aspas, arquivo com `-` no nome, TAB no label, multi-documento (NÃO MEDIDO correto) e o grafo sem
cadência.

## Mutantes

- **MUT-due-1 (desliga a leitura, `case "$MODE" in --nunca)`):** o mutante roda com rc 0 e o
  STALE-EXPIRED some. O `(a-due)` reprova.
- **MUT-due-2 (vencimento vira veredito, `problems++`):** rc 1. O `(a-due)` reprova pelo exit.
- **Medidos à mão:** sem `|| true` (rc 1, saída vazia, pego pelo `(d2-due)`) e sem a leitura de
  MALFORMED (0 contra 2, pego pelo `(g-due)`).

## Limites declarados

- **O `--freshness-tsv` não carrega o vencimento.** A bancada fixa 11 colunas exatas (caso (l)), e
  o `kg-realign-project.sh`, o `kg-console.sh` e o `mcp-onion-kg` leem por coluna fixa.
- **O veredito usa a data de hoje.** No dogfood, o dia do vencimento foi simulado por um `date` no
  PATH, porque não há override por ambiente.
- **O pré-filtro é texto.** Um grafo que só cite a chave numa narrativa paga a chamada; com vendor sem
  `--due`, ele imprime NÃO MEDIDO.
- **Nenhuma guarda de forma para os `x_`.** O contrato aceita `x_` livre. Se alguma for necessária,
  fica como proposta.
- **A leitura de `methods`** (1..N, `allow-other`) vem do metaschema OSCAL v1.2.3, sem âncora
  independente. `acceptance` não existe no OSCAL. Exportação e validador seguem adiados.
- **O `D_AUDIT_STORAGE_SEAL_AFTER_VENDOR_SWEEP_1021` foi citado da branch do PR #1254**, ainda aberto
  no momento deste resíduo.
