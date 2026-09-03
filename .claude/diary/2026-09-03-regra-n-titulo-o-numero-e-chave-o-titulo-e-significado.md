---
date: 2026-09-03
instance: onion-evolve
type: learning
classification: public
tags: [lint, regras, nomenclatura, mecanismo, reforço]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "ler o lint: toda VIOLATION agora diz REGRA N (Título) — se alguma sair só com número, é função sem cabeçalho de REGRA acima (o registro também a acusaria)"
review_after: 2026-12-02
conflict_class: static
---

## Signal
Reforço do maestro: *"são muitas regras e eu não sei o que é a regra quando você diz 'REGRA 65'"*. Pergunta: "REGRA 65
(Título)" ou "Título (REGRA 65)"? Resposta: **REGRA N (Título)** — o número é a chave de máquina (registro, grep, catraca
de baseline), o título é o significado; esconder a chave atrás do título quebra a busca. E a resposta não fica em prosa:
o `violation()` do lint passa a imprimir `REGRA N (Título): mensagem` para TODA regra, mapeando a função `check_*` ao
cabeçalho `# REGRA N — Título` pela mesma associação que o `rules-registry.sh` já usava (69 títulos, 68 funções).

## Evidence
- Antes: `VIOLATION: docs/onion/radar-baselines.yaml: REGRA 65: Claude Code mudou de versão…` — 15 mensagens citavam o
  número; as outras ~50 regras nem isso (o número ficava implícito na função).
- Depois: `VIOLATION: …: REGRA 65 (Radar de mundo com baseline DATADA por eixo): Claude Code mudou de versão…`.
- Eu tinha a memória `rule-reference-with-name` desde julho e reincidi no relatório de hoje ("REGRA 65 SOFT" nu):
  disciplina reincide; saída de ferramenta não.

## Next crumb
O mesmo vale para quem cita regra em prosa (relatórios, PRs, migalhas): "REGRA N (Título)". Lint-rules.md continua
a SSOT dos títulos; se um cabeçalho mudar, o lint muda junto sem tocar em mensagem nenhuma.
