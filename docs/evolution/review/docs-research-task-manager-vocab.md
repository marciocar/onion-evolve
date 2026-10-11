---
reviewed_diff_sha256: fcf95014ea3d7de72fed85514901517a3c54762959e02b80e721285ca14e756f
reviewed_code_sha256: 142a8bae89b4f045ebde1f595662b5f9971c3791a55679291803f800238a9d32
findings_total: 20
findings_real: 18
tokens: 1012508
duration_min: 11
verdict: APROVADO
elenxo: sim
nota: >
  A passada adversarial é a do próprio workflow /onion-research em modo primaries. A ancoragem, feita por um
  verificador separado do leitor, rejeitou 3 claims por exagero. O Elenxo (refutador opus) deixou 17 objeções
  sobreviventes, que viraram nós CONSTRAINS. Uma delas (objeção 4) apontou a contradição entre o core e a
  primária sobre o /search do Jira, e foi resolvida neste PR pela via conservadora: o core passou a afirmar
  só o que a fonte sustenta.
---

# Resíduo — `docs/research-task-manager-vocab`

Onda 1 da SDAAL do Task Manager (SAC-62): o grafo da pesquisa, a SYNTHESIS e o retorno do run em `data/`. Junto,
a correção de uma afirmação sem fonte em 5 superfícies do core.

| # | achado | desfecho |
|---|---|---|
| 1 | 3 claims exageradas na ancoragem | não viraram nó; contabilizadas em `E_LACUNAS_*` |
| 2 | 17 objeções sobreviventes do Elenxo | nós CONSTRAINS no grafo |
| 3 | o core afirmava "o /search foi removido em maio/2025" sem fonte; a primária diz "currently being removed" | corrigido nas 5 superfícies; `Q_JIRA_SEARCH_REMOVAL_RECONCILE` fechada |
| — | a fonte da Zoho Projects v3 ficou inalcançável | declarado; vai à Onda 2 (`Q_WAVE2_PRIMARIES_CELLS`) |
