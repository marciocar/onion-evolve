---
title: "Revisão — PreModelSwitch dispara (medido): pré-condição do D_HOOK_PREMODELSWITCH_GUARDA satisfeita"
date: 2026-09-02
branch: research/premodelswitch-fires-measured
reviewer: "condutor com medição executada: sonda não-bloqueante em settings.json, sessão reiniciada 2.1.247→2.1.258, troca Opus 5→Fable 5.1 pelo picker → 2 linhas no log (Pre+Post) com payload; radar --integrity --schema exit 0 (33 nós, teto 34); backlog byte-identical LC_ALL=C; pre-commit completo 0 HARD sem --no-verify"
reviewed_diff_sha256: 81c0741f4b880e6b0f7e2b7862b67b5282b2c9173f432b9c55a8a4bd80432489
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 45000
duration_min: 25
---

# Resíduo — REGRA 56

Fecha a pré-condição da decisão proposta pela pesquisa Fable 5.1 (PR #763): o hook estava declarado no
CHANGELOG, não observado. Agora está observado, com payload e custo. A decisão segue `open` — o que a
guarda faz é selo do maestro.

## Achados

1. **Pré-condição escondida no meu próprio plano**: registrar o hook não bastava — a sessão interativa
   rodava 2.1.247 (binário já deletado do disco pelo auto-updater) e o evento nasceu em 2.1.251. O picker
   mostrava "Fable 5.1 (disabled)" num sistema em 2.1.258: ele reflete o PROCESSO, não o disco. A REGRA 65
   compara o disco — fio candidato nomeado no apêndice, não aberto.
2. **O Pre pode vetar**: strings do binário ("model switch blocked by a PreModelSwitch hook", "asked you to
   confirm") — a guarda pode ser exit-2 ou confirmação, não só log.
3. **Sonda não pode ser commitada**: `/meta:adopt` copia `.claude/` inteiro; a sonda viraria hook em todo
   adotante. Removida após medir; o log bruto vive em `data/probe-premodelswitch.md`.

## Não mudou

- `D_HOOK_PREMODELSWITCH_GUARDA` continua `open` (label intocado; a memória da medição vive na aresta).
- Nenhum hook novo em `settings.json` neste PR.
- `requested_model` com `[1m]` vs `to_model` sem: registrado como observação, não investigado.
