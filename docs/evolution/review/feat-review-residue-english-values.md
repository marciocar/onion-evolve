---
branch: feat/review-residue-english-values
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 5f53567dbddcf792b8d61c89f9440d888812116f7a2b3b75a6dfcf53ccc201d9
reviewed_code_sha256: c4fa8adf2f8f0992f6bac401b895a79795e7ed73d52a66c1fbc46bcf98f60aba
findings_total: 5
findings_real: 4
findings_blocking: 3
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: false
reviewer: execution agent (same session; no separate agent, creating agents was forbidden by the brief)
nota: "tokens e duração não medidos (0). Passada adversarial do próprio agente, uma voz só: por isso elenxo_isolado false. Este resíduo é o dogfood da mudança: sai no formato novo."
---

# Passada adversarial: `feat/review-residue-english-values`

## O que muda

Decisão do maestro de 2026-11-08: valor de campo de máquina é código e vai em inglês. No resíduo da REGRA 56
(PR aberto carrega RESÍDUO da passada adversarial), `verdict` passa a APPROVED | FIXED | REJECTED |
REJECTED_AND_FIXED | NO_FINDINGS, e `elenxo`/`elenxo_isolado` passam a true|false. A forma antiga só vale
nos 867 resíduos da lista congelada `docs/evolution/review-residue-legacy.txt`. A catraca impede a lista
de crescer. Leitores tocados: `review-artifact-check.sh` (o julgamento do PR, o `--schema` e o esqueleto),
`drive-automate.sh` (o gate do AUTOMATE) e `review-ledger.sh` (traduz a forma antiga para a nova, e a série
não se parte). O `testing-state.sh` lê o `--env` do ledger, que saiu idêntico byte a byte antes e depois.

## Achados

1. **REAL, BLOQUEIA, CURADO.** A 1ª versão resolvia a lista do legado pelo diretório do SCRIPT. A bancada
   julga sandboxes com o helper do repo real, então o legado e a catraca seriam os do repo que roda a
   bancada, não os do repo julgado. Cura: no julgamento do PR, `LEGACY_LIST` vem do `REPO_ROOT`.
2. **REAL, BLOQUEIA, CURADO.** Os casos novos só passavam pelo `--schema`. O julgamento do PR, que é o
   caminho que o lint consome, calcula a era por conta própria (`_ERA`), e nenhum caso nem mutante o
   percorria. Cura: casos (p2) e (p3) da família review_artifact, com mutante.
3. **REAL, LIMITE.** A catraca compara com a lista da `origin/main`. Um PR antigo, que ainda tem a lista
   anterior a uma descida já mergeada, aponta "cresceu" até ser rebaseado. Não se cura aqui: a lista só desce
   quando um resíduo é apagado, o que é raro, e o rebase resolve.
4. **REAL, BLOQUEIA, CURADO, achado pelo pre-commit e não por mim.** A lista nasceu em `.claude/validation/`, e
   os nomes dos resíduos carregam nomes de adotante. A REGRA 36 (Superfície VENDORIZADA sem nome comercial de
   cliente) barrou: `.claude/` viaja para todo adotante. Cura: a lista mora em `docs/evolution/`, ao lado dos
   próprios resíduos. O drive-automate passa a lê-la pela raiz do repo, e a bancada, pela raiz da sandbox.
5. **Não procede.** A suspeita era o CI sem `origin/main`, o que deixaria a catraca muda. Medido:
   `onion-validate.yml` faz checkout com `fetch-depth: 0`, então a ref existe.

## Mutantes

Todos com a cópia limpa provada no mesmo arranjo:
- (i) sem consultar a lista no `--schema`, o legado reprova;
- (j) com o enum novo trocado pelo antigo, o resíduo novo reprova;
- (k-verdict) com o legado valendo para todo resíduo, o verdict antigo passa num resíduo novo;
- (k-bool) sem a checagem dos booleanos, `elenxo: sim` passa num resíduo novo;
- (l) sem a chamada da catraca, a lista que cresce passa;
- (p3) sem consultar a lista no julgamento do PR, o legado reprova.

## Limites declarados

- O achado 3.
- Os PRs em voo cujo resíduo ainda não está na `origin/main` e usa a forma antiga passam a reprovar depois
  do merge. Isso é o efeito pedido pela decisão: a cura é trocar os valores no resíduo.
- O maestro falou em 618 resíduos de legado, e 618 é a contagem do campo `elenxo`. A lista tem 867, os que
  têm qualquer valor na forma antiga (verdict ou elenxo).
