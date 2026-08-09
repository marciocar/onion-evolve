---
branch: feat/regra59-modo-consumido
date: 2026-08-09
reviewed_diff_sha256: 3b160a11859372386f3a0ec0c53e15281a812e20dab4a840ee87c0f0d6949175
findings_total: 29
findings_real: 12
findings_fixed: 9
tokens: 725035
duration_min: 55
verdict: HARD-MAS-NAO-COMO-ESTAVA-A-ISENCAO-POR-DELEGACAO-MATAVA-UMA-REGRA-HARD
reviewer: Elenxo — 2 lentes × 2 refutadores + juiz (opus/high, juiz em max), wf_ec07ce39-714
---

# W4 · o instrumento se provou contra mim três vezes antes de virar regra

O plano deste ciclo mandava, em letra grande: **`consumed-mode-check.sh` → apagar, não ligar.**
*"Instrumento não-ligado, não-testado, com achado aberto contra si. Ligar guarda que já se sabe cega
é como a casa produz falso-verde."*

**Rodá-lo refutou o próprio plano, por execução.** É o mesmo movimento que produziu os achados das
duas rodadas anteriores: revisar o alinhamento **contra a fonte**, não contra o documento.

## As três vezes que ele acusou algo meu

1. **Antes de eu ligá-lo**, rodado à mão: `31 pares de produção, 5 sem teste`, todos nomeados. Um
   deles era **`kg-backlog-check.sh [--format tsv]`** — o modo que o **lint** consome do script que
   eu mergeara na véspera (REGRA 58), enquanto a bancada chamava o helper **sem** a flag. O caminho
   que de fato barra o merge nunca fora exercitado.
2. **O juiz do Elenxo anterior** o rodou independentemente e chegou ao mesmo `rc=1`, citando o mesmo
   par — terceira confirmação, por um caminho que não era meu.
3. **Na primeira corrida depois do wire-in**, a REGRA 59 acusou **o buraco que ela mesma criou**: ao
   ligar, o lint passou a invocar `consumed-mode-check --format tsv`, e a bancada só o chamava com
   `--selftest`. Um detector que não se cobre no modo que o gate usa **é a definição do que ele
   caça**.

## O bloqueio real era o parse

```
${1:-$(dirname ...)/../..}   →  cd --selftest  →  "repo_root inválido", exit 2
```

O script que existe para achar **modo sem teste** não conseguia rodar o próprio teste. Agora o
posicional é o primeiro argumento que **não** começa com `-`, e as quatro invocações
(`<sem flag>`, `--format tsv`, `--list`, `--selftest`) funcionam.

## A ordem, e por que ela não era cerimônia

Escrita no grafo antes de começar e cumprida:

```
--selftest  →  bloco na bancada  →  fechar os 5 modos  →  SÓ ENTÃO o wire-in
```

Ligar antes teria feito o CI reprovar **por dívida pré-existente**, não por regressão — e gate que
reprova de cara por dívida velha é gate que se aprende a desligar.

O detector se prova em 4 casos: modo coberto → silêncio · descoberto → **acusa nomeando script E
flag** · mesmo script com flag **diferente** ainda acusa · fonte ausente → `exit 2`.

O terceiro é o que carrega o valor: **o par é `(script, flags)`, não o script**. Distinguir
`--markdown` de `(sem-flag)` é o instrumento inteiro; sem ele, "exercitar o script com qualquer
flag" passaria.

## Os 5 modos, fechados com asserção — nunca com invocação vazia

Chamar o modo só para satisfazer o detector transformaria o instrumento num **contador de
invocações**, e teste que não pode falhar é ruído. Cada caso afirma algo:

| modo | o que o caso assere |
|---|---|
| `inventory.sh --markdown` | emite **tabela** — o formato que a REGRA de SSOT compara |
| `kg-backlog-check --format tsv` | **cala** no verde (o lint trata vazio como conforme) e emite **TSV tabulado** no vermelho |
| `kg-view` sem flag | o default **é** `--markdown` — um default que mude de forma quebra a REGRA 31 sem tocar em flag |
| `migalhas-generate --check` | **não escreve no repo** (verificar ≠ gerar) — medido pelo estado da árvore |
| `migalhas-generate` sem flag | roda no modo que a produção invoca |

## O que a bancada pegou de mim, e estava certa

O mutation test `(p)` reprovou: *"o mutante sem o filtro ainda satisfaz o caso (l)"*. Verdade — minha
cura de **ordem** (abaixo) passou a cobrir aquele caso sozinha, e os dois filtros se sobrepunham ali.
O `(l)` deixou de **isolar** o `unquoted`. Reapontado para um caso onde só ele salva: `|` entre aspas
**antes** do `$?`.

## A 4ª classe de falso-positivo da guarda do shell

Achada **por uso**, nesta sessão:

```bash
echo "lint rc=$?" >> "$O"; grep -E '...' arquivo | head -4
```

