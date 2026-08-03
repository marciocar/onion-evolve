---
date: 2026-08-03
instance: onion-evolve
type: learning
classification: collective
tags: [fail-open, shell-guard, verificacao, dogfood, behavior-over-declaration]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-01
conflict_class: static
significance: "A guarda anti-fail-open nasceu em 02-08 e no PRIMEIRO dia de uso real por outra sessão me pegou 4 vezes — e as 4 foram o MESMO eixo: eu lendo sinal derivado em vez do vivo. O eixo tem forma, e a forma é medível."
---

## Signal

Quando eu quero saber se algo deu certo, meu erro **não é esquecer de verificar** — é verificar
o **sinal derivado** em vez do vivo. Exit code de pipe, linhas `✓`, `2>/dev/null` antes de um
`wc -l`, um waiter que casou por substring: todos *parecem* verificação e nenhum toca o fato.
A cura não é "prestar mais atenção" (cura nula, ver `self-correction-trigger-was-social`) — é
que a guarda exista e **interrompa**.

## Evidence

- **4 capturas em uma sessão**, todas legítimas, todas o mesmo eixo:
  1. `2>/dev/null` a montante de `wc -l` numa varredura de contagens de `docs/` — pasta ausente e
     comando falho produziriam o mesmo `0`. Re-medi com `if [ -d ]` + stderr visível.
  2. `bash lint-selftest.sh | tail -15; echo "EXIT=$?"` — o `$?` é do `tail`. Eu teria declarado
     o selftest verde **sem ele ter passado**.
  3. Waiter `until ... grep -qE 'Sumário|passou|PASS'` casou por substring enquanto o selftest
     **ainda rodava** (138 linhas e subindo). Fui ao `pgrep` e o processo estava vivo.
  4. `gh pr merge 517 --squash | tail -5; echo "EXIT=$?"` — output **vazio** + `EXIT=0` do `tail`.
     Sem a guarda, eu teria anunciado "mergeado" sem evidência nenhuma.
- O que provou o merge de fato foi `git log origin/main` mostrando `797109c ... (#517)` — o vivo,
  não o exit code. Mesmo padrão do `org-map-boundary-closed-live-verify`.
- **Contraprova de que a guarda é load-bearing**: nas 4 vezes o comando já tinha rodado e eu já
  tinha a conclusão errada formada. O que mudou o resultado foi o `exit 2` do PostToolUse chegar
  ao modelo (mecanismo de `posttooluse-exit-2-is-the-only-channel`), não eu reconsiderar.
- Um 5º erro do mesmo dia foi pego por **outra** guarda: editei `plugins/onion-engineering/` à mão
  sendo ele artefato **gerado**; o lint reprovou com `tree_sha divergente`. Revertí e regenerei via
  `assemble-plugin.sh`. Eixo irmão: agir sobre a projeção em vez da fonte.

## Next crumb

O eixo tem uma forma nomeável — **ler a projeção em vez da fonte** (exit de pipe pela execução,
linha `✓` pelo veredito, arquivo gerado pela SSOT). Vale checar se as guardas atuais cobrem as
outras projeções da mesma família: `grep -c` sobre saída truncada por `head`, `test -f` sobre
symlink quebrado, e `gh pr view --json <campo>` com campo inexistente (que **falhou silencioso**
nesta sessão — `merged` não existe no schema do `gh` e o comando saiu 1 sem que eu notasse
de imediato).

_Sem `kg:`: nasceu de uso direto, não de investigação multi-round — não há cadeia de claims/evidência
a reconciliar, só um contador de 4 ocorrências observadas. Modelar como grafo seria cerimônia._
