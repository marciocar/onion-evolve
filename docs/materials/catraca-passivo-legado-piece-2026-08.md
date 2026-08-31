---
title: "Ligue o gate hoje, no repo que reprova — a catraca de passivo legado"
category: material
date: 2026-08-31
kg: docs/evolution/research/maestro-vivo-2026-08/maestro-vivo-2026-08.kg.yaml
status: DRAFT-PARA-PUBLICACAO (publicar no site é ato do maestro)
---

# Ligue o gate hoje, num repo que reprova — sem parar ninguém

Todo mundo que vende verificação determinística de agente esbarra no mesmo "não": *"adoraria,
mas meu repo tem anos de dívida — o gate vai travar o time no dia 1"*. Catraca de passivo é arte
consolidada em análise estática clássica — PHPStan baseline, detekt, Android Lint baseline,
leak period do SonarQube. O que NÃO tem par medido é aplicá-la a **regras de doutrina/agente**:
no nosso scan de guardrails determinísticos de agente (ago/2026, 5 players com juiz adversarial),
todos fazem veto binário sobre a ação corrente — nenhum resolve o repo LEGADO. É esse recorte,
dito assim, que o Onion ocupa: **a catraca de passivo congelado para regras de agente**.

## Como funciona

1. No dia em que o gate liga, tudo que já reprova vira uma **baseline versionada** — uma chave
   estável por violação (arquivo + hash do conteúdo), commitada no repo.
2. O gate liga VERDE no dia 1 **porque** a baseline congela primeiro (`regen-baselines.sh --emit` antes do CI nascer — a ordem É o mecanismo). Dali em diante: **violação nova = HARD** (bloqueia commit e CI). **Violação da baseline =
   tolerada e CONTADA** — um aviso agregado diz "N legados, a métrica de saúde é este número
   DIMINUINDO".
3. Corrigiu um legado? A chave sai da baseline — e **não volta**: a catraca só gira para baixo.
   (Byte a byte, com locale travado; a regeneração é comparada no lint — editar a baseline à mão
   para "ganhar espaço" reprova.)

## O caso real (anonimizado)

Numa atualização de framework num repo adotante, uma regra nova de segurança de compose (portas
sem bind + fallback literal de senha) encontrou **38 violações legadas** acumuladas ao longo de
meses. Sem catraca: 38 HARD, merge travado, time parado, regra desligada até "alguém arrumar" —
ou seja, nunca. Com catraca: **o gate ligou no mesmo dia**, os 38 congelaram visíveis e contados,
qualquer linha NOVA da mesma classe reprova na hora, e o número só pode descer.

## Por que isto não é "ignorar a dívida"

- A dívida fica **visível e contada** em todo run do lint — não some, não cresce.
- O congelamento é **auditável**: a baseline é um arquivo versionado; o blame diz quem tolerou o quê e quando.
- É o oposto do `// lint-disable`: a exceção não mora no código nem se copia — mora num ledger
  central que só aceita remoção.

## Os números (medidos, 2026-08)

- 6 catracas ligadas no core do Onion, 84 chaves congeladas hoje — concentradas em 2 ledgers;
  as outras 4 estão zeradas (a catraca também previne, não só tolera). Cada chave é um defeito
  real, nomeado, aguardando cura sem bloquear ninguém.
- Custo de execução do gate: **0 tokens** (bash/awk puro), latência de segundos.
- No dia da estreia da regra de compose num adotante real: 38 legados congelados, **0 merges
  travados**, proteção ativa para linhas novas desde o primeiro commit.

*Quer ver a catraca girando? O framework é aberto — o mecanismo inteiro são ~30 linhas de shell
por regra, e a baseline é um txt que qualquer revisor lê.*
