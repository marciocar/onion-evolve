---
branch: feat/regra60-idioma-identificador
date: 2026-08-09
reviewed_diff_sha256: 8e7f64728310449b2ee1c305dc0d1e1d84dd534368cadb54bbf9d31949795153
findings_total: 25
findings_real: 11
findings_fixed: 7
tokens: 551632
duration_min: 49
verdict: FICA-COM-RESSALVA-O-MOTOR-ESTA-CERTO-E-EU-QUASE-O-DESCARTEI
reviewer: Elenxo — 2 lentes × 2 refutadores + juiz (opus/high, juiz em max), wf_da308fb9-98b
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

## A passada adversarial — e ela me impediu de descartar um instrumento que funciona

**Veredito: `FICA-COM-RESSALVA`.** E a parte que mais importa é o que o juiz **mediu** e eu não:

> **324 scripts em inglês de terceiros, 810 extrações, ZERO falsos** (com canário vivo). O motor está
> certo — lista sem homógrafo, split por segmento, baseline e wire-in são a parte sólida. O wire-in
> **conta de verdade** (HARD 7→8) e baseline ausente é **fail-CLOSED**. **Não mexa nisso.**
> Todo o defeito está em **três lugares locais**.

### Eu tinha fechado este PR

Reproduzi **um** modo de falha real — heredoc lido como declaração — e **generalizei dele para o
instrumento inteiro**: *"`grep` sobre linha é o instrumento errado"*. Fechei o PR.

Nunca produzi a evidência que a decisão exigia. O juiz produziu: **324 scripts, zero falsos.**
Reaberto.

É o mesmo erro que esta sessão passou o dia curando — concluir sobre o todo a partir de uma medição
parcial — cometido por mim **na hora de descartar**, que é onde ele custa mais caro.

### E a revisão de alinhamento pegou a segunda metade

Eu escrevi que *"o próximo ciclo começa com o diagnóstico completo"*. Medido: **zero menções no
grafo**, zero no resíduo, zero em `main`. O diagnóstico vivia nos **comentários do PR** — que é
literalmente `C_BACKLOG_DE_DOCUMENTO_ORDENA_ITEM_MORTO`, a tese fundadora deste backlog.

Pior: o nó do grafo **afirmava o veredito refutado** (*"fechado sem merge, 3 de 4 disseram CAI"*) por
horas depois de o juiz me desmentir. `declarado ≠ verificado` no meu próprio backlog.

## As quatro curas, todas medidas

**(a) Elidir o corpo das aspas ANTES de cortar comentário** — e cortar `#` só quando **inicia
token**. Mata **dois achados de uma vez**:

| dano | medido |
|---|---|
| string lida como declaração | **2 das 7** "dívidas" do baseline que eu gerei **não eram identificadores** — eram prosa pt-BR em mensagem, nascidas carimbadas como dívida. Script com identificadores 100% ingleses e mensagens pt-BR (o que a doutrina **manda**) levava **5 HARD** |
| `sed 's/#.*//'` decapitava a linha | em `$#`, `${v#pfx}` e `"#fff"` — o idioma de arg-parsing do próprio repo, **27 arquivos**. Três declarações pt-BR **legítimas** ficavam invisíveis |

**(b) Baseline regenerado depois: 7 → 4**, saindo os **dois fantasmas** mais o `alvoPendente` já
curado no #570. **Zero entradas novas.**

**(c) Universo = rastreado ∪ não-rastreado, com `exit 2` no vazio.** O pior caso é o adotante
recém-adotado: `/meta:adopt` instala `.claude/` **sem commitar**, então **51 scripts no disco, 0
rastreados**, e a guarda nascia **muda no dia 1 exibindo aprovação**. E o mesmo arquivo passava
`rc=0` antes do `git add` e reprovava depois — *"ocorrência NOVA é HARD"* é o contrato, e código novo
está untracked no instante exato em que o lint roda.

**(d) A fixture do caso `(e)` passou a conter declaração DENTRO do comentário** — sem isso o caso
**não podia falhar**: apagar o strip de comentário **inteiro** mantinha 7/7 verdes. Um caso que não
pode falhar não é teste, é ruído com cara de cobertura. Provado: íntegro `rc=0`, mutante `rc=1`.

## O que NÃO foi feito, declarado

- **As correções do Elenxo não foram re-auditadas** por uma segunda passada. As três anteriores desta sessão acharam 18, 21 e 12 defeitos reais, e
  nas três os piores eram fail-opens que eu **introduzi curando outra coisa**. O que substitui aqui
  é a própria bancada, que achou os três acima — inclusive um que invalidava metade da regra.
  O que um refutador provavelmente atacaria: o extrator é `grep` sobre linha e **não entende string
  multi-linha** (foi por isso que as fixtures precisaram ser montadas em pedaços — a cura foi no
  chamador, não no extrator); e a lista de 61 palavras é **manual**, sem nada que impeça alguém de
  acrescentar um homógrafo novo que o `(g)` não enumera.
- **O baseline não tem catraca de tamanho** — ele só encolhe por convenção escrita, não por gate.
