---
branch: feat/review-auto-with-fallback
date: 2026-11-13
reviewed_diff_sha256: 95257f85a5197dc0529d6168f9a3fdfd56c6962663aae900637bdb86cf0db66b
reviewed_code_sha256: 714d03810de72a4836f3e93b3decfdf9415cdb1aa81aa5dcdc3c7a05b5070be3
findings_total: 9
findings_real: 8
findings_fixed: 8
tokens: 0
duration_min: 20
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "1ª passada: o próprio agente de execução; 2ª passada: refutador independente da sessão principal (evidência em scratchpad/r1652), que REPROVOU com 3 bloqueios e um mutante sobrevivente, todos curados aqui"
nota: "tokens = 0: não medido. elenxo_isolado: false porque as curas da 2ª passada não foram re-refutadas pelo refutador independente; pelo próprio mecanismo deste PR, a sessão não o mergearia em fallback. O merge é do maestro (D_DELEGATION_TRUST_MODEL_1113)."
---

# Passada adversarial: `feat/review-auto-with-fallback`

## O que muda

- `ops/review/guard-paths.sh`, novo: a lista de guardas num lugar só, derivada do `ops/moat-targets.tsv`
  (as colunas de ato, delega e wrapper) mais as cercas fixas. Conta o rename pelos dois nomes e o arquivo
  removido.
- `ops/review/review-mode-decide.sh`: o `auto` revisa só o PR que toca guarda, e o teto de 600 linhas
  saiu. A decisão também mede `guard` em todo modo, ganhou `--classify-credit` e `--fallback`, e o caso
  `run=false` passou a dizer "não revisado pelo CI: <motivo>".
- `.github/workflows/onion-review.yml`: o juiz, o helper e o tsv vêm da BASE. Sem crédito, sem chave ou
  com modo off, o veredito vira fallback verde com a marca, e o motivo vai para o sumário e para um
  comentário sticky no PR.
- `ops/pr-merge-verified.sh`: em fallback, o PR de guarda só entra com o resíduo da REGRA 56 com
  `elenxo: true`, `elenxo_isolado: true`, verdict aceito e diff carimbado.

## Achados

1. **REAL, CURADO.** O juiz da base anterior não conhece `--guard-helper`. O workflow novo passaria a
   flag ao juiz velho, que sai rc 2. O job do modo falharia, e o veredito ficaria vermelho neste PR. A
   cura é um bootstrap dito no log: se o juiz da base não conhece a flag, usa-se o do PR. Isso só
   acontece no PR que introduz o helper.
2. **REAL, CURADO (pré-existente).** Com a chave ausente, o veredito saía verde **sem a marca**, e o
   `pr-merge-verified.sh` o lia como aprovação. Agora esse caso também é fallback com marca, e o PR de
   guarda passa a exigir o resíduo.
3. **REAL, CURADO (na bancada).** O mutante `--name-status -M` do caso (j) sobreviveu. Com `-M`, a linha
   do rename vira `antigo<TAB>novo`, e o prefixo `.claude/hooks/` ainda casa no começo dela. Em produção
   o diff é `--no-renames`, então não há defeito no código. O mutante foi trocado por `--name-only -M`,
   que mostra só o nome novo, e esse reprova.
4. **REAL, CURADO (na bancada).** O caso (gp-d), prefixo só no início do caminho, rodava sobre uma branch
   sem caminho aninhado, e o mutante passava. A branch `b_nest`, com `docs/ops/review/x.md`, agora faz o
   mutante reprovar.
5. **NÃO É DEFEITO, É TETO DECLARADO.** O `reviewed_diff_sha256` só tem a forma conferida no merge, igual
   ao #1647. A coerência entre o hash e o diff é da REGRA 56 no lint e do `pr-finalize`.

## O que a bancada exercita

Na família `review_mode`, cada caso tem mutante:

