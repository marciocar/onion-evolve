---
branch: feat/cortex-seal-and-unique-anchor
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 26
findings_real: 8
tokens: 206552
duration_min: 9
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: code-reviewer (agente novo, recebeu o código e não as minhas conclusões)
nota: >-
  Um refutador separado leu o diff inteiro, rodou sondas do helper em mktemp e a família nova. Achou 10 coisas:
  4 reais, todas tratadas (2 por código e caso de bancada com mutante, 2 por contrato escrito no cabeçalho do
  helper, porque a cura por código quebraria os chamadores), e 6 confirmações, entre elas a da
  confidencialidade.
---

# Passada adversarial: `feat/cortex-seal-and-unique-anchor`

## O que muda

- `ops/mutate-and-restore.sh`: conta a âncora (sobreposições incluídas) e recusa a ausente (3) e a repetida (4,
  com a contagem); roda a linha de base e recusa a vermelha (5); só 0 (sobreviveu) e 1 (morreu) são veredito,
  com o rc cru em stderr e, sob `MUTATE_RC_FILE`, num arquivo; 6 para o alvo que não se lê ou não se escreve;
  9 para a restauração que falha, agora com o backup preservado.
- `lint-selftest.sh`: os chamadores (`stt_service`: (m), `_stcase`, w1, w2, w15, w27; `mcp_onion_kg_writer`: (m))
  leem o rc do helper, não a prosa; a família nova `mutate_helper`.
- `docs/evolution/dissect/cortex-2026-10/cortex-2026-10.kg.yaml`: o selo das 9 peças e os dois sinais em
  `_processed/`.

## Achados

1. Chamadores do helper: só 4 famílias o executam, todas ajustadas. Confirmação.
2. Nenhum rc de "não plantou" vira "mutante reprova" nos chamadores ajustados. Confirmação; a mensagem do
   `else` da (m) do stt diz "sobreviveu" também para o rc 2 e o 9, cosmético.
3. **Real.** A linha de base consome o stdin, e a rodada mutada lê EOF. Guardar o stdin foi tentado e
   descartado: dentro de um `while read … done <<EOF` (a forma das famílias stt e mcp) ele comeria o resto do
   laço. Ficou o contrato no cabeçalho: o comando não pode ler o stdin.
4. **Real.** Comando não idempotente sai "morto" na 2ª rodada pelo estado. Contrato no cabeçalho (o comando
   tem de ser idempotente); os chamadores que sujam estado já declaram a linha de base por
   `MUTATE_BASELINE_PROVEN`.
5. **Real, curado.** `MUTATE_BASELINE_PROVEN` e `MUTATE_RC_FILE` vazavam para o comando, e um helper aninhado
   pulava a própria linha de base. Agora o comando roda sob `env -u` das duas; caso (p) com mutante.
6. O w2 usa `MUTATE_BASELINE_PROVEN` num controle positivo, fora do texto do contrato. O contrato passou a
   nomear o controle positivo. Confirmação.
7. **Real, curado.** A bancada não provava INT, o rc 9 nem o rc 6. Casos novos (l) Ctrl-C na linha de base,
   (n) restauração que falha com o backup nomeado e (o) alvo sem leitura, cada um com mutante. Ao escrever o
   (o) achei mais um defeito, meu: com o `cp` do backup falho, o trap era armado com um backup vazio e podia
   truncar um alvo só de escrita no EXIT. Curado (o backup tem de existir antes do trap), e é o que o mutante
   do (o) reprova.
8. O rc 1 cobre também 126, 127 e a morte por sinal; com a linha de base declarada, um comando quebrado conta
   como morto. Não é regressão (antes não havia linha de base nenhuma); o mcp exige `^FAIL <caso>` na saída e
   o `_stcase` compara o rc cru. Confirmação.
9. Confidencialidade: os dois sinais e o grafo não trazem nome de pessoa, de repositório, de banco nem
   caminho do cliente; as URLs apontam o repo de curadoria do maestro. Conferi também o helper e a bancada.
   Confirmação.
10. Os 12 mutantes da 1ª versão da família derrubam cada um o seu caso. Confirmação.

## Os `confirmed` do grafo editado

