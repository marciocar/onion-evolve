---
title: "Revisão — poda de instruções, camada L1: hook InstructionsLoaded + censo de carga (pré-requisito resolvido no binário)"
date: 2026-09-03
branch: feat/poda-l1-instructions-loaded
reviewer: "condutor (tier 10: payload lido do binário 2.1.259; família instructions_loaded 4/4; censo testado com log sintético) — o L2 (replay de comportamento) fica gated no censo (≥ 20 sessões ou 14 dias)"
reviewed_diff_sha256: 16aee7063fc54b34895748f365e2e741c7bebea1886e09985984aff21506424e
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 120000
duration_min: 40
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Opção C re-especificada (recomendação do Elenxo da poda): medir COMPORTAMENTO, não carga. A decisão nascia com uma dependência
declarada — a spec do payload do hook `InstructionsLoaded`. Resolvida no binário (tier 10): `file_path`, `memory_type`, `load_reason`
∈ {session_start, nested_traversal, path_glob_match, include, compact}, `globs`, `trigger_file_path`, `parent_file_path`. O hook
registra CARGA, não influência → a decisão passa a ter ORDEM: L1 (censo de carga, mecanismo barato, este PR) → L2 (replay de
comportamento nos dois tiers, dirigido pelas candidatas do L1; protocolo em `docs/analysis/poda-instrucoes-protocolo-2026-09.md`).

## Achados

1. **O hook nunca veta e nunca derruba a sessão**: exit 0 sempre; payload inválido ⇒ nada escrito (caso (b)). Log fora do git
   (`.claude/sessions/` já ignorado), formato irmão do `model-switch.jsonl`.
2. **O censo marca candidatas, não decide**: `SO-SESSION-START` (regra/skill com `paths:` que só entra por session_start) e `NUNCA`
   (`paths:` que nunca casou). Sem log ⇒ exit 3 declarando, nunca 0 calado (caso (d)).
3. **Hook novo exige sessão NOVA para disparar** (lição do PreModelSwitch, 2026-09-02): o primeiro dado real chega na próxima
   sessão do maestro; o gatilho do L2 é o censo com ≥ 20 sessões ou 14 dias. Grafo da poda: +1 nó (TETO 19→20 justificado).
4. **Carona (4ª ocorrência de `kg-reverify-schema` no gate, com a saída capturada):** o helper reprovou 1 dos seus 7 casos DENTRO
   da bancada e passa isolado — ambiente herdado do worker. A família passa a rodar o selftest do helper em `env -i` (hermético por
   construção) e a falha mostra as linhas ✗ do helper. Gate refeito.
