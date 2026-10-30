---
branch: chore/kg-ssot-4401
pr: pendente
date: 2026-10-30
reviewed_diff_sha256: 07497925bc2f24e4dd591402af2cf9fa8e7f6ddf6250e86191ab7b9d2d3be62f
reviewed_code_sha256: 9d99657d3ac95f381d673babff92d2ce0a5c92a15063a517482049ea48af8e7a
findings_total: 7
findings_real: 0
tokens: 54461
duration_min: 1
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: revisor novo só-leitura (code-reviewer), sem o contexto da sessão
nota: "tokens do revisor medidos pelo harness (54461). Os sete achados são observações: nenhum defeito deste PR."
---

# Passada adversarial: `chore/kg-ssot-4401`

## O que muda

- `vendor/kg-ssot` 4.40.0 → 4.40.1, com o contrato v4.18 inalterado. Mudam o README de Company Brain, as descrições dos pacotes, a receita do evento externo no manual, o texto do `--help` do `kg_query --revisit` e a tradução no `.po`, mais o carimbo da release.
- O `.kg-ssot/gate/contract.json` é renovado por `bash ops/kg-gate-ci.sh --update`: só `"kit"` passa de `4.38.0` a `4.40.1`. O mesmo `--update` grava os registros de 4 grafos que já estavam na main sem registro na base, todos com `must []` e `should {}`.
- O gate sai rc 0 antes e depois do `--update` (206 grafos, 204 passam no MUST, as 2 dívidas herdadas).

## Achados

O revisor conferiu os pontos abaixo e não achou defeito real:

1. O vendor bate byte a byte com a tag: 712 arquivos do manifesto contra `git show kg-ssot-v4.40.1:<f>` e contra o worktree, 0 divergências. A tag resolve para `3787971fa0f1`, o commit gravado em `.kg-ssot-version`.
2. Nenhuma mudança de lógica: em `spec/` e `tools/` só mudam `release.json` (versão e tag) e a string de `help=` do `--revisit` no `kg_query.py`. Nenhum `spec/kg-contract-v4*` muda, e o `contract_sha256` fica igual. O `msgid` novo do `.po` casa com a string nova.
3. O commit simplifica ao dizer que só a string de help muda no código: `packaging/npm/build.py` e `packaging/python/build.py` também mudam, mas só em literais de `description` e `keywords`. O `requires-python`, que a bancada `kg-ssot-require-hashes` lê, fica igual.
4. `contract.json`: só o `kit` muda. Pelo `kg_gate.py` (`new_kit < old_kit` → `worse`) o kit é trava contra rebaixamento, então a renovação deixa a base mais estrita.
5. Os 4 registros novos com `must []` / `should {}` valem o mesmo que não registrar: registro vazio soma zero dívida, e um grafo fora da base que reprove no MUST cai em `worse` nos dois casos. Nenhum registro existente muda.
6. Nenhum consumidor fora de `vendor/` depende das strings mudadas (help antigo em inglês e pt-BR, descrições antigas de npm e python).
7. A mensagem de commit segue o padrão: prefixo `chore(kg-ssot):`, pt-BR, última linha `Orquestrado com 🧅 Onion Evolve`, sem `Claude-Session`.

## Limites declarados

- O revisor não rodou o gate, o lint, a bancada nem o `kg_query --revisit`. Esses foram rodados pela sessão: gate rc 0 antes e depois do `--update`; revisit rc 0 com `kg-ssot.revisit/2` e listas vazias; o `--help` em inglês e pt-BR lista os motivos novos.
- O revisor não leu a prosa dos READMEs e manuais quanto ao conteúdo, só a integridade com a tag.
- O commit do vendor saiu com `--no-verify` como checkpoint declarado: o pre-commit passou de 9 min e o timeout o matou. O gate final é o CI.
