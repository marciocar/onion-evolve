---
title: "Revisão — a prova real do offsite: o guard barrou, e a verdade era dupla"
date: 2026-08-30
branch: fix/offsite-destination-truth
reviewer: "prova executada ao vivo pós-destrave do GPG (confirmado por keyinfo, não por declaração); o nó de ontem — meu — ficou falso por medição e foi superseded no ato"
reviewed_diff_sha256: e95de3fdc32d2a054d8ec2609dda62df597f38020d669aa0d883c8c9192036b9
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 0
duration_min: 10
---

# Resíduo — REGRA 56

A prova real do backup offsite rodou — e **reprovou**, que é o mecanismo funcionando.

## Os 3 achados, todos medidos

1. **MATCH**: o nome do diretório acidental de 08-13 **É a senha atual do restic** (comparação
   com o pass decifrado, não com cache frio). Exposição de baixa visibilidade (grupo vazio,
   diretório já renomeado). Cura de classe = rotação — **parada por ordem do maestro**:
   registrado, não proposto.
2. **A troca de 08-13 foi DUPLA**: `onion/restic-repo` contém a MESMA string de 12 chars que a
   senha — sem esquema remoto. O restic tratou a senha como caminho e criou o repo LOCAL.
   **O offsite nunca existiu**; o "1º backup real" foi para o mesmo disco.
3. **O guard anti-local barrou** (rc=5, nada enviado, log nomeando a causa e a correção) — a
   direção-de-falha do mecanismo está provada em produção.

## O que mudou no grafo

Meu nó de ontem (`Q_BACKUP_MECANISMO_ARMADO_SEM_AGENDAMENTO` — "falta só a linha de cron")
ficou **falso por medição** e foi **superseded** por `Q_BACKUP_DESTINO_NUNCA_FOI_REMOTO`, que
nomeia os 2 insumos que só o maestro tem: o destino real (`pass insert onion/restic-repo` com
esquema remoto; chaves R2 já no pass; conta/bucket são dado dele) e a decisão sobre a senha
exposta. Com o insumo 1, a prova roda no ato.

## Gate

radar exit 0 · backlog 98 (R62 em dia) · zero fan-out
