---
branch: feat/dissect-default-own-repo-scope
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 2fd900bf21b5c6588583f63d87b0393f3067040bc26a5c6f487bc990d8ef1a51
reviewed_code_sha256: bf2c4651496b3d01fe1f3ac7747a5c85416a168f5644bac26562914207bb851c
findings_total: 8
findings_real: 7
tokens: 128192
duration_min: 6
findings_fixed: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR
nota: "achado 7 (projeção fora do índice) é do ciclo de fechamento: o pr-finalize regenera; achado 8 (id pelo remote pode surpreender num hub) foi declarado, não curado"
---

# Passada adversarial: `feat/dissect-default-own-repo-scope`

## O que muda

Decisão do maestro de 2026-10-15 (SAC-147): sem `--against`, a régua do `/meta:dissect` é o próprio
repo, derivada por `dissect-census.sh --regua-padrao` (no core continua `onion`), e `--scope
<pathspec>` estreita a régua a um componente (`meta.x_dissect_scope`). O leitor de planos mede a
régua = o próprio repo com raiz `.` implícita e confere o escopo no repo da régua. Decisões tomadas
sem o maestro, pela recomendada: escopo é pathspec do git (não nome), porque o forge-census só mede
candidatos do framework e caminho é o que se confere; id do adotado pelo remote `origin` (não pelo
`framework:` do carimbo, medido enganoso num adotado); porta (`kind: door`) = onion; grafo sem o
marcador segue lido como `onion`.

## Achados

1. MÉDIA, curado: no plugin `onion-meta` o projeto sem carimbo saía régua `onion`. Agora "sem
   carimbo ⇒ core" só vale com o medidor no repo medido. Caso g7.
2. MÉDIA, curado: census de pin antigo ignora `--regua-padrao` e o leitor tomava o cabeçalho do
   markdown como régua. Forma conferida (`<id>\t<origem>`), senão rc 3. Caso g10.
3. MÉDIA, curado: quatro mutantes sobreviveriam (raiz do escopo, vírgula, raiz explícita, ramo
   `role: source`). Casos k4, k3, k5, g8.
4. BAIXA/MÉDIA, curado: fonte desacoplada (`decoupled_from:`) virava `onion`. Caso g9.
5. BAIXA, curado: carimbo com CRLF furava o ramo. `tr -d '\r'`, coberto no g8.
6. BAIXA, curado: escopo só de exclusão casava o repo inteiro. `escopo-sem-pathspec-positivo`, caso k6.
7. BAIXA, não é do diff: projeção `testing-inventory.md` fora do índice. Regenerada e commitada.
8. BAIXA, declarado: no hub, o id pelo remote pode ser o do repo de origem do clone. A linha do censo
   diz de onde a régua veio, para o maestro conferir.

## Mutantes

16 mutantes plantados por `ops/mutate-and-restore.sh`, um por caso novo (g1–g10, k1–k6), todos
mortos pela família `run_dissect_selftests` (47 ✓ verde sem mutante). Dois mutantes (g7, g9) da 1ª
leva quebravam a sintaxe e não provavam nada; foram refeitos válidos e morreram pelo caso certo.

## Limites declarados

- O censo não confere se o escopo declarado existe; quem confere é o leitor de planos, e só no N4.
- Igualdade de escopo para o reuso é literal (o censo mostra as colunas e não julga equivalência).
- Bancada rodada só na família do dissect; a bancada inteira fica para o CI.
