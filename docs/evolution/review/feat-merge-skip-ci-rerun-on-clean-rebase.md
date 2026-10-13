---
title: 'Resíduo — merge da fila sem esperar o CI do head novo depois de auto-rebase limpo (A agora, B se precisar)'
date: 2026-10-13
branch: feat/merge-skip-ci-rerun-on-clean-rebase
reviewed_diff_sha256: 806ff39a838b889e1a20094e98c8f05b42f8ead73070d38cd422bcf13b311294
reviewed_code_sha256: 48faf483df07279e59448de3956732f1a53fdd0c50dd81a7bc802c8d86e1ca03
findings_total: 14
findings_real: 12
findings_fixed: 3
tokens: 0
duration_min: 150
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Decisão do maestro D_MERGE_SEM_CI_APOS_REBASE_LIMPO («A agora, B se precisar», selada pelo
  kg-decide-seal.sh). Depois de um auto-rebase limpo, o ops/pr-merge-verified.sh mergeia na mesma
  chamada, sem esperar o CI do head novo, quando sete condições valem. Os gates rodam contra o head
  ANTERIOR, e o merge vai por gh pr merge --admin --match-head-commit <head novo>. Qualquer condição que
  falha volta à espera (rc 4 na série). O opt-out é --wait-ci-after-rebase, repassado pelo
  ops/merge-serial.sh. A metade B (lote com bissecção) fica gated em Q_MERGE_LOTE_COM_BISSECCAO, com
  gatilho contado pelas issues do alarme (zero hoje). Conserto junto: label review:ia com descrição de
  101 caracteres (422 na API), agora com o texto que já vive no repo e com a guarda de 100 antes da API.
  Família nova merge_skip_ci com 14 casos e caso (wf) na merge_serial; 15 mutantes, 15 reprovados.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que o ruleset exige de fato no head (medido)

- **Ao vivo** (`gh api repos/marciocar/onion-evolve/rulesets/25001643`, 2026-10-13): `required_status_checks`
  com `selftest-gate` e `lint-onion-artifacts` (app 15368), `strict_required_status_checks_policy: false`,
  `bypass_actors` = papel admin (id 5) em `bypass_mode: pull_request`, e **`current_user_can_bypass:
  pull_requests_only`**. Nenhuma outra regra.
- **Doc REST de rules:** `pull_request` significa que *"an actor can only bypass rules on pull requests"*. O
  strict é *"whether pull requests targeting a matching branch must be tested with the latest code"*.
- **Doc de regras disponíveis e de status checks:** nenhuma das duas diz em QUAL commit os checks são
  exigidos, só que *"all required status checks must pass before collaborators can merge"*. O modo loose
  só dispensa a branch estar em dia com a base. **Lacuna da doc, declarada.** A leitura operacional é a de
  sempre: os checks são os do head do PR, e um head recém-empurrado tem zero.
- **`gh pr merge --help` (v2.96.0):** *"If required checks have not yet passed, auto-merge will be
  enabled"*. Sem `--admin`, um merge num head sem checks **não mergeia**: liga o auto-merge, e o verificado
  morreria com "estado OPEN".
- **O GitHub rebasear no merge não resolve:** o auto-rebase só roda em PR **CONFLICTING**, e PR em conflito
  o forge não rebaseia. A única porta que mantém o head julgado é o bypass com `--match-head-commit`.

## Como o merge passa a funcionar

```
merge-serial → (CI do head esperado fora do lock) → lock → pr-merge-verified
  PR CONFLICTING → pr-finalize --rebase --push (worktree da branch)
    _skip_ci_decide(head anterior, head novo):
      1. sem --wait-ci-after-rebase
      2. a worktree estava no head que o PR mostrava
      3. nenhuma issue aberta de título fixo do alarme (leitura falha ⇒ espera)
      4. o ruleset (ops/github-ruleset-main.json) só tem a regra dos checks
      5. os checks exigidos verdes e nenhum outro falho não dispensado, no head ANTERIOR
      6. diff da main (merge-base velho → novo) ∩ arquivos do PR (antes e depois) = ∅, fora projeção gerada
      7. o head novo MERGEABLE
    tudo vale → comentário "SEM esperar…" → gates contra o head anterior → gh pr merge --rebase --admin
                --match-head-commit <novo> → prova pelo estado
                (forge recusou → rc 4 na série; direto → para, "nada foi mergeado")
    alguma falha → comentário "o CI do head novo roda antes do merge (espera: <motivo>)" → rc 4 → como antes
```

**Tempo esperado por PR na fila:** o do rebase (o `pr-finalize --rebase --push`, que regenera as projeções e
roda o lint; da ordem de 1 a 3 min, **não medido** nesta execução) mais o merge, em vez de 20 a 25 min. Para
5 PRs prontos juntos, da ordem de 5 a 15 min em vez de ~2h, enquanto nenhuma condição cair na espera.

## Casos e mutantes (ops/mutate-and-restore.sh, LC_ALL=C, 2026-10-13): 15 de 15 reprovados

