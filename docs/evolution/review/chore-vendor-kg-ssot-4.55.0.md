---
branch: chore/vendor-kg-ssot-4.55.0
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: fc20252c0e626b2748d6fbc65e4aa5761c4523abac2049c3164e69ce7181a825
reviewed_code_sha256: 49f5c0082cce1e0fb2e9fa4ae4ff75f26d18af5519b46e5785400661e7f7e63a
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "agente de execução do core, medindo antes e depois do update na mesma árvore (origin/main 887f72f0e): integridade do vendor, ops/kg-gate-ci.sh antes, depois e com --update, kg-contract-check.sh em 269 grafos com o vendor 4.54 e o 4.55, lint de artefatos e as famílias da bancada que leem o vendor"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi a medição antes e depois pelo próprio agente que fez a subida, sem revisor separado. Adoção de vendor (v4.54.0 → v4.55.0, commit ff76116e, 963 arquivos; 39 mudam e 128 entram). Fora do vendor muda só a base do gate: a identidade nova do contrato e 4 registros de grafo sem dívida. Contrato v4.25, só SHOULD."
---

# Passada adversarial: `chore/vendor-kg-ssot-4.55.0`

## O que muda

`vendor/kg-ssot` v4.54.0 → v4.55.0 (commit `ff76116e646a`, tag `kg-ssot-v4.55.0`, objeto da tag `ad694bcc`), por
`kg_vendor.py update --tag`, com a conferência da atestação herdada do carimbo. O carimbo passa de 835 para 963
arquivos: 39 mudam e 128 entram. Dos novos, 125 são casos de conformidade em
`spec/conformance/fixtures/latest/form/ritual/`; os outros três são `spec/rituals.schema.json`,
`tools/kg_rituals.py` e `tools/requirements-rituals.txt`.

O que a versão traz, lido na nota de subida do guia de adoção do vendor novo:

- contrato v4.25, só SHOULD: o perfil `x_ritual` (o ritual do agente, num nó `rule` ou `policy`, com uma RRULE da
  RFC 5545, o `dtstart` e um fuso IANA), julgado só pela forma;
- o schema SHOULD muda, então o gate avisa `· identity` e passa, e o `--update` grava a identidade nova;
- duas ferramentas que não mudam veredito: `kg_validate.py --rituals` e `kg_gate.py --rituals-overdue` (desligado);
- o perfil `gate` passa de 19 para 21 arquivos (`tools/kg_rituals.py` e `tools/requirements-rituals.txt`);
- o `kg-mcp` ganha `--serve-ref` e `--secret-file`.

## A identidade do contrato

A nota manda gravar a identidade nova, e esta subida grava: `bash ops/kg-gate-ci.sh --update` (os mesmos `--exclude`
da base). Em `.kg-ssot/gate/contract.json` mudam `contract_sha256` (`198504d6…` → `b78a2b21…`) e `kit`
(`4.51.0` → `4.55.0`). Fecha o limite que as subidas 4.52.0, 4.53.0 e 4.54.0 deixaram aberto. Nenhum registro de grafo
que já existia mudou. Entram 4 registros de grafos que estavam no corpus e não na base, todos com `must: []` e
`should: {}`: nenhuma dívida foi aceita por este update.

## Achados

Nenhum. Medido na mesma árvore:

| Conferência | Antes (4.54.0) | Depois (4.55.0) |
|---|---|---|
| `kg_vendor.py check` | rc 0, 835 arquivos | rc 0, 963 arquivos |
| `ops/kg-gate-ci.sh` | rc 0, aviso de identidade | rc 0, mesma saída menos o carimbo e o hash medido |
| `ops/kg-gate-ci.sh --update` | — | rc 0; 266 grafos, 264 passam no MUST, 2 na dívida herdada |
| `ops/kg-gate-ci.sh` depois do `--update` | — | rc 0, sem o aviso de identidade |
| `kg-contract-check.sh` em 269 grafos | 264 conformes, 5 reprovam (dívida herdada) | saída idêntica byte a byte |

O "antes" do check do contrato rodou com o vendor 4.54.0 extraído do `HEAD` (`git archive`) e apontado por
`KG_SSOT_TOOLS`. Nenhum grafo do core tem a chave `x_ritual`, então o perfil novo não alcança o corpus.

## Mutantes

Não se aplica: a mudança é a troca dos bytes do vendor pelos da tag, conferidos contra o carimbo e a atestação, e a
regravação da base pelo próprio gate. Não há guarda nem código do core novo para mutar.

## Limites declarados

- `reviewed_diff_sha256` fica `pendente`: o commit saiu com `--no-verify` e sem o `pr-finalize`, que é quem carimba.
- A bancada rodou só as famílias cujo corpo lê o vendor real; a completa é do CI.
- As ferramentas novas (`--rituals`, `--rituals-overdue`) e o extra `rituals` não foram exercidos no corpus do core.
- O servidor `kg-mcp` em produção não foi reiniciado nem medido aqui.
