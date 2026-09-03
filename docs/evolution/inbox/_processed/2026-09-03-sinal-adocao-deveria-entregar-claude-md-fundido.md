---
title: 'Sinal: a adoção deveria entregar o CLAUDE.md FUNDIDO, não uma decisão para o maestro'
date: 2026-09-03
from: sacola-de-ideias (consumidor)
to: core (onion-evolve)
type: field-signal
source_commit: 8e2517724c0a
flow: upstream (consumidor→core)
re: inbound 2026-09-02-adopt-8e2517724c0a (passo 1 dos "próximos passos")
---

# A adoção deveria entregar o `CLAUDE.md` fundido, pronto e resolvido

## O que foi medido

Adoção greenfield deste repo (pin `8e2517724c0a`). O alvo já tinha um `CLAUDE.md` (boilerplate do
template Astro: dev server em background + 6 links de docs). O never-clobber fez o certo ao não
sobrescrever — mas o resultado foi **dois arquivos** (`CLAUDE.md` do Astro + `CLAUDE.onion.md` com o
esqueleto Onion) e um item de "próximos passos" no relatório: *"Fundir (ou não) `CLAUDE.onion.md` no
`CLAUDE.md` — decisão do maestro."*

Custo real: quem abre o repo pelo `CLAUDE.md` (o arquivo que o Claude Code carrega) **não vê o Onion**
— nem o papel `adopted`, nem os contextos, nem `/warm-up`, nem o gate. O esqueleto ficou ao lado,
invisível para o harness, até alguém decidir.

## O que o maestro disse (2026-09-03, verbatim)

> fundir da melhor forma para aproveitamento do Onion, o core deveria mandar pronto e resolvido

## O que foi feito aqui (implementação de referência, se servir)

`CLAUDE.md` único, **Onion-first**: projeto (posicionamento + stack + papel `adopted`) → desenvolvimento
(o conteúdo do `CLAUDE.md` original vira UMA seção, com os comandos e os links preservados) → deploy →
contextos → entrada → task manager → idioma → branches → gate. `CLAUDE.onion.md` removido do git.
O lint vendorizado só cita `CLAUDE.onion.md` como padrão de escopo da REGRA 16, não como exigência —
a remoção não reprova nada.

## Direções possíveis (decisão é do core)

1. **Fundir na adoção** quando o `CLAUDE.md` existente for reconhecível como boilerplate (template do
   Astro/Next/Vite: sem regras de projeto, só comandos e links) — o conteúdo vira seção "Desenvolvimento"
   do esqueleto Onion, sem perder nada. Never-clobber continua valendo para `CLAUDE.md` com regras reais.
2. **Sempre fundir**, com o conteúdo original preservado integralmente numa seção nomeada e o diff
   visível no commit da adoção — o maestro revisa no PR, não decide depois.
3. Manter o comportamento atual e apenas **avisar mais alto** (hoje é um item de lista no relatório).

A 1 parece o melhor custo/benefício: resolve o caso comum (templates) sem tocar no caso que justifica o
never-clobber. Nada foi alterado na superfície vendorizada deste repo.
