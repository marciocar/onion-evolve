---
branch: fix/moat-gate-indirection
pr: 1154
date: 2026-10-15
reviewed_diff_sha256: 6a2686f42fdc143f723e21eab8070b8489f56cbdb06a936a4b90ef328a5294f1
reviewed_code_sha256: 3539d3dd4501f3f217f0d7141677640d6b7302a2374b1131c7639555b6e2ba00
findings_total: 14
findings_real: 14
tokens: 230996
duration_min: 11
findings_fixed: 14
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose (opus), mandato REFUTAR, 2 passadas"
nota: "tokens e duração são os do refutador (104.630 + 126.366 tokens; 340 s + 292 s). A forma echo X | { true; bash; } segue aberta e não conta como achado deste diff: é classe anterior, fora de função, e passa igual na versão de origin/main."
---

# Passada adversarial: `fix/moat-gate-indirection`

## O que muda

A lib dos vetos PreToolUse (`.claude/hooks/lib/invocation-lines.sh`) passa a EMULAR a função definida na própria
string. A cada chamada, o corpo é re-julgado com `$1`/`$@`/`$*` trocados pelos argumentos literais e com o stdin
da chamada (pipe literal, here-string, heredoc). `bash -c TEXTO a0 a1` dá os posicionais ao texto, e `alias` da
string é re-analisado. A mudança vale para os três vetos que usam a lib: MOAT, merge e protect-main. No juiz do
MOAT (`moat-judge.py`), o par motor escritor + `create|revoke` conta como ação no trecho inteiro, `-I{}` colado
conta como substituição do `xargs`, e o ponto opaco dentro de uma função emulada julga o que entrou pelos
argumentos.

A opção vem de medir antes de mudar (SAC-148). Fechar toda indireção que cita um alvo, a opção (a), barraria
217 comandos honestos do corpus. São 93% dos 233 comandos com indireção e alvo, quase todos leitura. A emulação,
a opção (c), mudou 0 veredito em 5.258 comandos (MOAT) e em 2.004 (merge e protect-main). A reexecução foi
refeita depois de cada rodada de curas.

## Achados

1ª passada (contra ee3a1370), todos curados com caso:
1. ALTA, regressão: a função homônima escondia o programa (`gh pr merge 5; gh(){ :; }` e `( git(){ :; } ); git push --force origin main` iam de rc 2 para 0). Cura: a função não esconde o programa (fn2, fn3).
2. ALTA: redefinição depois da chamada → toda definição conta (fn6).
3. ALTA: definição depois de `then`/`do`/`{` → posição de comando (fn4).
4. ALTA: `}` entre aspas fechava o corpo → chave só em posição de comando (fn5).
5. ALTA: stdin entrando na função (`echo '<cmd>' | run`) → o stdin entra no corpo (i30).
6. ALTA: `printf -v c "%s" "$1"` gravava o formato → grava o argumento (i31).
7. ALTA: `alias r="bash -c"` → alias da string expandido (i32).
8. MÉDIA-BAIXA, falso positivo: o nome do motor num comentário de `python3 -c` só-leitura → exige `create|revoke` (i33).
9. BAIXA: fan-out exponencial → teto de 256 chamadas (i34).

2ª passada (contra 8af584b4), todos curados com caso:
10. MÉDIA-ALTA, regressão da cura 8: `python3 -c` multilinha com motor e `revoke` em linhas diferentes → o par vale no trecho inteiro (i35).
11. MÉDIA, falso positivo: `x(){ command x "$@"; }` recursava até fechar → `command`/`builtin` chamam o programa (i36, fn9).
12. MÉDIA: alias com `;`/`|` no texto → o texto é re-analisado (i37).
13. MÉDIA: here-string/heredoc na chamada e stdin lido pelo 2º comando do corpo → viram stdin da chamada, e todo comando do corpo o lê (i38, i39, i40).
14. BAIXA, falso positivo: o teto fechava a string honesta inteira no veto de merge → além do teto fecha só se o que entra na chamada é relevante (fn8).

## Mutantes

Cada um dos 33 casos novos (i17–i40 na `moat_gate`, fn1–fn9 na `pretooluse_veto`) é provado contra o mutante da
própria cura pela `_prove_mutation` da bancada. As duas famílias saem 443/0 com `LC_ALL=C`. No hook vivo,
`ops/mutate-and-restore.sh` plantou 4 mutantes: sem emulação, motor fora da ação, `-I` colado e ponto opaco sem
os argumentos da chamada. Com eles, as formas medidas da SAC-148 voltam a rc 0. Restaurado por hash, sem
marcador ONION_MUTANTE.

## Limites declarados

A análise estática não fecha indireção arbitrária (Rice). Seguem fora:
- `getopts`;
- laço sobre os argumentos fora de função;
- `$(…)` dentro do corpo, julgado só na definição;
- `echo X | { true; bash; }`, que é classe anterior;
- motor renomeado sem o marcador `MOAT-ARG-WRITER:`;
- alvo que chega por fora da string (arquivo lido, stdin opaco).

Nesses casos, a defesa que resta é a permissão do arquivo: 0600 da conta do serviço, escrita só com `sudo -u`.
Ordem e escopo de função não se modelam, então o hook erra para vetar.

## Re-revisão após o rebase sobre o #1152

O `ops/merge-serial.sh` recusou o rebase automático por um conflito real em `.claude/hooks/lib/moat-judge.py`.
O #1152 (wrapper `ops/a2a-queue-live.sh`) acrescentou ao juiz:
- `_MOAT_WRAPPER_COPIES`: a cópia do wrapper reconhecida pelo nome;
- o fechamento de `ONION_A2A_QUEUE_TEST` na linha de comando;
- 7 casos na `moat_gate`.

O conflito era de vizinhança: dois blocos novos no mesmo ponto do arquivo. Mantive os dois, sem mudar nenhum,
e a bancada não teve conflito.

Medido depois do rebase:
- **Bancada:** `LC_ALL=C`, famílias `moat_gate`, `pretooluse_veto` e `a2a_queue_live`, 515 passaram e 0 falharam. Inclui os 33 casos desta branch e os do #1152, cada um provado contra o seu mutante.
- **Hook vivo:** as 5 formas medidas da SAC-148 saem rc 2. Os 4 mutantes, replantados por `ops/mutate-and-restore.sh` no código rebaseado, as devolvem a rc 0. Restauração conferida por hash.
- **Revisor adversarial:** não repassou o código rebaseado. O diff desta branch não mudou; só se juntou ao bloco vizinho. Por isso `reviewed_diff_sha256` volta a pendente, para o `pr-finalize` carimbar de novo.

