# Dissecações de ferramenta — o "chupa-cabra" em cinco níveis

Cada subpasta aqui é **uma** dissecação: `<ferramenta>-<AAAA-MM>/` com o `.kg.yaml` (fonte) e o
`SYNTHESIS.md` (projeção). A doutrina inteira vive em
[`dissect-doctrine.md`](../../../.claude/commands/common/prompts/dissect-doctrine.md); o comando
que conduz é [`/meta:dissect`](../../../.claude/commands/meta/dissect.md).

O mínimo que não se negocia aqui:

- **A escada é gate.** N0 identidade → N1 capacidade → N2 mecanismo → N3 transferibilidade →
  N4 absorção. Nível reprovado **não sobe**; ferramenta morta nunca consome análise de mecanismo.
- **N0–N2 descrevem, N3 julga, só N4 recomenda.**
- **Quatro vereditos, nenhum deles "interessante"**: `absorver` · `costurar` · `parquear` (com
  **gatilho nomeado**) · `rejeitar` (com razão datada).
- **N2 exige comportamento**: rodou, ou leu o código-fonte. Não deu? o nó nasce `open` com a
  lacuna nomeada — nunca `confirmed` por folheto.
- **Marcadores que o censo lê** (sem eles a dissecação é invisível):
  `meta.x_dissect_tool:` · `x_dissect_level:` por nó · `x_dissect_verdict:` no nó de decisão ·
  e, quando houver, `meta.x_dissect_against:` (a régua; ausente = Onion) e
  `meta.x_dissect_mode: study` (estudo: para no N2, sem veredito).
- **Corpus primeiro**: `bash .claude/validation/dissect-census.sh` antes de abrir fonte externa.

Em 2026-10-27, `bash .claude/validation/dissect-census.sh --tsv` lista **10 dissecações**, todas
com estado `veredito` (o veredito conta): chatgpt-intelligent-ui, conductor, rea-method e superpowers
no N4; ai-front, anarlog, cedar, cortex, duolingo-actor e vexa no N3. O Superpowers só voltou a contar
nesse dia: antes saía `veredito-SEM-SUPERACAO`, porque a triagem era anterior à exigência de
superação e critério. A contagem envelhece, então rode o censo em vez de confiar neste número.
