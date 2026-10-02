---
name: guard-lens
description: A lente da forja de guardas — carrega ao tocar hook ou check de lint.
paths:
  - .claude/hooks/**
  - .claude/validation/*-check.sh
---

# 🛡️ Você está tocando uma GUARDA

A doutrina inteira está em
[`common:prompts:guard-doctrine`](../commands/common/prompts/guard-doctrine.md) — **leia antes de
selar**, não depois. O que mais falha, medido nesta casa:

1. **Sem defeito medido e datado, não se forja.** Guarda é dívida de manutenção permanente. Sem dano
   observado com evidência, o desfecho correto é **nó com gatilho nomeado**.
2. **A bancada tem de exercitar o artefato COMO O RUNNER O INVOCA.** Medido em 2026-10-02 no caso
   mais caro possível: 6 casos verdes alimentando uma função **pura**, enquanto **quatro de cinco
   bloqueadores** viviam na metade que nenhum caso tocava — a guarda vetava **todo turno honesto**
   em produção com a bancada verde. `bancada-espelha-o-runner`.
3. **O mutante é o que separa guarda de enfeite.** Reverta a cura e **exija** que o caso reprove.
   Caso que passa verde com a cura revertida **dá licença**.
4. **Ela erra para o lado de CALAR.** Falso positivo treina a sessão a ignorar o veto, e veto
   ignorado é pior que veto ausente. Na dúvida, declare que não sabe.
5. **O motor do padrão decide a sintaxe, e o locale do script não é o seu.** `[[:space:]]` é POSIX
   do `grep` e o `re` do Python o trata como *nested set*; `n[ãa]o` não casa em locale `C` no GNU
   grep. Meça com `/usr/bin/grep` e `LC_ALL=C` — o `grep` da shell interativa aqui é uma **função
   que chama o ugrep** e casa por caractere em qualquer locale.
6. **Registro é parte da forja**, não o passo seguinte: `.claude/settings.json` para hook,
   dispatcher do `lint-artifacts.sh` para check. Guarda exercitada e não registrada nunca dispara.

Censo antes de escrever: `bash .claude/validation/guard-census.sh . --markdown` — ele diz os moldes
por substrato, se a classe já está coberta, e o passivo. Superfície: [`/meta:forge-guard`](../commands/meta/forge-guard.md).
