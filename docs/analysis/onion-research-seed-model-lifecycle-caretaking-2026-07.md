# Semente de pesquisa — como tomar conta de um modelo pronto (model ops) × o Onion

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Território **novo**: a exploração desta rodada não
> achou nenhuma doutrina prévia sobre o tema no Onion.

## Por que esta pesquisa

O maestro pergunta: uma vez que se tem um modelo pronto (treinado, fine-tunado, ou adotado de
terceiro), como cuidar dele — monitorar, atualizar, saber quando está degradando?

**Nada disso existe hoje na doutrina do Onion.** A busca não achou menção a drift de modelo,
retraining, versionamento de pesos, avaliação contínua de qualidade de um modelo específico, ou
qualquer "ciclo de vida de modelo" análogo ao que já existe para *contexto* de domínio
(`domain-context-lifecycle.md`, doutrina CRUD+ com Remover/Validar como operações de primeira
classe) ou para *documentação* (`/meta:context-freshness`, veredito `CURRENT/STALE/HISTORICAL`).

O vizinho mais próximo é uma abstração **planejada, não construída**: `llm-provider` no roadmap do
SDAAL (`docs/sdaal/sdaal.md` §10.4 — `Anthropic, OpenAI, Google, local, none | 📝 Roadmap`). Mas
essa abstração trata o modelo como **provider intercambiável** (trocar de fornecedor), não como
algo que precisa de manutenção contínua enquanto está em uso — são problemas diferentes: "qual
modelo usar" vs. "como saber se o modelo que já escolhi ainda está bom". A mesma abstração já foi
marcada como "caso a repensar" por bootstrapping estranho
(`onion-repositioning-sdaal-session-2026-06-17.md`), o que sugere que qualquer resposta aqui
precisa ser mais concreta que "adicionar mais um provider ao roadmap".

## Questões de pesquisa

**Q1 — "Modelo pronto" no contexto do Onion significa o quê, concretamente?** Hoje o único
"modelo pronto" com que o Onion interage de fato é Claude (via Claude Code) — cuidado por
Anthropic, fora do escopo de quem opera o Onion. O único ponto onde "cuidar de um modelo" seria
responsabilidade nossa é o adapter `local-slm` do de-identification (gated, aguardando 1º
adotante regulado com runtime) — a pesquisa deveria partir daí: o que esse adapter especificamente
vai precisar em termos de manutenção quando for ativado?

**Q2 — Doutrina emprestável de domínios adjacentes.** O Onion já tem um framework de "ciclo de
vida" bem desenvolvido para *contexto* (CRUD+, veredito de frescor, curadoria periódica). Essas
mesmas formas (não o conteúdo) se transferem pra "cuidar de modelo"? Ex.: existe um "veredito de
frescor" análogo pra um modelo (RECENTE/DEGRADADO/OBSOLETO)? Quem faria essa avaliação — um script
determinístico (como o lint de inventário) ou julgamento humano?

**Q3 — MLOps já resolveu isso — o que é genuinamente aplicável aqui, e o que é overhead
desproporcional?** Existe uma indústria inteira de MLOps (monitoramento de drift, re-treino
agendado, canary deployment de modelo). A pergunta honesta: o Onion — um framework de
orquestração de agentes, não uma empresa que treina modelos — precisa de alguma fração disso, ou
essa pergunta só faz sentido no dia em que o Onion de fato tiver um modelo próprio (dependente da
semente `onion-as-model`)?

## Método previsto

Pesquisa (não necessariamente deep-research multi-fonte pesada — pode ser mais direcionada):
levantar práticas de MLOps para monitoramento/manutenção de modelos pequenos/especializados em
produção, e cruzar com o adapter `local-slm` real (gated) para ver o que dele já cobre isso e o
que falta. Achado útil vira nota de doutrina em `onion-engine-economy.md` (que já trata de SLM
como ferramenta) — sem propor nova abstração antes de o adapter real existir em produção.

## Gatilho

O maestro pede ("roda a pesquisa de cuidar de modelo pronto") → executar a partir DESTA semente.
Depende, em parte, de o adapter `local-slm` sair do estado gated (1º adotante regulado com
runtime) para ter chão concreto. Registro na memória da sessão:
`sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
