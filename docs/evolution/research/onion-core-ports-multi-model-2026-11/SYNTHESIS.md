---
title: Portas do onion-core para outros harnesses e modelos
date: 2026-11-03
kg: docs/evolution/research/onion-core-ports-multi-model-2026-11/onion-core-ports-multi-model-2026-11.kg.yaml
run_id: wf_407cda39-1fb
tokens: 7696206
agents: 106
duration_min: 27.9
review_after: 2026-12-02
type: research
mode: decision
---

# Portas do onion-core para outros harnesses e modelos

**A pergunta** (`Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11`), do `/meta:decide` de 2026-11-02: como fazer portas do
onion-core para outros harnesses e modelos (o onion-codex já vivo; candidatas onion-mistral, onion-gemma e
onion-qwen), com o onion-core, o Claude Code e o Claude como base e uma camada de aderência e transformação.

Esta síntese é projeção do grafo. A decisão `D_ONION_CORE_PORTS_MULTI_HARNESS_2026_11` segue **aberta**: quem sela
é o maestro.

## O que a pesquisa achou

- **A transformação é um gerador por porta, não uma ponte em runtime.** O molde é o `ops/materialize-door.sh`, que
  já projeta as portas do core. Os dois transpiladores de mercado, rulesync e Ruler, também são geradores.
- **A porta se recorta por harness, não por modelo.** Mistral, Gemma e Qwen são perfis de modelo dentro de um
  harness (Mistral Vibe, Qwen Code, Gemini CLI). «onion-gemma» é erro de categoria, porque o Gemma não tem harness
  próprio; «onion-mistral» quer dizer uma porta para o Vibe.
- **O veto tem contratos diferentes.** O Qwen Code e o Gemini CLI barram por `exit 2`, como o Claude Code. O Vibe
  barra por JSON `decision: deny` com `exit 0`, e o gerador precisa traduzir. No caminho de falha os contratos se
  separam: só o Claude Code (`onFailure: block`) e o Vibe (`strict=true`) documentam fechar na falha; o Gemini e o
  Qwen tratam outros códigos como aviso e seguem.
- **A porta mais fina é a do Qwen Code**, mas ela só sai com um gatilho de demanda real: um adotante que precise de
  modelo aberto ou local, por soberania, custo ou regulação. Sem gatilho, nenhuma porta nova (nada de elefante
  branco).
- **O piso que toda porta herda sem tradução é o gate de shell no CI**, que já é agnóstico.

## Mercado

Não há sinal de rodadas, aquisições ou analistas sobre portas multi-harness. A AAIF consolida os padrões portáveis
(MCP, AGENTS.md, Agent Skills, A2A e goose), numa fonte fraca (tier 3). Os laboratórios de modelo aberto mantêm
harness próprio e aberto (Mistral com o Vibe, Qwen com o Qwen Code, Google com o Gemini CLI). A portabilidade no
mercado é de ferramentas comunitárias de geração, não de produto financiado.

## Medição posterior, citada (não copiada)

A sessão do kg-ssot mediu o MCP de referência do kg-ssot, só leitura e sem chave de API, em três harnesses com
modelos abertos na CPU: nó `E_MCP_PORTS_LOCAL_MODELS_MEASURED_1103`, em
`docs/onion/measurements/mcp-ports-2026-11-03/RESULTS.md` do repo `marciocar/onion-kg-ssot` (main `b23b68d7`). O
resumo que ela enviou:
- o Mistral Vibe chamou a consulta ao grafo e respondeu dele com os três modelos;
- o Qwen Code acertou com dois modelos e pediu dois ajustes;
- o Gemini CLI conectou o servidor, mas só fala a API do Gemini.

Isso não foi re-medido pelo core. Confirma, para o MCP, o recorte por harness e a porta do Qwen Code como a mais
fina; não diz nada sobre o veto.

## A decisão aberta

As opções do nó `D_ONION_CORE_PORTS_MULTI_HARNESS_2026_11`: **A** gerador por harness · **B** ponte em runtime ·
**C** só o piso agnóstico de CI · **D** nenhuma porta nova até demanda medida. A recomendação do Elenxo (um agente,
sem votação): **D agora, com A como forma quando o gatilho disparar; C sempre como piso; B rejeitada**. Restrições
que sobreviveram (arestas `CONSTRAINS` no grafo): a paridade do veto se mede no caminho de falha; o veto tem de
aparecer como sinal de máquina no modo headless; a camada de permissões também se traduz; as skills viajam no
formato Agent Skills.

## Perguntas abertas

- Qual adotante real pede hoje modelo aberto ou local? É o gatilho da primeira porta nova.
- As portas se chamam pelo harness (onion-qwen-code, onion-gemini-cli, onion-vibe), com o modelo como perfil?
- No Qwen Code, no Gemini CLI e no Vibe, subagentes, MCP, sandbox e modo não interativo sustentam o ciclo de
  engenharia do Onion? Faltam spikes como os do Codex.
- Os modelos abertos seguem skills e o contrato de subagente com qualidade suficiente?
- O gerador entra no `ops/materialize-door.sh` e no `/meta:publish` como mais uma porta, ou como motor irmão?
- O onion-codex migra para o mesmo gerador ou segue mantido à mão?
- Vale adotar rulesync ou Ruler para as instruções e deixar no gerador próprio só a tradução dos hooks?

## NÃO-VERIFICADOS

- **Refutadas na votação (8):** entre elas, que o Vibe carrega skills e AGENTS.md sem transformação; que os hooks do
  Qwen Code aceitam a config do Claude Code sem mudança; e que um guard que converta todo erro em `exit 2` é
  portável entre quatro harnesses. Todas com voto 0 a 3.
- **Sem verificação por orçamento:** 37 claims; **cortadas no orçamento:** 38 fontes. A lista está no diário do run
  `wf_407cda39-1fb`.
- O mercado e o capital ficaram sem sinal; a única fonte institucional é tier 3.

## Valeu a pena

7,7 milhões de tokens para 65 nós, ou cerca de 118 mil por nó. A pesquisa derrubou a premissa «uma porta por
modelo» e deu a forma (gerador por harness) e o gatilho (demanda medida) antes de qualquer construção.
