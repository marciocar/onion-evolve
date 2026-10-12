---
branch: fix/radar-maestro-decision-in-dev
date: 2026-10-12
reviewed_diff_sha256: 5d47a1a8ac4dcbe3c6372b63aa74adc61f97a7897a72e27d4196154b5fa0c222
reviewed_code_sha256: 4b48bb0191719a28beaa607d31908fb65b2eaac0c3b9d2977f7e2f9956f91bac
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutante executado (sem subagente) — gate mecânico: família seed_adoption_graph
---

# Decisão selada pelo maestro fica em DEV sem aviso do radar

## Defeito (sinal de campo do onion-kg-ssot, 2ª rodada do /meta:evolve, 2026-10-12)

O `kg-decide-seal.sh` grava a decisão do maestro como `done`, `plane: DEV` e método `testemunho`. O radar avisava
`decision-done-em-DEV`, porque a gramática pede `done` verificada em PROD. Promovida a PROD, a decisão era acusada
pelo contrato de `integrity.testimony-in-prod`. Não havia como selar uma decisão do maestro sem cair num dos dois.

## Cura (decisão do maestro: "o radar aceita a decisão do maestro em DEV")

Uma decisão selada pelo maestro é conhecimento de ADOTAR, não uma claim verificada em produção. O radar passa a
ler o `provenance.method` e não conta no aviso a decisão `done` em DEV cujo método é `testemunho: decisão do
maestro…`. Ela aparece numa linha informativa própria. Qualquer outra decisão `done` em DEV continua avisando. O
contrato não muda, e a gramática (`kg-grammar.md`) passa a nomear a exceção.

## Prova

- Família seed_adoption_graph **12/0**. O caso novo é o (r2): a decisão selada é aceita, e a outra decisão em DEV
  segue avisando, na mesma leitura.
- Com o radar de `origin/main` (o mutante), o (r2) reprova e acusa as duas.
- No grafo real `auto-drive-2026-10`, o `D_AUTO_DRIVE_DEGRAU_AUTOMATE`, selado hoje, deixou de avisar e apareceu
  como aceito.

## O que NÃO cobre

- O reconhecimento é pelo prefixo do método. Um método escrito à mão com o mesmo prefixo também é aceito. É o
  mesmo texto que o selador grava, e o selador só sela o que foi perguntado.
