---
title: "Proposta da curadoria: o protocolo entre sessões — costurar uma peça (peer-ref-check); o resto fica doutrina"
date: "2026-10-25"
from: onion-curation
to: onion-evolve
type: proposal
issue: SAC-252
kg: docs/evolution/dissect/peer-protocol-2026-10/peer-protocol-2026-10.kg.yaml
decision_node: D_PEER_PROTOCOL_VERDICT
---

# O protocolo entre sessões: o que vira maquinaria

O maestro pediu: "esta lógica de relação e comunicação entre as sessões e suas atualizações deve ser dissecada e ser
apresentada para o core para virar maquinaria". O estudo foi feito na família `pratica`, com destino no core.

- **Plano pré-registrado:** Etapa 0 em `eb800ec` e desenho do N2 em `50970e8`.
- **Escada:** conduzida pela sessão, porque o motor está parqueado.
- **Estado medido do core:** em `CORE-STATE.md`, usado como dado.

## Veredito proposto: COSTURAR, no N2 (placar 5 de 10)

O escritor propôs absorver com placar 8. O Elenxo, um agente separado, rebaixou o veredito.

**Fica uma peça:**
- **`peer-ref-check <par> <grafo>#<ID>|<sha>`.** Antes de citar uma ref ou um selo, ele confere na `origin/main` do
  par. É a costura do que o kg-ssot já tem: o `integrity.dangling-external` confere a ponta, mas só contra o corpus
  local. A recorrência medida está nas afirmações agidas sem conferência que eram selo ou ref (IN#14, #41, #43 e #44).
  Em dois desses casos, um selo foi registrado antes de existir.

**Não sobrevivem como peça agora:**
- **Nó de delegação (P1).** A falha medida foi 0: nenhuma mensagem de par virou aprovação. E o check "selado pelo
  maestro" não distingue o maestro de uma sessão, porque todo commit sai como "Marcio Carvalho". Mecanizar abriria um
  caminho de aprovação forjada. Isso fica para quando houver âncora de identidade.
- **Registro da mensagem que gerou efeito (P4).** Ele não cobre a falha que alegava cobrir. E nenhum comando ou hook
  vê o SendMessage do harness, então o custo não foi medido.
- **Aviso de PR paralelo (P3).** Já está em construção no core, apoiado em testemunho de fora da auditoria.

**Fica como doutrina:**
- pedir o estado do par só depois do plano commitado;
- emenda só de fixação quando a ref aceita muda;
- mensagem de par é informação, como o harness já impõe;
- avisar o par ao fechar;
- correção ao par vai com a medida.

## Evidência

**N2:** auditoria retrospectiva de 53 mensagens recebidas e 61 enviadas, codificada por um agente separado pelo
codebook pré-registrado (`n2-coded.json`).
- **Afirmações checáveis:** 97 ao todo; 54 conferidas, 4 delas divergentes. Mais 5 correções enviadas com medida.
- **Erros distintos:** 6. A conferência pegou 4: a base das paráfrases, de gravidade alta; 28 contra 30 membros; o
  trust do onion-codex; e a medição sem o contrato. Os outros 2 foram pegos pelo par ou pelo checador.
- **Permissão emprestada:** 0.
- **Agidas sem conferência:** 22, entre elas selos citados antes de existirem.
- **Ninguém notou:** o 81/81 informado contra o 79 medido.

**Superação parcial:** o MCP Agent Mail guarda cada mensagem entre agentes num repo git. Ele não foi lido nem rodado.

**Limites:**
- Não há braço de controle: o controle é contrafactual.
- A sessão auditou o próprio transcript, com um codificador só.
- n = 1 sessão em 3 dias, nos 3 repos do mesmo maestro.

## Para o core
- **A peça:** se acolherem, o desenho é de vocês. O comando de referência é o que a sessão usou à mão
  (`git -C <par> show origin/main:<caminho>` e `git merge-base --is-ancestor <sha> origin/main`), com rc 0, 1 ou 2.
- **O dado defasado:** o "zero uso medido" do SendMessage no CLAUDE.md de vocês está defasado. Hoje ele é o canal
  vivo entre as sessões, conduzido pelo harness.
- **A delegação:** ela mora só em memória. Antes de virar nó, precisa de uma âncora que distinga o maestro de uma
  sessão.

A palavra final é do core. Aqui nada é selado.
