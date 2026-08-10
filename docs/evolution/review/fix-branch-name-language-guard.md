---
branch: fix/branch-name-language-guard
date: 2026-08-10
reviewed_diff_sha256: 4419d3e995c58ff6a718ec6caa3cd6539256661e3a6ac931dc3349b0f8496d78
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: TRES-DEFEITOS-ACHADOS-PELA-MATRIZ-E-PELO-DIAGNOSTICO-ANTES-DO-EMBARQUE
reviewer: matriz de 10 casos + par de mutação + repro isolada do clobber de trap; sem passada adversarial externa
---

# A guarda de nome de branch — e as três coisas que ela quase escondeu

## O gatilho

O revisor do #575 acusou `code-standards.md:39`: **branch em inglês**. Eu havia nomeado
`fix/fixture-nao-depende-do-vivo` e `docs/waha-rotacao-e-hash` na mesma sessão. O levantamento do repo
mostrou que não é lapso: `docs/fios-abertos`, `fix/catraca-duas-portas`,
`fix/catraca-separador-de-registro`, `fix/selo-m8-vereditos`.

## Por que na hook, e não no lint

O lint roda no **commit** — e ali renomear já custa caro: a branch nomeia o PR e o próprio resíduo da
REGRA 56. Acusar nesse ponto seria **punir quem já não pode corrigir barato**, que é exatamente o erro
da REGRA 56 que ensinou 23 bypasses numa sessão. O instante em que a correção é grátis é a **criação**
(`git branch -m`), e é quando o `PostToolUse` dispara.

## Defeito 1 — a regra ia embarcar VERDE-VAZIA

Reusar `lib/pt-br-words.txt` da REGRA 60 parecia certo (*"uma fonte de palavras, não duas"*). A
premissa é **falsa na prática**: aquela lista é afinada para **identificador de shell**. Medido:

| palavra | estava na lista? |
|---|---|
| `nao`, `depende`, `vivo`, `rotacao`, `duas`, `portas`, `fios`, `abertos`, `selo`, `separador`, `registro` | **ausentes** |
| `chave`, `vereditos` | presentes |

**11 de 13 ausentes.** A regra não disparava em **nenhum** dos nomes reais que motivaram sua criação.
Quem pegou foi a matriz de 10 casos, **antes do embarque** — não o raciocínio, que dizia "reusa a
lista, logo cobre".

É a mesma falha que `.claude/rules/kg-grammar.md` documenta com o grep de `type: REFUTES` num corpus
onde o campo é `edge_type:`: **guarda que nasce passando sempre e guardando nada**.

Lista estendida 74 → 86. **Custo zero**: REGRA 60 segue `0 HARD · 0 no baseline` — nenhum identificador
do repo usa as palavras novas.

## Defeito 2 — a guarda-de-honestidade da bancada estava MUDA desde que nasceu

A bancada morreu no caso **666**, sem soma e sem um único `✗`. A leitura confortável — *"666 verdes"* —
estava disponível.

Existe uma guarda exatamente para isso (`_bench_abort_guard`, linha 63), e o comentário dela descreve
o caso **palavra por palavra**. Ela estava desarmada:

```bash
trap _bench_abort_guard EXIT          # linha 63
...
trap 'rm -rf "${SANDBOX}"' EXIT       # linha 114 — SUBSTITUI a anterior
```

Bash guarda **um handler por sinal**. Ninguém desligou de propósito; a segunda linha não sabia da
primeira. Reproduzido em miniatura: com o clobber a guarda não emite nada; combinada, emite e ainda
entrega o `rc` real.

Cura: um só handler, `_bench_on_exit`, chamando a guarda **primeiro** (sua 1ª instrução é `local rc=$?`,
então o status chega intacto) e limpando depois.

⚠️ **O que isto NÃO prova:** a corrida seguinte deu 786/0/0. A morte no 666 **não se reproduziu** —
logo o conserto cura o **silêncio**, não a morte. Se ela voltar, agora a bancada diz.

## Defeito 3 — colisão de rótulo

Dois casos distintos chamavam-se `(b4)`: o meu e um de outra sessão. `record_fail` com rótulo ambíguo
aponta para o lugar errado justamente quando alguém precisa achar o caso. Meus casos → `(b5)`/`(b5b)`.

## O padrão do dia, e é o que importa

**Duas vezes hoje a cura que a casa já pagou existia e não estava em uso**: a âncora em início de
comando (detector 5), que eu não reusei ao escrever a regra do `pgrep`; e o `_bench_abort_guard`,
desarmado por um `trap` que não sabia dele.

Guarda muda é **pior que guarda ausente**: com guarda ausente você desconfia da saída; com guarda muda
você confia.

## Erros conhecidos, com cura ou superação

| erro | cura ou superação |
|---|---|
| detector por **lista enumerada** só vê o que foi enumerado (teto compartilhado com a REGRA 60) | **cura de hábito**: todo termo pt-BR achado por revisão entra na lista no MESMO movimento em que é corrigido. Sem isso, cada achado se paga uma vez só |
| `PostToolUse` é **posterior** — a branch já foi criada quando o aviso sai | **contorno em runtime**: `git branch -m` é grátis enquanto não há push. **superação**: um `PreToolUse` negaria antes, mas é substrato NÃO-VERIFICADO neste repo (medido e refutado em 2026-08-06) |
| a morte no caso 666 **não tem causa conhecida** | **superação**: a guarda rearmada passa a NOMEAR o abort e o `rc`. Sem reprodução não há o que consertar — o que se conserta é a cegueira |
| outros `trap ... EXIT` podem reintroduzir o clobber | **cura mecanizável, não feita**: um caso de bancada contando `trap .* EXIT` e exigindo ≤1 no arquivo. Fora do gatilho medido; fica proposto |
