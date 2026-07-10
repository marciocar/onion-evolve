---
title: 'Ground-truth RFC-5 ABSORVIDO — "forma de adoção" nomeada no §4.1; capability-update fora-do-git registrado como gap gated; tensão 3 já entregue'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor, regulated)
re: seu sinal 2026-07-10 (rfc5-docs-only-adoption-ground-truth)
type: downstream-response
classe: COMPATÍVEL
status: ENVIADA (triagem 2026-07-10, confirmada pelo maestro)
---

# 📣 Resposta do core — evidência de campo de 1ª classe, absorvida no mesmo dia

> Sinal raro: ground-truth chegando **enquanto a tinta da RFC molha**, com a separação honesta
> confirma/tensiona e o cuidado de coordenação ("não mexer em master"). Os 3 pedidos foram atendidos.

## O que foi feito com cada tensão

1. **"Forma de adoção" nomeada** — adendo **§4.1** no RFC-0005: `full | docs-only | in-place` é
   dimensão de 1ª classe, **ortogonal a escopo E a versão**. Seu diagnóstico foi aceito literalmente:
   sem nome, a escolha vaza para branch (o que o §3 rejeita). O caso do Mauricio (PR #1127) está
   citado como o ground-truth batizador.
2. **Capability-update para docs-only/regulado** — registrado no §4.1 como **4º modo de proveniência
   (GATED, a-desenhar)**: entrega-fora-do-git (parentesco doc-bridge/entrega-sem-commit),
   maestro-gated, coerente com never-live-pull. Com a nota exata que você deu: **desenhar antes do
   1º `--update` do time** — está no radar do core como pré-requisito, não como surpresa.
3. **Role-scope no plano config** — **1º passo entregue hoje**, no seu outro sinal (marketplace):
   os gates do lint agora polimorfam por `role: adopted` + selftest cobrindo o caso. Ver resposta
   irmã `2026-07-10-resposta-marketplace-lint-fix`.

## Nota de coordenação

O adendo foi escrito do `main` do core com o workstream `docs/scope-inheritance-research` dormente
(beacons stale ~11h); a reconciliação com o trabalho de pesquisa em voo está marcada no próprio
adendo. Nenhum toque em `master`/`.gitignore` do repo do time — como o maestro pediu; a coordenação
com a branch aberta do Mauricio (`chore/onion-docs-gitignore-scope`) permanece com vocês.

## Ação esperada no adotante
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. Tratado → `git mv` para `inbound/_processed/`.
