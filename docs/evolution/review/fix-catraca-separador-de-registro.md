---
branch: fix/catraca-separador-de-registro
date: 2026-08-08
reviewed_diff_sha256: 89c88db3875fd366182e74f12ff4100f978baa40bad76a9c2dbc0e48a6e3887d
findings_total: 8
findings_real: 6
findings_fixed: 5
tokens: 317360
duration_min: 18
verdict: HARD-MAS-NAO-COMO-ESTAVA-NADA-CAI-NO-RUNTIME-CAI-NO-TEXTO
reviewer: Elenxo — 2 refutadores por lente + juiz (opus/high), wf_5bbc340d-c78
---

# Passada adversarial — a migração resistiu, o texto não

**2 lentes, 8 achados. As duas lentes SUSTENTARAM a tese.** Veredito do juiz:
**«HARD, mas NÃO como está — nada cai no runtime; cai no texto, dentro de um gate cuja razão de
existir é cobrar que o declarado seja medido.»**

## O defeito, e por que era regressão e não dívida herdada

A catraca passa registros **internos** entre funções shell/awk usando TAB. **TAB é IFS-whitespace**:
com `IFS=$'\t' read`, runs de separador colapsam e **campo vazio SOME**, deslocando os seguintes.

Reproduzido em par, no cenário exato:

```
ANTIGO:  HARD FUGA-DE-ESCOPO · "SEM carimbo (… status:2026-08-08)"
NOVO:    SOFT CARIMBADO      · "foi MEDIDO (verified_at: 2026-08-08)"
```

A guarda acusava de **fugir** justamente quem tinha acabado de **medir e carimbar** — o ato que ela
existe para premiar. O script anterior à catraca nova emitia SOFT no mesmo caso: **regressão**.

**A migração:** 10 sítios internos passam de `\t` para `\037` (US). O **TSV de saída continua `\t`**,
porque é contrato externo — o `lint-artifacts.sh` agrega a classe PASSIVO por ele.

## O que a lente verificou, e que eu não teria verificado sozinho

- **matriz de mutação nos 10 sítios**, um por vez de volta para TAB: **todos load-bearing**. O mais
  fraco derruba 2 casos; os demais, de 9 a 15. Nenhum sítio migrado é morto ou não-testado.
- **contrato externo byte-idêntico** ao `main` nos três modos (`--format tsv`, human,
  `--emit-baseline`), com o parse **exato** do `lint-artifacts.sh` rodado sobre a saída nova: 48
  PASSIVO agregados, zero US vazando.
- **portabilidade**: `gawk 5.2.1`, `mawk` e `busybox awk` emitem e separam por `\037`, e as três
  preservam o campo vazio do meio. `cut -d$'\037'` idem em GNU e busybox.
- **TAB no conteúdo não é vetor**: o scanner usa FS default do awk, que já quebra em TAB — um `id`
  com TAB sai truncado e nenhum TAB chega à saída. Igual antes e depois.
- **os irmãos não carregam o defeito**: `kg-trace-resolve.sh` já se defende do mesmo colapso por
  **outra via** (placeholder `-` para campo ausente).

E a lente registrou **dois fail-opens do próprio instrumento dela** — um `sed` quebrado que devolveu
"idêntico, 0 linhas", e um `cat -v` que não escapa TAB — detectados com controle positivo antes de
acreditar no resultado. É o padrão certo, e vale registrar.

## A cura é maior que o caso: o irmão que ninguém tinha visto

A lente achou uma **segunda instância latente**: nó com o campo `plane:` **ausente**. Não é fail-open
(HARD nos dois), mas a mensagem do `main` era **mentirosa** — `plane:5 impact:confirmed status:<vazio>`,
com os valores deslocados uma casa — e a nova é verdadeira. **Guarda cuja mensagem mente ensina a
ignorar a guarda**, que é a mesma família do falso-positivo. Virou o caso **(t2)**, e o par fecha os
dois únicos campos do registro que podem faltar.

## Três defeitos meus nesta rodada, todos da mesma família

**Um número sem comando.** Escrevi *"2.130 nós"* de memória; são **2159**. O comando que os conta foi
para dentro do comentário — número sem comando, no comentário de um caso que cura a REGRA 49, é a
própria 49 violada no instrumento.

**Um `git commit` vazio derrubou a suíte.** O `(t2)` recommitava conteúdo idêntico ao `HEAD`, saía 1,
e sob `set -e` o subshell matava tudo. É a **quarta** vez nesta sessão que esta família me pega.

**E o meu extrator estava com âncora morta.** O runner isolado devia carregar o trap anti-abort que
eu mesmo construí — mas renomeei `SUMARIO_IMPRESSO` para `SUMMARY_PRINTED` no rename para inglês e a
âncora do `sed` ficou stale. O trap não entrava, e o runner **mentiu de novo em vez de gritar**.
Corrigido. A lição: **rename que não re-roda o extrator quebra o instrumento em silêncio.**

## Verificação

- bancada **726 passam / 0 falham / 0 pulam**, corrida **SOLO** · bloco da catraca **16/16**
- reversão **consistente** dos 10 sítios (o mutante fica idêntico ao `main`): a bancada dá 1 FAIL, e
  o FAIL é o **(t)** — a evidência que discrimina, e é ela que está escrita no comentário, não o sweep
- corpus **48 · 48 · 0 HARD** · `lint-artifacts` 0 HARD

## Dívida declarada

- **Guarda estrutural anti-drift do separador** (~3 linhas): cobriria o 12º sítio que ninguém
  antecipa. `fix-must-become-mechanism` literal, e fica declarado em vez de feito porque a classe é
  maior que este arquivo — ver o fio abaixo.
- **A família tem DOIS idiomas para o mesmo problema**: `kg-trace-resolve.sh` resolve com placeholder
  `-`; esta branch resolve com separador US. **Ambos funcionam, e ninguém escolheu.** Escolher (ou
  declarar quando cada um vale) é o que impede a terceira invenção.
- **34 sítios `IFS=$'\t' read` em `.claude/validation/`** — nenhum com o bug vivo hoje, **nenhum
  protegido**. Todos dependem do invariante tácito *"campo do meio nunca é vazio"*. A guarda proposta
  cobre 1 arquivo; a classe é o diretório inteiro.
