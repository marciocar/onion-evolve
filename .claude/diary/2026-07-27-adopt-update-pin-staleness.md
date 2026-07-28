---
date: 2026-07-27
instance: onion-evolve
type: observation
classification: collective
tags: [adopt, update, pin, onion-version, declarado-vs-verificado, fix-must-become-mechanism, co-evolution, arandek]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao mexer em /meta:adopt --update: após reescrever o .onion-version, GREPAR o repo do adotante pelo pin ANTIGO e reportar a contagem no relatório de update ('N referências ao pin anterior neste repo — revise'). O pin vive DERIVADO em artefatos que o --update não toca — memórias de sessão, frontmatter de sinais em rascunho, docs que citam a versão — e eles envelhecem em silêncio. Custo baixo (um grep), pega a classe inteira. É fix-must-become-mechanism: guarda no comando, não conselho."
review_after: 2026-10-27
conflict_class: dynamic
significance: "O adotante arandek reportou (upstream, disciplina exemplar: correção como artefato novo, sem editar história arquivada) que /meta:adopt --update atualiza o .onion-version mas deixa vencidos os artefatos DERIVADOS do pin (memórias, frontmatter, docs). É presença-de-campo passando por veracidade-de-campo — a mesma raiz de declarado≠verificado. Candidato de feature barato: grep do pin antigo pós-update. Registrado como BACKLOG (não implementado); decisão do maestro. Análise-par: docs/analysis/onion-adopt-update-pin-staleness-2026-07.md."
---

## Signal

**O `/meta:adopt --update` atualiza o pin canônico (`.claude/.onion-version`), mas o pin vive DERIVADO em artefatos que o update não alcança — e eles envelhecem em silêncio.** Memórias de sessão, frontmatter de sinais em rascunho, docs que citam a versão: todos carregam uma cópia do pin gravada num momento e nunca reconciliada. Quando o update roda, o `.onion-version` avança e as cópias ficam para trás — sem nada avisar.

## Evidência de campo

O adotante **arandek** emitiu um sinal upstream (`2026-07-27-correcao-pin-declarado`) corrigindo o pin de um sinal ANTERIOR dele: o frontmatter trazia `source_commit: 5e3ea5e` (o pin da adoção original, 2026-07-24) sendo o real `65d8a7` (o update de 2026-07-25). Causa nomeada pelo próprio adotante: **o pin veio da memória de sessão, gravada na adoção e nunca atualizada quando o update rodou.** Presença de campo (a memória existe) passando por veracidade de campo (a memória está certa) — a família do `declarado≠verificado`.

## Proposta (backlog — NÃO implementada)

No `/meta:adopt --update`, após reescrever o `.onion-version`: `grep -rl <pin-antigo>` no repo do adotante e reportar a contagem no relatório de update — "N referências ao pin anterior neste repo, revise". Um grep pega a classe inteira de erro, sem tentar consertar cada artefato (o que exigiria entender a semântica de cada um).

## Fronteira honesta

O custo pode não compensar para uma classe que "só morde quem escreve frontmatter à mão" (palavras do próprio adotante). Por isso é **backlog com decisão do maestro**, não fix imediato. O valor real: é a MESMA família de `declarado≠verificado` que apareceu no bridge (memória stale sobre o próprio estado) — um grep barato que fecha uma porta recorrente.
