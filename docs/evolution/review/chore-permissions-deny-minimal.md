---
branch: chore/permissions-deny-minimal
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 8c6204613d68e3646386f16bb4f2978abecbea11a3ac179a9ff36b460bfa0df1
reviewed_code_sha256: ddf8a8932f51800b81cdfbfeda239ef1084ece968dea7d7e00133a599b40279b
findings_total: 4
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, mais os mutantes por regra no motor real; nenhum refutador independente (o brief proibiu criar agentes)
nota: "tokens e duração não medidos (0). Passada do autor: cobre o que os mutantes alcançam, e não o que um terceiro acharia."
---

# Passada do autor: `chore/permissions-deny-minimal`

## O que muda

38 regras de `permissions.deny` em `.claude/settings.json`, a soma do deny da fonte no `merge-onion-hooks.sh`, a seção
da camada nativa na doutrina de guardas, a bancada no motor real (`ops/testing/permissions-deny-bench.py`) e o grafo
`docs/evolution/research/permissions-deny-minimal-2026-11/`.

## Achados

1. **Regras decorativas (curado).** O mutante por regra mostrou 11 regras que nenhum caso exigia. Dez ganharam caso;
   a do `$HOME` entre aspas saiu, porque o motor já a barra pela regra sem aspas.
2. **Regra Read com alcance maior que o previsto (curado na lista).** O motor leva a regra Read a `ls` e `stat`, e o
   censo mostrou `ls` e `find` em `~/.password-store` no fluxo real. Essa pasta saiu da lista: o conteúdo já é cifrado.
   `ls .env` fica como custo declarado, com `test -f` de saída.
3. **Bancada sem o allow real (curado).** Os casos rodavam sem o `allow` do core, que libera `Read`. Passaram a rodar
   com ele, e o deny seguiu vencendo.
4. **Falso positivo (declarado, não curado).** `git clean -nx` e `git -C . log --grep 'x push -f y'` caem na regra. Ficam
   na doutrina como custo.

## O que esta passada não viu

O sandbox no core real, o login real, e o que um revisor independente acharia. F04, F05 e F09 pararam em recusa do
próprio script no fixture: provam que o deny não barra a chamada, não que o fluxo foi até o fim.
