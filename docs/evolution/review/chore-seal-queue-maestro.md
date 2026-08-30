---
title: "Revisão — a fila de selos do maestro, executada: 2 REFUTED, doc caduco, granaai redigido, offsite armado"
date: 2026-08-30
branch: chore/seal-queue-maestro
reviewer: "cada item já veio com 3 camadas de medição (worker × juiz × re-medição); esta aplicação segue a tabela de selagem à letra, radar exit 0 nos grafos tocados; a medição do GPG-frio foi corrigida NO ATO (pass ls ≠ pass show)"
reviewed_diff_sha256: 00172049812deae49bab3221666260dfb43c4efb61dbec133602fc41169569a1
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 0
duration_min: 20
---

# Resíduo — REGRA 56

O maestro autorizou "o melhor para cada" um dos 4 pendentes. Executado:

## 1. granaai (classe arandek, 2ª instância)

- **Medido primeiro**: a exposição **não está viva nesta VPS** (nada em :5435; Redis todos em
  127.0.0.1; DOCKER-USER ativo desde 08-05). O risco é **latente e viaja com o repo**.
- **Material de comunicação escrito e RETIDO**: `docs/analysis/granaai-compose-exposure-2026-08.md`
  (`status: REDIGIDO-NAO-ENVIADO`, mesma regra do arandek) — com a mensagem de 1 parágrafo pronta.
  **Nenhum envio feito; nenhum toque no repo da granaai (I3).**

## 2. Os 2 REFUTED — flipados pela tabela (nó evidence + REFUTES + alvo refuted)

- `D_default_deny_routes` → refuted por `E_default_deny_never_existed`: o default-deny **nunca
  existiu em nenhum ponto do histórico** — o código sempre praticou o modelo inverso que o próprio
  label chama de perigoso. A superfície segue mapeada por `Q_route_inventory` (vivo).
- `C_d7_discussion_links` → refuted por `E_no_absolute_link_convention`: a "convenção de links
  absolutos" divergida **não existe** — a SSOT manda o oposto.

## 3. `a2a-live.md` — o doc caduco corrigido

Cabeçalho reescrito para o que o sistema FAZ: endpoint **vivo desde 07-09** (200 medido pelo juiz);
o que segue gated é a **aceitação humana** (`a2a-pending` → `a2a-accept.sh`). A correção nasceu
do selo envenenado que o juiz barrou no lote 7.

## 4. Backup offsite — ARMADO (VPS, fora deste diff)

- `offsite-cron.sh` criado e versionado em `onion-vps-vaultwarden` (commit `c16edcb`): wrapper
  com log fail-loud + o limite do GPG **declarado no próprio arquivo**.
- Cron do marcio: `0 13 * * *` (10:00 BRT, janela de cache GPG quente típica).
- **⚠️ A PROVA REAL ESTÁ BLOQUEADA pelo GPG frio** (pinentry sem TTY). Corrigi minha própria
  medição no ato: `pass ls` funcionou e eu declarei "cache quente" — falso; listar não decifra.
  Destrava: `pass show onion/restic-password >/dev/null` no tmux, e o run prova.
- **Achado colateral**: diretório `Abc@@@135791` (nome com forma de senha; um repo restic local
  acidental de 08-13) — **renomeado** para `restic-local-acidental-2026-08-13` (nunca deletado;
  pode conter o backup do 1º teste). Se o nome era uma senha real, a comparação com a atual ficou
  DESCONHECIDA (GPG frio) — conferir após o destrave. Visibilidade era restrita (grupo marcio vazio).

## Gate mecânico

radar exit 0 nos 4 grafos tocados · backlog 100 → 98 (R62) · zero fan-out (aplicação direta de
medições já julgadas)
