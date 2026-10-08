---
title: "Revisão — /meta:cc-update forjado pelo /meta:forge (medidor, doutrina, superfície, bancada, grafo)"
date: 2026-10-08
branch: feat/meta-cc-update
reviewer: "passada adversarial do próprio fork de execução (a ordem proibia subagente); mandato: achar onde o artefato AFIRMA mais do que mede. Evidência por execução: dogfood de carga headless nos dois modos, diff -r contra o data/ da r8, 9 mutantes, radar e contrato v3"
reviewed_diff_sha256: 85e9e9469d4c100a7c3d56252db5975cd6aad407d30c2c11c98e9f1b1662d384
reviewed_code_sha256: c060f0e3d21be1d3225776169c28c5af2fe92b10f0ff36133a4e9d0076c82330
findings_total: 7
findings_real: 7
verdict: APROVADO
tokens: 0
duration_min: 90
---

# Resíduo — REGRA 56

Forja do `/meta:cc-update` (decisão do maestro de 2026-10-08): o medidor
`.claude/validation/cc-delta-census.sh`, a doutrina `common/prompts/cc-update-doctrine.md`, a superfície
`.claude/commands/meta/cc-update.md`, a família `run_cc_delta_census_selftests` e o grafo de destino
`docs/evolution/research/forge-cc-update-2026-10/`. Censo da forja: o comando entrou com **6 de 7**
peças (a peça 4 está ausente por desenho, declarada).

## Achados da passada (7, todos reais, todos curados neste PR)

1. **O erro culpava a fonte quando a causa era um override.** Achado no dogfood de CARGA: com um
   `CC_DELTA_URL` de teste herdado, a sessão leu "CHANGELOG inalcançável". Cura: todo `CC_DELTA_*` ativo
   é declarado antes do veredito; caso (g) e mutante. O re-dogfood de carga confirmou que a sessão
   passou a nomear a variável.
2. **A extração não era byte a byte igual à r8.** Faltava a linha em branco final de cada seção. Cura:
   a seção passa a ser copiada crua; `diff -r` contra o `data/` da r8 ficou vazio.
3. **O inventário dizia "invocações de Workflow".** Na verdade contava arquivos que citam `scriptPath`.
   O rótulo foi corrigido para "citação, não execução", e o teto do inventário foi declarado no cabeçalho.
4. **Nome de adotante na superfície.** O passo 8 citava o time do Linear pelo nome. Cura: o time
   passa a ser lido de `LINEAR_TEAM_ID` pelo `env-check.sh --get`, chave que está na lista fechada de
   não-segredos.
5. **`node_type: constraint` no grafo da forja.** Não pertence ao enum da camada audit. Cura: `claim`, ligado por
   `CONSTRAINS`.
6. **Nó aberto do esqueleto sem `verified_at`.** O radar avisaria STALE-MISSING em toda rodada nova.
   Cura: o esqueleto carimba a data.
7. **O caso (k) do role-cut reprovou no CI.** O docstring do medidor cita `/meta:cc-update`, e o caso
   cobra que todo comando citado por guarda viaje para o papel standalone. O comando é core-only:
   re-mede a estratégia do core e sela a baseline do core. Cura: entra na lista de exceções da fábrica,
   pelo mesmo critério de `forge`, `dissect` e `forge-guard`, com a razão escrita junto. A cura
   apareceu na worktree escrita por outra sessão. Eu a revisei, rodei `role_cut` com 17/17 e a adotei.
   O registro fica aqui porque a I3 (um escritor por repo) foi tocada.

## Tetos declarados (não são achados, são fronteira)

- O medidor **não** liga item do CHANGELOG a superfície do Onion (as 3 reprovações da r8).
- A criação da issue segue o adapter doc em prosa (SAC-65); nó `Q_ISSUE_PELO_ADAPTER_EXECUTAVEL`.
- A passada foi do próprio autor, sem refutador isolado: o juiz independente é parte do FLUXO do
  comando, exercido na 1ª rodada de verdade, não nesta forja.

Ids (para a guarda): E_R8_FOI_FEITA_A_MAO D_COMANDO_PROPRIO_SCRIPT_MEDE_JUIZ_JULGA
E_CENSO_DA_FORJA_0_PARA_6 E_DELTA_DO_SANDBOX_IGUAL_A_R8 E_DOGFOOD_DE_CARGA_ACHOU_O_OVERRIDE_MUDO
E_BANCADA_9_CASOS_9_MUTANTES C_MEDIDOR_NAO_LIGA_ITEM_A_SUPERFICIE Q_ISSUE_PELO_ADAPTER_EXECUTAVEL