| Caso | O que prova | Mutante que o reprova |
|---|---|---|
| (a) | limpo + verde ⇒ merge imediato com `--admin --match-head-commit <novo>`, gates no head anterior, decisão no comentário | a1 sem `--match-head-commit` · a2 gates no head novo |
| (b) | conflito de fonte ⇒ para, sem merge | (guarda anterior) |
| (c) | a main mexeu em arquivo do PR ⇒ espera, nomeando o arquivo | c sem o teste do cruzamento |
| (c2) | cruzamento só em projeção gerada ⇒ não barra | c2 projeção conta |
| (c3) | a main renomeou arquivo do PR ⇒ espera | (hipótese refutada, ver 2) |
| (j) | ruleset com regra além dos checks ⇒ espera | j sem o teste de regra extra |
| (d) | exigido vermelho no head anterior ⇒ espera | d sem o teste dos exigidos |
| (d2) | outro check falho ⇒ espera | d2 sem o teste de falhos |
| (e) | alarme aberto ⇒ espera nomeando a issue; alarme ilegível ⇒ espera | e · e2 |
| (f) | `--wait-ci-after-rebase` ⇒ espera | f |
| (g) | worktree fora do head julgado ⇒ espera | g |
| (h) | forge recusa o bypass ⇒ rc 4 na série; direto, para sem declarar merge | h |
| (i) | head novo não MERGEABLE ⇒ espera | i |
| (l) | labels do `apply-ruleset-main.sh` ≤ 100 caracteres; a de 101 é recusada antes da API | l |
| merge_serial (wf) | o opt-out é repassado; a flag sozinha não começa série | wf |

Bancada: `pr_merge_verified`, `merge_serial`, `two_tier_bench` e `merge_skip_ci` com **89 de 89**, mais
`shell_pipefail_robustness` com 3 de 3. O `ops/apply-ruleset-main.sh` agora é citado pela `merge_skip_ci`, e
o `--map` o liga a ela (antes caía no failsafe da completa, medido no CI do #1075).

## Passada adversarial (refutador com o default reprovado)

1. **O `--admin` contorna o ruleset INTEIRO** (real, curado). Se alguém acrescentar ao ruleset uma regra
   de review ou de histórico linear, o pulo a contornaria calado. Agora o pulo só acontece enquanto a
   única regra é a dos checks (condição 4), com o caso (j) e o mutante j.
2. **Rename na main de arquivo do PR escaparia do cruzamento** (hipótese refutada). O rebase leva a
   mudança do PR para o nome novo, e o lado "depois" dos arquivos do PR cruza com o diff da main. O caso
   (c3) prova isso.
3. **Dois PRs mudam arquivos diferentes e se quebram semanticamente** (real, janela declarada). Os dois
   entram sem o CI do head novo. Só a bancada completa do push ao main pega, e o main fica quebrado até o
   revert (`main-bench-alarm.sh`). É o gatilho do B (`Q_MERGE_LOTE_COM_BISSECCAO`), contado pelas issues
   do alarme: **zero** em 2026-10-13.
4. **O rebase muda uma projeção gerada ou um lockfile** (real, declarado). A projeção regenerada no head
   novo nunca rodou no CI. O `pr-finalize` roda o lint (0 HARD) nesse head, o que cobre a catraca da REGRA 62
   (Projeção GERADA em sincronia com a fonte), mas a bancada não roda. Um lockfile (`site/package-lock.json`,
   `vendor/kg-ssot/tools/requirements.txt`) que a main muda e o PR não toca não barra o pulo. Mudança de
   dependência que quebra o PR é a classe semântica do item 3.
5. **Verde antigo de antes de um force-push** (hipótese refutada). O verde é lido por SHA do head que o
   PR mostra no início. A worktree tem de estar nesse head (caso g), e o merge amarra o head novo por
   `--match-head-commit` (mutante a1). Um push entre a decisão e o merge faz o forge recusar, e isso cai
   no caso (h).
6. **O 2º ângulo (`gh pr checks`, `statusCheckRollup`) não é lido no caminho sem CI** (real, declarado).
   Os dois seguem o head atual do PR, que é o novo e não tem checks. Resta só a leitura ancorada por SHA.
   A redundância cai nesse caminho.
7. **O ruleset é lido do JSON local, não do vivo** (real, declarado). Se o ruleset aplicado divergir de
   `ops/github-ruleset-main.json`, a decisão julga a SSOT, não o forge. O `apply-ruleset-main.sh` é quem
   os alinha.
8. **O bypass não foi medido ao vivo** (real, declarado). Nenhum merge real foi feito nesta execução. O
   `current_user_can_bypass: pull_requests_only` lido ao vivo e a doc sustentam o desenho. Se o forge
   recusar, o caminho volta a esperar sozinho (caso h). O 1º merge real da fila é a medição.
9. **Alarme aberto barra só o PULO, não o merge** (real, declarado). Com o alarme aberto o PR espera o CI
   e segue o caminho de sempre. "Só o conserto entra" continua sendo regra em prosa do passo D para o
   caminho com espera. Mecanizá-la exige identificar o conserto (branch `revert/*` ou flag), e isso é
   decisão do maestro.
10. **"Rebase sem conflito" lido como "sem conflito de FONTE"** (real, desvio declarado da letra). Pela
    letra, o A quase nunca valeria: o auto-rebase só roda em PR CONFLICTING, e o único rastro medido (#1071)
    é conflito de projeção (`docs/onion/testing-inventory.md`). A projeção é regenerada de forma
    determinística, e conflito de fonte segue parando.
11. **O 1º mutante (d) sobreviveu por erro meu, não do SUT** (real, curado). `&& true ||` mantinha o
    `return`. Refeito como `|| true ||`, ele reprova (d).
12. **O fixture (c3) não fazia o que dizia** (real, curado). `git mv -q` não existe, a main não andou, e
    o caso mediu um rebase sem efeito. Corrigido, (c3) passa pelo motivo certo. Achado lateral: rebase
    sem efeito (head igual) cai no caminho sem CI com o head já verificado, o que é correto.
13. **O hook `bash-empty-result-guard` disparou MERGE-SEM-FONTE-LIDA num `gh pr merge --help`** (real,
    fora do escopo). Falso positivo da guarda por vocabulário, registrado aqui e não curado neste PR.
14. **O scratchpad é compartilhado entre agentes** (real, processo). O driver de mutantes foi
    sobrescrito por outro agente, que apontava para outra worktree. Ele não foi rodado, e o meu foi
    refeito com nome único.
