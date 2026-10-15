---
branch: feat/sac151-consolation-overcoming
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
tokens: 163259
duration_min: 11
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutador general-purpose opus (mandato REFUTAR, default REPROVADO)
nota: "Refutador sobre o 1º commit (417cfd5c): 9 achados, todos reais. Curados 7 (1, 2, 3, 5, 7, 8, 9); o 4 (circular por inclusão) ficou DECLARADO com razão medida e o 6 foi curado em parte (estilo flow declarado). A bancada das 3 famílias saiu de 90/0 (main) para 110/0. Tokens e duração são do refutador; o lint completo não coube no timeout dele e fica com o CI."
---

# Passada adversarial: `feat/sac151-consolation-overcoming`

## O que muda

Fecha a classe da **superação de consolo** (SAC-152, filha da SAC-151). Um adotante de curadoria (PR #30,
lido como DADO) preencheu quatro superações que o gate do #1155 aceitou e só o Elenxo dele reprovou:
carimbo futuro, peça em cura, status quo e costura circular. O gate conferia a forma, não a entrega.

- **Juiz JSON** (bloco `overcoming-gate`, 3 cópias idênticas): `superacao.classe ∈ {entrega, nenhuma}`
  obrigatória, com a pergunta do consolo no prompt. Recusa a classe ausente, a classe incoerente com
  `achada`, `o_que` igual ao objeto e `medida` igual ao comando do critério. O `census-seal` só cria nó
  para `classe: entrega`.
- **Grafo do dissect** (`dissect-census.sh --check-verdict`): recusa a superação que é o próprio veredito
  ou deriva dele por tipo de aresta, a não medida e a ancorada no critério.
- Doutrina Elenxo, dissect-doctrine, research-doctrine e prompt do censo com a pergunta. Nós
  `E_CONSOLO_SUPERACAO_NO_CAMPO`, `E_CONSOLO_PASSA_NO_MAIN_MEDIDO`, `D_SUPERACAO_TEM_DE_ENTREGAR` e
  `Q_CONSOLO_INVISIVEL_A_FORMA`.

## Achados

| # | sev | achado | destino |
|---|---|---|---|
| 1 | alta | âncora por inclusão recusava o critério aplicado à variante e caía com espaços | curado: igualdade sem espaços, fixtures `variante-no-criterio` e espaçamento |
| 2 | alta | derivação ignorava o tipo de aresta: `D TRACES_TO S` virava falso positivo | curado: derivação por tipo, fora a aresta S→D; fixtures `citafonte` e `indireta`; mutante `direcao` |
| 3 | média | `verified_at` "-" passava, ISO com hora de hoje era recusado, `verified_against` "-" passava | curado: AAAA-MM-DD nos 10 primeiros, TODAY do script, mínimo de 3 alfanuméricos |
| 4 | média | circular só por igualdade; o Verify não tem alvo | DECLARADO: a inclusão recusaria a variante, que a doutrina pede; o teto do Verify está no bloco |
| 5 | média | o prompt do censo pedia "a medida certa", que é `nenhuma` | curado: o prompt separa a medida certa de a entrega medida |
| 6 | baixa | status aninhado vencia; o critério ia por `-v`; aresta em estilo flow | curado em parte: indentação do nó e ENVIRON; o estilo flow fica declarado (o corpus não usa) |
| 7 | baixa | a research-doctrine ficou com o schema antigo | curado |
| 8 | baixa | o grafo afirmava mais do que o medido | curado: "medido em scratch, não versionado" e mutante `sem-va` |
| 9 | baixa | filtro `classe` do `overcomingsFound` sem mutante | curado: sonda direta `of` e mutante `found` |

## Mutantes

- Na bancada (sed com `ONION_MUTANTE` em cópia): dissect circ, deriva, direcao, status, futuro, sem-vg,
  ancora, ilegivel (og-k1) e sem-va (og-k2); JSON classe, coerencia, circular, ancora, pergunta e found
  (og-c1); SSOT mutado no checker (og-c2); census-seal classe (og-km). Todos reprovam o caso.
- No arquivo vivo, com `ops/mutate-and-restore.sh`, antes da passada do refutador: 11 de 11 reprovaram,
  e a restauração foi conferida (zero `ONION_MUTANTE` nos SUTs). Depois das curas, as âncoras de
  futuro, sem-vg e ancora mudaram. Essas três ficaram só com o mutante da bancada.

## Limites declarados

- O **status quo** rotulado de superação e a **condição futura escrita em prosa** num nó `confirmed`
  não são vistos pela máquina. O `verified_against` da superação real é um token hifenizado, igual ao
  de um placeholder. Ficam com a pergunta obrigatória e o Elenxo (`Q_CONSOLO_INVISIVEL_A_FORMA`).
- `S TRACES_TO D` (nasceu da reprovação) segue aceito: é a forma que a doutrina pede, e por estrutura
  não se distingue de "parte do veredito".
- O **ancestral** não é recusado, embora a tarefa pedisse. Medido: a única superação real é
  `E SUPPORTS D`, ancestral direto.
- Dogfood nos grafos reais do adotante foi feito em scratch: `tessl` circular e `cross-session` com nó
  `open` dão rc 0 no main e rc 1 aqui. Os 5 vereditos da versão final do PR #30 seguem rc 0.