O grafo `cortex-2026-10.kg.yaml` nasce neste PR, então os `confirmed` dele são os que eu mesmo escrevi. Conferi
os três de maior impacto contra o que o PR propõe: `E_MUTATE_ANCORA_UNICA_MEDIDA_1027` é a própria bancada deste
PR (15 casos e 16 mutantes, rodados); `E_CORTEX_PECA_QUALIDADE_1027` é a lacuna que a cura fecha, e nada no
helper novo a contraria; `E_CORTEX_PECA_GATE_DE_PLANO_1027` diz que o gate de plano esbarra no `.gitignore` das
sessões, e por isso o PR não o implementa: deixa a pergunta aberta com o próximo passo. A peça de documentos foi
rebaixada de 6 para 5 depois da 1ª prova da curadoria (PR #137 de lá). A 2ª (PR #144 de lá) provou a captura e o
diagrama sem rede, e a peça passou a costurar a receita completa, nota 5 a 6 conforme o navegador; o parque da
captura fechou. O nó da peça, a pergunta dela e o selo dizem isso, e a evidência da peça ganhou a aresta externa
para a doutrina sem dependência de serviço externo.

## Mutantes

A família `mutate_helper` planta, com o próprio helper vivo, um mutante por cura numa cópia dele: âncora
ausente, repetida e sobreposta, a linha de base, a normalização do rc, o `MUTATE_RC_FILE`, o trap de EXIT, o de
TERM e o de INT, a recusa do marcador, o `MUTATE_BASELINE_PROVEN`, a escrita por bytes (CRLF), o backup
preservado no rc 9, o backup antes do trap e o `env -u`. Todos morrem. A linha de base de cada mutante é o
caso na cópia sem mutante, a cura que a família prova.

## Depois da passada: o CI achou um

O caso (l), Ctrl-C na linha de base, passava localmente e falhou no CI, junto com o mutante dele (rc 5). A
faixa paralela da bancada roda o job em segundo plano, e o bash herda o INT IGNORADO; sinal ignorado na
entrada não se captura. Reproduzi com `trap '' INT` em volta da bancada e curei no caso: o SIGINT volta ao
padrão por um exec em Python antes do helper. O helper não muda: quem o chama de um job em segundo plano já não
recebe Ctrl-C do terminal.

O delta desta cura passou por uma 2ª passada, com outro agente novo (47.679 tokens, 2 min). Ele rodou a família
com o INT ignorado e uma matriz que cruza o caso antigo e o novo com três versões do helper (original, o mutante
`trap '' INT` e sem trap de INT nenhum), sob INT padrão e ignorado. O caso antigo reprova só com o INT ignorado e
o helper correto, que é o vermelho do CI; o novo passa no helper correto e reprova nas outras duas versões, então
não é decorativo. São 7 achados, 6 confirmações e 1 falso-positivo descartado (o caso do TERM não sofre do mesmo
mal), e nenhum defeito real. Os totais do frontmatter somam as duas passadas.

## 3ª passada: a atualização da peça de documentos

A 2ª prova da curadoria (PR #144 de lá) mudou a peça de documentos, e o delta do grafo passou por um 3º agente
novo (63.112 tokens, 2 min), que leu o grafo da curadoria no commit fixado. Foram 9 achados: 4 reais, todos
curados, 4 confirmações e 1 falso-positivo. Os reais: o custo de 205 e 483 MB estava atribuído ao navegador,
quando é a pegada em execução (o navegador custa 0 MB a mais com o cache e 278 MB numa máquina limpa); faltava a
2ª condição da nota 6 (a versão do Playwright fixada); faltava dizer que a régua da nota 5 a 6 não era cega e que
a do custo mudou depois do 1º laboratório; e "exportava" afirmava que o Onion deixou de exportar pelo Gamma. Das
confirmações, apliquei três: a proveniência passou a citar as evidências da 2ª prova, o locator separa o campo do
label, e a frase da CDN admite o download da instalação. A quarta pedia não reescrever o label do selo do maestro,
e ele voltou ao texto selado; o complemento fica só na narrative.

## O conflito com a main, resolvido à mão

A main ganhou, no mesmo bloco do veredito dos mutantes da família `mcp_onion_kg_writer`, o ramo do mutante
equivalente `profundidade-tab-inicial` (sem libyaml no Python 3.15, ele sobrevive por construção). A resolução
mantém os dois: primeiro o rc do helper (≥2 é "não plantou"), depois o rc 1 com o `FAIL` do caso, depois o
ramo da main, que exige `mrc` 0, o mesmo "sobreviveu" do helper novo. A família foi rodada de novo depois da
resolução.

## Limites declarados

- O stdin e a idempotência ficam como contrato escrito, não como mecanismo.
- `(n)` e `(o)` pulam como root, porque a permissão não morde.
- O gate de plano e o pptx e docx não foram feitos aqui: são perguntas abertas no grafo, com o próximo passo.
