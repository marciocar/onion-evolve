---
title: "Revisão — REGRA 73 (hook empacotado resolve) + REGRA 74 (caminho .claude/ nu em plugin, catraca) + fix do aside-router no plugin"
date: 2026-09-04
branch: feat/plugin-lint-hooks-bare-paths
reviewer: "condutor com dogfood EXECUTADO: helpers --selftest 3/3 e 3/3; famílias plugin_hooks_resolvable 3/3 e plugin_bare_path 3/3 (com mutantes); 8 plugins regenerados; hook do plugin invocado ao vivo com CLAUDE_PLUGIN_ROOT e respondeu; lint 0 HARD"
reviewed_diff_sha256: c52af0f9650c74d9a433ce8319dc0a90a945cdc174192aeb843bb8f34bd2b592
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 110000
duration_min: 40
---

# Resíduo — REGRA 56

## Achados

1. **`sed -i 'Ns/…/'` por número de linha errou o alvo** e o gerador de `hooks.json` quebrou (tupla no f-string) — o `hooks.json` do `onion` sumiu e o helper 73 reportou "0 — limpo" porque não havia arquivo. Cura: substituição por conteúdo (python), e o achado fica registrado: *ausência de hooks.json quando o manifesto tem HOOKS* é uma classe que a família `plugin_hooks_json` (a) já cobre.
2. **`grp` vs `entry`** — o loop do gerador nomeia o grupo como `grp`; o patch chamou `entry` (NameError). Pego ao rodar o artefato de verdade.
3. **Comentário virava "motor ausente"** — o helper 73 varria linhas `#`; ignoradas agora.
4. **Here-string venceu o heredoc** no helper 74 (`python3 - <<'PY' <<< prev`): o python recebia o baseline como script e rodava nada — saída vazia = "limpo" falso. Cura: baseline anterior via variável de ambiente. Classe conhecida: exit 0 + saída vazia não é verificação.

## Fora de escopo declarado
- Os 125 caminhos nus ficam no baseline (SOFT); a cura é por manifesto/fonte no F2 (embarcar no dono; `allowed-tools` primeiro).
