---
branch: feat/register-consultoria-adopter
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 4a52d0a733522dcf9a0629ca8396ef45aeab94c641e96811c52f747247f161d5
reviewed_code_sha256: 97ae689f524eb1a92c1c9e354d0e96804007c45161b1b871b08ffd24f1348b98
findings_total: 4
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. A passada procurou primeiro o vazamento do nome comercial (REGRA 36 e P8) e depois o que o registro sem caminho quebra a jusante."
---

# Passada adversarial: `feat/register-consultoria-adopter`

## O que muda

- `members.yaml` ganha o membro `consultoria-analise-de-caso` (OP-1 do `/meta:federation-member`):
  `kind: adopter`, `role: standalone`, pin `6c4272252528` conferido por `pin-integrity-check.sh` (pin-ok),
  adoção greenfield de 2026-10-29, `remote` e `local_path` em `n/a`.
- Projeções regeneradas: `federation-map.md`, `federation-console.html` e `graph.md`.
- O grafo `session-orchestration-2026-11` citava o repo do adotante pelo nome, que leva o do cliente.
  A citação passa ao id neutro.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o nome do cliente já estava no core público, no grafo da orquestração de sessões (três linhas), e a fonte privada de termos não o conhecia, então nenhuma guarda o via | real | curado: a citação passa ao id neutro, e o termo entrou na fonte privada (`~/.config/onion/client-terms.txt`, formato `<termo><TAB><id>`), com `projection-safety.sh` OK depois |
| 2 | `remote` e `local_path` reais levariam o nome do cliente para o arquivo público, como na entrada do hub de operações | real | curado: os dois ficam `n/a`, com a razão no comentário |
| 3 | sem `local_path`, o `registry-pins.sh --check` dá ILEGÍVEL para este membro, a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) declara paridade não medida (SOFT), e o `/meta:co-deliver` não resolve o destino | real | limite: declarado abaixo |
| 4 | a troca no grafo altera o texto de um `verified_against` que transcreve a resposta do maestro | real | limite: a troca é só do identificador (nome do repo → id do registro); o sentido da decisão fica igual |

## Dogfood

- `members-validate.sh --json`: `valid:true`.
- `projection-safety.sh` com o termo novo na fonte privada: OK nas 86 superfícies.
- `lint-artifacts.sh`: o único HARD era `graph.md` desatualizado, e foi curado regenerando-o.
- `git grep -i` do nome do cliente na árvore: zero.

## Limites declarados

- O membro fica sem caminho e sem remoto no registro: o pin dele é carimbado à mão, e as ferramentas
  que resolvem o clone pelo registro não o alcançam. A cura de fundo seria um mapa local, fora da árvore,
  de id para caminho (como a P8 fez com os termos), ou renomear o repo e o clone. Fica com o maestro.
- O termo novo vive só na fonte privada desta máquina. O secret do CI que materializa a lista não o
  tem, então no CI a guarda segue sem conhecê-lo até o maestro atualizar o secret.
