---
branch: fix/kg-index-atomic-and-old-vendor-warn
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 5
tokens: 0
duration_min: 75
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: autor (passada adversarial própria, agente de execução)
nota: "tokens não medidos (0). Passada feita pelo próprio autor, contra o artefato rodado: a bancada e o lint, não a releitura."
---

# Passada adversarial: `fix/kg-index-atomic-and-old-vendor-warn`

## O que muda

- `kg-trace.sh --emit-index --out <arquivo>`: o índice vai para um temporário ao lado do destino, e o `mv` só
  acontece com rc 0. Com rc 2 (vendor anterior à 4.25.1, produto ausente ou quebrado), o destino fica
  byte-idêntico. Com rc 3 (índice vazio declarado), grava vazio só se o destino não existe ou já está vazio.
  Destino com linhas fica intacto, porque o rc 3 também vem com grafo ilegível e quem julga a divergência é a
  REGRA 84 (Índice de leitura do KG em sincronia com os traces). Sem `--out`, o stdout é o de sempre.
- As duas mensagens HARD da REGRA 84 (AUSENTE e DEFASADO) ensinavam `--emit-index > docs/onion/kg-read-index.tsv`,
  que é a forma que trunca. Agora ensinam `--out`. O `_regen` do `pr-finalize.sh` passou a usar `--out`.
- `kg-index-floor.sh` (novo, em `utils/adopt/`) imprime UMA linha `AVISO kg-index:` quando o vendor kg-ssot do alvo
  é anterior à 4.25.1, não tem versão legível ou não tem `tools/kg_trace.py` (perfil gate). O aviso sai em dois
  lugares. O primeiro é o `remeasure-contract.sh`, cuja saída vai inteira na seção "Contrato KG-SSOT do corpus" do
  relatório do update: medido NO ALVO, depois do merge, vale para vendor próprio e do Onion. O segundo é o
  `vendor-manifest.sh`, no ramo que já detecta o vendor PRÓPRIO, antes da cópia, onde a decisão "adote a kg-ssot
  junto" ainda cabe.

## Achados

1. **REAL, curado.** A REGRA 59 (Modo que a produção consome é exercitado pela bancada) acusou
   `kg-trace.sh [--emit-index --out]` sem teste, com a bancada nova já verde. O meu caso chamava `bash "${s}"` e
   `bash "${helper}"`, e o extrator resolve `${helper}` pela ÚLTIMA atribuição do arquivo inteiro, que é de outra
   família. Cura: o caso (j6d) chama `bash "${SCRIPT_DIR}/kg-trace.sh" . --emit-index --out …`, que é a forma
   literal da produção, no repo real, e compara índice e rc com o modo stdout.
2. **REAL, curado.** O stub de `kg-trace.sh` da bancada do `pr-finalize` imprimia no stdout e ignorava argumentos.
   Com o `_regen` em `--out`, ele ficaria verde sem escrever nada, ou seja, deixaria de espelhar o runner. O stub
   agora honra `--out`.
3. **REAL, curado.** O 1º rascunho do `--out` com rc 3 gravava vazio sempre, como o `regen-ssot-projections.sh`.
   Só que o `pr-merge-verified.sh` já mediu que grafo ILEGÍVEL também sai rc 3, e aí o índice povoado viraria vazio.
   O `--out` só esvazia o que já está vazio. O `regen-ssot-projections.sh` NÃO foi trocado: a porta materializada
   precisa do vazio-sobre-povoado (o índice do core chega populado, e o corpus da porta não tem trace), e ele já
   era atômico, porque captura numa variável e só escreve com rc 0 ou 3.
4. **Não-defeito, declarado.** A mensagem de rebase em repo alheio do `pr-merge-verified.sh` segue com
   `--emit-index > /tmp/idx.tsv && mv …`. Ela já é atômica (o `&&` não move no erro), e o alvo pode ter um
   `kg-trace.sh` anterior a este PR. Um script anterior IGNORA `--out` e imprime no stdout, então trocar a mensagem
   faria a regeneração virar um no-op calado lá.

5. **REAL, curado (achado pela bancada `--affected-range`).** O `pr-finalize --check` monta uma worktree
   descartável do índice. Ali `docs/onion/` não existe quando nada nele é rastreado, e o `--out` reprovava com
   "diretório não existe". Agora o `--out` cria o diretório do destino (`mkdir -p`) e só falha se ele for inválido.
   O stub da bancada faz o mesmo.
6. **REAL, curado (achado pela REGRA de shell-pipefail da bancada).** No `kg-index-floor.sh`, os pipes
   `sort -V | head -1` e `sed | head -1` fechavam cedo sob pipefail. Viraram `sed -n 1p` e `sed …;q`.

Grep de fechamento: `git grep -n -- '--emit-index >'` fora de `docs/evolution/` devolve só essa mensagem (item 4)
e o fixture-stub da bancada do merge alheio (`_fxg`, que exercita um stub próprio, não o gerador).

## Mutantes

- **j6-MUT:** o gerador escreve DIRETO no destino (`> "${OUT}"` no lugar de `> "${_otmp}"`). O (j6a) cai, porque o
  rc 2 esvazia o índice, que é exatamente o dano do adotante.
- **k-MUT:** sem a chamada ao `kg-index-floor.sh` no `remeasure-contract.sh`, o relatório cala o vendor 4.22 e o (k)
  cai.
- Os mutantes existentes das duas famílias seguem mordendo: os 11 do `remeasure-contract` (m) e o (g-MUT).

## Limites declarados

- O `--out` sobre um destino que é symlink troca o link por um arquivo, porque é `mv`. Ninguém versiona o índice
  como link, então o caso não foi tratado.
- O piso é comparado por `sort -V`. Uma pré-release `4.25.1-rc…` conta como >= 4.25.1.
- O aviso não bloqueia o update. É informação para o relatório e para o momento da cópia, como o resto do
  `remeasure-contract.sh`.
