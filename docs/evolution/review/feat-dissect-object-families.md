---
branch: feat/dissect-object-families
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: 3e186ee266a2248fc93e895e09a27836ffb7d41ce5b8d526758c74d6195a6c9b
reviewed_code_sha256: 23e498359ba63ec4521e4c2c6b61fee8c3232b93c1625fff45160eb71549d26b
findings_total: 6
findings_real: 4
tokens: 0
duration_min: 25
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "agente de execução da sessão principal (claude-opus-5-5), passada própria sobre o próprio diff"
nota: "tokens não medidos pelo agente; o harness reporta o uso na notificação final"
---

# Passada adversarial: `feat/dissect-object-families`

## O que muda

- Selo do maestro de 2026-10-24 em `sinais-de-campo-2026-09`: `D_DISSECT_ABSORVE_PECAS_PARQUEIA_MOTOR_1024`
  (por `kg-decide-seal.sh --new`), ligado ao sinal `E_SINAL_DISSECAR_QUALQUER_OBJETO_1023`; a pergunta aberta
  `Q_DISSECT_MOTOR_PARQUEADO_OBJETO_EXTRA` com o gatilho do motor; a entrega `E_DISSECT_PECAS_ABSORVIDAS_1024`.
- Peças absorvidas do protótipo do adotante, adaptadas: registro `.claude/validation/dissect-families.kg.yaml`
  (6 famílias, `x_term`), checador `.claude/validation/dissect-object-check.{sh,py}` (8 itens), bancada
  `.claude/validation/dissect-object-bench.py` na família nova `dissect_object` (72 casos + 4 de rc 3, piso).
- Doutrina §6, comando (passos 0, 4, 5 e 6, contexto injetado, o que NÃO faz) e lente do `/meta:dissect`.
- Sinal do inbox movido para `_processed/` (byte-idêntico ao da árvore principal e ao do remetente); entrada no
  CHANGELOG de co-evolução e rascunho em `docs/evolution/federation/outbox/onion-curation/`.
- Projeções regeneradas (backlog, índice de leitura do KG, inventário do harness) e a base do gate do contrato para
  o grafo novo.

## Achados

1. **REAL, curado (dogfood)** — o wrapper rodava o `.py` da RAIZ do repo. Chamado de outro repo (o core medindo o
   estudo de um adotante), a raiz não tinha o `.py` e o python saía **rc 2**, fora do contrato 0/1/3 — quem lê o rc
   como "0 aprova, 3 não mediu" não sabia o que era 2. Cura: o `.py` é o vizinho do wrapper e sua ausência é rc 3;
   medido: o mesmo comando agora sai rc 3 com "registro ausente".
2. **REAL, curado (fail-open do medidor)** — registro sem nenhuma família viva fazia todo estudo sair
   `familia-fora-do-registro` (rc 1): o defeito do MEDIDOR aparecia como defeito do estudo. Cura: rc 3; dois casos de
   rc 3 (cheque e `--context`). Mutante à mão (o `raise` trocado por `pass`) reprova a bancada.
3. **REAL, curado (tabela paralela)** — o apelido legado `A|B|C` era um dict no código, duplicando os labels `hidden`
   do registro. Cura: lido do registro. Caso legítimo "família pelo apelido legado C" + mutante à mão (labels ignorados)
   reprova a bancada.
4. **REAL, curado (declarado ≠ medido)** — a proposta diz bancada de 60 casos; medido no fonte do remetente: 69 + 2 de
   rc 3. O número do sinal e dos cabeçalhos é o medido.
5. **Adaptação, não defeito** — o modo estudo do core (`x_dissect_mode: study`, para no N2 sem veredito) não existia no
   protótipo: lá ele sairia `veredito-ausente`. Entrou com código próprio (`estudo-com-veredito`) e caso legítimo.
6. **Limite, não curado aqui** — o checador só julga quem o chama: nenhuma regra do lint o roda sobre o corpus, e um
   estudo que omite `x_study_destination` fica fora da projeção `--context` como "anterior". O passo 6 (GATE) do
   comando é quem o exige; uma guarda de lint é outro PR, se o uso pedir.

Procurado e não achado: nome comercial de cliente ou caminho do repo do adotante nos arquivos que viajam (as linhas
novas de `.claude/` só dizem "um adotante de curadoria"); o caminho do registro do adotante aparece apenas no
CHANGELOG e no rascunho da outbox (core-only, como instrução de reapontar a aresta) e no sinal processado.

## Mutantes

- Cada código do checador: calado um a um pela bancada (parte 3), todos mortos.
- Registro vazio aceito → caso "registro sem família viva" reprova (rc 1 em vez de 3).
- Apelido legado ignorado → caso "família pelo apelido legado C" reprova.
- Bancada encolhida (`CASES[:5]`) → o piso da família `dissect_object` reprova.

## Dogfood

- `--context` no core: 6 famílias, 7 estudos de antes de 2026-10-24 listados como "anterior".
- Num clone descartável do repo do adotante (o repo dele não foi tocado; `git status` limpo), o checador do core sai
  rc 0 nos 3 estudos reais depois de reapontar a aresta da família ao registro do core, e rc 1 com
  `veredito-fora-da-familia` + `perseguir-sem-saida` quando o veredito do app vira `perseguir`.

## Limites declarados

- O wrapper faz `cd` na raiz: grafo passado por caminho relativo a um subdiretório sai rc 3 (ilegível), não rc 0.
- O checador confere forma, pertença e ordem no git; se a superação entrega e se o gatilho mede a coisa certa é do
  Elenxo. O motor do protótipo (workflow de 3 agentes) não entrou: parqueado com gatilho.
- Bancada local rodada nas famílias `dissect_object` e `dissect`; a seleção completa é do pr-finalize e do CI.

## Re-revisão depois do rebase (2026-10-25)

O hash de código mudou só pelo rebase sobre a main (entraram #1338, #1339 e #1340). Conferido arquivo a arquivo contra o
push revisado (979b29ec): os 7 arquivos meus de `.claude/` estão byte-idênticos, e o hunk meu do `lint-selftest.sh`
é idêntico linha a linha (o resto da diferença é da main). O índice de leitura foi regenerado pelo `kg-trace.sh
--emit-index` (o `kg-trace-resolve.sh` saiu na main) e difere da main só nas 9 linhas dos meus traces. Bancada local nas
faixas: 2259 passam, 3 falham, todas na família `door` (c, e, f), que reprovam igual na origin/main limpa (índice de
leitura da porta vazio desde o #1340, curado à parte). Nenhum achado novo.
