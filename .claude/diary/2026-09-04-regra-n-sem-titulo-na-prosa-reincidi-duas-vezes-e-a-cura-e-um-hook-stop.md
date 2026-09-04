---
date: 2026-09-04
instance: onion-evolve
type: error
classification: public
tags: [regras, prosa, hook-stop, fix-must-become-mechanism, reforco-do-maestro]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "observar o hook disparar ao vivo numa sessão nova (hooks novos exigem reiniciar) e registrar o 1º veto"
review_after: 2026-12-03
conflict_class: static
---

# "REGRA N" sem título na prosa — reincidi duas vezes, e a cura é um hook Stop

**O reforço do maestro (2026-09-04):** *"criamos uma obrigação de quando falar da regra… tem que ser 'REGRA X (Título da REGRA X)' e você não está cumprindo. Por quê? Como resolve?"* — decisão de 2026-09-03; reincidência em 09-03 (1×) e 09-04 (várias: "REGRA 74", "REGRA 72", "REGRA 19").

**Por quê.** O mecanismo existia só no lint (`violation()` imprime `REGRA N (Título)`); na minha PROSA não havia guarda nenhuma. Gatilho social é cura nula (já medido em 08-02): lembrar não é mecanismo. O estilo conciso empurra para a forma curta; a memória `rule-reference-with-name` foi lida e não bastou.

**Como resolve (mecanismo).** Hook `Stop` `.claude/hooks/rule-title-in-prose.sh`: lê a última resposta do assistente no transcript, apaga blocos de código, procura `REGRA N` sem `(` logo depois e devolve `exit 2` com a forma correta — títulos vindos dos cabeçalhos `# REGRA N — Título` de `lint-artifacts.sh` (SSOT, nunca lista à mão). Anti-loop por `stop_hook_active`. Cadeias "REGRA 73/74" contam uma vez. Selftest 3/3; simulação com transcript de mentira devolveu `exit 2` e a forma correta.

**Teto declarado.** O hook vê o texto do assistente, não o que subagentes escrevem em arquivos; e hooks novos só valem em sessão nova (medido 09-02 com o PreModelSwitch) — o 1º veto ao vivo ainda não foi observado.
