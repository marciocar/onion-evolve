---
branch: feat/review-auto-with-fallback
date: 2026-11-13
reviewed_diff_sha256: 1b4cbdee597e318b89048bfa48dfce558a476c74c03c1f9d9284756c87e73674
reviewed_code_sha256: 94f8104c3c343f94f9703db9c44121853aa7f73c888a8413700a96bf697c1b50
findings_total: 5
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 20
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Uma voz só (elenxo_isolado: false): pelo próprio mecanismo que este PR cria, um PR de guarda em fallback não entraria pela sessão com este resíduo. O merge é do maestro (D_DELEGATION_TRUST_MODEL_1113)."
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
