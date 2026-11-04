---
branch: fix/write-stamp-rebuilds-installed-node
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 10
tokens: 0
duration_min: 0
findings_fixed: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente opus separado
nota: "A passada adversarial separada sobre 2dc3e2573 confirmou o núcleo: o grafo real da curadoria sai igual à cura à mão, e as 13 cópias seguem sem regressão. Ela achou 10 problemas (3 médios de YAML ou lista quebrados com rc 0, 1 de nome de cliente, 6 baixos), todos curados no commit seguinte e provados nas sondas do revisor. Na cura apareceram dois a mais: o x_commit na provenance, que a lista de chaves de hash não pegava e virou lista de permissão, e a regressão da leitura de volta com safe_load nos grafos de dois documentos, curada antes do commit. tokens e duration_min são 0 = não medidos (o revisor foi um subagente de outra sessão)."
---

# Passada adversarial: `fix/write-stamp-rebuilds-installed-node`

## O que muda

Sinal do adotante onion-curation (2026-11-04, `docs/evolution/inbox/2026-11-04-signal-write-stamp-pin-only.md`),
4ª recorrência seguida, cada uma curada à mão: no `--update`, o escritor do pin no grafo de adoção
(`.claude/utils/kg/stamp-adoption-graph-pin.sh`, chamado ao fim do `write-stamp.sh`) trocava só o token do pin no
label do `ONION_INSTALLED` e o `x_pin`. A data e a versão da kg-ssot no label, a lista de pins anteriores na
narrative (que passava a omitir o pin que acabou de sair) e a provenance ficavam do update anterior.

- `.claude/utils/kg/stamp-adoption-graph-pin.sh`: reconhece o **molde de update** (label `Framework instalado: pin
  `X` (update de D, com o kg-ssot V e o contrato vC), modo `m`, papel `p`, integração `b`.` e narrative `Pins
  anteriores, do mais novo ao mais velho (…): `a`, …; a adoção foi `z`. …`). Nesse molde ele **refaz**:
  - o label, com o pin do carimbo, a data do `updated_at` do carimbo (o relógio só quando ele falta), a versão lida
    de `vendor/kg-ssot/.kg-ssot-version`, o `CONTRACT_VERSION` de `vendor/kg-ssot/tools/kg_validate.py`, e
    modo/papel/integração do carimbo (o valor do label só fica quando o carimbo não tem o campo);
  - a lista de pins: a anterior mais o pin que sai, na frente, sem duplicar, sem o pin novo e sem o pin da adoção.
    O cabeçalho e o resto da narrative ficam como o dono escreveu;
  - a provenance: `source`, `locator` e `method` passam a citar o carimbo novo. O `@<commit>` do adotante sai,
    porque o commit do update ainda não existe quando o motor roda.
- O mesmo helper **recusa** (rc 4, nada escrito no grafo, a mensagem diz o porquê e o molde) quando:
  - o label começa no molde de update e não casa com ele inteiro, ou a narrative está fora do molde;
  - a versão da kg-ssot ou o contrato não foram medidos no vendor;
  - um label editado fora dos dois moldes traz dado do update (`update de`, `atualizado em/de/para`, `kg-ssot`,
    `contrato v`);
  - modo, papel ou integração do carimbo trazem aspa, barra, crase ou quebra de linha;
  - o `x_pin` e o pin do label divergem;
  - a provenance não está em bloco, ou traz chave fora de `source`/`locator`/`method`/`locality`;
  - o documento novo não passa na leitura YAML de volta (o nó relido com o `x_pin` escrito).
- `.claude/utils/adopt/write-stamp.sh`: o aviso do rc do helper nomeia o rc 4.
- `.claude/validation/lint-artifacts.sh`: a mensagem HARD da REGRA 108 (Pin do grafo de adoção concorda com o
  carimbo) diz que, se o escritor sair rc 4, o conserto do label é à mão.
