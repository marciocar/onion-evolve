---
branch: chore/vendor-kg-ssot-4.54.0
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "agente de execução do core, medindo antes e depois do update na mesma árvore (origin/main 74b3256be): integridade do vendor, kg_trace.py check, ops/kg-gate-ci.sh, kg-contract-check.sh em 269 grafos, radar em 10 grafos e 26 famílias da bancada"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi a medição antes e depois pelo próprio agente que fez a subida, sem revisor separado. Adoção de vendor (v4.53.0 → v4.54.0, commit 88b7fccf, 835 arquivos; 38 mudam e 25 entram no core). Sem código do core alterado; contrato v4.24, só recomendado."
---

# Passada adversarial: `chore/vendor-kg-ssot-4.54.0`

## O que muda

`vendor/kg-ssot` v4.53.0 → v4.54.0 (commit 88b7fccffde1, tag `kg-ssot-v4.54.0`), por
`kg_vendor.py update --tag`, com a conferência da atestação herdada do carimbo. O carimbo passa de 810 para 835
arquivos: 38 mudam e 25 entram, todos casos de conformidade em `spec/conformance/fixtures/latest/form/downgrade/`.
Fora de `vendor/` só entra este resíduo.

O que a versão traz, lido no guia de adoção do vendor novo:

- contrato v4.24, só recomendado: o perfil `x_downgrade` no `meta` (a trilha de rebaixamento de nível);
- política de áreas com `levels` que deixa área compartilhada sem teto passa a ser inválida;
- duas opções novas do gate, desligadas por padrão (`--classification-cites`, `--classification-downgrade`), e o
  resumo da política (`kg_policy.py digest`, `--area-policy-digest`);
- o `kg_trace.py` passa a ler o trace e o `provenance.source` sem o `<>` em volta, sem o prefixo `kg-node://` e
  parando no `?`; o que aponta arquivo ausente vira `missing` (rc 1).

## Achados

Nenhum. Medido antes e depois do update, na mesma árvore:

| Conferência | Antes (4.53.0) | Depois (4.54.0) |
|---|---|---|
| `kg_vendor.py check` | rc 0, 810 arquivos | rc 0, 835 arquivos |
| `kg_trace.py check` (268 grafos) | rc 0; 2847 julgados, 2847 resolvem, 0 ausentes | igual, campo a campo; mesmos 2847 alvos |
| `ops/kg-gate-ci.sh` | rc 0; 266 grafos, 264 passam no obrigatório, 2 na dívida herdada | rc 0; mesma saída, menos a linha do carimbo e o hash da identidade |
| `kg-contract-check.sh` em 269 grafos | 264 conformes, 5 reprovam (dívida herdada) | saída idêntica byte a byte |
| radar `--integrity --schema` em 10 grafos de `docs/onion/graph/` | não medido | rc 0 nos 10 |
| bancada, 26 famílias que leem o vendor, `--jobs 2` | não medido | 706 passam, 0 falham, 0 pulam |

As quatro perguntas da versão:

1. **`x_downgrade` fora da forma no corpus.** Nenhum grafo do core tem a chave. A busca acha um arquivo,
   `docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml`, e nele a palavra aparece só na prosa de um selo
   (linhas 155 e 160), não como chave do `meta`. As contagens do recomendado no gate são as mesmas antes e depois.
2. **Política de áreas.** O core não roda `--area-policy`: fora de `vendor/` a expressão só aparece em prosa (três
   resíduos antigos e dois grafos). Não há arquivo de política em `.kg-ssot/`, que guarda a base do gate e do
   vocabulário.
3. **Identidade do contrato do gate.** O gate imprime o aviso de identidade e passa (rc 0). A base
   (`.kg-ssot/gate/contract.json`) não foi regravada, como nas subidas 4.52.0 e 4.53.0.
4. **`kg_trace.py` mais apertado.** Nenhuma reprovação nova: os números e a lista dos alvos resolvidos são os mesmos.

## Mutantes

Não se aplica: a mudança é a troca dos bytes do vendor pelos da tag, conferidos contra o carimbo e a atestação. Não
há guarda nem código do core novo para mutar; quem prova que o vendor novo ainda morde é a bancada, nas famílias que
plantam defeito e leem o vendor real.

## Limites declarados

- A base do gate segue com a identidade da 4.51.0 (`kit: 4.51.0`); o aviso de identidade já saía antes desta subida,
  porque as subidas 4.52.0 e 4.53.0 também não a regravaram. Regravar com `ops/kg-gate-ci.sh --update` fica para
  quem decide a base.
- O "antes" foi medido nesta mesma worktree, no commit da `origin/main`, antes do update, e não numa segunda worktree.
- A bancada rodou só as 26 famílias escolhidas por lerem o vendor real; a completa é do CI.
- As opções novas do gate e o resumo da política ficam desligados; não foram exercidos no corpus do core.
- O servidor `kg-mcp` em produção não foi reiniciado nem medido aqui; a subida troca só os arquivos do repo.
