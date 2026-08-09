---
branch: feat/regra59-modo-consumido
date: 2026-08-09
reviewed_diff_sha256: a9c858185f769b4f6d9c9dec80dedef3b6c4596e6b9c5a76ff9e6243cd8b6258
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-O-INSTRUMENTO-SE-PROVOU-CONTRA-MIM-TRES-VEZES-ANTES-DE-VIRAR-REGRA
reviewer: sem passada adversarial — ver "O que NÃO foi feito"
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

## O que NÃO foi feito, declarado

- **Sem passada adversarial.** As duas anteriores acharam 18 e 21 defeitos reais, e nas duas os
  piores eram fail-opens que eu **introduzi curando outra coisa**. O que substitui aqui é menos: o
  instrumento se provou contra mim três vezes, e a bancada pegou o `(p)` sobreposto. O que um
  refutador provavelmente atacaria: o extrator de pares é regex sobre `bash "${VAR}/script.sh"` —
  invocação por variável indireta ou por `eval` escapa, e o rodapé conta isso como *"flag dinâmica"*
  sem dizer **quais** invocações ficaram fora.
- **A REGRA 59 julga só `lint-artifacts.sh` × `lint-selftest.sh`.** Outros pares produção/teste do
  repo não entram. É escopo fechado por desenho (a lição do `kg-trace-resolve`), mas está declarado
  como teto, não como cobertura.
- **W3 continua aberto como compromisso** — a medição fechou, a execução é do maestro.
