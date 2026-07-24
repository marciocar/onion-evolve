---
date: 2026-07-24
instance: onion-evolve
type: learning
classification: collective
tags: [workflow, resume, cache, orchestration, declarado-vs-verificado, custo, tooling]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Ao retomar um Workflow via resumeFromRunId, NÃO afirmar que é 'barato/cacheado' sem VERIFICAR: o cache do resume só é confiável se o run anterior TERMINOU LIMPO. Se o run foi morto por saída de processo (troca de sessão) ou ficou noutra sessão, o journal/cache pode não sobreviver e o resume RE-EXECUTA tudo. Antes de prometer 'não re-faz o caro', cheque: mtime do output (foi reescrito agora?) e o agent_count do run (== total de agentes = re-executou; == só os pendentes = cacheou)."
review_after: 2026-10-22
conflict_class: conditional
valid_when: "a ferramenta Workflow mantém o cache de resumeFromRunId no journal do run anterior; interrupção por morte de processo pode não persistir/alcançar esse journal (comportamento observado 2026-07-24; re-verificar se a semântica de resume mudar)"
significance: "Afirmei que retomar um workflow interrompido seria barato ('cacheia as 4 leituras + a síntese') — o maestro cobrou, e a evidência me refutou: agent_count 6 (todos) + 461k tokens + mtime do doc reescrito 42s atrás = o resume RE-EXECUTOU o caro. O cache do resume não sobreviveu à morte do processo."
---

## Signal
**Resume de workflow interrompido por morte de processo NÃO é cache barato — re-executa.** A ferramenta
`Workflow` promete que `resumeFromRunId` faz agentes completos voltarem do cache instantâneo. Mas isso vale
quando o run terminou limpo. Quando o run foi **morto por saída de processo** (uma troca de sessão, o
processo Claude Code anterior saindo), o journal/cache pode não persistir nem ser alcançável do resume — e
ele **re-roda tudo**. Eu afirmei "barato/cacheado" sem verificar; era `declarado≠verificado` sobre custo.

## Evidence
- Um workflow (`wf_3d0dc434-034`, refresh da síntese de federação) foi interrompido no meio (verify pendente)
  por saída do processo anterior. Retomei com `resumeFromRunId`, dizendo ao maestro que Gather+Synthesize
  voltariam do cache e só o Verify rodaria.
- O maestro cobrou. Verificação: `stat` do doc → mtime **42s atrás** (reescrito no resume, não do 1º run de
  >9min antes); `agent_count: 6` (4 gather + synth + verify = **todos**, não só o verify); `subagent_tokens:
  461799`. Conclusão dura: **re-executou o caro.** O journal do run anterior estava noutra sessão
  (`c5193106` vs o resume em `6e6d8cc8`) — o cache cross-sessão-após-morte não pegou.
- Diagnóstico do sinal barato: o cache do resume só vale se o run **terminou limpo**; morto no meio,
  re-executa.

## Next crumb
Ver `next_recommended`. É um caso concreto de [[what-the-maestro-taught-me]] — verificar antes de afirmar,
inclusive sobre **custo** (não só sobre estado). Antes de dizer "resume é barato", olhe `mtime` + `agent_count`.
