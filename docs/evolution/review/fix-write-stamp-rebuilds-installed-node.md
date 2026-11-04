---
branch: fix/write-stamp-rebuilds-installed-node
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: PREENCHA
elenxo: PREENCHA
reviewer: PREENCHA
nota: "REVISÃO PENDENTE: a passada adversarial será feita por outro agente. Os números são 0 = não medido (nenhuma passada ainda), não 'zero achados'. verdict/elenxo/reviewer ficam PREENCHA de propósito, para o --schema acusar até a passada existir."
---

# Passada adversarial: `fix/write-stamp-rebuilds-installed-node`

> **Revisão pendente.** Este resíduo foi escrito pelo construtor da cura, sem a passada adversarial. Quem revisar
> preenche o frontmatter (os números, o `verdict` num dos cinco, `elenxo`, `reviewer`) e a seção Achados.
> Confira com `bash .claude/validation/review-artifact-check.sh --schema <este arquivo>`.

## O que muda

Sinal do adotante onion-curation (2026-11-04, `docs/evolution/inbox/2026-11-04-signal-write-stamp-pin-only.md`),
4ª recorrência seguida, cada uma curada à mão: no `--update`, o escritor do pin no grafo de adoção
(`.claude/utils/kg/stamp-adoption-graph-pin.sh`, chamado ao fim do `write-stamp.sh`) trocava só o token do pin no
label do `ONION_INSTALLED` e o `x_pin`. A data e a versão da kg-ssot no label, a lista de pins anteriores na
narrative (que passava a omitir o pin que acabou de sair) e a provenance ficavam do update anterior.

- `.claude/utils/kg/stamp-adoption-graph-pin.sh`: reconhece o **molde de update** (label `Framework instalado: pin
  `X` (update de D, com o kg-ssot V e o contrato vC), modo `m`, papel `p`, integração `b`.` e narrative `Pins
  anteriores, do mais novo ao mais velho (…): `a`, …; a adoção foi `z`. …`). Nesse molde ele **refaz**:
  - o label, com o pin do carimbo, a data de hoje, a versão lida de `vendor/kg-ssot/.kg-ssot-version`, o
    `CONTRACT_VERSION` de `vendor/kg-ssot/tools/kg_validate.py`, e modo/papel/integração do carimbo (o valor do
    label só fica quando o carimbo não tem o campo);
  - a lista de pins: a anterior mais o pin que sai, na frente, sem duplicar, sem o pin novo e sem o pin da adoção.
    O cabeçalho e o resto da narrative ficam como o dono escreveu;
  - a provenance: `source`, `locator` e `method` passam a citar o carimbo novo. O `@<commit>` do adotante sai,
    porque o commit do update ainda não existe quando o motor roda.
- O mesmo helper **recusa** (rc 4, nada escrito no grafo, a mensagem diz o porquê e o molde) em quatro casos: o
  label começa no molde de update e não casa com ele inteiro; a narrative está fora do molde; a versão da kg-ssot
  ou o contrato não foram medidos no vendor; e o label editado fora dos dois moldes que traz um dado do update
  (`update de`, `atualizado em/de/para`, `kg-ssot`, `contrato v`).
- `.claude/utils/adopt/write-stamp.sh`: o aviso do rc do helper nomeia o rc 4.
- `.claude/validation/lint-selftest.sh`: caso (i6) e oito mutantes na família `adopter_shape`, a que já testa o
  escritor do pin ((i)–(i5)). Os auxiliares levam o prefixo `_as_rb_`.

Por que a cura mora no helper do grafo e não no `write-stamp.sh`: o `write-stamp.sh` só chama o
`stamp-adoption-graph-pin.sh`, que é o único escritor do nó (SAC-149). Curar no chamador deixaria o helper, que o
lint e o operador chamam direto, livre para repetir o defeito.

Por que a lista vem da narrative e não do `git log` da `onion/vendor` (a proposta do sinal): os commits da
`onion/vendor` não carregam o pin do core num campo de máquina, e ler pins do assunto de commit seria inferência.
A lista anterior mais o pin que sai (o `x_pin` do nó) são fontes medidas e reproduzem a cura à mão da curadoria.

## Dogfood

- Grafo REAL da curadoria, reconstruído no estado anterior ao update `a682c090d1bc` (x_pin `3ade85b7e1c0`, label
  com 2026-11-03 e kg-ssot 4.40.2, lista sem o `3ade85b7e1c0`, provenance `@d86aa63`), com o carimbo e o vendor
  reais: o helper sai rc 0, e o label e a narrative ficam **byte a byte iguais** à cura à mão do commit `21af2d9`
  da curadoria. A provenance difere só no `@a44e101`, que o motor não tem como saber (o commit ainda não existe), e
  no `method`. 2ª rodada: nada muda. Radar `--integrity --schema` rc 0. O contrato acusa só o `external_edges`
  (a cópia está fora do corpus da curadoria) e SHOULD de outros nós.
- Cópias dos 17 grafos de adoção locais, com um pin novo fictício: 13 seguem como antes (seed ou troca do token);
  a curadoria é refeita; `gmill` (2 cópias) e `meugmill-vendas` passam a ser **recusados** (rc 4), porque o label
  deles traz "ATUALIZADO de … em 2026-10-05" e "atualizado em 2026-10-21", que a troca só do pin deixava velhos.

## Mutantes

Cada guarda nova, desligada, derruba o desvio que ela segura em (i6):

| mutante | o que desliga | desvio que aparece |
|---|---|---|
| refaz | o ramo do molde de update | `a:label-nao-refeito` |
| pin-que-sai | a inserção do pin que sai na lista | `a:lista-sem-o-pin-que-saiu` |
| sem-duplicar | o teste de já-presente na lista | `b:lista-com-o-pin-2-vezes` |
| provenance | a reescrita da provenance | `a:provenance-source-velha` |
| recusa-label | a recusa do label no molde com token fora dele | `c:label-fora-do-molde:rc=` |
| recusa-narrative | a recusa da narrative fora do molde | `c:narrative-fora-do-molde:rc=` |
| recusa-vendor | a recusa sem a versão medida (o mutante inventa `0.0.0`) | `c:vendor-sem-versao:rc=` |
| recusa-marcador | a recusa do label do dono com dado do update | `c:label-do-dono-com-data-do-update:rc=` |

Bancada: `adopter_shape` e `write_stamp` verdes, com os oito mutantes reprovando.

## Achados

(pendente: a passada adversarial)

## Limites declarados

- A recusa fora dos moldes é por **vocabulário** (`update de`, `atualizado em/de/para`, `kg-ssot`, `contrato v`).
  Um dado do update escrito com outras palavras segue a troca só do token, como antes.
- Os mutantes `recusa-label` e `recusa-narrative` caem por exceção do Python (rc 1), não por escrita: o caso mede
  rc 4 exato e grafo intacto, então pega os dois, mas não distingue "quebrou" de "escreveu".
- O label da semente (sem data nem kg-ssot) não é convertido para o molde de update: segue trocando só o pin, que
  é tudo o que ele carrega.
- O `write-stamp.sh` segue saindo rc 0 quando o helper recusa: o carimbo já foi escrito, o aviso diz o rc 4, e a
  REGRA 108 (Pin do grafo de adoção concorda com o carimbo) cobra o `x_pin` velho como HARD no lint seguinte.
