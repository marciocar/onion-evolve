---
reviewed_diff_sha256: b2812159b9a80bfa8384b0c68c9208ef8fd27438a3625eb1de4ac6d60f2d0399
reviewed_code_sha256: 086ad31669b9017e15861ba24a15cf575d6c31a2d6afdb11d5712c297a6cd252
findings_total: 6
findings_real: 6
tokens: 0
duration_min: 15
verdict: APROVADO
elenxo: sim
nota: >
  Passada adversarial feita pelo próprio autor, no contexto da execução, sem refutador independente
  (declarado: a independência é menor que a de um subagente com default REPROVADO). O mandato tinha
  três perguntas: sobrou IP ou hostname em superfície que viaja, algum exemplo fictício caiu num nome
  real, e o diff de hooks novo dá falso "mudou" por ordem de chaves. Cada uma foi respondida por
  medição, e as três renderam cura no mesmo laço. APROVADO descreve o estado depois das curas.
---

# Resíduo — `chore/core-cleanup-batch-2026-10-13`

Lote de limpeza do core: pins de dois adotantes, dois defeitos do relatório do `/meta:adopt --update`,
o defeito do greenfield nas projeções que contam o índice, a superfície pública e dois registros no grafo.

| # | achado | desfecho |
|---|---|---|
| 1 | Pergunta 1, IP e hostname na superfície que viaja. Antes: 1 IP e 2 hostnames, todos em `docs/knowledge-base/`. | Curado com `<ip-da-vps>` e `<host-da-vps>`. Medido depois com `git grep` nas raízes do manifesto (`.claude/{agents,commands,skills,utils,validation,hooks,rules,workflows}`, `docs/meta-specs`, `docs/knowledge-base`, `docs/sdaal`, `plugins`): zero para os dois, e zero IPv4 fora de loopback, rede privada e link-local. O núcleo core-only (grafos, pesquisa, diário, federação) fica, por decisão de escopo: não viaja, e o pedido era não reescrever a história. Mas o core é público desde 2026-10-13, então ali o IP e o hostname seguem legíveis; isso está declarado no PR. |
| 2 | Pergunta 2, exemplo fictício caindo num nome real. A 1ª troca usou `empresa-exemplo.com`, que é um domínio registrável e pode ter dono. | Curado para `empresa.example` (TLD reservado pela RFC 2606). Achado que fica: os vizinhos do mesmo bloco (`cto@empresa.com`, `status.empresa.com`) já usavam `empresa.com`, que é domínio real; e o nome da empresa de birô de crédito aparece em uns 70 pontos de 4 arquivos de compliance como "exemplo real" de due diligence. Só o e-mail e o canal de Slack do bloco de contato foram trocados, porque eram os identificadores compostos com o nome. O resto vai como achado ao maestro. |
| 3 | Pergunta 3, falso "mudou" por ordem. A ordem das chaves dentro de um hook não gera mudança (o `==` do jq é estrutural), mas a ordem de uma lista no topo (a allowlist de `permissions`) gerava "chave de topo diferente". | Curado: o topo compara com as listas ordenadas. Caso (b) da família `hooks_diff` reordena chaves e a allowlist; o (b-MUT) tira a ordenação e vê a mudança falsa voltar. |
| 4 | O rótulo de origem do `regen-baselines` comparava com o HEAD da fonte. No dogfood contra a cópia de um adotante real, 1 das 31 chaves do `ops-citation-travel-baseline` saiu "do adotante" só porque o core mudou o arquivo depois do pin (o próprio `adopt.md` deste PR). | Curado: a chave também é do core quando o blob do alvo é o do core no `source_commit` do carimbo. Dogfood depois: 31 do core e 0 do adotante. Caso (e3) e o mutante dele. |
| 5 | O 1º mutante do (e2) comentava o resto da linha (`#` no meio de um `if`) e quebrava a sintaxe; o caso reprovava pelo motivo errado. | Curado: o marcador entra como operando (`[ ONION_MUTANTE ]`), sem comentar código. |
| 6 | O diff de hooks indexa por (evento, matcher, command). Dois hooks idênticos no mesmo grupo colapsam numa entrada, e a duplicata não aparece. | Declarado, não curado: o merge do Onion não produz duplicata (é idempotente por command) e o caso não foi medido em adotante. |
