---
title: "Resíduo da passada adversarial — o selo do maestro e a guarda reprovada duas vezes"
date: 2026-09-06
branch: fix/kg-yaml-validity-ratchet
reviewed_diff_sha256: 0935af6c8faeef9f0865136bd8f7766a61224b3e6dd4a6ed3b877bc5d97773c6
findings_total: 21
findings_real: 19
tokens: 317211
duration_min: 20
verdict: REPROVADO-E-CURADO
kg: docs/onion/graph/onion-plugin-publication-2026-08.kg.yaml
---

# Resíduo da REGRA 56 — dois revisores, dois REPROVADO, e o gate verde o tempo todo

Dois workers adversariais (opus, mandato de REFUTAR) atacaram lentes diferentes: **a catraca nova** e
**o selo no grafo**. Os dois voltaram REPROVADO com o lint em 0 HARD e a bancada em 1084/0.

## A lição que atravessa tudo: medir no caminho errado não é ter medido

Eu concluí, e **escrevi em comentário de código**, que a guarda nova derrubava o lint quando falta
PyYAML. A medição que me convenceu estava viciada: eu rodava uma **cópia** do lint em `/tmp`, o que
muda `SCRIPT_DIR` e desvia o caminho inteiro do programa. Medido in-tree nos dois lados — worktree de
`origin/main` e a branch — os dois abortam **igualmente** logo após a REGRA 39.

O achado real é maior e **pré-existente**: sem `python3`, o lint morre antes do sumário. Quem lê vê
VIOLATIONs e nenhum veredito; quem automatiza pelo `rc` vê `1`, que é o mesmo de "há HARD". *"A guarda
não rodou"* e *"a guarda reprovou"* ficam indistinguíveis. Registrado como
`Q_LINT_ABORTA_SEM_PYTHON_E_NAO_DIZ`, com gatilho.

É a segunda vez nesta sessão que a mesma classe me pega — a primeira foi exportar `CLAUDE_PLUGIN_ROOT`
à mão e chamar aquilo de "prova por execução".

## Revisor 1 — a catraca da REGRA 78

| achado | o que passava | cura |
|---|---|---|
| **fiação engolia o `exit 2`** | `2>/dev/null \|\| true`: a regra não rodava e o gate dizia limpo | rc lido; vira violação `NAO-VERIFICADO` |
| **catraca não era catraca** | baseline crescia com uma linha apendada; único sinal era um SOFT que ninguém compara | `CATRACA-VIOLADA` vs `origin/main` |
| **`git` ausente / raiz não-git** | virava SOFT verde "nada a validar" — três situações fundidas num sinal | exit 2 fail-closed; raiz normalizada ao toplevel |
| **`split()` nos nomes** | espaço estilhaçava, não-ASCII chegava CITADO (`core.quotePath`): HARD falso **e** cobertura zero no arquivo real | `git ls-files -z` direto no python |
| **I/O como veredito** | arquivo apagado-no-índice virava "não é YAML válido" | `OSError` separado → SOFT `ILEGIVEL` |
| **`--format` no fim** | `shift 2` falhava e o laço girava para sempre, mudo | aridade validada |
| **`emit` + `format`** | a ORDEM decidia o modo, em silêncio: gravava violações onde ia baseline | modos exclusivos, exit 2 |
| **bancada decorativa** | ela AFIRMAVA exercitar `--format tsv` e assertava com grep que casa nos dois formatos | caso conta **4 campos por TAB**; outro casa **linha inteira** no baseline |

Os dois mutantes que o revisor mostrou **sobrevivendo** (apagar o ramo `tsv)` do `_out`; trocar
`grep -qxF` por `-qF`) agora **morrem**. O `-z` rendeu um defeito próprio no caminho: **NUL não passa
por variável** — `$( )` do bash descarta bytes nulos, e a 1ª tentativa colou 121 caminhos num nome só
("File name too long"), reportando UM `ILEGIVEL` gigante e **exit 0**.

## Revisor 2 — o selo no grafo

- **Reescrevi o label de um nó selado.** A doutrina do `/meta:kg-freshness` proíbe em letra: *"Nunca
  reescreva o label do antigo"*. Label original **restaurado**; a metade que sobrevive (a precondição
  do `rc=11`, nunca refutada) virou nó próprio, `C_PRECONDICAO_INTEGRACAO_SOBREVIVE`. E o carimbo
  velho cobrindo texto novo (`verified_at: 2026-09-05` sob label datado 09-06) desaparece junto.
