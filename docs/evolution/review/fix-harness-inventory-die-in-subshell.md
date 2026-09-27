---
title: 'A guarda gritava cinco vezes e não parava nada'
date: 2026-09-27
branch: fix/harness-inventory-die-in-subshell
reviewed_diff_sha256: 658d73144086980618aad0f9075e23563984a3f376836f007671a3be71e10f1b
elenxo: nao
findings_total: 5
findings_real: 5
verdict: REPROVADO_E_CURADO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e a ausência é declarada com o motivo: o revisor semântico do CI está fora da conta por SALDO da conta de API (medido — a chave local, distinta da do CI, devolve o mesmo HTTP 400), e o maestro instruiu explicitamente a seguir sem contar com ele. Quem reprovou aqui foi a MEDIÇÃO: o defeito estava vivo em main e foi achado contando ocorrências de stderr. Dos 5 achados, 1 é o defeito e 4 são erros MEUS de medição, todos do mesmo formato.'
---

# Resíduo — a guarda gritava cinco vezes e não parava nada

## O defeito, e a forma de achá-lo

`_die` dentro de `$( )` **mata o subshell, não o script**. O `harness-inventory.sh` tinha a recusa no
ramo `else` do `_tracked`, e `_tracked` é chamado **sempre** em substituição de comando. Resultado
medido em `origin/main`:

```
stderr: "sem índice git ... Recusa."   × 5   (contadas com grep -c)
tabela: CINCO contadores zerados
rc:     0
```

E a tabela **declara o comando** que produziu cada zero (`git ls-files '.claude/validation/*.sh'`) —
visível para quem lê, invisível para qualquer gate.

**A forma de achar vale mais que o caso:** eu **contei as ocorrências da mensagem no stderr** em vez de
ler o código. A guarda dizia tudo o que era preciso saber — cinco vezes. Ler o `_tracked` sugeria uma
guarda funcionando; contar mostrou uma guarda decorativa.

## Duas correções ao nó `I_AUSENCIA_LIDA_COMO_RESULTADO` (atenção 14,2)

1. São **cinco** contadores, não quatro — exatamente os que delegam ao `git ls-files`. Os outros quatro
   usam `grep` no arquivo e saem **certos** (193 famílias, 1254 asserções, 89 regras, 51 pares), o que
   torna a tabela **parcialmente verdadeira e por isso mais convincente**.
2. A causa **não** é *"o fallback para `find` nunca dispara"* — é que a **recusa não alcança** o
   programa de onde é chamada.

## A cura, e os três cenários medidos

Pré-condição verificada **uma vez, fora de subshell**; mais assertiva de contradição (arquivo em disco
+ contagem rastreada zero ⇒ `rc=2`, porque zero ali não é resultado).

| cenário | antes | depois |
|---|---|---|
| sem `.git` | `rc=0`, 5 zeros | **`rc=2`** antes de contar |
| git presente, tudo **untracked** (o sinal do adotante, 2026-09-08) | `rc=0`, 5 zeros | **`rc=2`** nomeando `CONTRADIÇÃO … 75 arquivo(s) em disco … RASTREADA = 0` |
| repo real | 80 scripts, 16 hooks | inalterado |

**Mutante morto:** devolvendo o `_die` ao subshell e removendo a assertiva, os dois casos novos
reprovam com `rc=0` **e a mensagem "Recusa" impressa** — a prova literal do defeito.

## Quatro erros MEUS de medição, todos do mesmo formato

| # | o que eu concluí | o que era |
|---|---|---|
| 2 | *"`selftest-summary.sh` está ausente em main"* — quase virou achado grave | procurei em `.claude/validation/`; ele vive em `ops/testing/` |
| 3 | *"o caso `backlog-projection: em-dia` está errado"* | medi com `git archive HEAD` **sem `git init`** — sandbox diferente do que o caso monta; com o real ele vê 49 grafos, e o drift era **verdadeiro e meu** |
| 4 | caso `(z1)` reprovando SUT correto | asserção com condição **redundante** |
| 5 | caso `(z1)` reprovando de novo | padrão que não sobrevive a `LC_ALL=C` — `í` são **dois bytes**, e `sem .ndice` espera um |

**O padrão é idêntico nos quatro:** escolho um caminho de medição plausível, ele **não é o que a
produção usa**, e o resultado vazio vira **conclusão** em vez de *"não sei"*. É a mesma família do
defeito que este PR cura — ali era o `_die` que não alcançava; aqui sou eu que não meço onde importa.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **1502 casos · 0 falhas**
- `kg-radar.sh --integrity --schema` → **exit 0** (evidência apendida ao grafo da onda)
- `door-staleness-check.sh` → **rc=0**, as duas portas em `ok` (25ª materialização)
