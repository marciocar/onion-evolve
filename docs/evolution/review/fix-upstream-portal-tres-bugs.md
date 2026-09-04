---
title: "Revisão — três bugs upstream do portal-gamificacao: workflows na adoção, inventário rastreado, assunto pt-BR no durable-commit"
date: 2026-09-04
branch: fix/upstream-portal-tres-bugs
reviewer: "condutor com dogfood EXECUTADO (incl. re-prova sob env -i após o CI reprovar): família upstream_portal_fixes 4/4; TRÊS mutantes provados um a um (find de volta → (a) reprova; want= sem workflows → (b) reprova; assunto em inglês → (c) reprova); inventário do core idêntico ao commitado após a cura"
reviewed_diff_sha256: 0e5f9560677732a4bd8106c130269f11599907e4a3c75e9e4db43243d2064a8a
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 120000
duration_min: 45
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **A guarda casava o comentário, não o código.** O caso (b) ficou verde com o mutante aplicado porque o comentário que eu escrevi acima do `want=` também cita `.claude/workflows`. Corrigido para `^[^#]*want=\(.*\.claude/workflows` — e só então o mutante mordeu. Classe: assert de conteúdo tem de ancorar no CÓDIGO e ignorar prosa (a guarda `shell-pipefail` já fazia isso; a minha não).
2. **A família abortou sob `set -euo pipefail`** na primeira execução: `grep` sem match dentro de pipeline de extração sai 1 e mata a suíte. Blindado com `|| true`. É a classe `bancada-espelha-o-runner`, quinta ocorrência.
3. **O assert usava um formato de saída imaginado** (`**N** agentes`); o real é `| Agentes | **N** |`. Conferido no artefato antes de corrigir, não deduzido.
4. **Escopo declarado:** a enumeração rastreada cobre comandos e agentes (as contagens que o sinal mediu). Skills e KBs seguem por `find` — mesma classe latente, sem ocorrência medida; anotado como fio, não curado às cegas.

5. **O CI reprovou o que passou local — 6ª ocorrência da classe.** O caso (c) roda o `durable-commit`, que faz o PRÓPRIO `git commit`; o runner não tem `user.email` global, o helper saiu 1 e, sob `set -e`, MATOU a suíte (a bancada acusou "abortou antes da soma" em vez de mentir verde). Cura: identidade por env (`GIT_AUTHOR_*`/`GIT_COMMITTER_*`) + invocações blindadas com `|| true`. Provado agora sob `env -i PATH=… HOME=/nonexistent` — o ambiente do runner, não o meu.

6. **O CI reprovou por um caso ALHEIO, e a causa era estado EXTERNO ao sandbox.** O `outbox-channel: severidade` comparava os totais do lint em dois instantes do MESMO sandbox; a REGRA 65 (Radar de mundo com baseline DATADA por eixo) lê a versão do binário `claude`, que atualizou de 2.1.260 para 2.1.261 ENTRE as medições — HARD 32→33 e reprovou sem defeito na regra. Cura: sandboxes IRMÃOS de uma cópia única + ambas as medições sob `env -i` (ambiente congelado). Provado: mutante SOFT→HARD reprova (33→34); 4 rodadas concorrentes idênticas (SOFT 8→11, HARD 32).

## Fora de escopo
- Os outros 3 sinais do mesmo adotante (feature do `kg-inbox`, 2 field-signals) — aprovados para depois.
- `docs/onion/radar-sources.yaml` na adoção: o sinal cita, mas é decisão de escopo (roster do core × roster do adotante), não bug.
