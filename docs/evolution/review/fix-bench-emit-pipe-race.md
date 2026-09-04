---
title: "Revisão — a corrida é do LEITOR: _emit|grep -q em veredito devolve falso sob concorrência (ugrep multi-thread); cura por here-string em 496 sítios"
date: 2026-09-04
branch: fix/bench-emit-pipe-race
reviewer: "condutor com medição EXECUTADA: probe.sh (12 processos × 40, serial vs concorrente) e cure.sh (4 formas × 480); bancada completa pós-cura 1035/0/0 em 777s; guarda de reintrodução provada com mutante"
reviewed_diff_sha256: ce1e68b6b4adf7097ad6e829b333cf1fb3681e0006a9b0290495fddcbac2b839
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 400000
duration_min: 55
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **A cura anterior tratava o lado errado.** 2026-09-03 curou 489 sítios tornando o **escritor** (`_emit`) imune a EPIPE. A medição de hoje mostra que o falso nasce no **leitor**: o pipeline devolve 1 com o padrão presente. Sem medir as duas pontas, "curado" era declaração.
2. **`grep` aqui é ugrep 7.8.4, não GNU grep.** Ninguém tinha registrado isso; explica por que a classe não aparece em CI de outra máquina do mesmo jeito. Fica no nó de evidência.
3. **Três patches falharam antes do certo** — o primeiro converteu `_emit` dentro de `$( )` (here-string saiu do `$()`), o segundo quebrou linhas com continuação `\`, o terceiro deixou negações e condições encadeadas. A conversão só ficou segura restringindo a **posição de comando** e tratando continuação e `$'...'` em passes próprios, com `bash -n` a cada passe.
4. **Escopo declarado:** 40 sítios que só compõem MENSAGEM continuam com pipe. Ali um truncamento degrada a mensagem, não o veredito — e converter tudo aumentaria o diff sem ganho medido.
5. **A guarda nova cobre a 2ª classe na mesma família** (`shell_pipefail_robustness`) em vez de virar regra nova: mesmo predicado (idioma frágil sob `pipefail`), mesmo alvo (scripts strict-mode da casa).

## Fora de escopo
- Flip de `Q_KG_BACKLOG_E_INTERMITENTE_EM_PARALELO` para fechada: selo do maestro (tabela do `/meta:drive`).
- `printf ... | grep` fora do idioma `_emit` (não medido nesta passada).
