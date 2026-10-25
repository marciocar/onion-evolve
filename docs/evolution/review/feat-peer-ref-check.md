---
branch: feat/peer-ref-check
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: ceb0ff020533d365fc39d01723b4e799ae162480c93931547f274f2b5b530b14
reviewed_code_sha256: d2e4c5834112aded90126f32fbf89ae921d158e6c8eb1e0ac471f1583fc88b84
findings_total: 4
findings_real: 3
tokens: 0
duration_min: 25
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução do core, passada própria sobre o diff (helper, família e a linha do /meta:co-evolve)
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `feat/peer-ref-check`

## O que muda

- `.claude/validation/peer-ref-check.sh <par> <ref>` (novo): faz o fetch da origin do par e confere na
  `origin/main` dele um `<caminho>.kg.yaml#<ID>` (nó lido pelo `kg_query.py` do produto, id exato; PyYAML sem o
  produto), um `<caminho>` ou um `<sha>` (commit e ancestral). rc 0 existe · 1 não existe · 2 não mediu.
- `.claude/validation/lint-selftest.sh`: família `peer_ref_check`, com par real (bare + clone).
- `.claude/commands/meta/co-evolve.md`: a regra invariante «conferir antes de citar o par» aponta o helper.
- `docs/onion/testing-inventory.md`: projeção do harness regenerada (REGRA 80 (Números do harness saem de SSOT
  gerada, nunca de comentário)).

## Achados

1. **Prefixo de sha AMBÍGUO caía em «não existe» (rc 1).** Real e curado: dois objetos com o mesmo prefixo não
   provam ausência. Agora é rc 2, contado pelo `git rev-parse --disambiguate` (rc e número de linhas), nunca pela
   prosa do erro do git.
2. **Sha em maiúsculas caía no ramo de caminho** e saía «o arquivo não existe». Real e curado: o hex é
   normalizado para minúsculas, e o caso (e2) prende.
3. **A âncora do mutante (MUT-a) apontava um nome de função que o rename da REGRA 60 (Identificador de código em
   INGLÊS) trocou.** Real e curado: a bancada acusou «a mutação não aplicou» em vez de passar verde, que é o
   comportamento certo; a âncora segue o nome novo.
4. **O fetch escreve em `.git/refs/remotes` do par.** Descartado como defeito: é o que o D pede («depois de
   `git -C <par> fetch -q origin`»), não toca árvore, índice nem branch do par, e não é commit (a REGRA de um
   escritor por repo fala de commit e push). Fica nos limites.

## Mutantes

- **MUT-a** — grep por prefixo (`grep -q "id: ${ID}"`) no lugar do parser: o caso (b) (`C_X` com só `C_X_2` no
  grafo) vira rc 0. Morto.
- **MUT-b** — sem o `merge-base --is-ancestor`: o sha que só está numa branch vira rc 0. Morto.
- **MUT-c** — sem o fetch: com a `origin/main` local defasada, o nó publicado depois some (rc 1 em vez de 0). Morto.

## Limites declarados

- O prefixo ambíguo (rc 2) não tem caso na bancada: forjar colisão de 7 hex exige dezenas de milhares de objetos.
- Uma ref só de hex (7 a 40) é sempre lida como sha, nunca como nome de arquivo.
- O fetch roda na rede do par: sem rede ou sem credencial, sai rc 2, nunca «não existe».
