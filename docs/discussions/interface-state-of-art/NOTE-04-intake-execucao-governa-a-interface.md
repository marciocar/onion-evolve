---
title: "Nota 04 — Onde a linha intake×execução governa a interface (pergunta 4 do SEED)"
category: discussion-note
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
responde: SEED.md — pergunta 4
metodo: aterramento no estudo interno (authorization-layers) + síntese das notas 01–03
relacionado: NOTE-01, NOTE-02, NOTE-03, docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md
---

# 🧵 Nota 04 — A linha intake×execução governando o que a interface coleta sozinha vs sob gate

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Aterrada no estudo interno (não pesquisa web): `authorization-layers-intake-vs-execution.md`.

## Posição em uma linha

A interface é um **quinto canal de ingestão** que a tabela §4 do estudo ainda não lista — peculiar
porque a fonte é a **própria sessão do maestro** (auto-observação), a mais-permitida que existe. Mas o
achado forte: a interface é a **casa candidata** para o *enforcement transversal* que o próprio estudo
(§7) admitiu faltar. O **gate visual da Nota 03 é a materialização uniforme da linha** que o estudo queria.

## A escada do estudo aplicada às três notas

O estudo separa **intake (0–6, autônomo, `committed:false`)** de **execução (7–8, gated)**, linha na
*guarda gated*. Cada comportamento da interface tem sua versão da mesma linha:

| Comportamento | Intake (autônomo, "guardar") | 🟢 A linha | Execução (gated, "agir") |
|---|---|---|---|
| **Telemetria (N01)** | coletar **estrutura** (tokens, `tool_decision`, `blocked_on_user`, spans), guardar **local** | dado guardado, formativo, `committed:false` | **exportar pra fora** OU capturar **conteúdo** (prompt/código) → gate |
| **Padrão (N02)** | detectar recorrência, N≥3, **surfacear candidato** com evidência | candidato guardado | **promover a doutrina** → gate humano **+ refutador** |
| **Comunicação/gate (N03)** | estado calm, **diff-first**, evidence-pack (ler/exibir) | decisão pendente exibida | **aplicar a ação** → hard gate se irreversível |

Três comportamentos, a mesma linha.

## O que o estudo prescreve à interface

- **Fail-safe: veto, nunca skip — mas só na metade de execução.** Se o gate não consegue se avaliar
  (não constrói o evidence-pack, não renderiza o diff) → **VETA**, não auto-aprova (anti-rubber-stamping
  da N03 com dentes). **Nuance fina:** a metade *intake/display* (visualizar telemetria, surfacear padrão)
  é **gerador**, degrada **gracioso** (não renderizou = sem dano, skip). Regra: **exibir degrada skip;
  gatear degrada veto.** Confundir isso é o bug latente.
- **`entrega-sem-commit` (I3) vale pra auto-observação:** guardar ≠ aceitar ≠ aplicar. "Observei um padrão"
  nunca auto-commita doutrina (no-self-promotion, N02) nem auto-aplica ação (hard gate, N03).
- **Corolário §5:** pedir permissão pra *coletar estrutura* da própria sessão = gateou cedo demais; deixar
  padrão→doutrina/ação auto-aplicar = gateou tarde demais. Gate **exatamente na linha, visível**.

## Auto-observação intensifica o gate, não afrouxa

A fonte ser o próprio maestro torna o intake maximamente autônomo (sustenta o colapso ético da N01). **Mas**
por ser o canal mais confiável, a tentação de deixá-lo auto-agir é a maior — onde a negligência
("IA-fala-IA autônoma") mais entra. Canal mais confiável no intake ⇒ gate de execução **mais** importante.

## A lacuna do estudo que a interface pode fechar

§7: *"a linha não é enforçada uniformemente por um só helper — cada canal a implementa. Um lint transversal
seria o próximo passo — gated por gatilho."* A interface é onde esse enforcement pode **viver visível**: um
lugar onde a linha vira UI (gate em camadas auto/soft/hard, N03), em vez de reimplementada por canal. E §7
*"reputação condicionando o gate é futuro"* = a "autonomia progressiva" (HITL→HOTL) da N03. Mesmo futuro,
nomeado dos dois lados, gated atrás de dogfood.

## Fios abertos que voltam ao maestro

1. Interface como **casa do enforcement transversal** (o "lint da linha" do §7 virando UI) — encaixe certo,
   ou enforcement continua por-canal e a interface só *exibe*?
2. **"Exibir degrada skip / gatear degrada veto"** vale como invariante de design da interface?
3. Reputação/autonomia progressiva condicionando a intensidade do gate — quando destravar (gatilho de dogfood)?

## Fonte

- Estudo interno: `docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md` (v1.0.0, candidato)
- Notas 01–03 desta pasta.
