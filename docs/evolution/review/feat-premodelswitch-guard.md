---
title: "Revisão — guarda PreModelSwitch 1+3: veta downgrade fora do lineup, loga sempre"
date: 2026-09-02
branch: feat/premodelswitch-guard
reviewer: "condutor com medição executada: bancada run_premodelswitch_guard_selftests 11/11 + radar-staleness (h)/(i) 2/2 isoladas no runner; lint --only radar-baselines.yaml e --only settings.json rc=0, 0 HARD; radar Fable --integrity --schema exit 0 (34/34, no teto); hook piped com o payload REAL medido no #767; backlog regenerado LC_ALL=C"
reviewed_diff_sha256: dd2c43187e98b20ca9a62c481ba12205ed57145efb94017bcae5b9fe8f67493a
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 90000
duration_min: 40
---

# Resíduo — REGRA 56

Selo do maestro (2026-09-02): *"sela 1 + 3: veta downgrade e loga sempre"* — depois de provado que o
evento dispara (#767) e de curada a cegueira processo-vs-disco (#768) que faria a guarda ser fail-open
em silêncio.

## Achados

1. **Baseline é DADO, não prosa**: `session_models` no eixo E6 de `radar-baselines.yaml` (a saída
   datada do radar de modelos), não na KB de orquestração — muda por rodada E6, nunca por `/model`.
2. **Desarmar por omissão é fail-open**: sem o arquivo (adotante) a guarda desarma e LOGA; com o arquivo
   e sem a chave, VETA (fail-loud) **e** o lint acusa HARD (`check_session_models_baseline`) — a
   omissão nunca passa em silêncio. O check lê o arquivo REAL (`ONION_SESSION_MODELS_FILE` só para a
   bancada) para não disparar nos fixtures da REGRA 65.
3. **Sufixo de contexto**: `requested_model: claude-fable-5-1[1m]` vs `to_model: claude-fable-5-1`
   (medido no #767) — o match ignora `[…]`, senão o próprio Fable 5.1 seria vetado.
4. **Vendorização**: `settings.json` copia para todo adotante via `/meta:adopt`; por isso a guarda
   desarma sem baseline em vez de vetar — declarado no cabeçalho do hook.

## Não mudou

- `D_HOOK_PREMODELSWITCH_GUARDA` segue `open`: o veto **ao vivo** no `/model` do maestro ainda não
  foi observado (hooks carregam no início da sessão — exige reiniciar após o merge). É o dogfood que fecha.
- Nenhuma confirmação por custo de cache (opção 2) — não selada.
- Processo < 2.1.251 não chama o hook: fronteira, coberta pelo par `session-version-drift.sh` (#768).
