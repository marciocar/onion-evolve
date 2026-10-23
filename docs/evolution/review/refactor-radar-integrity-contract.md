---
branch: refactor/radar-integrity-contract
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 70
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (fork); paridade medida em repo de teste com 247 grafos"
---

# Passada adversarial: `refactor/radar-integrity-contract`

## O que muda

- `.claude/validation/kg-radar-integrity.sh` (REGRA 52 (Todo .kg.yaml do repo passa no radar de integridade)): com o
  leitor do contrato vendorizado, UMA chamada do `kg_validate.py --format json` sobre o corpus e o veredito sai dos
  códigos; sem o leitor (plugin sem vendor, python3 ausente, rc fora de 0/1, JSON ilegível), o laço antigo de um radar
  por grafo segue inteiro e a saída declara a troca. Arquivo que o contrato não parseia vai para o radar próprio.
- `.claude/validation/lint-selftest.sh`: casos (m)–(p) do caminho do contrato, com mutante.

## Mapa medido (19 defeitos, um por variante, radar contra kg_validate)

| Classe | Checagens |
|---|---|
| Duplicada (vem do contrato, MUST) | id repetido, chave repetida, aresta solta from/to/trigger, ponta local de external_edges, nó órfão, edge_type (aresta e external), node_type, plane, layer, status, impact, confidence, alfabeto do id |
| Mais rígida na casa (escalada) | REFUTES sobre alvo pendente: SHOULD `integrity.refutes-unreconciled` no contrato, HARD aqui |
| Mais frouxa na casa, de propósito | `on:` legado e `valid_from` inteiro: MUST no contrato, só SOFT aqui (passivo dos adotantes) |
| Só da casa | MODO PROPOSTA (relaxa grau 0 e referência para fora num fragmento) e o aviso de `target:` vazio |

## Achados

1. Plugin sem `vendor/kg-ssot` (o bundle não o leva): fail-closed quebraria a REGRA 52 em todo plugin. Curado com o
   radar próprio como caminho declarado, mesma régua — nada afrouxa. Por isso nenhuma linha do radar foi removida.
2. O `parse.duplicate-key` interrompe o resto da leitura do contrato: o arquivo reprova (HARD) mesmo assim; outros
   `parse.*` mandam o arquivo ao radar próprio.
3. Os casos antigos da família rodam num sandbox SEM vendor e só exercitavam o radar próprio: (m)–(p) cobrem o
   caminho do contrato e o mutante prova que a escalada sustenta a catraca.

## Mutantes

- (o): `ESCALATE = set()` deixa a contradição passar no caminho do contrato → o caso reprova o mutante.
- Paridade (repo de teste com o corpus, as 19 variantes e as fixtures do kg, 247 grafos): 25 achados idênticos em
  (sev, tag, arquivo) entre o gate antigo e o novo; com o leitor indisponível, saída idêntica à antiga.

## Limites declarados

- Tempo do gate no repo de teste: 89 s → 15 s. O `kg-radar.sh --integrity` por arquivo (selador, `/meta:decide`,
  bancadas) segue o motor próprio: per-file o Python custa ~0,2–1 s a mais por chamada, e ali não compensa.
- A mensagem HARD agora cita o código do contrato e o lugar, não a linha do radar.
