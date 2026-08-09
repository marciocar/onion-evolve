---
branch: fix/extrator-piso-e-supressao
date: 2026-08-09
reviewed_diff_sha256: adc4433e708af8a4746d2fae28322e03838ce38cb4544eda58f6c8cc42906e3d
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-FECHA-A-DIVIDA-QUE-O-JUIZ-DO-PR-566-NOMEOU-COMO-RAIZ
reviewer: sem passada adversarial — os três achados vieram do Elenxo do #566, já reproduzidos por ele
---

# A dívida que o juiz nomeou como raiz, fechada

O Elenxo do PR #566 confirmou a REGRA 59 e apontou três defeitos no extrator que **não** foram
curados lá — eu os declarei como dívida e escrevi que pediam ciclo próprio, *"porque meia-cura num
extrator é como este PR nasceu"*. Este é o ciclo.

## 1 · O contador de supressão estava errado por 13×

```
awk emite:  #DYN⇥13
shell fazia: grep -c '^#DYN'   →  1
```

`grep -c` conta **quantas linhas casam**, e o awk emite **uma**. O rodapé dizia *"1 flag dinâmica"*
tendo perdido **13**. Contador de supressão errado é pior que ausente: ele dá a **dimensão errada do
próprio teto**, e quem lê "1" decide que não importa.

## 2 · A supressão era invisível no único modo que o gate consome

O rodapé inteiro vivia sob `if FORMAT != tsv`. A promessa escrita em letra grande no cabeçalho da
REGRA 59 — **"supressão CONTADA, nunca silenciosa"** — era **falsa** exatamente onde alguém olharia:
`--format tsv` saía com **0 bytes** de supressão.

**Contar para quem não lê é o mesmo que não contar.** Agora o tsv emite `SOFT SUPRESSAO` com o
número.

## 3 · Não havia PISO — a vacuidade só disparava em zero exato

O juiz mediu: um refactor de estilo derrubou **32 pares para 11** e o veredito seguiu ✅. Um extrator
que perde 2/3 da produção "cobre" tudo o que ainda vê, e o verde fala **do que sobrou**, não do que
existe.

E este extrator **já errou por essa família**: a cegueira a prefixo de env produziu duas acusações
falsas, cuja cura cerimonial gerou um caso que escrevia no repo.

`COVERAGE_FLOOR=30`, declarado no arquivo com data e motivo (medido: 32 pares, margem de 2 para
refactor legítimo). Crescer é livre; **encolher exige alguém escrever por quê**, e a edição aparece
no diff — mesma doutrina da catraca da REGRA 49.

**O piso só julga onde a suíte inteira vive.** Aplicá-lo a repo sintético faria a guarda acusar o
próprio teste — falso-positivo em regra HARD, que é como se ensina a ignorar o gate. O marcador é a
presença do detector no root julgado; um adotante que não o vendoriza simplesmente não é julgado.

## E o caso (0) ficou para trás por uma corrida

Ele exigia **saída vazia** no verde. Ao fazer a supressão falar no tsv, o verde deixou de ser vazio e
o caso reprovou — **o teste estava desatualizado, não o código**. Realinhado para *"tabulado ou
vazio, nunca prosa; e nenhum HARD no verde"*.

Vale registrar porque é a forma honesta do inverso: teste que afirma "vazio" contra um contrato que
passou a falar vira **falso-alarme**, e falso-alarme em bancada é o que faz alguém afrouxar o caso em
vez de ler o código.

## Verificação

- bancada **765 passam / 0 falham / 0 pulam**, **artefato ESTÁVEL** · lint **0 HARD** + 4 SOFT
- supressão real: **13**, não 1 · e visível no `--format tsv`
- piso: repo com 1 par contra piso 30 → **HARD `PISO-DE-COBERTURA`**; `--selftest` **4/4** intocado;
  repo real **verde**
- 3 casos novos: `(0e)` o piso morde · `(0e2)` não acusa as próprias fixtures · `(0f)` a supressão
  aparece no modo do gate

## Dívida que permanece

- **O prefixo de env** segue cego no extrator (`ALVO_ROOT="${x}" bash "${h}" --modo` some do lado
  teste). É a raiz que produziu os dois falsos, e o piso **contém** o dano sem curá-lo: agora perder
  visão reprova, mas a perda específica do prefixo continua não sendo contada como dinâmica.
- **O piso é um número único.** Ele pega perda em massa, não perda cirúrgica de 2 pares.
