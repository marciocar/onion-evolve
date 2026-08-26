---
title: "Revisao — --ensure-from: adotante pre-catraca emite o proprio baseline (self-review + dogfood real)"
date: 2026-08-26
branch: fix/adopt-emit-missing-baselines
reviewer: "self-review (autor) — cura com reproducao + DOGFOOD REAL no clone do oraculo regulado; fecha o fio aberto de gatilho disparado"
reviewed_diff_sha256: 3fb19c8463ca65f9668aaa0fe0d288f85d68fccd818d0b79249cb889f00e984f
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 900
duration_min: 5
---

# Residuo — REGRA 56 (self-review; a passada foi a reproducao + o dogfood do oraculo)

Fecha D_ADOPT_MUST_EMIT_MISSING_BASELINES (fio aberto com gatilho DISPARADO: a cura da contaminacao
deixou o adotante pre-catraca com a catraca em NO-BASELINE fail-closed apos o --update).

- **Cura minima e correta?** SIM:  semeia um STUB para cada
  baseline que o core DEFINE mas o alvo NAO tem; o loop --auto o trata como "1a chegada -> emit" e o
  preenche do CORPUS DO ADOTANTE (nunca do core — KG-SSOT-First). Reusa a maquinaria de emissao que ja
  existia; nao toca a catraca critica. adopt.md passa --ensure-from no update.
- **Provado por comportamento?** SIM, em dois niveis: reproducao isolada (adotante pre-catraca: catraca
  rc 1->0, baseline presente) + DOGFOOD REAL num clone descartavel do oraculo regulado (update completo +
  --ensure-from → kg-verification-coverage rc=0, HARD:0, NO-BASELINE resolvido, baseline emitido do
  corpus dele com 0 chaves). Nunca toquei o repo real.
- **Mecanismo contra regressao?** SIM: run_regen_ensure_from_selftests 2/2 — (a) a cura resolve; (b) MUT
  sem a flag o NO-BASELINE PERSISTE, provando que --ensure-from e load-bearing.
- **Fantasma de ambiente tratado?** SIM: o 1o commit falhou por PyYAML ausente no venv (a2a-ssrf/graph
  em-sync — fantasmas, nao meu diff). Consertei o ambiente (pip install pyyaml + graph.md regenerado),
  registrei o gotcha na memoria. lint 0 HARD, kg-radar exit 0.

**Veredito: APROVADO** — os DOIS bloqueios do oraculo (contaminacao por D_CURE_PRESERVE_ADOPTER_BASELINE
+ NO-BASELINE por esta cura) estao fechados e provados; o update do oraculo agora fecha limpo. Q_GRANAAI_
UPDATE_BLOCKED->done. Resta so o maestro RODAR o update real quando quiser — a maquinaria esta pronta.