- `.claude/validation/lint-selftest.sh`: caso (i6) e 18 mutantes na família `adopter_shape`, a que já testa o
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
  (a cópia está fora do corpus da curadoria) e SHOULD de outros nós. Refeito depois das curas da revisão: igual.
- Cópias dos 17 grafos de adoção locais, com um pin novo fictício: 13 seguem como antes (seed ou troca do token);
  a curadoria é refeita; um hub (o `hub-operacoes-enterprise` do `members.yaml`, em duas cópias) e outro adotante
  passam a ser **recusados** (rc 4), porque o label deles traz a data do update anterior ("ATUALIZADO de … em
  2026-10-05" e "atualizado em 2026-10-21"), que a troca só do pin deixava velha. O aviso a eles fica com o core,
  depois do merge.
- As 18 sondas do revisor (`p_*`), re-rodadas com o helper curado: cada forma que saía rc 0 com o YAML quebrado ou
  a lista errada agora sai rc 4 com o grafo intacto; as formas válidas (unicode na branch, carimbo entre aspas,
  sem integração, sem x_pin, sem provenance, rollback, pin da adoção) saem rc 0 com YAML válido.

## Mutantes

Cada guarda, desligada, derruba o desvio que ela segura em (i6):

| mutante | o que desliga | desvio que aparece |
|---|---|---|
| refaz | o ramo do molde de update | `a:label-nao-refeito` |
| pin-que-sai | a inserção do pin que sai na lista | `a:lista-sem-o-pin-que-saiu` |
| sem-duplicar | o teste de já-presente na lista | `b:lista-com-o-pin-2-vezes` |
| provenance | a reescrita da provenance | `a:provenance-source-velha` |
| recusa-label | a recusa do label no molde com token fora dele | `c:label-fora-do-molde:rc=0` (escreve: morde pelo motivo certo) |
| recusa-narrative | a recusa da narrative fora do molde | `c:narrative-fora-do-molde:rc=1` (AttributeError: mede o contrato de rc) |
| recusa-vendor | a recusa sem a versão medida (o mutante inventa `0.0.0`) | `c:vendor-sem-versao:rc=0` |
| recusa-contrato | a recusa sem `CONTRACT_VERSION` (o mutante inventa `0.0`) | `c:vendor-sem-contrato:rc=0` |
| recusa-marcador | a recusa do label do dono com dado do update | `c:label-do-dono-com-data-do-update:rc=0` |
| recusa-aspa | a recusa de aspa/barra/crase/quebra no carimbo | `c:carimbo-com-aspa:motivo` (a leitura de volta segura, com outro motivo) |
| recusa-x_pin | a recusa de x_pin e pin do label divergentes | `c:x_pin-divergente:rc=0` |
| recusa-inline | a recusa da provenance fora de bloco | `c:provenance-inline:motivo` (a leitura de volta segura, com outro motivo) |
| recusa-chave | a lista de permissão das chaves da provenance | `c:provenance-com-hash:rc=0` |
| leitura-de-volta | a recusa do documento que não lê como YAML | `c:yaml-que-nao-le:rc=0` |
| data-do-carimbo | o `updated_at` como data do label | `d:data-nao-e-a-do-carimbo` |
| rollback | a retirada do pin novo da lista | `e:pin-novo-ficou-na-lista` |
| pin-da-adocao | o "não inserir o pin da adoção" | `f:pin-da-adocao-entrou-na-lista` |

Bancada: `adopter_shape` verde, (i)–(i5) inclusive, com os 18 mutantes reprovando; `review_ledger` verde.

## Achados

Passada adversarial separada (subagente opus) sobre `2dc3e2573`. Cada citação foi conferida no código antes da cura.

| # | sev. | achado | cura |
|---|---|---|---|
| 1 | médio | modo, papel e integração entravam sem escape no label entre aspas; com `"` no carimbo, rc 0 e YAML quebrado | recusa (rc 4) com aspa, barra, crase ou quebra; um par de aspas em volta do escalar sai; o label refeito tem de casar com o molde; leitura YAML de volta antes do `os.replace` |
| 2 | médio | provenance inline (`{…}`) ou `null` ganhava filhos, rc 0 e YAML quebrado | exige `    provenance:` em bloco, recusa o resto; a leitura de volta cobre também |
| 3 | médio | no molde de update, x_pin e pin do label divergentes faziam a lista perder um pin sem aviso (forma de campo, em duas cópias de um hub) | recusa quando os dois existem e divergem |
| 4 | médio | nome comercial de cliente no resíduo de um repo público | trocado pelo id neutro do `members.yaml` e por "outro adotante" |
| 5 | baixo | a guarda da versão era um `assert`, que some com `PYTHONOPTIMIZE` | `if not re.fullmatch(...): refuse(...)`; provado com `PYTHONOPTIMIZE=1` (rc 4); a leitura de volta também usa `if` |
| 6 | baixo | o resíduo dizia que `recusa-label` caía por exceção; ele escreve com rc 0 | texto corrigido; o mutante de narrative aceita só `rc=1` e o de label só `rc=0` |
| 7 | baixo | rollback, "não inserir o pin da adoção" e recusa sem `CONTRACT_VERSION` sem caso nem mutante | casos (e), (f) e `vendor-sem-contrato`, com os mutantes `rollback`, `pin-da-adocao` e `recusa-contrato` |
| 8 | baixo | a mensagem HARD da REGRA 108 mandava re-carimbar pelo escritor, que recusa de novo | a mensagem cita a recusa rc 4 e o conserto à mão do label |
| 9 | baixo | a data do label vinha do relógio | `updated_at` do carimbo; o relógio só quando ele falta; caso (d) e mutante |
| 10 | baixo | chaves de hash da provenance (`sha256`, `node_sha256`, `scheme`) ficavam velhas | recusa; e como a sonda do revisor trouxe também um `x_commit` velho, a guarda virou LISTA DE PERMISSÃO (`source`, `locator`, `method`, `locality`) |

Dois achados da própria cura, curados antes do commit:

- A 1ª leitura de volta usava `yaml.safe_load`, e o dogfood nas 17 cópias mediu **sete adotantes recusados** que
  antes eram carimbados: a semente antiga abria e fechava o cabeçalho com o separador de documento, e o grafo
  deles tem dois documentos. Agora é `safe_load_all`, e um grafo que já não lia antes só é recusado no molde de
  update.
- A guarda do achado 10, como lista de bloqueio, deixava passar o `x_commit` da sonda `p_prov_extra_key`.

## Limites declarados

- A recusa fora dos moldes é por **vocabulário** (`update de`, `atualizado em/de/para`, `kg-ssot`, `contrato v`).
  Um dado do update escrito com outras palavras segue a troca só do token, como antes.
- `recusa-aspa` e `recusa-inline` são guardas com reforço: sem elas a leitura de volta ainda recusa, com outro
  motivo. O caso as distingue pelo motivo na mensagem.
- Sem PyYAML, a leitura de volta só é obrigatória no molde de update (lá o motor recusa); nos caminhos antigos ela
  é pulada, como era antes.
- O `field()` do `write-stamp.sh` (l.94) segue sem tirar aspas do valor: aqui o helper tira um par de aspas em
  volta e recusa o resto, mas o carimbo regravado pelo `write-stamp.sh` não foi tocado.
- O label da semente (sem data nem kg-ssot) não é convertido para o molde de update: segue trocando só o pin, que
  é tudo o que ele carrega.
- O `write-stamp.sh` segue saindo rc 0 quando o helper recusa: o carimbo já foi escrito, o aviso diz o rc 4, e a
  REGRA 108 cobra o `x_pin` velho como HARD no lint seguinte, agora com o caminho do conserto à mão.
