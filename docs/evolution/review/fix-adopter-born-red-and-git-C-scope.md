---
title: "Revisão — adotante greenfield nascia vermelho (rule research-lens) + falso-positivo de escopo do -C nos vetos + registro da sacola-de-ideias"
date: 2026-09-02
branch: fix/adopter-born-red-and-git-C-scope
reviewer: "condutor com medição: sinal upstream do 1º adotante com o pin 8e2517724c0a (sacola-de-ideias, 1 HARD REGRA 53 no dia 1) e veto do push do adotante (hook do core julgando `git -C /outro/repo push origin main`); bancada run_pretooluse_veto_selftests 37/37 (5 casos de escopo novos; o caso antigo `-C /tmp` continua VETO); lint --only rc=0 em lib/members/adopt.md após regenerar graph/federation-map/console; members-validate 14 membros; lint do adotante 0 HARD após a semente"
reviewed_diff_sha256: df21a9f46eebd38f1d1e278efad53a9de0fa354b854ab2373742e5d1761e9740
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 60000
duration_min: 30
---

# Resíduo — REGRA 56

Dois defeitos medidos pelo primeiro adotante do pin da F1 (sacola-de-ideias, adotado nesta sessão) e a cura na
origem; mais o registro do adotante.

## Achados

1. **Todo adotante greenfield nascia com 1 HARD** (REGRA 53): a rule `research-lens.md` declara
   `paths: docs/evolution/research/**` e nenhum arquivo do adotante casa. Cura na ORIGEM: o procedimento
   pós-cópia do `/meta:adopt` semeia `docs/evolution/research/README.md` (que também ensina a lente). A
   sacola recebeu a semente à mão (lint 0 HARD); o sinal upstream do adotante foi processado
   (`inbox/_processed/`).
2. **Falso-positivo de escopo nos dois vetos**: `git -C /outro/repo push origin main` era vetado — a lib
   colapsava o `-C` antes de julgar. Cura: linha cujo `-C`/`--git-dir`/`--work-tree` resolve para um
   **repositório git com raiz ≠ a nossa** sai antes do colapso. `-C /tmp` (dir sem .git, o truque de invólucro
   da auditoria) **continua vetado** — a bancada pegou a 1ª versão que liberava tudo (36/37).
3. **O agente adotante não contornou** a guarda (o buraco `push origin HEAD` existe e ele o declarou): o push
   ficou para o maestro rodar fora da sessão. Comportamento correto; a cura é este PR + reinício da sessão.
4. **Registro**: `sacola-de-ideias` em `members.yaml` (standalone/adopter/greenfield, pin 8e2517724c0a a
   verificar por `pin-integrity-check.sh` após o 1º push); projeções regeneradas.
5. **Contagem de skills drifted em 8 docs vivos** (12→13 após a skill `onion-research` do F2; o CI do #774 não
   pegou): dois gates deste PR acusaram 3 + 2 arquivos; varri o resto de uma vez (REGRA 16). Dados de pesquisa
   de agosto e um `verified_against` datado do grafo de identidade foram **preservados** — snapshot histórico
   não se reescreve.
6. **Vendor-scrub (REGRA 36) pegou o próprio registro**: ao entrar em `members.yaml`, o id do adotante passou a
   ser protegido — e eu o citava nos comentários do `adopt.md` e da lib (viajariam para todo adotante).
   Generalizado para "um adotante greenfield"; o crédito nominal fica no resíduo (não vendorizado) e no grafo.

## Não mudou

- A rule `research-lens.md` e a REGRA 53 ficam como estão: a cura é semente, não afrouxar a guarda.
- Adotantes já existentes não têm a rule (pin anterior) — nada a migrar.
- O buraco `push origin HEAD` (sem refspec `main`) segue como fronteira declarada do merge-gate.
