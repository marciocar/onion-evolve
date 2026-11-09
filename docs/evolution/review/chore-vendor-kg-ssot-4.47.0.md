---
branch: chore/vendor-kg-ssot-4.47.0
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: 3acba1cd3096b3396e2ab976e67b0a15565436cb6686adb0d16dbe8e9e3a8dab
reviewed_code_sha256: 5a4de554998bf0f72a68e6d548fe11cf396e56a5502a21cffe1d450f0ac0c235
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente
nota: "tokens 0 = não medido. Vendor do kg-ssot 4.47.0 e o gate --touched no CI, pela decisão «Catraca e escoteiro» (D_MD_GRAPH_HYGIENE_RATCHET_SCOUT_1109). A passada é do próprio autor: backtest, mutantes e bancada; nenhum agente separado foi criado, por ordem da tarefa."
---

# Passada: `chore/vendor-kg-ssot-4.47.0`

## O que muda

- **Vendor:** `kg-ssot-v4.46.0` → `kg-ssot-v4.47.0` (`3fe2e12c1ad0`), 732 arquivos, sem mudança de contrato (segue o v4.19). `kg_vendor.py check` rc 0.
- **Atestação:** o `update` com `--verify-attestation` deu rc 0, e o carimbo guarda `attestation.manifest_sha256` `4141e10af6eb`. A opção só existe na própria 4.47.0: o 1º `update` foi com a ferramenta 4.46.0 e o 2º, com a verificação, com a 4.47.0 já trazida.
- **CI:** `ops/kg-gate-ci.sh` roda o `kg_gate.py --touched`, contra `origin/main` em PR, no `pr-finalize` e no dispatch, e contra `HEAD^1` em push. O `onion-validate.yml` ganhou o gatilho `push` na main, que não tinha.
- **Base do gate:** só o `kit` (4.46.0 → 4.47.0) e 6 registros de grafos que nasceram depois da base. A dívida segue 736 e 63, então o motivo aceito em `accepted/9e32e64d130b1993.json` não muda.
- **Grafos:** `Q_KG_VENDOR_VERIFY_ATTESTATION_1130` e `Q_KG_PROV_AGENT_1208` fechados com a medida; `E_KG_TOUCHED_BACKTEST_1109` sustenta `D_MD_GRAPH_HYGIENE_RATCHET_SCOUT_1109`.

## Achados

1. **A bancada do `kg-gate-ci` quebraria:** o mundo falso não tinha commit nem `origin/main`, e o `--touched` sairia rc 2 nos casos (a) a (c). Corrigido: a seed vira commit, e os casos (f), (g) e (h) cobrem o toque, a base por evento e a base ausente.
2. **O `HEAD^1` só vê o último commit do push.** Com merge por rebase, um PR de vários commits entra num push só, e o último costuma ser o de projeções. Não bloqueia: o PR inteiro já foi julgado contra `origin/main`. `github.event.before` veria o push todo; fica como proposta, porque a ordem foi `HEAD^1`.
3. **O gatilho `push` faz o job inteiro rodar na main**, não só o `--touched`: cerca de 1 min por push, e um HARD novo na main fica vermelho ali. A `concurrency` do workflow cancela o run anterior da mesma ref, então numa rajada só o último push é julgado. Não bloqueia.

## Mutantes

- Mudar o `label` de `D_FIX_GAP2`, decisão da dívida antiga: `--touched` rc 1, nomeando o nó.
- Mudar só o `verified_at` do mesmo nó: rc 0.
- Árvore adulterada sob a mesma tag (`tools/kg_gate.py`) com `--verify-attestation`: rc 2, destino não criado.
- Repositório errado em `--attestation-repo`: rc 2.
- Bancada `kg_gate_ci`: 8 de 8.

## Limites declarados

- O backtest cobre 34 PRs que mexeram em grafo, de 60 mergeados: rc 0 em todos. Ele usa a cabeça de cada PR e a base registrada, e não prova o comportamento futuro de quem tocar os 736 e 63 nós, que passa a pagar, como pedido.
- A passada é do autor, sem Elenxo nem revisor independente.
