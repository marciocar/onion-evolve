---
branch: fix/residuos-2026-08-18
pr: 632
date: 2026-08-18
reviewed_diff_sha256: 179ec9dcb267cf3b474951ebec7e85f51fb9528a6a7a560d54e8da97da0fe9f2
findings_total: 6
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 90
verdict: CONFORME-BACKLOG-EXECUTADO-3-DE-3-COM-MUTANTE-EM-CADA-CURA
reviewer: passada adversarial manual + medição contra o vivo + teste de mutação em cada mecanismo; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `fix/residuos-2026-08-18`

**Origem: ordem do maestro** (2x, marcador `reforço:`): revisar o alinhamento dos 5 resíduos
colhidos nos PRs #630/#631 **em ordem de valor**, executar até o merge, e — a parte que muda o
padrão — *"se precisar coloque um mecanismo para não ficar nada sem controle e parado"*.

## O mecanismo de controle pedido

`docs/onion/graph/residuos-2026-08-18.kg.yaml` — o backlog É grafo: item executado vira `decision
done` com `verified_at`/`verified_against`; item reprovado no Teste do Gatilho vira `question open`
com **gatilho nomeado** (parado SOB CONTROLE ≠ órfão). O cabeçalho declara o limite que o
fios-abertos já mediu: a ordem de execução é por VALOR DECLARADO, nunca pela atenção do radar
(grau não-direcionado ≠ precedência).

## Achado 1 — a contagem estava errada PELA TERCEIRA VEZ (REAL, curado)

Re-medição de abertura: eram **15** links irmãos mortos, não 11 — e em **DOIS** plugins
(onion-work-tools 12, onion-engineering 3). As contagens anteriores (4 → 11) mediram só um plugin.
Mesma família dos erros de contagem do #630; a régua agora varre `plugins/*/kb/` inteiro.

## Achado 2 — item 2 do backlog DISSOLVIDO pelo item 1 (decisão de desenho, declarada)

"Estender o kb-vendored-link-check a plugins/" morreu ao medir o predicado: aquele guard testa
*link core-privado*; o defeito era *link irmão-não-embarcado* — predicados diferentes. A cura
certa não é guarda (detecção): é o **assembler converter no empacotamento** (construção) —
`R_MECANISMO_ANTES_DE_INSTANCIA`: impossível > detectável > corrigido-uma-vez.

## Achado 3 — item 4 REPROVADO no Teste do Gatilho (GATED com gatilho nomeado)

Alarme de ausência de agendado: **zero** agendados pararam silenciosamente na história do repo
(1 workflow com schedule, 1 run). Construir agora é catedral. Gatilho nomeado no grafo: a 1ª
ausência >48h observada de um run `event=schedule`.

## Achado 4 — meu primeiro mutante era INVÁLIDO (REAL, corrigido no método)

No VALOR 3, o mutante-por-sed quebrou o script (rc=2) — controle que não compila não prova nada.
O mutante honesto era a **versão de HEAD**: ela engole `collection 📤` (rc=0) e a guarda reprova
(rc=1). Diferencial limpo. Instrumento improvisado errando é a 5ª vez nesta sequência de sessões —
e desta vez o próprio processo pegou antes de virar afirmação.

## As 3 curas, cada uma com prova de mutação

| Valor | Cura | Prova |
|---|---|---|
| 1 | assembler: irmã-não-embarcada → plain-text no empacotamento | 15→0 medido nos 2 plugins; kind 11/11; mutante (assembler sem o bloco) dead=12 → (e4) reprova |
| 2 | gerador de KB reescrito com as famílias medidas (38 ref / 5 doutrina / template antigo = 2 de 86) | números ancorados no comando; seções rebaixadas a sugestão |
| 3 | guarda de enum na linha inteira de classification + 2 migalhas 07-16 curadas | kind 8/8; mutante honesto = HEAD engole (rc=0), guarda reprova (rc=1) |

## Prova global

- Bancada no pre-commit do VALOR 1: **825/0/0** (o +1 é o caso (e4)); a dos VALORES 2+3 no
  pre-commit deste ciclo (o placar final vai no PR).
- Lint: 0 HARD.
- Grafo de controle: radar exit 0; **1 único aberto**, GATED com gatilho nomeado.
- Diário: 0 stale; nenhuma migalha com marcador na fonte (grep = ZERO).

## Ressalva declarada

O commit do VALOR 1 morreu uma vez por **prazo artificial meu** (timeout 110s sobre um hook que
roda a bancada inteira, ~13 min) — refeito sem prazo. O sintoma no terminal ("BANCADA ABORTOU")
era o meu kill, não defeito da suíte; registrado para o próximo não diagnosticar fantasma.
