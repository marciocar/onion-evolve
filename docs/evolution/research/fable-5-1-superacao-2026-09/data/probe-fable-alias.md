# Medição: o alias `fable` do Agent tool resolve para 5.1 nesta sessão (fecha a lacuna 2 do E3)

- **Método:** `Agent({model: "fable"})` com prompt de 1 linha; depois leitura do transcript do subagente
  (`~/.claude/projects/-home-marcio-onion-evolve/<sessão>/subagents/agent-aprobe-fable-alias-*.jsonl`)
  com `grep -o '"model":"[^"]*"' | sort | uniq -c`.
- **Observado (verbatim):** `1 "model":"claude-fable-5-1"` — campo `model` da RESPOSTA da API, não a
  declaração do system prompt (o probe também respondeu `model=claude-fable-5-1`, mas isso é declaração).
- **Data:** 2026-09-02 ~02:20Z · Claude Code 2.1.257 · sessão sem gateway corporativo.
- **Escopo declarado:** mede o `Agent` tool desta conta/sessão. O `Workflow` tool usa a mesma cadeia de
  resolução (ext-claude-code.md), mas NÃO foi medido aqui; sessões via gateway seguem CHANGELOG l.99.
- **Consequência:** a restrição transversal do `int-estrategias.md` ("hipóteses não executáveis até o alias
  mudar") cai para o Agent tool; `agent-orchestration.md:330` precisa de emenda (fica como snapshot datado).
