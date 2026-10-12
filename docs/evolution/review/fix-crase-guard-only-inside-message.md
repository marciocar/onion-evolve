---
branch: fix/crase-guard-only-inside-message
date: 2026-10-12
reviewed_diff_sha256: 178ab7defe75701d6c9634846e6b18c8d6b8051c5d436f328203da58a745514b
reviewed_code_sha256: 50c218165f52f2941a1ed01e1cc36320742869b8f2f7c53f19fc2f4b042002a5
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutante executado (sem subagente) — gate mecânico: empty_result_guard
---

# A guarda de crase acusava qualquer crase do comando, não a da mensagem

## Defeito medido

Foram 3 falsos positivos de `CRASE-EM-MENSAGEM-DE-COMMIT` numa só sessão, em 2026-10-12. O padrão foi
o mesmo nos três: um `printf '…`x`…'` ou um `sed` com crase entre aspas **simples**, na mesma linha de
um `git commit -m "…"` sem crase. O predicado juntava três condições soltas: havia `git commit`, havia
`-m "`, e havia uma crase **em qualquer ponto** do comando. Guarda que grita errado ensina a sessão a
ignorá-la (item 4 da lente).

## Cura

A varredura começa em cada `-m"`/`-F"` e vai até a aspa dupla de fecho; a barra invertida escapa o
caractere seguinte. Só conta a crase que está nesse trecho. Se a aspa dupla não fecha, o caso é
indeterminado, e a guarda **grita**.

## Prova

- `empty_result_guard`: 47/47. Casos novos:
  - (c9): crase fora do `-m` cala;
  - (c10): crase dentro do `-m`, depois de outro comando, avisa;
  - (c11): aspa sem fecho avisa.
- Mutante, voltando ao predicado antigo: (c9) e (c11) reprovam.

## O que NÃO cobre

- `-m` em formato longo (`--message="…"`). A guarda antiga também não cobria.
- Mensagem montada em variável e passada como `-m "$MSG"`: a crase estaria no conteúdo da variável, não na linha do comando.
