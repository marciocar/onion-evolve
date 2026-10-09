---
title: 'Resíduo — o corte por papel leva junto os companheiros do comando cortado'
date: 2026-10-09
branch: fix/role-cut-command-companions
reviewed_diff_sha256: 9f28594d04b6665e24787fd3c7d0dd396afdec7a2653128fa8ad59d241f9ff2f
reviewed_code_sha256: f91e70c7e88618f0469c0de86e8d9484c3f8bcc78725a6e241c7d6ac8e280ce2
findings_total: 4
findings_real: 4
findings_fixed: 3
tokens: 0
duration_min: 70
verdict: CORRIGIDO
elenxo: nao
---

# Resíduo — REGRA 56

## O que o PR faz

O `vendor-manifest.sh --role standalone` cortava os comandos de `meta/` que o papel não recebe, mas
deixava viajar as peças que só esses comandos usam: doutrina, lente, censo e workflow. A cura
(`_emit_companion_excludes`) deriva essas peças pelo grafo de citação em HEAD, como o `forge-census.sh`
já faz. A zona é restrita às quatro formas de peça da forja. A bancada (`lint-selftest.sh`, `fixtures/`)
e a própria planta não ancoram. O fecho é transitivo nos dois sentidos, e a lente que cita comando
cortado sai mesmo viva, com aviso.

Higiene: o glob `/home/marcio/*/` saiu do hook `pretooluse-env-guard.sh` e da bancada `env_exposure`.
Nos comentários virou `/home/<usuario>/*/`. No caso executável virou `/home/usuario/*/`, porque `<>`
seria redirecionamento e mudaria o que o hook julga.

## Achados da passada (dogfood como revisor)

1. **REAL, CURADO: a planta mantinha vivas três peças.** No primeiro commit, a materialização cortou 11
   peças, não 14. O comentário do `vendor-manifest.sh` cita `cc-delta-census`, `forge-census` e o
   workflow do evolve com extensão, e a planta viaja como contrato. O manifesto saiu de `_is_anchor`.
   A fixture da bancada agora cita uma peça na sua cópia da planta, e o caso (m) reprovaria sem a exclusão.
2. **REAL, CURADO: custo.** A 1ª redação fazia um `git grep` por peça e por lente×comando, e levava o
   manifesto de 1,8s para 8,5s, medido. A forma final faz um `git grep -o` por token inteiro (1,7s), com
   saída byte a byte igual à da 1ª redação.
3. **REAL, CURADO: dívida MUST do grafo.** `door-role-parity-2026-09.kg.yaml` falhava em
   `form.required.node.provenance` já em HEAD. Os seis nós antigos ganharam `provenance`. Cinco são
   `testemunho` da sessão de 2026-09-30, sem nova medição. O sexto, `D_GUARDA_EM_DUAS_LINHAS`, é
   `medição`: as duas famílias rodaram hoje, 19/0.
4. **REAL, NÃO CURADO (teto declarado):** o `lint-selftest.sh` da porta ainda cita os censos cortados,
   a mesma classe que já existia com `validation/federation-*`. A bancada não viaja como consumidora, e
   rodá-la dentro da porta não é contrato de porta nenhuma. O `AVISO` da lente forçada sai em stderr,
   e o `materialize-door.sh` descarta o stderr do manifesto.

## Provas

- Família `role_cut` com LC_ALL=C: 34/34. Casos novos: (m), (m-hub) e (m-MUT).
- Faixa afetada (`--affected` do manifesto e do hook, 25 famílias, `--jobs auto`): 151/0.
- Mutante: com o `vendor-manifest.sh` de `origin/main`, o caso (m) reprova e lista as 5 peças que
  voltariam a viajar.
- `materialize-door.sh --role standalone`: 691 → 677 arquivos. Saem 14 e não entra nenhum. A
  `client-material-doctrine.md` fica, porque `/docs:build-project-manual`, que viaja, a cita.
- `materialize-door.sh --role hub`: 782 → 782, com a mesma lista. O conteúdo só difere nos arquivos
  editados por este PR, no carimbo e nas projeções.
- Lint da porta standalone: rc 0, 0 HARD e 11 SOFT. Antes eram 12 SOFT.
- `kg-radar.sh`: exit 0. `kg-contract-check.sh`: rc 0. `kg_gate.py` com os excludes do CI: rc 0, e o
  grafo passa no MUST. O ganho não foi travado com `--update`, porque isso mexeria na base de outro grafo.

Ids (para a guarda): E_CORTE_DERIVA_COMPANHEIROS_DO_COMANDO
