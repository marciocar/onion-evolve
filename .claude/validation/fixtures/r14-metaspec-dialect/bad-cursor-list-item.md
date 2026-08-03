# Fixture BAD (Regra 14) — dialeto Cursor em item de lista YAML

Meta-spec de exemplo. O bloco abaixo declara ferramentas como **item de lista YAML**, que é
exatamente a forma que a REGRA 14 casa:

tools:
  - Read
  - edit_file
  - Bash

O token `edit_file` é dialeto Cursor. Num exemplo de meta-spec (autoridade L0) ele se propaga
para todo artefato que copie o padrão — por isso a guarda é HARD aqui.
