---
date: 2026-09-04
instance: onion-evolve
type: error
classification: public
tags: [plugins, hooks, marketplace, fail-open, behavior-over-declaration]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "REGRA 75/76 (links mortos em plugin; marketplace.json raiz == gerador)"
review_after: 2026-12-03
conflict_class: static
---

# Hook morto e silencioso no plugin: o motor não viajou e o `exit 0` escondeu

**O erro.** `plugins/onion/hooks/aside-router-hook.sh` montava `ENGINE="$REPO/${CLAUDE_PLUGIN_ROOT}/validation/aside-router.sh"` — a fonte escrevia `$REPO/.claude/validation/…` e o PATH-PORTABILITY do assembler reescreveu só a metade, produzindo um caminho absoluto prefixado por outro absoluto, sempre inválido. O motor `aside-router.sh` nem estava no manifesto. E `[ -f "$ENGINE" ] || exit 0` engolia os dois: o "aparte do maestro" estava morto e silencioso em toda instalação do plugin. De quebra, o `hooks.json` gerado descartava o `matcher: Bash` do core, então o `PostToolUse` rodava em toda tool.

**Por que ninguém viu.** Guarda nenhuma varria `plugins/`; e um `exit 0` de fail-open é indistinguível de "nada a fazer".

**Cura como mecanismo.** (1) O hook do core resolve o motor pelo próprio diretório (`$HERE/../validation/…`) — a mesma forma funciona no core e no plugin, sem reescrita. (2) O manifesto `onion` embarca o motor. (3) O gerador de `hooks.json` carrega o `matcher`. (4) REGRA 73 (`plugin-hooks-check.sh`: script-ausente, repo-prefixado, motor-ausente, matcher-divergente), HARD sem baseline. (5) REGRA 74 (`plugin-bare-path-check.sh`): 125 caminhos `.claude/` nus em plugins, catraca com baseline (só encolhe; `allowed-tools` marcado — o comando nasce morto). Bancada: 3 + 3 casos com mutante. Provado ao vivo: o hook responde ao aparte quando invocado com `CLAUDE_PLUGIN_ROOT` apontando para o plugin montado.
