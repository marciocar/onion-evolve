---
title: 'Resíduo — eu falsifiquei minha própria declaração dez minutos depois de mergeá-la'
date: 2026-09-21
branch: fix/harness-declaration-now-false
reviewed_diff_sha256: eef24bc1ed3a61425ce29700fd74b6bce7e6176e1ea54b88221247a0d55f3497
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Sem passada adversarial dedicada: o achado não veio de refutador, veio de mim, ao notar que uma
  frase que acabara de mergear tinha deixado de ser verdadeira por ação minha. O diff é a correção
  desse fato mais o mecanismo que fecha uma recorrência medida 3× no mesmo dia.
---

# O achado: um artefato meu passou a mentir sobre si

O resíduo do PR #859, já em `main`, declarava:

> **(2) O harness NUNCA foi executado desde 12/07.** Trazê-lo para `main` não é o mesmo que tê-lo provado.

Era verdade quando escrevi. **Deixou de ser cerca de dez minutos depois**, quando o maestro mandou
rodar o dogfood e eu executei o instrumento ponta a ponta. A frase seguiu em `main`, orientando quem
lesse — que é exatamente a definição de *artefato que mente sobre si*, a classe que este repo mais
persegue. Introduzida por mim, e não por descuido de escrita: por o mundo ter andado e eu ter sido
quem o moveu.

**Curado por superação, não por reescrita.** A frase antiga fica riscada ao lado da medição que a
derruba — Aufhebung. Quem ler daqui a um mês vê as duas coisas e a data.

| etapa medida | resultado |
|---|---|
| `otlp_sink.py` | LISTEN em `127.0.0.1:4318` |
| sessão headless instrumentada | 3 sinais com dado: `logs` 119 KB · `metrics` 8,6 KB · `traces` 11,9 KB |
| `leg1_analyze.py` | `rc=0`; 1 sessão, `reject-rate=0%`, `blocked_on_user` max=18 ms, 6 spans |

E o achado que vale mais que o meu: o analisador **recusou-se a minerar**. Com 1 sessão declarou
*"nenhum span-pattern em ≥3 sessões"* e *"sem candidatos a confirmar"* em vez de inventar padrão — a
trava anti-HARKing do pré-registro funcionando no primeiro contato com dado real.

**O estado verdadeiro passou a ser outro, e está escrito:** instrumento **provado**; dado
confirmatório da Leg-1 **inexistente e fora do meu alcance** (exige ≥4 sessões interativas; os 18 ms
de `blocked_on_user` são o flatline que a NOTE-05 previu para headless, não espera humana).

# O mecanismo: a REGRA 81 me pegou 3× no mesmo dia

**REGRA 81 (Painel de estado é GERADO dos produtores, nunca redigido)** barrou três commits desta
sessão, sempre pelo mesmo motivo — e o motivo **não é descuido**: `testing-state.sh` lê
`review-ledger.sh --env`, que **conta resíduos e achados**. Escrever um resíduo defasa o painel **por
construção**. Cura de disciplina ("lembrar de regenerar") é cura nula aqui.

O pre-commit passa a regenerar o painel quando há resíduo no commit, no **mesmo idioma que o repo já
usa** para plugins (REGRA 19/76): *auto-fix com rastro, e a regra segue HARD no CI* — quem contorna o
hook com `--no-verify` (que nesta casa é checkpoint, não validação) ainda é pego lá.

Detalhe de desenho, não cosmético: `temp+mv`, nunca redirecionar direto no alvo. Redirecionar trunca
o arquivo **antes** de o gerador poder falhar, e aí o painel **some** em vez de ficar defasado — a
saída destrutiva é plausível ([[generated-projection-needs-ratchet]]).

**Provado nas duas pontas:**
- com resíduo staged e painel adulterado por isca → regenera, a isca some, o rastro sai na tela;
- sem resíduo staged → **0 disparos**. Mecanismo que dispara sempre é ruído, não guarda.

# A cura criou um defeito, e o CI o pegou no primeiro uso real

O auto-fix acima roda **depois** de eu carimbar o `reviewed_diff_sha256`: ele acrescenta o painel ao
commit, o diff muda, e o hash fica caduco. O CI do PR #860 acusou `ARTEFATO-CADUCO` num commit cujo
único "culpado" era **o próprio hook que eu acabara de escrever**.

É a mesma forma do defeito que este PR cura no #859 — mecanismo que produz um artefato desalinhado
com o que ele mesmo declara —, agora cometida por mim no ato de mecanizar. Curado no próprio hook:
depois de regenerar o painel, ele **re-carimba o hash** usando a **mesma fórmula** de
`review-artifact-check.sh` (flags canônicos + exclusão de `docs/evolution/review/`), senão o hook e o
gate discordariam sobre o mesmo número. Converge porque o hash exclui o diretório de review: re-adicionar
o resíduo não altera o valor.

**A lição, que é a do dia inteiro:** o mecanismo só se prova no uso real. A isca eu construí e ela
passou; o caso verdadeiro apareceu no CI, três minutos depois, com um modo de falha que eu não tinha
imaginado.

# Declarado

`guardrails: test-r15.sh` falhou **na faixa** e passa **isolada** (2/0). É a classe de flaky que a
migalha `bench-flaky-kg-reverify-schema-real` registra — ambiente herdado na bancada, não carga —, e
não é deste diff.
