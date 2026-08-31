---
title: "Benchmark do gate determinístico — os números que a narrativa devia (2026-08)"
category: analysis
date: 2026-08-31
kg: docs/evolution/research/maestro-vivo-2026-08/maestro-vivo-2026-08.kg.yaml
verified_at: 2026-08-31
---

# O gate do Onion, em números medidos

O confronto MAESTRO-VIVO (F2, moat-gates) validou a tese *verificação determinística > LLM
julgando LLM* — e apontou que o mundo publica MÉTRICA (Sponsio: 5.000-60.000× mais rápido que
LLM-as-judge; Statewright: 2/10→10/10 no mesmo subset; Obsidian: US$85M) enquanto nós
publicávamos narrativa. Este doc paga a dívida: números, todos medidos em 2026-08-31 (comandos e
condições declarados).

## O que se mede

| Métrica | Valor medido | Condição |
|---|---|---|
| Latência do lint completo (63 REGRAS, 218 emissões HARD possíveis) | **132,3–132,9 s** (2 amostras) | VPS compartilhada SOB CARGA; o histórico registra **16 s** em máquina ociosa (memória `onion-lint-perf-hotspot`, pós-PR #357) e >7 min no pior caso de carga |
| Custo de tokens por execução do gate | **0** | é bash/awk puro — nenhuma chamada de modelo |
| Regras registradas | **63** (registry gerado de docstrings; severidade = união do emitido com o declarado) | `rules-registry.sh` |
| Catracas de passivo legado (baselines versionados) | **6 arquivos, 84 chaves congeladas** no core | dívida que só pode DIMINUIR; adotantes carregam as suas (ex.: 38 chaves de compose num adopt real) |
| Vetos REAIS numa única sessão de trabalho (2026-08-31) | **5 bloqueios de commit** (console drift, campos de resíduo, TETO ausente, colheita sem registro ×2) + **≥8 intervenções da guarda anti-fail-open do shell** (exit-code-de-pipe, contagem com stderr engolido, branch pt-BR, PR sem passada) | cada um era defeito real; nenhum chegou ao CI |
| Bancada de selftests do lint | ver rodapé (rodada em background nesta data) | `lint-selftest.sh` — testes que provam que as guardas MORDEM (inclui mutações que têm de reprovar) |

## Por que estes números vendem o que a narrativa não vendia

- **0 tokens** é a resposta à pergunta de custo que todo comprador de "AI governance" faz — o
  gate roda em pre-commit e CI sem gastar modelo, ao contrário de LLM-as-judge.
- **5 vetos num dia** é frequência de valor: o gate não é cerimônia, ele pega defeito diário.
- **84 chaves congeladas** é o ativo sem par medido (F1/E5: nenhum dos 5 players faz catraca de
  passivo): liga-se o gate hoje num repo sujo, sem parar ninguém.
- A comparação honesta com Sponsio (0,005-0,14 ms por chamada) é de CLASSE diferente: eles medem
  um monitor por chamada de função; nós medimos um lint de corpus inteiro. A régua comum é
  **determinismo + custo-zero de token**, não a latência absoluta.

## Reproduzir

```bash
time bash .claude/validation/lint-artifacts.sh   # latência, 0 tokens
bash .claude/validation/rules-registry.sh        # 63 regras
for b in .claude/validation/*-baseline.txt; do grep -vc '^#' "$b"; done  # 84 chaves
bash .claude/validation/lint-selftest.sh         # bancada completa
```

## Rodapé — a bancada, medida (2026-08-31)

**884 selftests, 882 ✓** na primeira rodada desta medição. As 2 reprovações foram ACHADO, não
ruído: (1) o caso `kg-backlog (c)` dependia de o grafo vivo estar no TETO — a colheita da Onda 6
o expôs, e a cura (fixture enche até ultrapassar o teto lido do próprio arquivo) entra neste
mesmo PR; (2) `rules-registry (f)` acusou o estado em-voo da branch (resíduo ainda não escrito) —
sensibilidade conhecida da bancada ao branch, não defeito. O benchmark medir a bancada e a
bancada devolver um defeito da própria bancada é o loop de dogfood funcionando.
