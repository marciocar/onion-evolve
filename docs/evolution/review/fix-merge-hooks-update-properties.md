---
branch: fix/merge-hooks-update-properties
date: 2026-10-12
reviewed_diff_sha256: 0e8801fc53db3ad8123c831eaeb38cc052729c8adf7618bd7c3d870a84213846
reviewed_code_sha256: b2754e5b32ebdd35e466e46a726f4b310d5c8054191f119d98b55c0af66266ca
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 90
verdict: REPROVADO_E_CURADO
reviewer: passada própria + 2 mutantes executados (sem subagente) — gate mecânico: família fixtures (run_merge_fixture)
---

# O merge de hooks do `/meta:adopt --update` não atualizava o que já era do Onion

## Defeito medido

No `--update` do onion-kg-ssot (2026-10-12, PR #78 de lá), o pós-merge reprovou 4 HARD na REGRA 101.
Os 4 vetos do adotante continuaram sem `onFailure: block`, e o veto novo `pretooluse-direct-provider-api`
chegou **sem `matcher: "Bash"`**. Os dois defeitos estavam no `merge-onion-hooks.sh`:

1. **Hook presente = intocado.** O merge só anexava o que faltava. Quando o alvo já tinha um hook com o
   mesmo `.command`, nenhuma chave nova da fonte chegava. Assim o `onFailure` nunca alcançava um
   adotante antigo.
2. **Matcher perdido.** O hook ausente entrava como `{hooks:[obj]}`, sem o `matcher` do grupo de origem.
   Um veto de `Bash` virava hook de todas as ferramentas.

## Cura

- **Refresh:** um hook do alvo com o mesmo `.command` de um hook da fonte é do Onion. As chaves da fonte
  sobrepõem as do alvo, e uma chave extra que só o alvo tem fica. Hook próprio do alvo (command que a
  fonte não tem) não é tocado.
- **Matcher:** o hook ausente entra num grupo próprio com o `matcher` do grupo de origem.

## Achado da passada adversarial (3º)

3. **A própria cura abortava o merge.** Um hook do alvo sem `.command` (`type: prompt`/`agent`) fazia
   o `$srcmap[null]` do jq sair com rc 5 e derrubava o merge inteiro. O `origin/main` passava nesse caso,
   então a regressão era da cura. Curado com uma guarda de tipo (`.command` string) no script e também
   na asserção (4) da bancada, que tinha a mesma indexação.

## Prova

- Fixture nova `adopt-settings-merge/target-old-adopter-no-onfailure.json`: um adotante antigo com 2
  vetos sem `onFailure`, 1 hook próprio num grupo com matcher e 1 hook `type: prompt` sem command.
- Asserções novas em `run_merge_fixture`: (4) refresh, em que todo hook Onion do resultado traz as chaves
  e os valores da fonte; (5) matcher, em que todo hook da fonte de grupo com matcher aparece num grupo
  com o mesmo matcher.
- Família fixtures **com a cura: 117/0**.
- **Mutante 1** (o script de `origin/main`): as 4 fixtures do merge reprovam, 3 pelo matcher e 1 pelo
  refresh.
- **Mutante 2** (a cura sem a guarda de null): a fixture nova reprova, com o merge saindo em exit
  não-zero.
- Idempotência medida à mão: rodar 2× dá o mesmo resultado (`cmp`).

## O que NÃO cobre

- Um mesmo `.command` em dois grupos da fonte com matchers diferentes: o refresh aplica as chaves da
  última ocorrência (`from_entries`). Isso não acontece no `settings.json` do core hoje.
- Uma chave que a fonte **removeu** continua no alvo. O refresh sobrepõe, mas não apaga. Apagar exigiria
  decidir o que é do Onion por chave, e o alvo pode ter acrescentado a chave de propósito.
- O `--update` já aplicado no onion-kg-ssot não se cura sozinho: o próximo update leva a cura.
