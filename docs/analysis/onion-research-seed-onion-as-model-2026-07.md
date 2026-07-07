# Semente de pesquisa — o Onion pode virar um modelo (SLM ou conceito mais moderno)? × identidade do Onion

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Irmã próxima, mesma vizinhança por ângulo diferente:
> [onion-research-seed-srl-plea-2026-07.md](onion-research-seed-srl-plea-2026-07.md) Q5 — "LLM-as-VM
> com família de bytecodes como arquitetura cognitiva" — **ficou ABERTA, não executada**. Linkar,
> não fundir: aquela pergunta olha pela lente de arquitetura cognitiva (ACT-R/SOAR/memória
> externa); esta olha pela lente de identidade/produto ("o Onion se torna um modelo?").

## Por que esta pesquisa

O Onion já tem uma tese-mãe registrada (memória de sessão `sdaal-intelligent-breadcrumbs-vision`,
2026-07-02): **LLM-as-VM, markdown-as-bytecode** — o master-prompt é o programa; qualquer
Transformer de terceiro é a máquina que o interpreta. O onion-mini (ADR
[`onion-adr-mini-distillation-2026-07.md`](onion-adr-mini-distillation-2026-07.md), decisão D2) já
prova essa tese em produção: *"É a tese LLM-as-VM em estado puro: o master-prompt é o bytecode;
qualquer Transformer é a VM"* — rodando hoje em Claude, e desde 2026-07-06 também como Custom GPT
no ChatGPT (`chatgpt_gpt:` em `members.yaml`).

A pergunta do maestro empurra essa tese um passo além: e se, em vez de só ser **interpretado por**
modelos, o Onion virasse **um modelo em si** — um SLM (small language model) treinado/destilado
com a própria doutrina, ou algum conceito mais moderno equivalente?

**O que já existe não responde isso.** Toda "destilação" documentada no Onion — onion-mini
incluído — é destilação de **doutrina em markdown** (reescrita curada de texto por um humano+IA),
nunca destilação de **pesos** de um modelo de machine learning. Não há, em nenhum artefato
encontrado, menção a fine-tuning, LoRA, checkpoint, ou qualquer pipeline de treinamento a partir do
corpus do Onion.

**Ressalva que esta semente precisa enfrentar, não ignorar**: a própria metáfora que a motiva já
foi qualificada, pelo maestro, como frágil se levada a sério tecnicamente —
[`onion-repositioning-sdaal-session-2026-06-17.md`](onion-repositioning-sdaal-session-2026-06-17.md):
*"Usar 'Markdown é o bytecode, o LLM é a VM' como metáfora didática, não como argumento técnico — o
engenheiro sênior do cliente vai perguntar 'cadê os testes?'"*. Qualquer pesquisa aqui precisa
decidir se está testando a metáfora tecnicamente (e então essa ressalva é o primeiro obstáculo a
enfrentar) ou usando-a como ponto de partida de um produto diferente (e então a pergunta muda de
forma).

## Questões de pesquisa

**Q1 — O que "virar um modelo" significaria, concretamente?** Distinguir ao menos 3 sentidos
possíveis antes de pesquisar qualquer um: (a) treinar/fine-tunar um SLM real com o corpus de
doutrina do Onion (pesos novos); (b) formalizar o master-prompt como uma especificação executável
mais rigorosa — "bytecode" levado a sério, com grammar/schema formal, não metáfora; (c) algo entre
os dois — um "modelo" no sentido de arquitetura de execução (como CoRE/AIOS trata "LLM como
interpretador de programas de agente" — achado A2 da pesquisa de breadcrumbs, precedente formal
publicado com confiança ALTA, mas sem ablação estrutura-vs-prosa-livre).

**Q2 — Existe ganho real em treinar pesos, dado que a doutrina já muda rápido?** O Onion evolui
por PRs/ADRs quase diários; um SLM fine-tunado congela conhecimento no momento do treino. A
pesquisa deveria mapear: para que tipo de conhecimento (o que raramente muda vs. o que muda
sempre) faria sentido "virar peso" em vez de continuar como spec interpretada ao vivo?

**Q3 — O que a literatura de arquiteturas cognitivas diz** (mesma pergunta de Q5 do seed-irmão,
aqui sob a lente de produto): ACT-R, SOAR e agentes LLM com memória externa já resolveram
"conhecimento como peso vs. conhecimento como spec lida em runtime" de alguma forma generalizável?
Onde a tese do Onion é original, e onde já é caminho batido?

**Q4 — Onde a analogia quebra.** Anti-tese deliberada: um modelo treinado não tem o mesmo tipo de
auditabilidade/versionamento em PR que um markdown tem (rastreabilidade, `git blame`, revert
granular). "Virar modelo" pode estar trocando exatamente a vantagem que hoje sustenta a doutrina
`fonte≠derivação` e `declarado≠verificado` (tudo é texto revisável) por uma caixa-preta.

## Método previsto

Deep-research harness (fan-out multi-fonte + verificação adversarial, mesmo padrão das pesquisas
já entregues): (1) literatura de arquiteturas cognitivas citada acima; (2) precedentes de
"markdown/spec-as-bytecode" fora do Onion (a pesquisa de breadcrumbs #226 já achou "zero ocorrências
de memória markdown/CLAUDE.md/AGENTS.md" no estado da arte mapeado — checar se isso mudou); (3)
custo real de fine-tuning de SLM vs. custo de manter spec viva. Achados acionáveis viram claims no
Knowledge Graph SDAAL e, se sobreviverem à verificação, candidatos a nota de doutrina em
`onion-engine-economy.md` ou `specification-driven-ai-abstraction-layer.md`.

## Gatilho

O maestro pede ("roda a pesquisa de Onion-como-modelo") → executar a partir DESTA semente.
Registro na memória da sessão: `sementes-modelo-federacao-lente-radar-2026-07` (ponteiro
consolidado — ver também as sementes 2, 8, 9 da mesma rodada).