- **Apaguei uma aresta alegando que ela partia de nó refutado.** Refutado pelo próprio motor: o radar
  ignora superador morto por desenho (`supersederConta`), e com a aresta de volta a reconciliação
  fecha `✅` — **custo zero de ruído**, medido. Apagar feria o append-mostly e rebaixava fato
  legível-por-máquina a prosa. **Restaurada.**
- **"14 pares em 7 arquivos" não reproduzia.** O revisor achou 9/4; minha recontagem, 13/5. Três
  parsers, três números — e isso **é** o argumento da REGRA 78: a verdade das arestas do corpus depende
  do parser. Agora o número vem de um script reproduzível (`conta.py`, PyYAML sobre `git ls-files`),
  com o que ele **não** leu declarado: **13 pares em 5 arquivos**, 4 grafos não contados por serem
  ilegíveis.
- **A recusa de mecanizar estava errada no recorte.** A classe LARGA ("superador refutado") é
  majoritariamente escada de Elenxo legítima — ali guarda seria ruído. A classe ESTREITA ("superado sem
  NENHUM superador vivo") é outra coisa: **17 de 211 (8%) em 7 arquivos**, e o discriminador já existe
  no radar. Virou `Q_SUPERADO_SEM_SUPERADOR_VIVO_MERECE_GUARDA`, com gatilho — não guarda apressada,
  não recusa mal-fundamentada.
- **O nó do selo era `evidence` carregando decisão.** Agora é `decision`, e as duas afirmações minhas
  que caíram estão escritas nele.

## O que a restauração da aresta expôs (não estava no escopo de ninguém)

O radar ignora superador morto; o **realign não**. O mesmo grafo dava `✅` no radar e `REALINHAR` no
realign, e um alvo legitimamente reaberto sob superador que caiu virava drift tipo-(c) **permanente** —
duas doutrinas na mesma casa, sobre o mesmo arquivo, exatamente o defeito que o comentário do próprio
radar nomeia.

A 1ª cura foi **no-op silencioso**: li o status do `--freshness-tsv`, que **omite nó de atenção zero**,
e atenção zero é precisamente todo `refuted` — ou seja, o superador morto é quem falta ali. Só a
medição de raio de alcance ("0 de 90 grafos mudaram, inclusive o que devia mudar") pegou. Daí o feed
novo `--status-tsv`, aditivo. Com ele: **1 de 90 grafos muda**, e é o caso alvo. O par de fixtures
`superseder-morto`/`superseder-vivo` existe porque a cura podia ter silenciado a camada 1 inteira.

## Placar

| | antes | depois |
|---|---|---|
| casos da família `kg_yaml_validity` | 7 | **14** |
| mutantes sobreviventes na guarda | 2 | **0** |
| casos da família `realign` | 6 | **8** + 2 asserções de completude do feed |
| bancada total | 1084 | **1095** |
| afirmações minhas derrubadas e registradas | — | **4** (aresta, label, contagem, "guarda nasceria vermelha") |

**Veredito:** REPROVADO nas duas passadas, curado em 17 dos 19 achados. Os 2 não curados são
`ANOTAR` declarados: `regen-baselines --auto` não reconhece a forma de chave deste baseline (inócuo, o
caminho de emissão funciona e foi provado em sandbox de adotante) e o escopo de `--only` herdado dos
irmãos. Ambos ficam nomeados aqui em vez de silenciados.

## Adendo — o CI achou o que a bancada local não podia achar

O caso `regen-baselines: relatório` monta o sandbox com `git archive HEAD`: antes do commit, o emissor
novo **não existia no HEAD**, então ele nunca era exercitado ali. Depois do commit, foi — e reprovou.
Duas causas: o sandbox **não era um repo git** (adoção só existe sobre git; emissor nenhum reclamava
porque nenhum precisava dele até o meu) e a asserção contava **duas das três** formas de linha do
relatório.

E isso derrubou o meu próprio `ANOTAR` do C1: o filtro de baseline era cego a chave **sem separador**.
`path<TAB>contagem` e o **caminho nu** passavam inteiros, e **o adotante herdava a dívida do core** —
`kg-yaml-validity` 4→0 e `pipe-verdict` **24→15** depois da cura, ou seja, 9 chaves estrangeiras
sobreviviam em todo adotante sem que ninguém visse. Não era inócuo: inflava a métrica de saúde para
sempre. Caso de bancada com as quatro formas na mesma baseline, e o mutante que devolve o
comportamento antigo reprova.
