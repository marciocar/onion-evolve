---
branch: fix/evolve-staleness-delta-by-commit
date: 2026-10-13
reviewed_diff_sha256: 9d272b8f035d66f58f44109de4c8812a0015a8722a6aa4ce481bc9e109a5a603
reviewed_code_sha256: 7e58ab02aed3138c593f0c08ec5f9baf110882d51a7f32b5e3bce557ab320241
findings_total: 4
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 15
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida, mais 3 mutantes executados. Gate mecânico: famílias evolve_staleness e evolve_census
---

# A REGRA 97 conta o delta desde o commit do relatório, não desde a data

## Defeito (sinal de campo do onion-kg-ssot, 2ª rodada do /meta:evolve, 2026-10-12)

A perna do delta populacional da REGRA 97 (A auto-auditoria do framework tem GATILHO) contava
`git log --since=<data>T00:00:00`. Um artefato commitado no mesmo dia, antes do relatório, contava como
posterior à auditoria. No adotante isso deu 42 artefatos, acima do limiar de 40, e o alarme falso disparou
uma 2ª rodada inteira. O teto da própria guarda chamava o erro de "caso de borda de um dia".

## Cura

- A base do delta passa a ser `git log -1 --format=%H -- <relatório>`, e o delta conta `<commit>..HEAD`.
- Fallback para a data só em dois casos, e sempre declarado com `EVOLVE-DELTA-BASE-DATA` e o motivo: o
  relatório ainda sem commit, ou o commit dele na fronteira de um clone raso, onde o git finge que o
  arquivo nasceu ali.
- A mensagem de `EVOLVE-DELTA` passa a dizer a base (`base: commit` ou `base: data`).
- O teto do script foi reescrito: o item de granularidade de dia saiu, e entraram a base por commit, o
  fallback declarado e a edição tardia do relatório.

## Prova

- `--selftest` do check **14/0** com `LC_ALL=C`. Casos novos: (l) artefato no mesmo dia antes do relatório
  não conta; (m) o par de (l), commit depois conta exatamente 1, base commit; (n) clone raso declara o
  fallback. O (j) foi reescrito para exercitar o fallback (relatório sem commit) e exigir a declaração.
- Família `evolve_staleness` do `lint-selftest.sh` **7/0** com `LC_ALL=C`. Casos novos (e1) e (e2), no modo
  `--tsv` que o dispatcher consome, pelo caminho literal (REGRA 59 (Modo que a produção consome é
  exercitado pela bancada)). Família `evolve_census` verde junto (21/0 as duas).
- Mutantes, todos reprovando:
  - M1, base volta ao `--since` por data: reprovam (l) e (m) no `--selftest`, e (e1) e (e2) na família.
  - M2, sem detecção de clone raso: reprova (n). A saída fica vazia, então o delta sairia zero em
    silêncio.
  - M3, fallback sem emissão: reprovam (j) e (n).
- No adotante (clone local do onion-kg-ssot, HEAD 1fe102a, relatório gravado em b0ec4f9): a guarda de
  `origin/main` conta 42 e acusa. A curada conta 0 e cala.
- No core: 134 pela data, 132 pelo commit `d688f71d` do relatório de 2026-10-04. A diferença são os
  artefatos do mesmo dia antes do relatório.

## Passada adversarial (default reprovado na dúvida)

1. **REAL, curado.** A 1ª redação usava `git rev-parse --path-format=absolute`, que só existe desde o
   git 2.31. Em git mais velho o `|| true` deixava o caminho vazio e o clone raso passava como completo,
   com o delta subcontado em silêncio. A versão final usa `--git-path shallow` relativo, testado dentro do
   REPO, e num worktree ligado ele aponta o dir comum.
2. **REAL, curado.** O caminho do relatório ia absoluto para o `git log`. Com o REPO resolvido por um
   symlink, isso pode cair em "outside repository" e mandar um repo saudável para o fallback. Agora o
   caminho vai relativo quando mora dentro do REPO. **Sem caso de bancada**: o absoluto também funciona na
   fixture, então nenhum mutante distingue as duas formas. Fica declarado.
3. **Teto, aceito.** Um artefato no MESMO commit do relatório conta como coberto, e editar o relatório
   depois move a base para a frente. Os dois estão declarados no teto do script.
4. **Teto, aceito.** Entre escrever o relatório e commitá-lo, o lint emite `EVOLVE-DELTA-BASE-DATA` (SOFT).
   Isso é verdade: naquela janela a base é a data. O raio-X do evolve conta essa linha como sinal.

## O que NÃO cobre

- O item 2 do sinal (contradição radar/selador/contrato sobre decisão selada em DEV) não é deste diff. Já
  foi curado no PR #1064 e está registrado no grafo `triagem-evolve-kgssot-2026-10`.
- O localizador do MAQ-0 foi conferido por `grep -n` (linha 157 no pin dcdacf9ba196 e em 50cd399d). A cura
  já está em main, pelo `_guard_links` do PR #1062. Só fica registrado no grafo.
- MAQ-2, MAQ-3, MAQ-5, MAQ-6, MAQ-7, D7-0 e os 13 de D1/D2/D6 ficam como informados, sem medição nesta leva.
