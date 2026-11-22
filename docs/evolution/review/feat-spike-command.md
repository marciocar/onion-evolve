---
branch: feat/spike-command
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 9
findings_blocking: 1
tokens: 126322
duration_min: 5
findings_fixed: 6
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose opus, mandato refutar, isolado e só leitura"
nota: "O achado 8 (radar lê aresta inline como ausente) é defeito anterior ao diff e fica fora da contagem de reais deste PR; vai declarado abaixo. Depois do refutador, o 2º spike de prova (aberto pela cura do achado 1) também morreu pelo critério, e a lição entrou no comando."
---

# Passada adversarial: `feat/spike-command`

## O que muda

- Comando novo `/engineer:spike` (`.claude/commands/engineer/spike.md`): ficha do spike (pergunta fechada,
  critério de morte antes da amostra, tempo-caixa, prova, não toca, desfazer, resultado, próximo degrau) e a forma
  no grafo (`Q_` com `x_spike_*` → `evidence` → `decision`).
- Grafo `docs/onion/graph/spike-standard-2026-11.kg.yaml`: decisão da forja, sinal do hub, dois spikes de prova do
  molde (os dois morreram pelo critério) e a pergunta aberta do medidor.
- Sinal do hub arquivado em `docs/evolution/inbox/_processed/`; ligações no README e no help do engineer e no
  `/product:estimate`; inventário regenerado (123 comandos) e contagens propagadas pelo `lint --fix`.

## Achados

1. **BLOQUEIA (curado):** critério de morte sem consequência; o 1º spike morreu e foi promovido a `slice` com uma
   2ª medida sem pré-registro. Cura: passo 8 do comando (critério disparado leva só a `discard`; outra tentativa é
   spike novo com `Q_` novo e critério commitado antes); no grafo, `D_SPIKE_XFIELDS_PASS_GATES_1122` virou
   `discard` e nasceu `Q_SPIKE_MOLDE_V2_1122`, com critério no commit d9d9e65d1, anterior à amostra.
2. LIMITE (curado): ensaio antes do pré-registro. O comando passa a dizer que ensaio da forma vale e amostra
   julgada não; a narrative da evidência declara o ensaio.
3. LIMITE (curado): o mutante do 1º spike testava o radar, não o molde. O mutante do 2º spike exercita a regra do
   molde (aresta do nó destravado) e foi ele que matou o 2º spike.
4. LIMITE (declarado): os valores de `x_spike_*` não são conferidos por juiz. Entrou no escopo de
   `Q_SPIKE_ORDER_MEASURER_1122` e no «O que este comando NÃO faz».
5. LIMITE (curado em parte): as KBs citadas não viajam na vertical de engenharia. As duas regras do drive §3.1
   foram escritas em uma linha cada no comando; o verificador do contrato é citado sem caminho, como «onde estiver
   instalado». O manifesto não foi mexido.
6. LIMITE (curado): squash apaga a ordem na main. O passo 3 manda citar o sha do commit do critério na evidência.
7. LIMITE (curado): `verified_against` faltava na lista de campos de todo nó.
8. Fora deste diff: o radar trata aresta inline `{from:…}` como ausente sem erro de legibilidade (defeito anterior;
   o comando usa a forma de bloco).
9. LIMITE (declarado): o original do sinal segue não rastreado na caixa de entrada do checkout principal; este PR
   não toca o checkout principal. Remover é da sessão principal depois do merge.
10. LIMITE (curado): o mesmo comando atende pergunta técnica e hipótese de valor; uma linha no comando o diz.

## Mutantes

- Aresta com `edge_type: ANSWERS`: radar rc 1 e contrato rc 1 (scratch).
- Pergunta sem nenhuma aresta: radar rc 1 (nó órfão) e contrato rc 1 (`integrity.orphan-node`).
- Grafo final sem a aresta do nó destravado para `Q_SPIKE_MOLDE_V2_1122`: radar rc 0. **O mutante passou**, e por
  isso o 2º spike morreu. Lição escrita no passo 7 do comando e no escopo do medidor.

## Limites declarados

- Nenhum medidor nem bancada nesta onda (peças 3 e 7 da forja): com os spikes registrados só pelo core, não há
  série para medir. Gatilho em `Q_SPIKE_ORDER_MEASURER_1122`.
- Doutrina nova não nasceu: a escada de promoção e o drive §3.1 já são a doutrina, e o comando as cita.
- O `forge-census.sh` não lista o comando entre os candidatos (não tem as peças que ele procura).
- A aresta do nó destravado só é cobrada pelo radar no commit 1.
- Itens 4, 5 (manifesto), 8 e 9 acima.
