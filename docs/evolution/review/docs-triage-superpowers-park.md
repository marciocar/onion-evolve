---
branch: docs/triage-superpowers-park
date: 2026-10-14
reviewed_diff_sha256: 6a967b1607ab840c742c69155d078db70e2eb543859d8399e5f984cc202ea798
reviewed_code_sha256: d35f8bf203293ca04feb06c51e16dae40eeec049f90b37fae9891611db412745
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada própria contra o grafo da dissecação do adotante de curadoria (lido inteiro, 285 linhas), gate mecânico com kg-radar --integrity --schema, kg-contract-check e dissect-census
---

# Triagem: o Superpowers fica PARQUEADO, e o panorama fecha a entrada

## O que o PR faz

- Processa a proposta upstream de 2026-10-13 (`docs/evolution/inbox/_processed/`). O veredito PARQUEAR
  já estava selado pelo maestro do lado do adotante, então a triagem é derivável e não abre pergunta.
- Fecha a entrada do Superpowers no panorama competitivo e na tabela do `strategy.md`. O movimento se
  confirma só em parte, porque o mecanismo é persuasão injetada no SessionStart, sem gate determinístico.
  A medição de estrelas mais recente fica (297,9k em 2026-10-12) e a da dissecação é citada (296,6k em
  2026-10-09), como crescimento.
- Cria o grafo `docs/evolution/dissect/superpowers-2026-10/superpowers-2026-10.kg.yaml`, com 4 nós
  dentro do teto declarado: a decisão da triagem, os dois gatilhos de reabertura como `question` open
  com `x_gatilho`, e a evidência da triagem. O panorama não projeta nem cita grafo próprio, e o grafo de
  pesquisa que ele cita (plugin-directory-landscape) está fechado no teto de 20 nós. Por isso o registro
  foi para uma dissecação no core, que o `dissect-census.sh` lê.

## Passada adversarial

Perguntas: os números batem com o grafo do adotante? A hipótese está marcada como não medida? Ficou id
ou caminho privado em arquivo que viaja?

1. **Locators errados na evidência.** Na 1ª escrita, os intervalos de linha dos nós citados foram
   estimados, não medidos. `D_SUPERPOWERS_2610` aparecia como l.159-200, mas o nó seguinte começa na
   l.181. **Curado:** os intervalos agora saem de `grep -n '^  - id:'` (l.32-50, 149-158, 159-180,
   220-229), e o id `E_N0` virou o nome completo `E_N0_IDENTIDADE`.
2. **Data do veredito ambígua no panorama.** A 1ª redação dizia "PARQUEAR (2026-10-14)", que soava como
   selo do core. **Curado:** agora diz que foi selado pelo maestro em 2026-10-13 e triado pelo core em
   2026-10-14.
3. **Labels acima de 280 caracteres.** O contrato acusou `form.range.node.label` em dois nós. **Curado:**
   o porquê foi para o `narrative:`, e o `kg-contract-check.sh` deu rc 0.

O que foi conferido contra a fonte, sem divergência: 296.605 estrelas em 2026-10-09; 15 harnesses
declarados; 24 de 30 methods em prosa (3 com sudo, 2 com web); a REGRA 57 (O veredito do run está
SELADO no grafo que ele julgou) só dispara com `ledger:`; confiança 0,4 na hipótese de mercado; grafo de
origem com 14 nós, no teto. O `def stamp` está em `census-seal.py:54` no origin/main de hoje. O adotante
citou :51-76 num sha anterior, e o grafo do core cita a linha medida hoje.

A hipótese de posicionamento aparece como **NÃO medida** no panorama, com os fatores de confusão do nó
`E_MERCADO_PERSUASAO_E_DISTRIBUICAO`. Um `grep` por id de adotante, caminho de casa e id de sessão nos
arquivos editados devolveu zero. A única ocorrência é o campo `from:` da proposta processada, que é
cópia verbatim do dado recebido, como nas outras entradas de `_processed/`.

## Gate

- `kg-radar.sh <grafo> --integrity --schema`: exit 0 (4 nós, 3 arestas).
- `kg-contract-check.sh <grafo>`: rc 0.
- `dissect-census.sh . --tsv`: `superpowers 4 parquear 2026-10-09 2026-11-08 fresco`. Antes da triagem,
  o censo do core não via o Superpowers. Contra o repo do adotante, a mesma linha.
