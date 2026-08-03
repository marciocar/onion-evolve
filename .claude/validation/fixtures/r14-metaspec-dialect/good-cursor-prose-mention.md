# Fixture GOOD (Regra 14) — dialeto Cursor citado em PROSA, não em lista

Meta-spec de exemplo. Este arquivo **menciona** tokens do dialeto Cursor, mas sempre em prosa
ou dentro de citação — nunca como item de lista YAML.

> Nomes como `edit_file`, `search_replace` e `run_terminal_cmd` pertencem ao dialeto Cursor e
> **não** devem ser usados; prefira `Edit`, `Write` e `Bash`.

Esta é a proteção anti-falso-positivo que mantém a R14 verde hoje: `docs/meta-specs/agents.md`
lista os tokens proibidos **de propósito**, num blockquote. Se a guarda casasse prosa, a própria
meta-spec que documenta a proibição seria reprovada por documentá-la.

A forma declarativa correta usa nomes nativos:

tools:
  - Read
  - Edit
  - Bash
