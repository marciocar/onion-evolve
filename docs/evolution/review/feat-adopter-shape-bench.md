---
branch: feat/adopter-shape-bench
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: eda07b5b71373f59b0b4f1d66b0ae0dc49ed81d3183385e7b0352809f7c47546
reviewed_code_sha256: 47c21d0bddcd09ed573bb5d535315cd5806010549bfe54adda14d79e5ff901ac
findings_total: 11
findings_real: 9
tokens: 189594
duration_min: 18
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus em worktree isolada (mandato de refutar)
nota: "achado 3 curado em parte (CI do adotante instala os requisitos; maquina local e teto); 8, 10 e 11 sao notas (declaradas no grafo ou curadas pelo pr-finalize)"
---

# Passada adversarial: `feat/adopter-shape-bench`

## O que muda

PR 1 de 2 da SAC-149. Ele mede a maquinaria no formato do adotante que a recebe. A família de bancada
`adopter_shape` usa o `ops/materialize-adopter.sh` (core-only), que chama os helpers reais da adoção pelo
mesmo corte do `--update`, para montar um adotante greenfield. Em seguida ela clona esse adotante e roda
no clone o lint, o `kg-contract-check.sh` e o `kg-radar.sh --integrity --schema`. Quando o resultado é
"não pude julgar" por uma dependência que não viajou, a família reprova. O passivo das REGRAS 85 e 92
fica numa catraca de dois sentidos, por par regra|dependência, até o PR 2.

A família provou o fechamento de dependências:
- `vendor/kg-ssot` passa a viajar, menos quando o alvo já tem um contrato próprio ou é o produto;
- o commit durável deixa de largar o vendor e o `.gitignore` de segredo fora do commit;
- o vendor atravessa um `vendor/` que esteja ignorado.

## Achados

Refutador: subagente opus em worktree isolada, sobre 53612815. Foram 11 achados, todos medidos por
execução, exceto o 4, que foi lido no código.

1. **BLOQUEADOR.** Um adotante que vendoriza o KG-SSOT num pin próprio (4.7.2) teria 13 conflitos no merge
   de três vias do `--update`. **Curado:** `ONION_TARGET` no `vendor-manifest.sh`; o vendor não viaja
   quando o alvo já tem um vendor próprio ou é o produto. O caso (j) cobre isso.
2. **BLOQUEADOR.** Num alvo com `vendor/` no `.gitignore`, o `git add` sem `-f` pulava o vendor em silêncio.
   **Curado:** o `durable-commit.sh` passa a forçar o vendor/kg-ssot ignorado. O caso durable-commit
   (sac149) cobre isso.
3. Sem PyYAML/jsonschema o contrato sai rc 2. **Curado em parte:** o template de CI do adotante instala os
   requisitos do vendor. A máquina local fica como teto declarado.
4. O `kg-decide-seal.sh` afirmava "contrato rc 0" sem ter julgado. **Curado:** o sufixo agora depende do CRC.
5. O produto KG-SSOT receberia uma cópia de si mesmo. **Curado** pela mesma regra do achado 1.
6. Detector léxico:
   - **curado:** a pontuação final ficava no caminho, a caixa importava, não havia "não consegui" nem
     `./ops/`, e a catraca era por regra;
   - **segue como teto:** ops sem extensão.
7. Comentário do `.gitignore`: **curado**, e os dois tetos ficam declarados no helper e no grafo.
8. O vendor vai para as portas (exceto o mini). Fica **declarado** no grafo.
9. `.prettierignore` não cobria o vendor. **Curado.**
10. As projeções estavam defasadas. O `pr-finalize` as regenera.
11. `eval` e o `--from INDEX`: declarados, não alterados.

O dogfood da cura pegou um defeito meu: com as duas linhas novas, o adopt.md passou de 800 linhas
(REGRA 5) e o caso (b) reprovou. Curado: a variável passou para a mesma linha da chamada.

## Mutantes

São 9 mutantes, todos plantados pelo `ops/mutate-and-restore.sh` com LC_ALL=C, e todos mordem.

| Mutante | Casos que reprovam |
|---|---|
| vendor fora do manifesto | (a), (d) |
| vendor fora do commit durável | (a), (d) |
| `.gitignore` fora do commit | (a) |
| catraca sem a REGRA 85 | (c) |
| catraca sem o `ops/` | (f) |
| detector sem o filtro do que viajou | (p), (c) |
| `_target_owns_contract` sempre falso | (j) |
| sem o `add -f` do vendor ignorado | durable-commit (sac149) |
| detector sem tirar a pontuação | (p) |

## Limites declarados

- O materializador copia só os passos determinísticos do adopt.md.
- Só o papel adopted é medido.
- Sem jsonschema na máquina, o contrato segue em rc 2.
- O caso Go não foi medido.
- Teto do bundle de plugin.
- O detector é léxico.
