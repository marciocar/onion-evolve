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
| Latência do lint completo (64 REGRAS, 88 pontos de emissão HARD + 11 de severidade variável) | **132,3–132,9 s** (2 amostras) | VPS compartilhada SOB CARGA; o histórico registra **16 s** em máquina ociosa (memória `onion-lint-perf-hotspot`, pós-PR #357 — corpus de julho, NÃO re-medido no corpus atual) e >7 min no pior caso de carga |
| Custo de tokens por execução do gate | **0** | é bash/awk puro — nenhuma chamada de modelo |
| Regras registradas | **64** (registry gerado de docstrings; severidade = união do emitido com o declarado) | `rules-registry.sh` |
| Catracas de passivo legado (baselines versionados) | **6 arquivos, 84 chaves congeladas** no core | dívida que só pode DIMINUIR; adotantes carregam as suas (ex.: 38 chaves de compose num adopt real) |
| Vetos REAIS numa única sessão de trabalho (2026-08-31) | **5 bloqueios de commit** (console drift, campos de resíduo, TETO ausente, colheita sem registro ×2) + **≥8 intervenções da guarda anti-fail-open do shell** (exit-code-de-pipe, contagem com stderr engolido, branch pt-BR, PR sem passada) | OBSERVADO NA SESSÃO, não-reproduzível por comando — os SHAs dos commits bloqueados são o rastro; célula rebaixada a testemunho pelo Elenxo |
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
bash .claude/validation/rules-registry.sh        # 64 regras
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

## Emendas do Elenxo (2026-08-31, mesma passada)

O refutador da passada derrubou 2 células da 1ª versão: "63 regras" (a própria stack apendou a
REGRA 65 — 64) e "218 emissões HARD" (contagem de PALAVRA por grep; o número real de pontos de
emissão é 88 + 11 de severidade variável — 2,5× inflado). Corrigidas acima; ficam registradas
porque um doc de números que se auto-refuta pelo comando que manda rodar é a classe
declarado≠verificado que o gate existe para matar.
