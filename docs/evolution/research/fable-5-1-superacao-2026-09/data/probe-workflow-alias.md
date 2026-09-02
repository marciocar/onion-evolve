# Probe — alias `fable` no `Workflow` tool (2026-09-02)

- **Ordem:** maestro, em texto próprio: *"use um workflow para medir o alias fable"* (opt-in explícito do `Workflow`).
- **Método:** `Workflow` run `wf_5f0d93a6-28b`, 2 agentes de 1 turno em `parallel`: `{model:'fable', effort:'low'}` e controle `{model:'opus', effort:'low'}`; depois `grep -o '"model":"[^"]*"'` nos transcripts em `subagents/workflows/wf_5f0d93a6-28b/agent-*.jsonl`, casados ao alias pelo `agent-*.meta.json`.
- **Observado (verbatim):**
  - `agent-a88b32c6e833b4f70.meta.json` → `"model":"fable"`; transcript → `1 "model":"claude-fable-5-1"`
  - `agent-a032004d84d776ed7.meta.json` → `"model":"opus"`; transcript → `2 "model":"claude-opus-5"`
- **Auto-declaração dos workers (NÃO é a medição):** fable: "claude-fable-5-1 (conforme o prompt de sistema; sem verificação externa)"; opus: "Claude Opus 5 (1M)". `env_hint`: "desconhecido" nos dois — não há env var lida pelo worker que identifique o modelo.
- **Custo:** 93.999 tokens de subagente, 7,8 s, 0 erros/0 skips.
- **Veredito:** o alias `fable` do `Workflow` resolve para `claude-fable-5-1` nesta sessão (Claude Code 2.1.257, sem gateway) — mesmo resultado do `Agent` (`probe-fable-alias.md`). `Q_PROBE_WORKFLOW_ALIAS` fecha; `Q_EXP_JUIZ_FABLE_CALIBRACAO` deixa de estar bloqueada por ele.
- **Teto declarado:** 1 sessão, 1 versão do CC, sem gateway; via gateway vale o CHANGELOG (radar E3).