- `auto` com PR de guarda roda (f); `auto` com PR comum não roda (g, h, i);
- rename pelo git (j) e pela API, via `previous_filename` (gp-f); remoção (j2);
- derivação do tsv: ato, wrapper e delega (gp-a a gp-c); prefixo só no início (gp-d); tsv ilegível revisa
  (gp-e); diff ilegível revisa (k); `guard` medido também em off (k2);
- off é fallback com sumário e comentário (o, o1); auto sem guarda não comenta (o2);
- falta de crédito pelo pré-voo e pela evidência (cr-a a cr-c); 400 que não é crédito segue vermelho
  (cr-d, cr-e); `--fallback` emite a marca (fb-a); fiação do workflow (s, s2).

Na família `pr_merge_verified`, também com mutante:

- (rv-f) fallback num PR de guarda sem resíduo recusa;
- (rv-g) fallback num PR de guarda com resíduo sem `elenxo_isolado` recusa;
- (rv-h) fallback num PR de guarda com resíduo independente mergeia;
- (rv-i) fallback num PR comum mergeia sem exigência extra.

## 2ª passada: refutador independente (REPROVOU, 3 bloqueios, curados)

6. **B1, REAL, CURADO. Verde sem marca contava como aprovação.** O `_fallback_guard_gate` só entrava com a
   marca de desligado, e isso deixava duas portas:
   - (a) um PR que edita o `onion-review.yml` faz a action se auto-pular e sai verde sem marca. Este PR cai aí;
   - (b) o job do veredito rodava o `review-mode-decide.sh` do head, então um PR que mudasse o `--verdict-gate` saía verde sem marca.

   Cura:
   - o job do veredito lê o juiz e o `review-verdict.sh` da **base**;
   - quando o revisor rodou e aprovou, o juiz da base emite a marca **positiva** `onion-review-revisado: … <sha>`;
   - num PR de guarda, o merge-verified só aceita como revisão essa marca, com o sha do head e sem mudança na maquinaria do revisor (workflow, `ops/review/`, `review-verdict.sh`, `post-review-comment.sh`). Todo o resto é fallback, com o resíduo;
   - o caso da action auto-pulada passou a ser fallback dito.

   Casos: (rv-j) a (rv-m), (pos-a) e (s3).
7. **B2, REAL, CURADO. O `--classify-credit` fazia grep no arquivo inteiro.** O arquivo traz o diff e as saídas das ferramentas, então a frase num `tool_result` fazia um estouro de turnos sair verde. Agora lê só o último evento `result`, com `is_error`, `api_error_status` e a mensagem. Caso (cr-f), com mutante que lê o arquivo inteiro.
8. **B3, REAL, CURADO. A lista regredia.** Escapavam:
   - `materialize-door.sh`, `.githooks/`, `lint-artifacts.sh`, `review-artifact-check.sh`, `review-verdict.sh`;
   - `pr-finalize.sh`, `merge-serial.sh`, `post-review-comment.sh`;
   - `apply-ruleset-main.sh` e os globs antigos.

   Agora o helper lê a classe `fecho` (o fecho transitivo do #1647) e soma o tsv da árvore ao de `origin/main`. Também soma `.githooks/`, `.claude/validation/` inteiro, a `SENSITIVE_PATHS` antiga (com glob) e o fecho que a main ainda não traz. Casos (gp-item), um por cerca e cada um com mutante, mais o fecho e a soma dos tsv.
9. **REAL, CURADO. Faltava caso para a chave repetida no frontmatter, e o mutante dela sobrevivia.** Caso (rv-n).

Limites declarados, que também estão no cartão:

- `elenxo_isolado` é auto-atestado;
- os bootstraps (o juiz e o helper do PR quando a base não os tem) voltam a abrir a cada capacidade nova. Quem entra por eles muda a maquinaria e cai no resíduo;
- com o #1647, a sessão nem mergeia PR de guarda.

Este resíduo segue com `elenxo_isolado: false`: a 2ª passada foi independente, mas o resíduo não foi escrito por ela.
