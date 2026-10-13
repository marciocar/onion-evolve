---
title: 'Resíduo adversarial — o painel de testes deixa de ser o arquivo-ímã, e a catraca ganhou linha de base'
date: 2026-10-13
branch: feat/merge-process-step-a-magnet
reviewed_diff_sha256: 0e1364c80a58f6b1991437ef03bbe9b171eab155847aaf91e0b64a37300ad045
reviewed_code_sha256: 63facdf57fa757c62c5eca2958b9d08a7532d1856f8659577114a303d59e522f
findings_total: 8
findings_real: 8
findings_fixed: 7
tokens: 129902
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador opus com default REPROVADO atacou o passo A de D_MERGE_PROCESS_ONION_2026_10, lendo o
  diff, rodando os geradores e remontando o sandbox da bancada. Ele confirmou três alegações: o painel
  versionado ficou invariante ao PR, a REGRA 81 continua barrando número digitado, e nenhum leitor do
  painel quebrou. Achou um defeito ALTO, que era meu e anterior à mudança, mas que o commit passou a
  alegar ter provado. Achou também um MÉDIO, uma nota que afirmava mais do que o medido. O mutante
  achou um 7º e o pr-finalize, um 8º (REGRA 58). Um achado fica declarado, sem cura.
---

# O painel deixou de mudar por PR. A prova da catraca era vácua.

## 1. (ALTO, curado) O caso (g) acusava a REGRA 81 com ou sem adulteração

O sandbox do caso não tinha a série nem os resíduos. O painel gerado pelo repo real divergia do painel
que o lint do sandbox calcula (`⊘`, "Produtores vivos 1/3"), e por isso a REGRA 81 disparava mesmo com
o painel intacto. O caso provava que a regra é alcançável. Não provava a catraca. Cura:
- o sandbox recebe a série e os resíduos e gera o **próprio** painel;
- a **linha de base** exige zero REGRA 81 com o painel intacto;
- só então se digita o número;
- se o `sed` não casar, o caso reprova, em vez de trocar em silêncio para outra adulteração.

## 2. (MÉDIO, curado) "↻ ao vivo: não mora no git" era falso para a seção 1

Os mesmos sete contadores da seção 1 seguem versionados em `docs/onion/testing-inventory.md`
(REGRA 80). Esse arquivo é outra projeção e fica para o passo B, que tem Elenxo próprio. A nota passa
a dizer "não mora neste painel" e nomeia onde o número ainda mora. Só os contadores da REGRA 56
(seção 4) saíram de fato do git. Isso quer dizer que dois PRs que acrescentam **asserções** ainda
colidem, mas no inventário e não mais no painel. Fica declarado aqui e no PR.

## 3. (curado, achado pelo mutante) O sentinela `510` casava com o número real

Com o mutante que devolve os números ao versionado, o caso (g) ficava verde: `**510**` era o número
real de resíduos naquele instante. O sentinela agora é `987654`. Com o mutante, (g) e (h) reprovam.

## 4. (BAIXO, curado) O pre-commit regenerava o painel a cada resíduo stageado

O comentário dizia "o painel CONTA resíduos", o que já não é verdade. O gatilho passa a ser o
próprio gerador ou a série coletada. Produtor quebrado por outro diff é pego pela REGRA 81 no lint.
A família `hook_regen_table` continua verde.

## 5. (BAIXO, curado) A defesa 1 só era testada no `--markdown`

Os números agora só aparecem no `--live`. O caso (a') exige comando ao lado de toda célula com
número também ali.

## 6. (BAIXO, curado pelo pr-finalize) `testing-inventory.md` defasado na branch

1919 contra 1921 sítios, efeito dos commits de checkpoint feitos com `--no-verify`. O pr-finalize
regenera.

## 7. (BAIXO, declarado, não curado) Perda de visibilidade no diff de PR

Se um produtor sair 0 com números errados (por exemplo, zero resíduos), antes isso aparecia como diff
do painel no PR; agora o versionado não mostra. A troca foi deliberada, porque é exatamente o que
fazia do painel um ímã. O número está a um `testing-state.sh --live` de distância, e um produtor que
falha continua virando `⊘`, o que muda o versionado.

## Mutantes (via `ops/mutate-and-restore.sh`, todos restaurados, marcador zero)

| Mutante | Caso que reprovou |
|---|---|
| `_vol` imprime o número (desfaz a cura) | (h) e (g) |
| `--live` sem o marcador `SAÍDA AO VIVO` | (i) |
| a REGRA 81 sem o diagnóstico nomeado | (i) |
| a REGRA 81 sem o diff | (g), mutante interno da família |

## Simulação de dois PRs paralelos que acrescentam um resíduo cada um

- **Antes** (`origin/main`): os 2 PRs tocam o painel, e o rebase do segundo tem **CONFLITO** em
  `docs/onion/testing-state.md`. Com dois resíduos de conteúdo idêntico, o rebase sai limpo, mas o
  painel fica **defasado** (REGRA 81 vermelha), e o commit de regeneração vira o próximo conflito.
- **Depois**: 0 de 2 PRs tocam o painel, o rebase sai limpo e o painel fica em sincronia.

## 8. (curado, achado pelo pr-finalize) O selo novo estourou o teto do grafo

O `kg-decide-seal.sh --new` criou o 65º nó num grafo que declarava `TETO: 64 NÓS`, e saiu com rc 0,
porque o gate do selador é só o radar e o contrato. O lint do commit reprovou pela REGRA 58 (O backlog
cumpre as promessas do próprio `meta:`). O teto sobe para 65 **declarado** no `meta:`: o nó é
resposta do maestro, não onda nova de pesquisa. Fica como achado para o selador. Ele deveria conferir
o teto antes de escrever, ou recusar com rc 2 nomeando a REGRA 58. Não curei aqui porque está fora
do escopo do passo A.