O `$?` é do comando da linha **anterior** e o pipe vem **depois** dele. A heurística só via *"há `$?`
e há `|` na mesma linha"*. Agora o pipe da própria linha só conta se estiver **antes** do `$?`; o da
linha anterior segue contando sempre, porque lá ele é necessariamente anterior.

Par `(q)`/`(r)`, como a doutrina do arquivo exige — e é a **quarta** classe dela curada por uso.

## E a guarda de estabilidade me pegou duas vezes

`⚠ MUDOU DURANTE A MEDICAO` — eu editava `lint-selftest.sh` **enquanto a bancada o executava**.
Bash lê o script por offset de byte. A guarda (nascida na rodada anterior, dessa mesma lição) fez o
trabalho: recusou o número em vez de reportá-lo. **Guarda que nasceu de um erro meu, pegando o mesmo
erro meu, duas rodadas depois.**

## W3 · medido, e a medição QUALIFICA o item

| afirmação do nó | medido em `srv1812846` |
|---|---|
| credenciais WAHA legíveis via `docker inspect` | **verdade** (`Config.Env` de `onion-vps-waha` tem as duas) — **mas o raio é root**: socket `660 root:docker`, grupo `docker` **vazio**, `marcio` e `granaai` **negados** ao tentar |
| `bypassPermissions`: contenção é de processo | **confirmado, com especificidade nova** — o bridge roda como `onion` (não root), mas `NoNewPrivileges=no` e `ProtectHome=no`: a contenção existe e é **parcial** |

O teste foi **tentar ler**, não inferir dos bits — é a mesma correção de método que hoje já derrubou
um alarme falso meu sobre os `.env.bak` do bridge.

`impact` rebaixado **5 → 4 por medição**, com o motivo escrito no nó. Rebaixar sem medição seria a
`FUGA-DE-ESCOPO` da própria catraca, cometida na autoria.

**Nada foi executado em produção.** Tirar as credenciais do env exige **recriar o container**, o que
interrompe ferramenta viva. A superação barata e reversível de (2) — drop-in com
`NoNewPrivileges=yes` + `ProtectHome=yes`, que é restart e não recriação — fica **sugerida**.

## Verificação

- bancada **759 passam / 0 falham / 0 pulam**, **artefato ESTÁVEL** (sha antes = sha depois)
- lint **0 HARD** + 4 SOFT pré-existentes · REGRA 59 classificada e projetada em `lint-rules.md`
- detector: **31 pares de produção, 0 sem teste** · `--selftest` **4/4**
- guarda do shell: **5/5** nas cinco direções (o falso-positivo de ordem cala; os quatro casos
  fundadores gritam)
- backlog **18/20**, nenhum `done` sem carimbo · radar do grafo verde

## A passada adversarial — 3 de 4 refutadores disseram `CAI`

