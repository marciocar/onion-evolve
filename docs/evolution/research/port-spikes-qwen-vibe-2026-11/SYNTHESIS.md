---
title: Spikes das portas — o veto de hook no Qwen Code e no Mistral Vibe
date: 2026-11-03
kg: docs/evolution/research/port-spikes-qwen-vibe-2026-11/port-spikes-qwen-vibe-2026-11.kg.yaml
run_id: "nenhum (sem Workflow: executor e células rodados pela sessão do core e por um agente construtor)"
tokens: 1827790
agents: 1
duration_min: 120
review_after: 2026-12-03
type: research
mode: spike
---

# Spikes das portas — o veto de hook no Qwen Code e no Mistral Vibe

**A pergunta** (`Q_PORT_SPIKES_VETO_QWEN_VIBE_1103`): o Qwen Code 0.26.6 e o Mistral Vibe 3.0.4 sustentam a peça que
compra o acoplamento do Onion, o veto determinístico de hook que barra a ação? Ela vale também no caminho de falha e
com sinal de máquina. Decisão de origem: `D_COORD_SPIKES_DAS_PORTAS_NA_VPS_1103`; a pesquisa que leu as docs é
`onion-core-ports-multi-model-2026-11`.

**Como:**
- **Pré-registro:** o `PRE-REGISTRO.md`, na v3, com 5 emendas datadas. Foi revisado em três camadas, desenho, código e
  processo, pela curadoria e pelo kg-ssot, e reprovado cinco vezes antes de fechar.
- **Matriz:** roda contra um **modelo stub**, um servidor local compatível com OpenAI que devolve uma chamada de
  ferramenta fixa, decidida pelo conteúdo do pedido. O **lote do critério é o m2** (121 células com o executor final
  8336f4f97, 3 repetições válidas por família). Ele repetiu a m1 (108 células, executor anterior) família a família;
  a m1 fica como registro, pela regra do medidor (Emendas 1 e 6).
- **Braço real:** Qwen3.5-9B local (Q4, llama-server b12063, temperatura 0, seed 42), em dois lotes (real1 e real2),
  com o controle positivo e o veto do push nos dois clientes. O **agregador** (`aggregate-final.json`, depois da cura do
  A1) pareou as 8 famílias reais com as do stub: `divergences: []` e `unpaired_real: []`.
- **Reprodução:** o executor (`harness/`), com 218 casos de teste e 7 mutantes de código, e a evidência reproduzem o
  agregado a partir do commit pelo `git archive`, com SHA256SUMS por célula.

## O que o dado diz

| Pergunta | Qwen Code 0.26.6 | Mistral Vibe 3.0.4 |
|---|---|---|
| O veto barra o push, a escrita pelo shell e a escrita sem shell? | **BARRA** com `exit 2`, e também com JSON `permissionDecision: deny` | **BARRA** com JSON `decision: deny` e `exit 0` |
| O `exit 2` do Claude Code, portado cru? | barra | **não barra sem `strict`** (libera); com `strict`, barra como falha |
| O matcher `Bash` do core casa com o shell? | **sim** (alias) | **sim** (fnmatch sem diferenciar maiúsculas) |
| E um script que compara o `tool_name` a "Bash"? | **fura** (o nome é `run_shell_command`) | **fura** (o nome é `file_system.bash`) |
| Falha do hook (ausente, exit 1, timeout, não JSON, vazia) | **abre em todas**, e não há opção que feche | sem `strict`: abre em todas; **com `strict`: fecha em 4, abre na saída vazia** |
| Timeout do hook configurado (5 s) | respeitado | respeitado |
| Sinal de máquina do veto | rc 0; o campo `permission_denials[]` | rc 0; `notice hook_completed` mais o efeito `skipped` da chamada e a mensagem «Denied tool» sem «(strict)» (esquema interno, fixado na 3.0.4) |
| Modo de aprovação padrão, não interativo | **não oferece** shell nem escrita ao modelo | o hook roda **antes** da aprovação |

## O critério da porta (`C_PORT_SPIKE_CRITERIO_DA_PORTA_1103`)

- **Caminho feliz:** os dois clientes sustentam o veto que barra.
- **Caminho de falha:** só o Vibe com `strict` fecha, e nem ele fecha a saída vazia com `exit 0`, que é o modo mais
  provável de um hook real falhar em silêncio. O Qwen não fecha em nenhuma falha.
