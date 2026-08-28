---
title: "Revisão — backlog volta a ser grep-ável (UTF-8 do projetor)"
date: 2026-08-28
branch: fix/backlog-pipe-escape-utf8
reviewer: "self-review adversarial — causa isolada por medição de bytes, cura provada por regeneração + idempotência"
reviewed_diff_sha256: b8f08d7e34d301f6d347a3244b376074fb5e861af1bbaeafed33848160e2fa96
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 9000
duration_min: 14
---

# Resíduo — REGRA 56

Correção de **gerador**, achada por acidente: o `grep` mentiu para mim duas vezes nesta
sessão e eu quase concluí que um nó recém-carimbado não entrara na projeção.

## Achados (3 reais)

1. **O sintoma é fail-open silencioso, não cosmético.** Com um byte inválido, o `grep` trata
   `docs/backlog.md` como **binário e suprime a saída** — a busca por um nó aberto devolve
   vazio **sem erro nenhum**. A superfície de controle do trabalho aberto para de responder e
   nada avisa. Só uma leitura direta (Python, `errors='replace'`) revelou que o nó estava lá.
2. **`tr` opera em bytes.** `tr '|' '·'` mapeia `|` (0x7C) para o **primeiro byte** de
   `·` (U+00B7 = C2 B7) → `0xC2` solto. Curado com `sed`.
3. **`cut -c` conta bytes** (medido aqui sob `LANG=C.UTF-8`) e partia `ç` ao meio →
   `0xC3` solto. Evidência literal: `b'na. A autoriza\xc3\xa7\xc3 |\n'`. Curado com
   `iconv -c`, com degradação graciosa (`cat`) se o `iconv` faltar.

## O que foi descartado como hipótese

**Os grafos-fonte não têm o defeito** — varri todos os `.kg.yaml` de `docs/onion/graph/` e
`docs/evolution/research/`: **zero** com UTF-8 inválido. O dano nasce inteiro na geração, o
que exclui "consertar o rótulo na fonte" como cura (seria tratar o sintoma no lugar errado).

## Verificação

- `docs/backlog.md` regenerado: **UTF-8 válido** (era inválido em 11 posições).
- `grep -c 'Q_INDICE_DO_DIARIO_SEM_CATRACA'` → **1** (antes: saída suprimida).
- **Idempotência**: duas regenerações produzem o arquivo byte-a-byte igual.
- Contagens **inalteradas** (190 abertos · 29 grafos) — a mudança é só de encoding, o que é a
  asserção certa para uma correção de gerador: mudou a forma, não o conteúdo.
- Plugin `onion-work-tools` (vendoriza o projetor) regenerado — REGRA 19 em-sync.

## Teto declarado

Não foi adicionada **catraca** que reprove um `docs/backlog.md` inválido: a cura impede a
geração ruim, mas nada impede alguém de commitar um arquivo quebrado por outra via. Fio
irmão do `Q_INDICE_DO_DIARIO_SEM_CATRACA` (projeção gerada sem guarda de em-sync).
