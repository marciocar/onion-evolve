---
branch: fix/cited-directive-reextract-2-1-295
pr: pendente
date: 2026-10-09
reviewed_diff_sha256: b81b73cae687ea7b3f71d501f4933f5b796b03ee9156147b7aacf9bdf5063372
reviewed_code_sha256: 76c06b34d2e3b457133ddfbaca85adfdf82a265b2e984cc1b54cb2e5072dc68a
findings_total: 4
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial manual sobre o próprio diff (4 ataques: semântica do binário, mutantes, contrato do grafo, falso positivo do medidor); sem subagentes
REVISOU: true
---

# Resíduo — `fix/cited-directive-reextract-2-1-295` (SAC-84)

## O defeito

O caso (f) da família `cited_directive` reprovava DERIVA na main LOCAL com o Claude Code 2.1.295. A
causa não foi mudança de comportamento: o minificador renomeou as **locais do laço** (`g`/`h` viraram
`h`/`y`), e o molde estrutural de 2026-10-06 só punha curinga nos nomes de **função**.

## Os ataques

1. **A semântica mudou mesmo?** Extraí o parser da 2.1.295 por bytes (offset 215300431) e o comparei à
   cópia 2.1.290 de HEAD, normalizando os nomes: **idênticas**. 2.1.293 e 2.1.294 têm a forma da 2.1.290.
   Corpus `--tsv` com as duas cópias: rc 0, vazio nas duas. Nenhuma acusação nova, nenhuma sumida.
2. **O (f) ainda morde?**
   - Copiar a 2.1.290 de volta passa, por desenho: renomear não é deriva.
   - Tirar a máscara da cópia reprova com `guarda:`.
   - O molde antigo reprova com `guarda:` e `binario:`.
   - Medidor com a regex cegada: o caso (h) reprova.
3. **Contrato do grafo (achado REAL, curado):** o `cited-directive-2026-10.kg.yaml` já reprovava MUST
   `form.required.node.provenance` em HEAD. Era dívida pré-existente, de 4 nós `confirmed` sem
   provenance. Curei com a fonte que cada nó já declarava em `verified_against`/`trace`. O `method` de
   leitura saiu na forma `leitura: …`, que o padrão SHOULD exige.
4. **O medidor acusa à toa?** O fixture do caso (h) escreve `command -v %s` + `claude`. Sem isso, a
   própria família `cc_delta_census` se listaria como guarda de binário no repo real. Medido no repo
   real: lista só `cited_directive`.

## Tetos declarados (não curados)

- `⟨G⟩` e `⟨H⟩` podem casar o MESMO nome. Uma cópia com `for(let h…let h=` passaria o (f). Nenhum
  minificador emite isso, e o efeito em JS é erro de TDZ, não mudança silenciosa.
- O medidor só reconhece guarda de binário pela forma `command -v claude`. Uma família que achasse o
  binário por `which` ou por caminho literal ficaria fora da lista.
- O medidor atribui a linha à última `run_*_selftests()` aberta. Um helper definido entre duas
  famílias seria creditado à anterior.
