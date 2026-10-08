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
  `meta.x_dissect_tool:` · `x_dissect_level:` por nó · `x_dissect_verdict:` no nó de decisão.
- **Corpus primeiro**: `bash .claude/validation/dissect-census.sh` antes de abrir fonte externa.

Nenhuma dissecação selada ainda — este README é a semente que a lente ancora.