- **O que o gerador precisaria fazer:**
  - traduzir o contrato: `exit 2` para o Qwen, JSON `deny` com `strict` para o Vibe;
  - filtrar pelo matcher, nunca pelo nome no script;
  - ler o sinal no campo JSON, não no rc.
- **O que nenhum gerador dá:** o fechar na falha do Qwen. A única saída seria o próprio guard do core nunca falhar
  calado (converter toda falha interna em veto explícito), sem contar com o cliente.

Para o gatilho de porta nova da decisão das portas (`D_ONION_CORE_PORTS_MULTI_HARNESS_2026_11`), isso significa que o
Qwen Code segue a porta mais fina no caminho feliz, mas é a mais fraca no caminho de falha. A decisão volta ao maestro
com o dado.

## NÃO-VERIFICADOS (`E_PORT_SPIKE_LACUNAS_1103`)

- Hook sobre ferramenta MCP.
- A camada de permissões dos dois clientes.
- Subagente (S4): ficou **INCONCLUSIVO POR JANELA**. O Qwen delega pela ferramenta `agent`, oferecida via
  `tool_search`, e o Vibe por `agents.spawn` dentro de `run_typescript`. O roteiro em vários passos não foi construído.
- Contorno por ferramentas além das nomeadas: `run_typescript` e `process_start` no Vibe, `tool_call` e `tool_search`
  no Qwen. **Achado da porta:** o matcher `Bash` do core, portado ao Vibe como `match = "bash"`, não pega o
  `process_start` (processo em segundo plano).
- No S1-tn-matcher do Vibe, o efeito se liga à chamada pela ordem da sessão (ressalva da Emenda 6).
- Isolamento de rede: o `unshare` sem root falha na VPS; o stub escuta só em loopback.
- As células além do controle e do veto do push foram extrapoladas do stub, não confirmadas com modelo real.
- O modo de aprovação padrão fica fora do critério: no Qwen ele não oferece ferramenta de ação; no Vibe o controle dá
  recusa por aprovação, e o veto fica INCONCLUSIVO por falta de controle pareado com FURA.

## Medidas de outras sessões, citadas

A receita do modelo local é do kg-ssot (`docs/onion/measurements/mcp-ports-2026-11-03/RECIPE.md`@872c42f5 no
repo dele). Os tempos do braço real desta rodada (6 a 19 min por célula) são medidas próprias, gravadas na
evidência dos lotes reais (`harness/evidence-archive/evidence-real1.tar.gz` e `evidence-real2.tar.gz`, células `RS*`). O braço real do Qwen usou a configuração de tempo da RECIPE (`streamIdleTimeoutMs: 0`), e é a 1ª
medida do 9B com ela. Nas quatro células do Qwen, duas do real1 e duas do real2, nenhuma teve ETIMEDOUT nem
nova tentativa. A leitura do prompt do turno principal levou de 650 s a 702 s (15,7 mil tokens, 22 a 24 tok/s), e
o maior tempo total de um pedido foi 731,7 s, com 16 a 19 minutos de processo. Isso mostra que o corte de ~900 s da
RECIPE, onde a conexão do Gemma e do Ministral caiu, **não conta do início do processo**. Mas **não separa** «o corte
conta até o 1º byte» de «o corte conta a duração total da conexão», porque nenhum pedido passou de 900 s. O teste
que separa as duas é um pedido com o 1º byte antes de 900 s e o fim depois, com uma geração longa. (Correção de
2026-11-03, apontada pela revisão do kg-ssot e conferida nos logs: a 1ª redação citava só o real1 e afirmava a
hipótese do 1º byte.) Os logs do servidor (`_llama-server-real*.log`) estão dentro desses mesmos arquivos.

## Valeu a pena

1,8 milhão de tokens do agente construtor, mais as revisões das duas sessões, por 14 nós e um executor reproduzível.
O stub transformou uma matriz que não cabia em 9 horas de CPU em minutos. As revisões acharam, antes do dado, três
defeitos que dariam BARRA falso:
- o modo padrão recusando antes do hook;
- o push que não discriminava;
- a evidência ausente virando veredito.
