---
branch: chore/kg-ssot-4510
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: passada adversarial da 1ª sessão desta leva (agente interrompido pelo limite de uso), retomada e re-medida por outro agente
nota: "tokens e duração não medidos: a passada foi da sessão interrompida, e o registro dela sobrevive só nos rótulos B1, B2, L1, L2, L3, L4 e L6 citados no código e na bancada. Um rótulo L5 não aparece em lugar nenhum e não entra na conta."
---

# Passada adversarial: `chore/kg-ssot-4510`

## O que muda

- O vendor da kg-ssot sobe de 4.50.0 para 4.51.0 (tag `kg-ssot-v4.51.0`, commit `0bdebbd3b9cd`, contrato v4.22).
  `kg_vendor.py check` dá rc 0 nos 781 arquivos, e o `git ls-remote` da tag aponta o mesmo commit.
- A regra do `kg_gate.py --private-repos` (manual 05 da 4.51.0) é portada para `.claude/utils/kg/private_repos.py`,
  e as duas guardas da casa a chamam com o arquivo privado de padrões do dono: `private-repo-cite-check.sh`
  (REGRA 121, `--private-repos` ou `ONION_PRIVATE_REPOS`) e `kg-trace.sh` (`--private-repos`, nos modos humano e TSV).
  Sem o arquivo, nada muda: o CI não o tem, então é guarda local do dono.

## Achados

| Id | Triagem | Achado | Cura |
|----|---------|--------|------|
| B1 | (blocking) | âncora aninhada de 300 bytes expandia em potência e travava o porte (2 GB em 60 s) | teto de nós no percurso; o grafo inflado vai linha a linha; caso (o) e mutante |
| B2 | (blocking) | chave com TAB ou quebra de linha partia a linha TSV, e o achado sumia; rc 1 sem linha traduzida saía mudo | `cell()` sanea o TSV; rc 1 sem linha vira rc 2 nas duas guardas; casos (p) e (n4) |
| L1 | (non-blocking) | o carimbo do vendor na RAIZ esvaziava o corpus inteiro, verde | carimbo da raiz não conta, como na referência; caso (q) |
| L2 | (non-blocking) | o rc 2 da guarda principal (não julgou) podia virar rc 1 quando o porte achava algo | o pior rc vence; caso (m3) |
| L3 | (non-blocking) | `--private-repos` com valor vazio passava sem conferir | rc 2 nas duas guardas; caso (n4) |
| L4 | (non-blocking) | chave repetida escondia o valor da 1ª ocorrência | a chave repetida derruba o parse e o grafo é lido linha a linha; caso (j) |
| L6 | (non-blocking) | o valor sob `!!set` escapava (aqui e na referência) | grafo com tag explícita vai linha a linha; caso (s) |

## Mutantes

- Porte: 18 mutantes na cópia, um por regra, todos mortos pela família `private_repos_port` (42 passam, 0 falham, `LC_ALL=C`).
- Guardas, por `ops/mutate-and-restore.sh` em 2026-11-13: 5 plantados, 5 mortos (rc 1 do helper): o rc 1 da REGRA 121,
  o desligamento sem o arquivo, o rc 2 da guarda principal preservado (L2, morto pelo caso m3), o rc 2 do modo humano
  do `kg-trace.sh` e a linha `ENTRADA-QUEBRADA` do TSV dele. A árvore voltou idêntica (mesmo `git diff --stat`).
- Paridade no corpus real com o arquivo do dono: 260 grafos, 313 achados no porte e 313 no `kg_gate.private_repo_check`,
  nenhum só de um lado; o porte acha mais 5 em comentário de linha inteira (extensão da casa, declarada).

## Limites declarados

- O teto herdado da referência: largura cheia, largura zero no texto, barra invertida, nome quebrado em bloco dobrado,
  dupla codificação, sósias de caractere, comentário no fim de linha, `.kg.json`, e as formas sem padrão possível
  (`repo @ sha`, `repo (HEAD sha)`, nome nu em prosa). Estão no cabeçalho do porte e das duas guardas.
- No `kg-trace.sh`, a máscara vale só nas linhas `PRIVATE-REPO`; as linhas do produto seguem com o grafo e o id em
  claro. A saída com a flag é do dono e não vai para superfície pública (dito no cabeçalho).
- A migração dos nós para `private-cite:<id>` não está aqui: é o PR seguinte.

## Re-revisão depois do contrato

O `pr-finalize` parou no contrato do kg-ssot: a decisão do porte sem `provenance` e um rótulo da passada lido como
código sem termo na narrativa da evidência. A cura mexe só no grafo do tema (a proveniência aponta a seção do manual
05 da 4.51.0, e o rótulo saiu do texto); o `kg-gate-ci.sh` dá rc 0. Revisei esse diff: nada muda no código das guardas.