**29 achados brutos → 12 sobrevivem.** Veredito: **«HARD, mas NÃO como está.»** O juiz refutou
explicitamente um medo meu (*"a contagem está CORRETA — a process substitution funciona,
`HARD_COUNT` sobe 7→8; não há eco do defeito da REGRA 58"*) e confirmou que a concepção está certa.
O que estava errado era cirúrgico — e o pior era grave.

### O pior: a isenção por delegação MATAVA uma regra HARD, hoje, no core

Emudecendo **só o ramo `tsv`** do `ladder-integrity-check.sh` — o modo que a produção consome:

```
--selftest do ladder :  8/8 VERDE
REGRA 59             :  rc=0, par COBERTO
classe forjada       :  o lint DEIXA de acusar  →  8 HARD viram 7
```

**A regra que existe para pegar *"o modo consumido diverge do modo testado"* declarava cobertura
exatamente sobre o par onde isso estava acontecendo.**

A isenção vinha de um raciocínio honesto e errado, e eu o escrevi no código: *"não dá para saber
daqui se o `--selftest` embutido cobre o modo tsv, e acusar sem medir é o erro que esta regra caça"*.
Mas **o oposto de acusar-sem-medir não é absolver-sem-medir — é declarar que não se sabe.** Absolver
por ignorância é o fail-open que o P0 da REGRA 30 proíbe, com a agravante de o teto estar escrito no
comentário e ninguém o ler ao ver o ✅.

**Removida.** Os três pares que viviam dela ganharam caso explícito: `(0)` o próprio detector,
`(0c)` o ladder — **com a classe forjada, provando que o ramo `tsv` não é mudo**, que era exatamente
a mutação que passava —, e `(0d)` o `kb-vendored-link`. Cobertura **provada** substitui cobertura
**presumida**: `32 pares · 0 sem teste · 0 por delegação`.

### O segundo: eu ceguei o modo-de-falha fundador da guarda

```
ls | wc -l; echo "rc=$?"      main DISPARA  ·  o commit do PR CALA
```

Pipe real, `$?` **entre aspas**, mesma linha. Causa: eu lia **os dois** em `nu`, e `unquoted()` apaga
o `$?` junto com as aspas. A assimetria certa: **`|` entre aspas é texto; `$?` entre aspas ainda é
leitura.** O pipe se lê em `nu`, o `$?` na linha crua.

E o juiz apontou o que faltava mesmo depois de eu curar: **a cura estava desguardada** — ele mutou-a
de volta e a bancada passou 19/0. Agora há caso.

### O terceiro, e ele explica a corrente inteira

**O extrator é cego a prefixo de env.** `ALVO_ROOT="${tmp}" bash "${h}" --modo` some do lado
**teste**, porque a regra indireta pega o primeiro `${...}` da linha (o do prefixo), não o adjacente
ao `bash`. São 25 invocações da bancada invisíveis — e **0 na produção**, que não usa prefixo. A
cegueira é **assimétrica**, e assimetria produz falso-positivo.

Consequência medida pelo juiz: **duas das cinco acusações originais eram FALSAS.** A bancada já
exercitava `migalhas-generate` desde as linhas 804/819/826/832, em sandbox.

> falso-positivo em regra HARD → "cura" cerimonial → caso que **escreve no repo** e apaga outra
> regra HARD.

A ponta final dessa corrente eu também vivi ao curar: escrevi `(0d)` como `bash "${kbv}" ...`, o caso
**exercitou o modo**, a bancada passou 762/0 — e o detector **seguiu acusando o par**, porque não
resolve variável indireta. Reescrito em caminho literal.

### O quarto: a bancada escrevia no repo

O caso `(e)` rodava `migalhas-generate.sh` em **modo escrita contra a árvore real** e apagava o drift
que a REGRA 34 existe para pegar. As 6 invocações **pré-existentes** do mesmo gerador usam
`MIGALHAS_ROOT="${tmp}"`; só as minhas omitiam. E o `(d)` tomava a linha-base **depois** de já ter
invocado `--check` uma vez — media o delta entre a 2ª e a 3ª corrida, então um `--check` que escreve
passava. **Vácuo por ordem.**

Os dois foram para sandbox git de verdade. **Dano não ocorreu**: medi que nenhum arquivo de `site/`
entrou no diff e que `main` já estava verde no `--check`. O defeito era real; o estrago, não.

### Mais três, fechados

- **`rc=1` com stdout VAZIO era tratado como veredito** — e `rc=1` é também o código de abort do
  `set -e` do helper. Agora é `CONTRADICAO` HARD: *"saiu 1 (=há modo sem teste) e NÃO nomeou nenhum"*.
- **A isenção casava por SUBSTRING** (`grep -F`): `radar.sh` ficava coberto por
  `kg-radar.sh --selftest`. `-xF` fecha.
- **O `$?` que importa é o ÚLTIMO** — achado por mim, medindo: em `echo $?; ls | wc -l; echo $?` o
  `index()` pegava o primeiro (antes do pipe) e calava, enquanto o segundo lê o exit do `wc`.

## Dívida que fica, e ela é a raiz

- **O extrator não conta o que perde.** O juiz plantou 4 invocações, saiu **1 par**, e o rodapé disse
  *"0 flag dinâmica"* — o que **falsifica** a promessa escrita em letra grande no cabeçalho da REGRA
  59 (*"supressão CONTADA, nunca silenciosa"*). Pior: o rodapé inteiro está sob `if FORMAT != tsv`,
  então **no único modo que o gate invoca a supressão é invisível**.
- **Não há PISO.** Um refactor de estilo derrubou 32 → 11 pares e o veredito seguiu ✅ — a guarda de
  vacuidade só dispara em **zero exato**.
- **O prefixo de env** segue cego, e é o que produziu os dois falsos.

As três são a mesma família e pedem um ciclo próprio: **o extrator precisa de catraca de cobertura,
não de mais casos.** Não as forjei aqui porque meia-cura num extrator é como este PR nasceu.

## O que NÃO foi feito, declarado

- **As correções do Elenxo não foram re-auditadas** por uma segunda passada. As duas anteriores acharam 18 e 21 defeitos reais, e nas duas os
  piores eram fail-opens que eu **introduzi curando outra coisa**. O que substitui aqui é menos: o
  instrumento se provou contra mim três vezes, e a bancada pegou o `(p)` sobreposto. O que um
  refutador provavelmente atacaria: o extrator de pares é regex sobre `bash "${VAR}/script.sh"` —
  invocação por variável indireta ou por `eval` escapa, e o rodapé conta isso como *"flag dinâmica"*
  sem dizer **quais** invocações ficaram fora.
- **A REGRA 59 julga só `lint-artifacts.sh` × `lint-selftest.sh`.** Outros pares produção/teste do
  repo não entram. É escopo fechado por desenho (a lição do `kg-trace-resolve`), mas está declarado
  como teto, não como cobertura.
- **W3 continua aberto como compromisso** — a medição fechou, a execução é do maestro.
