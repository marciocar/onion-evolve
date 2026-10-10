---
title: 'Resíduo — F3 das portas: /meta:publish sob demanda'
date: 2026-10-10
branch: feat/doors-publish-f3
reviewed_diff_sha256: c3ee4a77661e60a229b585b32110644eb2f00b5e92225c6bbe0124007123bb26
reviewed_code_sha256: 40e5f89be8efd4335fd08dea898890b5610a163482f74e393be1de3159a33872
findings_total: 13
findings_real: 13
findings_fixed: 11
tokens: 162568
duration_min: 13
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: "passada adversarial (branch-code-reviewer, default reprovado) achou 2 bloqueadores, 4 importantes e 7 menores; 11 curados no mesmo laço com caso de bancada e mutante; 2 declarados (defasagem não é por papel; conta de outra máquina fora da derivação)"
---

# Resíduo — REGRA 56

## O que o PR faz

É a F3 do plano das portas (SAC-92), pela matriz `D_MATRIZ_DE_PORTAS_2026_10`, forjada pelo
`/meta:forge` (doutrina, medidor, lente, bancada; destino especificado na doutrina).

- **`/meta:publish <porta>|--all|--status`** e o motor **`ops/publish-door.sh`**: fonte em
  `origin/main` (conteúdo, materializadores e registro), verificação do montado, commit no clone,
  push só com `--push` e `--expect-pin`, conferência no remoto.
- **`--status`** lê o carimbo publicado de cada porta no remoto; `door-staleness-check.sh --count`.
- **REGRA 85** informativa por inteiro; workflow **`onion-door-staleness`** virou relatório.
- **Vazamento real curado** na superfície que viaja, achado pelo 1º ensaio do próprio motor: ids de
  três adotantes `onion-*` em 17 comentários, e a home de duas contas reais da máquina em KBs,
  validadores e fixtures de bancada.
- A skill `onion-publish` virou condução do comando.

## Achados da passada adversarial, e o destino de cada um

| # | Severidade | Achado | Destino |
|---|---|---|---|
| 1 | bloqueador | `--clone` empurrava commits locais não verificados (inclusive de ensaio `--from`) | CURADO: clone tem de estar em `origin/<ramo>`; `--from` recusado com `--clone`; push leva exatamente 1 commit. Casos (m), (m2) |
| 2 | bloqueador | nomes comerciais da REGRA 36 falhavam abertos conforme o CWD (`projection-safety` sem registro) | CURADO: `--members` explícito, roda do core, rc lido, e registro com marcador sem termo derivado reprova. Caso (l) |
| 3 | importante | "core intacto" contava worktrees de outras sessões; rc 1 depois do push contradizia "nada publicado" | CURADO: mede só o que é do motor (temporários dentro do próprio prefixo); pós-condição depois do push sai rc 4 |
| 4 | importante | `--clone` apagava arquivos ignorados (um `.env`) | CURADO: `status --porcelain --ignored` tem de estar vazio. Caso (m3) |
| 5 | importante | registro lido da árvore de trabalho; destino não mostrado; repo sem carimbo passava | CURADO: registro de `origin/main`; cabeçalho mostra `destino url@ramo`; pin real sem carimbo recusa; `--remote-url` removido. Caso (o) |
| 6 | importante | o pin confirmado podia não ser o publicado | CURADO: `--expect-pin`. Caso (n) |
| 7 | menor | `--status`/`--all` sem porta saíam rc 0 | CURADO: rc 3. Caso (p) |
| 8 | menor | `/meta:publish` viaja para a onion-core e a injeção quebrava sem o motor | CURADO: injeção com teste de existência |
| 9 | menor | `/home/onion/` (conta real) ia a público, e a derivação não a via | CURADO: contas também do passwd (uid ≥ 1000); os 4 sítios trocados; `vps-exposure-check.sh` deriva a home da conta de serviço |
| 10 | menor | `--count` ignora o papel | DECLARADO na doutrina: superestima, nunca subestima, é informativo |
| 11 | menor | bancada sem plugins, `--clone`, `--role`, `--all`, REGRA 36; esboço engolia falha do tar; caso (e) textual | CURADO: casos (q), (q2), (m*), (r), (p), (l); esboço sai 3; (e) recusa qualquer `exit` |
| 12 | menor | `paths:` do workflow não incluía o próprio motor | CURADO |
| 13 | menor | corrida da main no meio; texto "commitado" sem commit; prompt de senha em TTY | CURADO: `--from <sha>` sempre ao materializador (o aviso dele só dispara quando a ref não é a integração); texto condicional; `GIT_TERMINAL_PROMPT=0` |

## Bancada e mutantes

- `run_publish_selftests`: 25 casos; `run_door_staleness_severity_selftests`: 5 casos (reescrita).
- Mutantes por `ops/mutate-and-restore.sh`, um por caso (23 no motor + 4 na severidade e no `--count`).
- Bancada completa **não** rodada local (horas nesta VPS compartilhada; o pre-commit caiu no failsafe
  da bancada inteira e foi interrompido). Commits com `--no-verify` declarado; o CI é o gate final.

## Dogfood

Ensaio de branch (`--from HEAD`, sem push) contra os remotos públicos: onion-standalone, onion-core
(como `source`, a troca decidida na matriz) e onion-plugins com 0 vazamento, paridade e 0 HARD (ou
validate `--strict`); onion-mini recusado com a F5 nomeada; `--role standalone` sobre a onion-core sem
`--force-role-change` recusado (o caminho do dano de 2026-09-30). Nenhum push em repo de porta.
