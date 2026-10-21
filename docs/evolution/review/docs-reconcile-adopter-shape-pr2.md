---
branch: docs/reconcile-adopter-shape-pr2
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 4
tokens: 140605
duration_min: 11
findings_fixed: 4
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose opus (juiz adversarial fixo do /meta:kg-freshness, mandato de refutar, read-only)
nota: "3 NOTAS sem defeito (5, 6 e 7); a 7 foi corrigida por precisão de citação. O MISPLANED que sobrou na D_FECHAMENTO é lexical (a palavra é o nome da família durable_commit e do script), declarado abaixo e não contornado"
---

# Passada adversarial: `docs/reconcile-adopter-shape-pr2`

## O que muda

Reconciliação, contra a `origin/main` em 02709b98, do grafo
`docs/evolution/research/adopter-shape-bench-2026-10/adopter-shape-bench-2026-10.kg.yaml`, pedida pelo maestro
no `/meta:decide` de 2026-10-21. O PR 2 da SAC-149 foi mergeado (d5315a67, 0624aa87, 5eed13fa, f77350dd) e o
grafo seguia com as decisões `open` e sem carimbo. Só o grafo e este resíduo mudam; nenhum código.

Cada nó foi medido pelo `/meta:kg-freshness`, com o comando executado:

- `LC_ALL=C bash .claude/validation/lint-selftest.sh --families adopter_shape` → `Passaram : 16 … Falharam : 0`, rc 0.
- `LC_ALL=C bash .claude/validation/lint-selftest.sh --families rules_registry,ops_citation_travel,migrate_seed_graph,env_exposure,door_role_parity,durable_commit` → `Passaram : 102 … Falharam : 0`, rc 0.
- `LC_ALL=C bash .claude/validation/ops-citation-travel-check.sh --selftest` → `selftest: 25/25 verdes`, rc 0.
- `bash .claude/utils/adopt/vendor-manifest.sh --kind adoption --role adopted|standalone` lista `vendor/kg-ssot`; `--kind door --role mini` não lista.
- Sondas de PreToolUse no `pretooluse-env-guard.sh`: o grep com padrão de nomes de hook e `test -f .env` sai rc 0; `cat .env` sai rc 2; `*.env` no scratchpad sai rc 2, com a dica da extensão.
- `stamp-adoption-graph-pin.sh <fixture> --check` com ONION_INSTALLED sem x_pin → rc 3, `pin do grafo NÃO MEDIDO`.
- Leitura por `grep -n` das linhas citadas em cada `verified_against`.

Desfecho:

- **D_SUBSTRATO_FAMILIA_COM_MATERIALIZADOR, D_FECHAMENTO_LEVA_A_RELEASE_INTEIRA, D_APLICABILIDADE_POR_PAPEL_DECLARADA,
  D_REGRA_100_NAS_MENSAGENS e D_PIN_COM_ESCRITOR_UNICO** viram `done` em `plane: PROD`, com `verified_at`,
  `verified_against`, `provenance` e o commit acrescentado ao `trace` que já existia, sem chave duplicada.
- **Q_CURAS_DO_PR2** fecha. As catracas `_AS_PENDING_UNJUDGED` e `_AS_PENDING_OPS` estão vazias. Cinco das sete
  curas estão feitas. O role do registro saiu como não-defeito: o caso g3c está verde e o cabeçalho ADOTANTE do
  `door-role-parity-check.sh` o sustenta. As duas sobras têm um Q aberto cada:
  - `Q_GITHOOK_TRES_VEZES_NAO_REPRODUZIDO`, que já existia, tem gatilho próprio e não foi fechado;
  - `Q_ENV_SCRATCHPAD_ISENCAO_SEGURA`, que é novo.
- **C_TETO_HUB_COM_REGISTRO_PROPRIO** é novo: o teto do hub, que só existia em prosa.

## Achados

O juiz rodou sobre 2471e11c, o 1º commit desta branch.

1. **MENOR: as cinco decisões `done` estavam em `plane: DEV`.** A gramática (`kg-grammar.md`) só aceita `done` em
   DEV para decisão selada pelo maestro, e o radar avisava `decision-done-em-DEV`. **Corrigido:** as cinco foram
   promovidas a PROD, cada uma com bloco `provenance` (`source` em `arquivo@02709b98`, `locator`, `method`,
   `locality: repo`). Elas foram medidas por execução: bancada, `--selftest`, manifesto e sondas.
2. **MENOR: a instrução pedia um Q_ novo para o que não estivesse feito.** A sobra do scratchpad apontava para um
   `claim` (C_TETO_SCRATCHPAD_ENV_SEGUE_VETADO), não para um Q_. **Corrigido:** nasceu `Q_ENV_SCRATCHPAD_ISENCAO_SEGURA`,
   com gatilho e as arestas `C_TETO_SCRATCHPAD… SUPPORTS Q_ENV…` e `Q_ENV… CONSTRAINS Q_CURAS_DO_PR2`. Reutilizar o
   Q_GITHOOK, que já é um Q_ aberto com gatilho, foi julgado legítimo. O role do registro é **não-defeito**, não
   "feito", e a narrativa da Q diz isso com todas as letras; cabe ao maestro ratificar.
3. **MENOR: o teto do hub com members.yaml próprio só existia em prosa** dentro de uma decisão que ia a `done`.
   **Corrigido:** virou `C_TETO_HUB_COM_REGISTRO_PROPRIO`, aberto, `CONSTRAINS` a D_APLICABILIDADE.
4. **MENOR: o "pin ilegível sai SOFT nomeado" da D_PIN não tinha medição citada.** **Corrigido por declaração:**
   reproduzi a sonda do juiz (helper `--check` numa fixture sem x_pin → rc 3). O `verified_against` agora diz que o
   mapeamento rc 3 → SOFT no case da REGRA 108 (`lint-artifacts.sh:5997`) foi **lido, e não exercido por caso de
   bancada**.
5. **NOTA:** o materializador troca o `merge-onion-hooks.sh` e omite o `emit-eol-gitattributes.sh`. O teto já está
   declarado no cabeçalho dele e em `C_TETO_PASSOS_COPIADOS_DO_ADOPT`, que segue aberto. Sem mudança.
6. **NOTA:** o label da D_FECHAMENTO fala em "316 arquivos, 1,9 MB", números da release de 2026-10-15. Hoje são 492
   arquivos rastreados e 3,2 MB (kg-ssot-v4.15.0). O `verified_against` declara a diferença. O label fica como está,
   porque registra a decisão no dia dela.
7. **NOTA:** a faixa da isenção da REGRA 100 é `:236-241`, não `:236-240`. **Corrigido.**

## Mutantes

Nenhum mutante novo: este PR não muda guarda. As famílias citadas carregam os mutantes do PR 2
(E_MUTANTES_PR2_MORDEM), e o `(i4-MUT)` da adopter_shape e os `(m)` da ops_citation_travel morderam nesta rodada.

## Limites declarados

- **MISPLANED lexical na D_FECHAMENTO.** O radar casa `commit` como palavra em `durable_commit` (o nome da família
  da bancada) e em `durable-commit.sh`. O nó cita uma família executada, não um commit lido. O aviso fica: não
  reescrevi o nome da família para calar o gate. Candidato a cura do radar: o MISPLANED não distingue nome de
  arquivo ou de família da palavra `commit`.
- A D_PIN fica `done` com uma parte lida e não exercida (achado 4), e isso está declarado no próprio nó.
