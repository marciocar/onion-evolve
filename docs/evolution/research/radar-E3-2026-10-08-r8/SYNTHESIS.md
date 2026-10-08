---
title: "Radar E3 · rodada 8 — seis versões, e o harness passou a oferecer o fail-closed que os vetos do Onion ainda não usam"
date: 2026-10-08
axis: E3-claude-code-delta
baseline_anterior: 2026-10-05 (2.1.289)
baseline_desta_rodada: 2026-10-08 (2.1.295)
kg: docs/evolution/research/radar-E3-2026-10-08-r8/radar-E3-2026-10-08-r8.kg.yaml
run_id: "sem run_id de Workflow — rodada conduzida na sessão principal com 1 juiz subagente (opus, high). Declarar a ausência é o contrato."
tokens: 158870   # medidos, do juiz; o custo da sessão principal não é atribuível por run
agents: 1
duration_min: 25
---

# O que esta rodada mediu

São **seis versões contíguas**, de `2.1.290` a `2.1.295`, contra a baseline r7 (`2.1.289`). Os blocos
estão em `data/2.1.29x.txt`, e o juiz os conferiu byte a byte contra o `CHANGELOG.md` oficial.

## O que toca a casa (projeção do grafo, depois do juiz)

- **`onFailure: "block"` para hooks** (2.1.295), e **nenhum dos 20 hooks do Onion o usa**. Nos
  PreToolUse, um hook que não inicia, estoura o timeout ou sai com código fora de 0 e 2 deixa a ação
  passar; isso é documentado. É o modo de falha que o exit 2 não cobre por construção. Proposta aberta:
  `Q_ADOTAR_ONFAILURE_BLOCK_NOS_VETOS`, com medição ao vivo como condição, porque a documentação oficial
  de hooks ainda não menciona o campo.
- **Lentes por caminho carregam também via Bash** (2.1.293). As 5 rules com `paths:` passam a valer
  quando o arquivo é lido por `cat`, `head`, `sed -n` ou `grep`.
- **Mods:** 4 correções em 3 versões na janela de restart do worker, e mais uma falha aberta na 2.1.295.
  A recorrência é **evidência a favor** da tese da r7 (mod tem janelas de falha aberta), não cura.
- **Fail-open de hook julgado por LLM** (2.1.294). Hooks `prompt` e `agent` escritos como instrução
  deixavam passar o que deveriam barrar. É evidência a favor do exit 2 determinístico.
- **Zero silencioso no harness, curado.** O WebFetch cortava acima de 100 mil caracteres sem avisar, e
  Grep e Glob davam "no matches" em caminho ilegível.
- **Forks em worktree:** perdiam escrita e Bash quando a sessão-mãe trocava de worktree (2.1.290) e
  viam o git da mãe (2.1.295). Os dois estão curados.
- **Distribuição do `onion-plugins`:** `install --marketplace`, `validate` pede a linha de instalação no
  README, e `marketplace add` com nome não instalável passa a ser recusado.
- **Sem impacto no core**, medido pelo juiz:
  - reescrita de input por PreToolUse: nenhum hook reescreve input;
  - SessionStart async: os do core são síncronos;
  - Haiku 5.5: a guarda é allowlist sem haiku.

## Cura feita nesta rodada

A REGRA 89 (Rodada de radar selada reconcilia o corpus que superou (Aufhebung), com catraca) exigia
`meta.supersedes_external`/`supersedes_none`. O contrato v3 do `.kg.yaml` acusa essas chaves como
desconhecidas, e o gate do CI reprova grafo novo que traga essa dívida: **toda rodada de radar nova
reprovaria**. A guarda passa a aceitar `x_supersedes_*`, a forma de extensão do contrato. Casos (d2) e
(d3) foram acrescentados, e o mutante sem o prefixo faz os dois reprovarem.

## Juiz

O juiz julgou 12 nós: 5 SUSTENTA, 3 EXAGERA (corrigidos) e 4 REPROVA (corrigidos ou rebaixados para impacto
1). Além disso, achou 12 itens que tocavam o Onion e que a rodada não tinha capturado; os 5 de maior
impacto viraram nós. **O `supersedes` sobre a r7 era indevido** e foi trocado por
`x_supersedes_none`, com a razão.

## NÃO-VERIFICADOS

- `onFailure`: a única fonte é o CHANGELOG, porque a documentação oficial de hooks não tem nenhuma
  ocorrência do campo. Nada foi medido ao vivo.
- Efeito da chave `onFailure` em adotantes pinados abaixo de 2.1.295: não medido.
- Itens do juiz que não viraram nó: permissões com curinga (2.1.290:54, :78, :80, :106), effort em
  fallback e Max só para a sessão, `allowed-tools` perdido em `-p`, correções de SendMessage, e
  `agent.spawn` com agentes de workflow, que toca o Q_AGENT_SPAWN da r7, ainda aberto.

## valeu-a-pena

São 158.870 tokens do juiz para 17 nós, cerca de 9,3 mil por nó (a r7 custou 115 mil para 1 versão). O
juiz pegou 4 reprovações, um `supersedes` indevido e 12 omissões. Sem ele, a rodada teria afirmado uma
ligação falsa com o core em 3 nós e uma Aufhebung que não aconteceu.
