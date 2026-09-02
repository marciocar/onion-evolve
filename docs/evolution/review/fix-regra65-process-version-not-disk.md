---
title: "Revisão — REGRA 65 lê a versão do PROCESSO, não do disco (hook de drift + 2º SOFT)"
date: 2026-09-02
branch: fix/regra65-process-version-not-disk
reviewer: "condutor com gate executado: pre-commit COMPLETO (lint 0 HARD + bancada inteira, rc=0) no commit ade77b90; famílias novas run_version_drift_selftests 5/5 e radar-staleness (f)/(g) 2/2 provadas no runner real; radar radar-E3 --integrity --schema exit 0 (19/20); dogfood do hook com drift simulado (ONION_CC_EXECPATH=…/2.1.247) emitiu o aviso, rate-limit calou a 2ª vez, sem drift calou"
reviewed_diff_sha256: 75594a0629a55492a8e9c56b9d72c936bc7789ed938bb8c842919c140545f00d
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 120000
duration_min: 70
---

# Resíduo — REGRA 56

Fecha o fio nascido da medição do PreModelSwitch (PR #767): picker, hooks e capacidades refletem a
versão do PROCESSO; a REGRA 65 lia o disco. Este commit foi validado pelo pre-commit completo; o
resíduo entra em commit de checkpoint e o gate que aprova o PR é o CI no head.

## Achados

1. **O 1º commit foi REPROVADO pelo gate** (rc=1): o `CLAUDE_CODE_EXECPATH` da própria sessão vazava
   para dentro do fixture (f) da bancada e o caso mudava de resultado entre CI (sem sessão) e pre-commit
   (dentro de uma). Cura: o override `ONION_CC_EXECPATH` vale quando DEFINIDO, mesmo vazio (`-` em vez
   de `:-`), no lint e no hook — a bancada isola. O caso "sem sinal do processo" da família nova passava
   por coincidência (processo real == disco falso) pelo mesmo vazamento; corrigido junto.
2. **Bug de mensagem** `${proc_cc:+processo}${proc_cc:-instalado}=` expandia o valor ("processo2.1.247=2.1.247")
   — pego no dogfood do lint com processo simulado; rótulo explícito.
3. **UserPromptSubmit, não SessionStart**: no início processo e disco coincidem por construção; o drift
   nasce quando o auto-updater roda com a sessão viva. Só um hook ao longo da vida da sessão o vê.

## Não mudou

- Nenhum veto: o hook avisa 1x por (sessão, versão-do-disco) e nunca bloqueia — reiniciar é ato do maestro.
- CI (sem sessão) segue lendo o disco: fronteira declarada no nó `D_REGRA65_MEDE_O_PROCESSO`.
- `D_HOOK_PREMODELSWITCH_GUARDA` continua `open` — a guarda vem no PR seguinte (#769).
