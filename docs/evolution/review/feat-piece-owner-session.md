---
branch: feat/piece-owner-session
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 2
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução (o brief proibiu spawnar agentes); sem refutador separado. É uma voz só e está DECLARADA: a revisão separada fica para o revisor do CI e para quem ler este resíduo."
nota: "tokens 0 = não medido (o agente de execução não vê o próprio consumo); duration_min é a passada de revisão pelo relógio da sessão. Medido depois da última cura: família baton_pulse 78/78 (7 casos novos, (ag) a (am), cada um reprovando contra o mutante dele, e o mutante de (v) reancorado), e o pulso real na máquina com onion-messaging PIECE_UNOWNED e kg-ssot e curadoria PIECE_OWNED."
---

# Passada adversarial: `feat/piece-owner-session`

## O que muda

O `members.yaml` ganha `piece: true`, `owner_session` e `sponsor: maestro` em `onion-kg-ssot`, `onion-curation` e
`onion-messaging`. O `baton-pulse.sh` resolve o dono de cada peça em ordem fixa (owner_session, depois `owners.tsv`,
depois a sessão do core), casa pelo NOME da sessão viva e dá as classes `PIECE_OWNED`, `PIECE_UNOWNED`,
`PIECE_OWNER_NAME_MISMATCH` e `PIECE_UNMEASURED`, com o card de arranque em texto. As peças entram no sha do estado,
no `--tsv`, no `--markdown` e no `--quiet`. A doutrina ganha a cláusula 8, e a pesquisa entra com grafo e SYNTHESIS.

## Achados

1. **(blocking) Curado: `kind: piece` quebraria o registro.** Cenário: com `kind: piece`, o `members-validate.sh`
   reprova o registro inteiro (o enum `KINDS` é fechado), e a peça sai do pin obrigatório de quem vendoriza. Cura:
   campo novo `piece: true`. O `kind:` segue `adopter`, e o `members-validate.sh` passa com 33 membros.
2. **(blocking) Curado: um `owners.tsv` ilegível dava o dono ao core por palpite.** Cenário: a peça sem
   `owner_session`, com um `owners.tsv` que existe e não se lê (permissão, diretório no lugar), caía no 3º degrau e saía
   `PIECE_OWNED` pelo core. Isso é a mesma classe do `parked.tsv` ilegível da cláusula 7. Cura: a ordem para no 2º
   degrau e a peça sai `PIECE_UNMEASURED`. Caso (am) com mutante.
3. **(non-blocking) Sem a lista de peers não há nome a casar.** limite: sem `claude agents --json` nem `--peers`, toda
   peça sai `PIECE_UNMEASURED`, nunca `PIECE_UNOWNED`. Caso (al).
4. **(non-blocking) O nome é o contrato.** limite: uma sessão viva com o nome do dono conta como dona mesmo rodando
   fora do repo da peça. O pulso não exige que o cwd bata, porque a retomada pode abrir a sessão numa worktree.
5. **(non-blocking) O card de arranque não cita caminho com espaço.** limite: o nome vai por `shlex.quote`, mas o
   caminho sai como está (com a home trocada por `~`). Os `local_path` de hoje não têm espaço.

## Mutantes

| caso | o que o mutante faz | resultado |
|---|---|---|
| (ag) dono vivo | `match = []` | reprova |
| (ah) sem dono, com card | `pc['card'] = ''` | reprova |
| (ai) nome divergente | `elif in_repo:` → `elif False:` | reprova |
| (aj) ordem fixa | owner_session só vale sem linha no owners.tsv | reprova |
| (ak) só o nome casa | casa também pelo sessionId | reprova |
| (al) sem peers | `if not peers_ok:` → `if False:` | reprova |
| (am) owners.tsv ilegível | o degrau de parada desligado | reprova |

## Limites declarados

- Sem a lista de peers, as peças saem `PIECE_UNMEASURED`.
- O nome é o contrato: o cwd da sessão dona não é conferido.
- O caminho do card de arranque não é citado para shell.
- O `onion-bridge` não é membro nem peça: é infra do core, e os conectores ficam sob `onion-messaging`.
- A passada foi de uma voz só (`elenxo: false`), porque o brief proibiu spawnar agentes.
