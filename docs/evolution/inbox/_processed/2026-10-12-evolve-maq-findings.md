---
title: 'MAQ do /meta:evolve no adotante: um blocker e três recomendados no medidor e nas guardas do core'
date: 2026-10-12
from: onion-kg-ssot (produto KG-SSOT, papel adopted)
to: core
type: field-signal
pin: dcdacf9ba196
---

# Sinal: o que a dimensão MAQ achou

O `/meta:evolve` rodou pelo comando, com a seção 7 do raio-X como `maqTargets` (run `wf_a360563c-2f3`). Os 5 achados
sobreviveram ao refutador e todos são código do core. O worker confirmou no core em HEAD `6e7d546e8911`.

| Id | Sev | Alvo | Achado | Cura mínima proposta pelo worker |
|---|---|---|---|---|
| MAQ-0 | blocker | `.claude/validation/evolve-census.sh:173-180` | a seção 7 dá create-skill e create-vertical como "vigiados por guarda", mas o grep casa `/meta:<cmd>` em comentário (`cited-directive-check.sh:6`, `marketplace-root-check.sh:45`) e em string de mensagem (`cited-directive-check.sh:204`) | tirar comentário e string de mensagem antes do grep, ou exigir elo estrutural; fixture em que citação só em comentário não conta |
| MAQ-1 | recommended | `evolve-census.sh:116-120 e 217-221`, `instructions-loaded-census.sh` | no adotante, as 4 lentes "com paths: que nunca casou" são ausência de objeto no papel (dissect casa 0 arquivo) e amostra de uma sessão (49 linhas, 48 de uma sessão) | imprimir N de sessões e a janela ao lado de NUNCA, e rotular SEM-OBJETO-NO-PAPEL reusando `_rule_without_object_for_role` (`lint-artifacts.sh:1112-1131`) |
| MAQ-2 | recommended | `.claude/hooks/pretooluse-env-guard.sh:121, 151, 338, 351-355` | o veto lê texto citado como shell: um `(` dentro de aspas zera a pasta conhecida, o token entre aspas simples é julgado como glob, e `for` não está nas palavras-chave. Veto fail-closed com mensagem que engana. Reproduzido por stdin sintético (sondas p3 e p4) | decidir subshell pelos tokens do shlex, não por substring; token entre aspas não é glob; `for` nas palavras-chave; levar p3 e p4 à bancada |
| MAQ-3 | recommended | `.claude/validation/forge-census.sh:49` | os 37 comandos 1/7 incluem `commands/meta/README.md` e 7 skills, que não são comandos; o alvo cai para no máximo 29 | excluir README (como `lint-artifacts.sh:1061`) e separar skill de comando |
| MAQ-4 | opportunistic | `consumed-mode-check.sh:35-41, 171-176` | o extrator da REGRA 59 ainda lê `bash …x.sh --flag` dentro de mensagem como invocação; teto declarado, sem sítio vivo hoje | nenhuma urgente |

**Alerta transversal:** MAQ-0, MAQ-2 e MAQ-4 são a mesma classe, "texto citado lido como invocação viva", em três
mecanismos. A guarda da classe existe no harness (REGRA 98), mas não nos confrontos dos censos nem no env-guard.

Do lado daqui: o grafo de auditoria `docs/analysis/onion-evolution-2026-10-12.kg.yaml` registra isso como
`C_EVOLVE_MAQ_CITED_TEXT_AS_GUARD_1012` e `C_EVOLVE_MAQ_UPSTREAM_RECOMMENDED_1012`. Nada foi curado aqui: é código de
vocês e chega pelo update.
