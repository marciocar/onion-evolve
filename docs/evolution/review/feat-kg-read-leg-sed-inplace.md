---
branch: feat/kg-read-leg-sed-inplace
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 2
tokens: 0
duration_min: 40
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: agente de execução (passada própria sobre o diff, com mutantes)
nota: "tokens não medidos (0): passada no próprio contexto do agente de execução"
---

# Passada adversarial: `feat/kg-read-leg-sed-inplace`

## O que muda

O `kg-read-leg.sh` (PreToolUse, lembrete por `additionalContext`, exit 0 sempre) ganha o ramo
do Bash in-place: `sed -i` (com `-i.bak`, `-Ei` e `--in-place`) e `perl -pi`/`-i` sobre arquivo
que o índice de leitura conhece avisam com o mesmo texto do Edit. O caminho relativo é resolvido
pelo `cwd` do payload. O matcher do hook no `.claude/settings.json` já era `Read|Edit|Write|Bash`,
então não mudou.

**Reuso medido, e não duplicação.** O parser de comando da guarda do .env (`segments`, sobre o
`LinearShlex` linear, com o corte de comentários e de `\;`) vive inline no `GUARD_PY` de
`pretooluse-env-guard.sh`, e esse veto viaja sozinho no manifesto do plugin. Extrair o parser
para `hooks/lib/` faria o veto depender de um 2º arquivo que o plugin não leva, e veto que falha
fecha: barraria todo Bash. Por isso o hook lê a fonte da guarda e carrega por `ast` só as
definições (import, def, class e constantes em maiúsculas). O corpo que lê a entrada fica de fora.
A família `kg_read_leg` passa a declarar `selftest-covers` sobre a guarda: se ela mudar de forma,
o (m) reprova.

## Achados

1. **Real, curado:** em `cd x && sed -i s/a/b/ f` o hook resolvia `f` pelo `cwd` do payload e
   apontava os nós de outro arquivo. Agora um `cd`/`pushd`/`popd` anterior na linha faz o alvo
   relativo calar (o absoluto segue avisando). Coberto no (o). Mutante (cd ignorado): o (o)
   reprova com o aviso indevido.
2. **Real, curado (bancada):** a 1ª redação do caso lia o rc dentro de `$(…)`, um subshell. O
   `rcs` nunca chegava e, sob `set -u`, a suíte abortava. O helper passou a gravar saída e rc no
   mesmo shell.
3. **Não real:** o custo. O parse da guarda leva cerca de 0,1 s e só roda quando há `sed`/`perl`
   e uma chave com `i` ou `--in-place`. `git status` segue em ~8 ms e `sed -n` em ~9 ms (sonda
   no host); o caso (j) da bancada, sem python no caminho mudo, segue verde.
4. **Não real:** a guarda do .env. Ela não muda neste PR. A família `env_exposure` roda verde
   junto com a `kg_read_leg` (37 de 37).

## Mutantes

- **Hook da origin/main** (sem o ramo): o (m) reprova com `sed-i=[] in-place=[] perl=[] cwd=[]`.
- **(q-MUT) na própria bancada:** o laço dos segmentos é desligado e o `sed -i` volta a calar.
- **`cd` ignorado:** o (o) reprova.

## Limites declarados

- Fica calado, sem aviso: `sed -i` dentro de `bash -c "…"`, `xargs`, `find -exec`, alvo por
  glob ou variável, e alvo relativo depois de `cd`.
- Uma linha `sed -i … f` no corpo de um heredoc é lida como comando, como na segmentação da
  guarda. Pode dar aviso a mais, nunca bloqueio.
- Sem a guarda do .env ao lado (instalação parcial), o ramo cala com rc 0. Isso está coberto no (p).
