---
branch: feat/regra60-idioma-identificador
date: 2026-08-09
reviewed_diff_sha256: 93debd6c66ded4a16955e8dca3ed2d27eb4725c57a5395fee250af5cf78e5de0
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-A-PROPRIA-BANCADA-ACHOU-OS-TRES-E-UM-DELES-INVALIDAVA-METADE-DA-REGRA
reviewer: sem passada adversarial — ver "O que NÃO foi feito"
---

# REGRA 60 — e a bancada achou que metade da guarda não funcionava

Sexta ocorrência da classe numa sessão (PRs #559, #562, #563, #565, #566 e um rename interno). Cada
vez eu renomeei, cada vez voltou — porque a cura era **disciplina**, e esta casa já mediu que o
gatilho eficaz de correção é **social**.

O desenho foi decidido **por medição no PR #568**, antes de existir uma linha de código. Este PR é a
execução daquele desenho — e a bancada encontrou três defeitos nele.

## 1 · O split camelCase nunca funcionou

```awk
gsub(/([a-z0-9])([A-Z])/, "\\1_\\2", s)     # awk POSIX NÃO tem backreference em gsub
```

O camelCase ficava **inteiro**; só o `_` separava. `semAspas` — **a forma exata dos achados reais** —
escapava. Metade da cobertura que a regra promete não existia.

**Quem pegou foi o caso `(c)`**, escrito justamente porque a medição do #568 mostrou que palavra
inteira pega 3 de 636 e segmento pega 10 de 12. Sem esse caso, a regra teria nascido cobrindo metade
do que anuncia, e o número do docstring seria falso.

Reescrito à mão, caractere a caractere.

## 2 · A bancada virou a maior fonte de violações da regra que ela testa

As fixtures inline continham linhas como `local contagem_de_erros=0` — **literais neste arquivo**. O
extrator as lia como declaração **real** do `lint-selftest.sh`.

Achado pelo caso `(a)`, que existe para que os outros não provem o nada. As fixtures passaram a ser
montadas **em pedaços** (`local $(printf 'contagem')_de_erros=0`), de modo que nenhuma linha do
arquivo *seja* uma declaração.

## 3 · A quarta vez que `x=$(cmd)` sob `set -e` matou a suíte

O caso `(g)` verifica que a lista **não** contém homógrafo. `grep` que **não acha** sai 1 — e não
achar é o **resultado desejado**. A suíte abortou sem sumário.

As quatro ocorrências desta sessão foram todas em casos onde **o silêncio do comando é a
conformidade**. É o padrão, não o acaso.

## O desenho, com o número ao lado de cada escolha

| escolha | por que, medido |
|---|---|
| por **segmento**, não palavra inteira | inteira pega **3 de 636**; segmento pega **10 de 12** históricos |
| lista **sem homógrafo** (`base`, `total`, `local`, `final`, `real` fora) | **0 falsos** nos substitutos em inglês que usei nos renames |
| **baseline** desde o nascimento | **7 residuais** anteriores à sessão → dívida SOFT, novo HARD, como a R49 e a R45 |
| **só identificador**, nunca comentário | a doutrina é código em inglês, **prosa em pt-BR** — e uma varredura minha à mão já errou assim no #565, acusando 48 "sobras" que eram todas comentário |

O `alvoPendente` só entrou no baseline **depois** de curar o camelCase — antes ele era invisível.
Isso é o defeito nº1 medido pelo seu efeito, não pelo argumento.

## Teto declarado

- **abreviação não é palavra**: `arq`, `donenu`, `qtd` escapam — são os 2 dos 12 que a medição do
  #568 já previa;
- **identificador dentro de programa awk embutido em string** não é lido pelo extrator;
- o baseline **só encolhe**; acrescentar entrada é regressão.

## Verificação

- bancada **772 passam / 0 falham / 0 pulam**, **artefato ESTÁVEL** · lint **0 HARD** + 4 SOFT
- 7 casos: `(a)` repo vivo passa · `(b)` novo é HARD nomeando o segmento · `(c)` camelCase quebra ·
  `(d)` inglês não acusa, inclusive homógrafo · `(e)` comentário pt-BR não acusa · `(f)` lista
  ausente é `exit 2` · `(g)` guarda-da-guarda: homógrafo na lista reprova
- baseline **7 tolerados, 0 HARD**; identificador novo em sandbox → **HARD**

## E a revisão de alinhamento achou um `drifted`

`Q_QUANTAS_DAS_52_REGRAS_JA_JUNTAM_SOZINHAS` classificou 26/26 contra **52 regras**; o lint tem
**58**. Mediu **certo** e o mundo andou — as 6 novas (55–60) nasceram depois e nenhuma foi
classificada. Marcado `drifted`, que é o status feito para isso e que **sobe** a atenção em vez de
zerá-la.

## O que NÃO foi feito, declarado

- **Sem passada adversarial.** As três anteriores desta sessão acharam 18, 21 e 12 defeitos reais, e
  nas três os piores eram fail-opens que eu **introduzi curando outra coisa**. O que substitui aqui
  é a própria bancada, que achou os três acima — inclusive um que invalidava metade da regra.
  O que um refutador provavelmente atacaria: o extrator é `grep` sobre linha e **não entende string
  multi-linha** (foi por isso que as fixtures precisaram ser montadas em pedaços — a cura foi no
  chamador, não no extrator); e a lista de 61 palavras é **manual**, sem nada que impeça alguém de
  acrescentar um homógrafo novo que o `(g)` não enumera.
- **O baseline não tem catraca de tamanho** — ele só encolhe por convenção escrita, não por gate.
