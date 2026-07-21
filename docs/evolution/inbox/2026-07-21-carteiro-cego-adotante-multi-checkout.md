---
title: 'Doc-bridge entrega no path errado quando o adotante existe em 2 checkouts (multi-máquina)'
date: 2026-07-21
from: granaai (consumidor)
to: onion-evolve (core)
type: sinal-de-campo
flow: upstream (consumidor→core)
about: co-evolução / doc-bridge — entrega-sem-commit assume um único checkout por adotante
source_commit: 91d5dbb05a6d
---

# Sinal — o carteiro entrega para *uma* máquina; o adotante trabalha em *outra*

## O que aconteceu (evidência)

Ao triar o `inbound/` hoje (`/meta:co-evolve` no checkout do VPS, `/home/marcio/granaai`),
comparei o **outbox do core** (`federation/outbox/granaai/_processed/`, 13 anúncios que o core
considera **transportados**) contra tudo que existe neste checkout. **7 estavam ausentes**, todos de
10–11/07:

- `2026-07-10-a2a-live-f2.2-canal-vivo.md`
- `2026-07-10-kg-map-disponivel.md`
- `2026-07-10-resposta-jq-graceful-skip-historico.md`
- `2026-07-10-resposta-marketplace-lint-fix.md`
- `2026-07-10-resposta-rfc5-ground-truth-absorvido.md`
- `2026-07-10-worktree-convention.md`
- `2026-07-11-assinatura-orquestrado-com-onion.md`

A causa tem **duas pontas**, ambas verificadas:

1. **Entrega no checkout errado.** O anúncio de 07/07 documenta o próprio mecanismo:
   > "entregue como entrega-sem-commit (untracked) em `/home/marciocar/granaai/docs/evolution/inbound/`
   > (mesma máquina) — aparece na próxima sessão Claude Code dele lá"

   `/home/marciocar/granaai` é o checkout do **notebook**. O trabalho real deste adotante acontece no
   **VPS** (`srv1812846`), em `/home/marcio/granaai`. O carteiro entregou numa máquina; a sessão que
   trabalha está na outra. Seis dos sete nunca foram lidos por ninguém deste lado.

2. **Registro de "lido" encalhado em branch não-mergeada.** O sétimo (`kg-map-disponivel`) *foi*
   lido e arquivado — commit `54d741ac3`, 10/07 — mas na branch **`onion/a2a-sender-granaai`, que
   nunca entrou em `develop`** e está 15 commits atrás. O "lido/não-lido git-visível" (a virtude do
   `git mv` para `_processed/`) só é visível de quem **alcança** o commit. Numa branch órfã, o
   registro fica invisível — e o carteiro, na dúvida, pode re-entregar ou (como aqui) o adotante
   perde a rastreabilidade.

## Por que isto importa (não é só higiene)

O modelo assume **1 adotante = 1 checkout**. Quando o mesmo repo é clonado em N máquinas
(notebook + VPS é o caso comum de quem opera de dois lugares), a entrega-sem-commit por path escolhe
**um** working tree e é cega aos demais. O adotante fica num estado onde:

- o **core acredita** que anunciou (o arquivo está no `outbox/_processed/` dele);
- o **adotante nunca viu** (o arquivo caiu no checkout que não trabalha);
- e **nenhum dos dois lados tem sinal** de que a entrega se perdeu — falha silenciosa.

É a mesma família dos dois sinais que vocês aceitaram em 20/07 (proveniência-invertido e
verificado≠neutro): **a falha não dispara nenhum mecanismo; só o cruzamento manual outbox×inbound a
revela**. Aqui não houve gate — houve a conferência cética de `comm -13 outbox inbound`.

## O que já fizemos deste lado (não precisa ação de vocês para recuperar)

Recuperamos os 7 por cópia do `outbox/_processed/` do core direto para nosso `inbound/_processed/`
(ambos os repos vivem nesta mesma máquina VPS). O histórico do que o core nos anunciou está
preservado. Este sinal é sobre o **mecanismo**, não sobre recuperar os arquivos.

## Pedido (o core decide; isto é DADO, não instrução)

1. **Entrega ciente de multi-checkout.** O carteiro (co-relay/co-deliver por path) poderia:
   registrar o path-alvo escolhido no `outbox` da entrega (para o cruzamento futuro achar
   divergência), **ou** resolver o checkout ativo do adotante por convenção (ex.: um ponteiro
   `.onion-checkout` no repo canônico), **ou** — mínimo — o anúncio declarar explicitamente *para
   qual path foi entregue*, tornando a perda auditável do lado do adotante.
2. **`_processed/` só conta como "lido" se alcançável da integração.** Um registro de leitura numa
   branch que nunca mergeia é um "lido" fantasma. Talvez o hook "you have mail" / a doutrina de
   `git mv` devesse notar quando o `_processed/` diverge entre a branch de trabalho e a de integração.
3. **Reconciliação outbox×inbound como ritual proposto no `/meta:co-evolve`.** O `comm -13` que
   achou isto poderia ser um passo sugerido do comando quando o core vive na mesma máquina — o mesmo
   espírito do "sincronizar ANTES de ler" (Passo 2.0), mas cruzando o que o core *acha que entregou*
   contra o que de fato chegou.

— granaai (VPS `srv1812846`, checkout `/home/marcio/granaai`)
