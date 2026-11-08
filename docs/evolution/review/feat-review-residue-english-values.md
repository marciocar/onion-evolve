---
branch: feat/review-residue-english-values
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 14
findings_blocking: 4
tokens: 0
duration_min: 0
findings_fixed: 10
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: execution agent (1st pass) + separate refuter of the core session (2nd pass, isolated)
nota: "tokens e duração não medidos (0). 1ª passada do próprio agente; a 2ª, de um refutador separado, REPROVOU por 1 bloqueio e 5 limites, todos curados neste PR com caso e mutante: por isso elenxo_isolado true. O resíduo sai no formato novo (dogfood)."
---

# Passada adversarial: `feat/review-residue-english-values`

## O que muda

Decisão do maestro de 2026-11-08: valor de campo de máquina é código e vai em inglês. No resíduo da REGRA 56
(PR aberto carrega RESÍDUO da passada adversarial), `verdict` passa a APPROVED | FIXED | REJECTED |
REJECTED_AND_FIXED | NO_FINDINGS, e `elenxo`/`elenxo_isolado` passam a true|false. A forma antiga só vale
nos resíduos da lista congelada (871 na geração final de 2026-11-08, sobre a origin/main com o #1540, o #1542 e o #1543) `docs/evolution/review-residue-legacy.txt`. A catraca impede a lista
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

## 2ª passada: refutador separado (REPROVOU; tudo curado aqui)

6. **B1, BLOQUEIA, CURADO.** A lista do legado era chaveada só pelo caminho. Uma branch nova com o slug de um
   resíduo legado (`feat/decide-painel`) o reescrevia com APROVADO e `sim`, e passava. Slug repetido não é hipótese:
   houve 6 em 1530 PRs. Cura: legado é **estar na lista e ser idêntico ao blob da base**. O julgamento do PR compara
   o blob julgado com o do `BASE`, e o `--schema` compara com o merge-base. No gate do AUTOMATE não sobrou era de
   legado: o `residue()` só aceita o resíduo que o PR traz no diff, que por definição está tocado. A comparação
   `show(base)==show(head)` pedida seria sempre falsa ali, então o legado saiu do gate. Casos: (p2) pelo PR,
   (k2) pelo `--schema`, (e14b) pelo AUTOMATE, cada um com mutante.
7. **L1, CURADO.** Chave duplicada no frontmatter: o bash lê a 1ª ocorrência e o YAML a última. Agora reprova no
   `--schema`, no julgamento (`CHAVE-DUPLICADA`) e no gate (`RESIDUO-CHAVE-DUPLICADA`). Medido: 0 dos 958 resíduos
   tinham duplicata, então nada quebra.
8. **L2, CURADO.** Dois mutantes do refutador sobreviviam na família drive_automate. Os casos novos os matam:
   (e14a) `elenxo_isolado: sim` num resíduo novo → ELENXO-UMA-VOZ; (e14b) o caminho na lista, reescrito com
   sim/sim/REPROVADO_E_CURADO → ELENXO-AUSENTE. O caso "legado com `sim` passa no gate", também pedido, não existe
   mais, porque o gate não tem legado (achado 6).
9. **L3, CURADO.** O gate lia pelo YAML 1.1, onde `yes`/`on` viram True. Agora lê pelo mesmo extrator do bash
   (`fm_raw`: 1ª ocorrência, texto cru). Caso (e14c), com mutante.
10. **L4, CURADO.** A lista se gera por `--legacy-candidates [<ref>]`, regenerada no último rebase sobre a
    origin/main. O resíduo antigo mergeado DEPOIS da geração fica de fora, e de propósito: resíduo mergeado não
    volta a ser julgado, e a lista não cresce. A janela é declarada. Caso (k3).
11. **L5, CURADO.** "Cresceu" e "entrada nova" medem contra o merge-base; a órfã segue medida na árvore. Caso (l5)
    com mutante. O achado 3 (falso "cresceu" num PR antigo) morre com ele.

## 3ª passada: refutador separado (APROVOU COM RESSALVAS)

12. **Limite 1, CURADO.** Comparar com a lista da base não pegava a lista que NASCE (a base não tem lista) nem a
    entrada de um resíduo já no formato novo. A catraca agora exige lista ⊆ `--legacy-candidates <merge-base>`.
    Caso (l1) com mutante; os casos (l) e (p2/p3 B1) passaram a usar resíduos de base na forma antiga, para que a
    nova checagem não mascare o que eles isolam.
13. a 15. **Limites 2 a 4: declarados, não curados neste PR.** Ficaram no parecer da 3ª passada, que está com a
    sessão do core. O texto deles entra aqui quando o team-lead o repassar. Editar o resíduo não muda o hash
    revisado, porque o diretório de review fica fora do diff.

## Mutantes

Todos com a cópia limpa provada no mesmo arranjo:
- (i) sem consultar a lista no `--schema`, o legado reprova;
- (j) com o enum novo trocado pelo antigo, o resíduo novo reprova;
- (k-verdict) com o legado valendo para todo resíduo, o verdict antigo passa num resíduo novo;
- (k-bool) sem a checagem dos booleanos, `elenxo: sim` passa num resíduo novo;
- (l) sem a chamada da catraca, a lista que cresce passa;
- (p3) sem consultar a lista no julgamento do PR, o legado reprova.
- (p3 B1-sem-intocado) e (k2-B1): sem exigir "intocado", o slug de legado reescrito passa.
- (p3 sem-duplicata) e (k2-dup): sem a checagem de duplicata, a duplicata passa.
- (m-sim), (m-sim-B1), (m-yaml) e (m-dup) no drive-automate.
- (l5): a catraca medida contra a ponta acusa "CRESCEU".
- (l1): sem a checagem ⊆ candidatos, o resíduo novo listado passa.

## Limites declarados

- O achado 3 caiu com o L5.
- Os PRs em voo cujo resíduo ainda não está na `origin/main` e usa a forma antiga passam a reprovar depois
  do merge. Isso é o efeito pedido pela decisão: a cura é trocar os valores no resíduo.
- O maestro falou em 618 resíduos de legado, e 618 é a contagem do campo `elenxo`. A lista tem 871 (na geração final), os que
  têm qualquer valor na forma antiga (verdict ou elenxo).
