---
branch: feat/a2a-gate-local-standalone
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. A passada procurou primeiro o FALSO POSITIVO (a volta honesta da fila recusada) e depois o furo (standalone aceito pela rede)."
---

# Passada adversarial: `feat/a2a-gate-local-standalone`

## O que muda

- `a2a-verify.sh` ganha `--channel network|local-queue` (default `network`). Na camada 0b, com
  `local-queue`, o receptor `role: standalone` (kind não `door`) passa **só** se o `local_path` dele no
  registro é absoluto, existe nesta máquina e o `st_uid` é o uid que roda o gate. Senão
  `receiver-not-local:no-path|path-absent|path-foreign-owner`. Pela rede nada muda.
- O veredito verificado ecoa `"channel":"local-queue"` só nesse modo; gate antigo recusa a flag com rc 2.
- Bancada `run_a2a_verify_selftests`: LQ.1–LQ.8 e dois mutantes (LQ.MUT: sem a condição do canal;
  LQ.MUT2: sem a prova do dono). Família verde: 143/0 sob `LC_ALL=C`.
- Selos do maestro (`kg-decide-seal.sh --new`) em `messaging-standards-2026-11`:
  `D_GATE_STANDALONE_FILA_LOCAL_1106` e `D_CHAVES_A2A_CORE_E_CURADORIA_1106`; teto 120 → 122.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o 1º mutante "morria" por vacuidade: o envelope da fixture vetava em `kid-not-owned-by-from` e o caso contava como reprovado | real | curado: o core ganhou `a2a.keys` na fixture e o mutante só conta se **verificar**; veto por outro motivo reprova como "não exercido" |
| 2 | no dogfood com o registro REAL, um `a2a:` novo no topo do bloco do core foi ignorado em silêncio: o core já tem `a2a:` (o endpoint) e o YAML fica com a última chave | real | curado no dogfood (a chave vai DENTRO do bloco existente); vale para o PR das chaves |
| 4 | a REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação) acusou o id do adotante em três linhas que viajam | real | curado: o texto diz «a fila local de mensageria»; re-revisado (só comentário) |
| 3 | qualquer processo do mesmo uid pode chamar o gate com `--channel local-queue` | limite | declarado: o mesmo uid já lê as chaves privadas do disco; o gate prova o host e a conta, não qual processo chamou |

## Dogfood

Registro real copiado (só a chave efêmera do core acrescentada), envelope `onion-evolve → onion-curation`
assinado pelo `a2a-send.sh --dry-run`:

- rede: `receiver-not-a-receiver:role-standalone`, rc 1;
- `--channel local-queue`: `verified:true`, `receiver:onion-curation`, `channel:local-queue`, rc 0;
- `--channel local-queue` para `onion-core` (porta): `receiver-not-a-receiver:kind-door`, rc 1.

## Teto

- A fila do onion-messaging ainda não passa a flag: a cura do lado dele é da sessão dele.
- O `a2a-accept.sh` (fila do bridge) não usa o modo local: a fila do bridge é a rota de rede.
