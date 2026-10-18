---
title: 'Resíduo — o tokenizador dos vetos carrega o estado das aspas entre linhas ao procurar heredoc'
date: 2026-10-18
branch: fix/heredoc-opener-multiline-quote
reviewed_diff_sha256: 11faa3fad0acf643bc6fdb908aa9c1b7f6b46de68ae5e88cac00537d36408598
reviewed_code_sha256: 6becd1a6498520069e79a72087280268c3b875cd8b59743c6248f35d4797c369
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 90000
duration_min: 90
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Sinal de campo de um adotante: o aviso da trava de merge disparou num comando honesto, com push de branch de
  trabalho. Reproduzido com o tool_input.command LITERAL, extraído do transcrito dele; a reconstrução à mão não
  reproduzia. A bisseção (delta debugging) achou a causa: find_heredoc_openers analisava uma linha por vez e
  recomeçava fora de aspas. Um `git commit -m "…"` de várias linhas, fechado na linha do `cat > r.md <<EOF`,
  fazia o `"` de fecho parecer abertura, o `<<EOF` parecia estar entre aspas, e o CORPO do heredoc (crases
  escapadas que citam merge) era lido como comando. No core isso dá veto falso em comando honesto; no
  adotante, aviso falso. Caso mínimo: 1 com a mensagem multilinha, 0 com a de uma linha. A cura passa o estado
  [aspa, pilha] de uma linha de comando para a próxima; o corpo de heredoc não conta, porque é literal. O lado
  perigoso (um `cat <<EOF` dentro da string e um push para a main depois) já falhava fechado como
  inanalisável e agora é lido como o bash o lê: o push vira invocação e é vetado. Bancada: (hq-a) core, a
  forma do adotante passa; (hq-b) adotante, sem aviso; (hq-c) lado perigoso, veta; (hq-MUT) sem o estado
  carregado o veto falso volta. pretooluse_veto 262/262; pretooluse_veto + empty_result_guard +
  moat_boundary 311/311. ELENXO: o refutador com mandato de bypass parou antes de testar (um classificador
  de segurança interrompeu a montagem das strings de ataque), então a passada dele não aprova nem
  reprova. Em troca, rodei um teste DIFERENCIAL defensivo: os 12.827 comandos Bash multilinha reais dos
  transcritos desta máquina pelas duas versões da lib, comparando só as linhas de risco (git push, gh pr
  merge, gh api, inanalisável). Resultado: 5 divergências, todas a antiga marcando inanalisável e a nova
  não, e nenhuma linha de push ou merge real perdida. As 5 foram lidas uma a uma: 2 são o meu próprio teste
  dentro de uma string entre aspas simples, que o bash não executa; 3 são comandos do adotante com push de
  branch de trabalho. Na forma exata desses comandos, com o alvo trocado para a main, o hook do core veta
  nas duas versões (rc=2).
---

# Resíduo — `fix/heredoc-opener-multiline-quote`

Teto: o diferencial cobre comandos que a casa de fato rodou, não o espaço adversarial. A busca deliberada por
bypass na nova contabilidade de aspas (comentário com aspa, `$'…'`, continuação com `\`, heredoc dentro de
`$(…)` multilinha) fica declarada como NÃO FEITA. Pede uma passada humana ou uma ferramenta de fuzzing de
gramática bash, não uma geração de strings de ataque por modelo.
