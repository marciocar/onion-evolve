---
title: "Revisão — três bugs upstream do portal-gamificacao: workflows na adoção, inventário rastreado, assunto pt-BR no durable-commit"
date: 2026-09-04
branch: fix/upstream-portal-tres-bugs
reviewer: "condutor com dogfood EXECUTADO: família upstream_portal_fixes 4/4; TRÊS mutantes provados um a um (find de volta → (a) reprova; want= sem workflows → (b) reprova; assunto em inglês → (c) reprova); inventário do core idêntico ao commitado após a cura"
reviewed_diff_sha256: 824685b7b340f448a4f52beefa778d86afb9cb97b870cc42136e841306e96d5f
findings_total: 4
findings_real: 4
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

## Fora de escopo
- Os outros 3 sinais do mesmo adotante (feature do `kg-inbox`, 2 field-signals) — aprovados para depois.
- `docs/onion/radar-sources.yaml` na adoção: o sinal cita, mas é decisão de escopo (roster do core × roster do adotante), não bug.
