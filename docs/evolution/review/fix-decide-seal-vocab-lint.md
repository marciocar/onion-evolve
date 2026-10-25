---
branch: fix/decide-seal-vocab-lint
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 4
tokens: 0
duration_min: 50
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "passada própria + 2 mutantes executados + replay do incidente real (sem subagente) — gate mecânico: família decide"
nota: "tokens 0: a passada foi do próprio agente de execução, sem subagente medido à parte."
---

# Passada adversarial: `fix/decide-seal-vocab-lint`

## O que muda

O `kg-decide-seal.sh` ganha um terceiro gate depois do radar e do contrato: o **lint de nomes**
(`kg_vocab.py lint`, o mesmo leitor que o CI do core roda sobre a prosa dos grafos). O selador mede o
lint sobre o corpus **antes** da escrita e **depois** dela; achado que o selo acrescentou ao grafo tocado
(chave nó, campo, achado, código) desfaz a escrita byte a byte e sai rc 3 nomeando código, campo e nó.
Lint ausente, grafo não rastreado pelo git ou lint que não julgou são declarados em stderr, e a linha ✅
diz `nomes NÃO julgados`. As externas do repo (`.kg-ssot/vocab-externals.tsv`), quando existem, entram
como `--external`.

O leitor escolhido é o `kg_vocab.py` do vendor (ou o `tools/kg_vocab.py` do produto KG-SSOT), e não o
wrapper com catraca do CI do core: o wrapper é core-only e o vendor viaja para os adotantes. A catraca
do selo é o próprio grafo antes da escrita, e não a base versionada, então dívida antiga não vira culpa
do selo e o selador não depende de uma base que só o core grava.

## Achados

1. **(real, curado) O defeito do enunciado.** O selo copia o `verified_against` e a proveniência anteriores
   para a narrative. O lint lê a narrative e não lê o `verified_against`, e o selador saía ✅ sem rodá-lo.
   **Replay** do caso real: o grafo da rodada 18 do radar do Claude Code na versão anterior ao selo de
   2026-10-25, selado com os mesmos argumentos pelo selador novo → rc 3,
   `✗ «r18» no campo narrative do nó Q_FECHAR_SAC_239_COM_O_REVISOR_PROVADO_1024 (vocab.code-unresolved)`,
   sha256 do grafo igual ao de antes.
2. **(real, curado) Bash antigo.** `"${VOCAB_EXT[@]}"` com o array vazio sob `set -u` quebra no bash anterior
   ao 4.4, o do macOS. Trocado por `${VOCAB_EXT[@]+"${VOCAB_EXT[@]}"}`.
3. **(real, curado) GNU-ismo.** `realpath --relative-to` não existe no BSD. O caminho relativo agora sai do
   `os.path.relpath` (o python3 já é pré-requisito do selador).
4. **(real, curado) Override sem caso.** A 1ª versão declarava um `DECIDE_SEAL_VOCAB` de bancada que nenhum
   caso usava. Era declaração sem comportamento verificado, e foi removido.
5. **(falso) "A comparação por nó diverge da catraca do CI, que conta por arquivo."** Ela só diverge para o
   lado de recusar: um código novo que o CI aceitaria pela folga da base (uma ocorrência removida em outro
   nó do mesmo arquivo) o selador recusa. O sentido inverso, o CI reprovar e o selador aceitar por culpa do
   selo, não existe, porque toda ocorrência que o selo acrescenta cria uma chave nova ou excede a contagem.

## Mutantes

- **Sem a chamada do lint depois da escrita** (o "depois" copiado do "antes"): o (s16) reprova com
  `solto-rc0`. O código solto passava calado, exatamente o dano.
- **Sem as externas** (a linha que monta o `--external` removida): o (s16) reprova com `externa-rc3`.

Os dois foram restaurados, e a família decide fecha **36/0** com o selador real.

## Limites declarados

- Dois lints do corpus por selo, cerca de 3,4 s cada no core. O custo é aceito: o selo é raro, e o CI
  reprovaria do mesmo jeito.
- O lint lê só os grafos que o git rastreia. Um grafo nascido no mesmo movimento, antes do `git add`, não é
  julgado, e o selador declara isso. Nesse caso o lint roda no pr-finalize.
- Os excludes padrão do vendor (vendor, fixtures) e os do CI do core (`kg-inbox/_rejected`, `_sealed`) não
  são replicados um a um. Grafo excluído pelo vendor não tem achado antes nem depois, então passa, como
  passaria no CI. Já um selo num grafo da `kg-inbox/_sealed` pode ser recusado quando o CI aceitaria. O erro
  é para o lado de recusar.
- Dívida de nomes que o grafo já tinha não é cobrada no passo 0: ela não é do selo, e a catraca do CI segue
  cobrando.
- Não reescrevi o texto copiado (o passo opcional 2): a guarda recusa e diz como glosar na origem. O texto
  do maestro não é alterado.
