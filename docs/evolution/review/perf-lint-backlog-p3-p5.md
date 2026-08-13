---
branch: perf/lint-backlog-p3-p5
pr: 589
date: 2026-08-13
reviewed_diff_sha256: 57cece98cfed59d4ad67fd0d5c90698573138cfab769c16a05b67b3a5981a295
findings_total: 13
findings_real: 13
findings_fixed: 11
tokens: 121254
duration_min: 30
verdict: CORRIGIDO-E-RE-REVISADO
reviewer: code-reviewer (opus, adversarial — 3º Elenxo da linha de mecanismos)
---

# Passada adversarial — `perf/lint-backlog-p3-p5`

## Contexto: o 3º Elenxo de uma linha que se auto-corrige

1º Elenxo: diagnóstico (4 lentes, 19 achados). 2º: derrubou metade da cura v1 dos gates. **3º (este):
atacou a execução do backlog P3-P5** — e derrubou uma das minhas três réguas, provou que meu wire-in
absolvia sem medir, e achou a cura mais substantiva do PR escrita dentro de um nó que o radar ignora.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| A1 | ALTA | bundle do plugin fora do change set (R19 HARD) | corrigido — e a R19 me bloqueou 2× durante o próprio PR |
| M2 | MÉDIA | número-cabeça do pre-commit stale no mesmo bloco que curei (921s/612 vs 1136s/802 medidos) | corrigido |
| M3 | MÉDIA | duas frases stale a 20 linhas da que corrigi ("seguem abertas" — fechadas; "não puxado" — puxado) | corrigido |
| M4 | MÉDIA | a "tripla régua" do P5 era **dupla** — o consumed-mode é cego por construção a scripts sem produção; "33/0" idêntico em `main` | corrigido — nó reescrito |
| M5 | MÉDIA | o wire-in lia só `rc` — absolver-sem-medir, contra a doutrina do próprio arquivo curado | corrigido — **mutante de produção** que exige a acusação |
| M6 | MÉDIA | o gatilho da bancada não casa com o SUT (kg-freshness.md) | **declarado em nó com gatilho** — REGRA no lint só com o 1º incidente como fixture |
| B1 | BAIXA | "58 grafos" copiado de comentário vizinho (real: 62) | corrigido |
| B2 | BAIXA | "6/6" era string livre nunca conferida | corrigido — placar asserido |
| B3 | BAIXA | 78s não reproduz em máquina ociosa (71,3s) | condição da medida declarada |
| B4/B5 | BAIXA | `superseded` sem aresta + resultado vivo dentro de nó morto | corrigidos — nó `I_P3` + `SUPERSEDES` |
| B6/B7 | BAIXA | direção de aresta incomum; nits de formatação | corrigidos |

**Limpo (atacado, não achado):** captura única do `v_json` — comportamento idêntico em erro (4
cenários adversariais, veredito byte-idêntico nos 62 grafos) e um TOCTOU eliminado de bônus; o
wire-in com escopo/helpers/posição corretos; sem colisão de sandbox.

## Os números, reproduzidos pelo revisor

coverage 912ms/47 spawns ✓ · kg-view A/B 12,2→8,2s intercalado (-33%) ✓ · consumed-mode 33/0/14 ✓
(e idêntico em `main` — o que refuta o meu uso dele) · REGRA 59 consome o script ✓ · paridade
byte-idêntica nos 62 ✓ · bancada 802→**803** com o mutante, 0 falhas.

## Teto declarado

O gap M6 fica **aberto de propósito**: o sítio certo da guarda é uma REGRA no lint, e criar REGRA
às pressas foi o padrão de defeito das últimas 24h (required duplicado na guarda contra duplicação,
morte-silenciosa na guarda contra cegueira, absolver-sem-medir no wire-in contra órfãos). O CI
cobre o furo; o gatilho de promover é o 1º edit de `kg-freshness.md` que quebrar o schema e passar
local — a REGRA nasce com o incidente como fixture. E não houve 4º Elenxo sobre estas correções:
re-validação por gate mecânico (bancada 803/0 no hook, radar exit 0, lint 0 HARD) + prova isolada
dos 3 casos do wire-in, incluindo o mutante acusando.
