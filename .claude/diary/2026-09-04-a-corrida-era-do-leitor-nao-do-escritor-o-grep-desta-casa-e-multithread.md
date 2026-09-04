---
date: 2026-09-04
instance: onion-evolve
type: error
classification: public
tags: [bancada, flaky, pipefail, ugrep, behavior-over-declaration, fix-must-become-mechanism]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "se a classe recorrer com here-string, medir o leitor de novo — e considerar `case` em bash (0 processos) nos sítios mais quentes"
review_after: 2026-12-03
conflict_class: static
---

# A corrida era do LEITOR, não do escritor — e o `grep` desta casa é multi-thread

**A classe** ("falha só em paralelo, passa em série") tinha 4 ocorrências e duas curas erradas antes desta. Em 2026-09-03 eu tratei o **escritor**: `_emit` com `|| true` em 489 sítios, contra EPIPE. Hoje o `/meta:drive` conduziu o nó e a **medição** mostrou o oposto: `_emit "$saida" | grep -q PADRÃO` devolve **falso com o padrão presente** — 4 a 18 falhas por processo em 12 processos × 40 tentativas com 145 KB; zero em série.

**O fato que ninguém tinha registrado:** `/usr/bin/grep` nesta máquina é **ugrep 7.8.4**, multi-thread. `-q` sai no primeiro match e fecha o stdin; sob concorrência o leitor devolve 1 antes de ver o padrão.

**A cura, medida antes de aplicar:** das quatro formas sob a mesma carga, o pipe falhou 9 em 480 e as três alternativas deram **0 em 480** — here-string, `case` em bash e arquivo temporário. Apliquei here-string em 496 sítios de veredito; os 40 que só compõem mensagem ficam (truncar mensagem não é veredito falso). A guarda de reintrodução entrou na família que já cuida da 1ª classe.

**A lição que fica:** quando um pipeline mente, meça as DUAS pontas. Curar o escritor e declarar vitória é a forma mais convincente de deixar o defeito vivo — e ele volta como flake, que é o disfarce mais caro.
