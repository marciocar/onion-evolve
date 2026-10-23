---
branch: research/kg-backlog-case-e-flaky
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: e79224259a0d0dd7925f130b83684bb0da178460415d8bbf32b4cd51549042e9
reviewed_code_sha256: 3a4914fe9572a594c63fba467e362b5f17a433debca3023c33d5388cefe9a7bf
findings_total: 4
findings_real: 4
tokens: 120179
duration_min: 25
findings_fixed: 3
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "refutador general-purpose (subagente, sem o meu veredito como premissa: recebeu as hipóteses H1-H3 para derrubar e o harness para re-medir)"
nota: >-
  Pesquisa sem mudança de código. Um refutador re-mediu as três hipóteses e reprovou duas
  afirmações minhas: a árvore das falhas (o 9->9 é de 9cd7efb0, anterior à cura do edges:, e não de
  980bdbe3) e o "HEAD 0->2" (o meu próprio commit deixou a REGRA 84 vermelha por não regenerar o
  índice de leitura). As duas foram corrigidas no nó e no índice. O achado maior dele, o (e) ser
  fail-open por contagem, entrou no nó como cura proposta; não se cura aqui porque o passo é pesquisa.
---

# O mutante sempre contou: quem oscilava era o controle

## O que muda

Um nó de evidência, `E_KG_BACKLOG_E_CONTROLE_INFLADO_PELO_EPIPE_DO_LINT`, no grafo da classe EPIPE
(`passada-adversarial-2026-09`), com o teto subindo de 56 para 57 pelo critério de recorrência da
mesma classe. Ele responde `Q_KG_BACKLOG_E_CONTADOR_NAO_SOBE_NO_MUTANTE` (fios-abertos) pelo id, sem
aresta: o fios-abertos está no teto (19/19) e a REGRA 58 (O backlog cumpre as promessas do próprio
`meta:`) reprova um 20º nó (medido com o helper numa cópia). A aresta para a pergunta e o selo dela
são do maestro no checkpoint. Junto vai o `docs/onion/kg-read-index.tsv` regenerado.

## Achados

1. **Árvore errada (real, curado).** Eu atribuí as duas falhas a 980bdbe3. Essa árvore já tem a cura
   do `edges:` (d2b27c7b, 15:31), e nela a margem do mutante é +2: o espúrio dá 10->10, não 9->9. O
   9->9 do f-par.log é de 9cd7efb0 (13:18), com margem +1 (refutador: ctrl 8, mut 9 no mesmo sandbox).
   O mecanismo não muda; o nó agora diz as duas árvores.
2. **"HEAD 0->2" falso no meu commit (real, curado).** O nó novo tem `trace:` e o índice de leitura
   não foi regenerado, o que dá 1 HARD real da REGRA 84 (Índice de leitura do KG em sincronia com os
   traces) no controle. Índice regenerado neste PR.
3. **O (e) é fail-open por contagem (real, registrado como cura proposta).** Com `check_kg_backlog`
   fora do dispatcher, o (e) passa (ctrl 1, mut 2) porque a REGRA 52 acusa o nó órfão da fixture.
   A cura do `edges:` não curou causa nenhuma: só subiu a margem de +1 para +2.
4. **`kg-verification-coverage.sh` l.431 (`_retired`) segue decidindo por pipe (real, latente).**
   Hoje nenhuma chave do ledger está no baseline, então o espúrio troca falso por falso. Fica nomeado.

Confirmado pelo refutador: o diagnóstico do (e) é cego (0 linhas `VIOLATION` contêm "HARD"); o
mecanismo é corrida dentro de um processo (`PIPESTATUS` 141 0), piorada pela carga; mesmo sandbox ou
sandboxes separados não mudam o número.

## Mutantes

- Helper da REGRA 49 de 980bdbe3: original 4/150 execuções concorrentes com HARD espúrio; os 4
  leitores trocados por here-string, 0/150 (o liga-desliga). HEAD: 0/150.
- Matcher de glob: forma `ls-files | grep -q .` 84/400 falsos mortos concorrentes; capturado, 0/400.
- `check_kg_backlog` fora do dispatcher (refutador): o (e) continua verde, e é o achado 3.

## Limites declarados

- A ocorrência original não tem log guardado: a ligação "o espúrio era este" é por mecanismo
  reproduzido na mesma classe de árvore, não pelo log da falha.
- Não houve máquina sem carga: a série foi medida com load de ~2,6 de outros usuários.
- Proposta de cura (para outro PR): o (e) julga o CONJUNTO pelo `ONION_LINT_HARD_FILE` (a linha
  `DONE-NU` no mutante e o controle contido no mutante), não a contagem, e a mensagem de falha
  passa a diffar esses arquivos. Caso de bancada que a prova: um lint-mutante que injeta um HARD só
  no controle (o (e) por contagem reprova em falso e o por conjunto passa) e um que desliga a
  REGRA 58 (o por contagem passa em falso e o por conjunto reprova).
