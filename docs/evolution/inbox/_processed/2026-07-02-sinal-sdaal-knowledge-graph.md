---
type: co-evolution-signal
direction: upstream   # sinal → core
from: instância rhilo-metagamify (dogfood ao vivo)
to: Onion core / Mestre
date: 2026-07-02
subject: Padrão novo — Knowledge Graph SDAAL + governança DEV↔PROD + anti-whack-a-mole
status: proposta-para-avaliação
maturity: dogfoodado numa auditoria real de produção (WRR/Modo Equilíbrio)
---

# Sinal ao Mestre — um padrão nasceu no uso; proponho para o core

> Canal upstream (sinal→core). Escrito por uma instância adotada do Onion, durante uma auditoria real de
> produção. Não é sobre o WRR (isso é a evidência) — é sobre **três peças de método** que resolveram um
> problema recorrente e que acho que pertencem ao **core do Onion**.

## O problema que doeu (e deve doer em qualquer instância)

Numa investigação longa, a "fonte da verdade" (docs) **degrada para um log cronológico**: cada achado é
datado, e as **correções ficam enterradas em prosa**. Consequências observadas ao vivo:

1. **Não dá para confrontar verdade×verdade.** Tive ~6 auto-correções ("X era verdade → refutado"); todas
   ficaram espalhadas, nenhuma reconciliada. O log não sabe que se contradiz.
2. **Confusão DEV↔PROD.** Como agora sou **um agente só** (em vez de vários terminais separados),
   misturei "o código que li" com "o que roda em produção" — conclui coisas falsas lendo a branch de
   trabalho em vez do commit deployado + flags vivas + env. (Ex.: afirmei "feature não deployada" lendo
   uma branch **inexistente**.)
3. **Whack-a-mole.** Variáveis compartilhadas/sobrecarregadas (uma métrica alimenta dois gates com
   semânticas diferentes) → consertar um quebra outro, sem aviso.

## O que proponho promover ao core (3 peças)

### 1. Knowledge Graph SDAAL — a fonte da verdade como grafo ponderado
Em vez de log, um `.kg.yaml`: **nós tipados** (`claim/decision/question/entity/evidence/artifact`) +
**arestas tipadas com peso** (`SUPPORTS/REFUTES/SUPERSEDES/CAUSES/DEPENDS_ON/TRACES_TO`) + **plane**
(`DEV`/`PROD`). No espírito [SDAAL](../../knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)
(markdown/YAML executável por IA). As auto-correções viram **arestas `REFUTES` explícitas** — a história
não se apaga, se reconcilia. Uma ferramenta (`scripts/kg/radar.js`) computa **atenção = impacto × confiança
× centralidade (PageRank)**, lista as verdades confrontadas e **checa integridade** (rejeita nó `done` não
verificado no plane PROD, acha órfãos/contradições/ciclos). **Reusa peças que a instância já tinha**
(grafo `ElementLink`, embeddings, clustering, pgvector) — quase nenhum código novo.

### 2. Governança DEV↔PROD (regra dura)
> Comportamento em produção = **commit deployado + flags do banco vivo + env + config + dados**.
> Uma `decision` só é `done` quando **verificada no plane PROD** — não quando "o código deveria".

A checagem de integridade do grafo **reprova** decisões `done` fora do plane PROD. Isso teria evitado
todos os meus erros de DEV↔PROD nesta sessão.

### 3. Anti-whack-a-mole (disciplina)
- **SSOT-por-conceito**: uma variável = um significado (nomear distinto quando fluxos divergem).
- **Grafo de blast-radius**: modelar variável→consumidores → prever o rebote **antes** de mexer.
- **Replay/golden-test**: snapshot→muda→replay+diff pega regressão em outro fluxo automaticamente.
- **Invariantes como asserts testados** (não só comentários).

## Evidência (dogfood real)

Aplicado à auditoria WRR (`docs/rhilo/graph/wrr-audit.kg.yaml`): o radar priorizou corretamente a **cura de
raiz** (reduzir SLOT-limbo + fail-soft local) acima dos **paliativos** (que o grafo marcou `superseded`); a
reconciliação reencontrou as 6 auto-correções como `REFUTES`; a integridade **pegou 3 nós órfãos** que eu
tinha esquecido de ligar. O método se auto-corrigiu.

## Artefatos (para avaliar/portar ao core)

- `docs/knowledge-base/concepts/knowledge-graph-sdaal.md` — a spec do método.
- `scripts/kg/radar.js` — a ferramenta (atenção + reconciliação + integridade).
- `docs/rhilo/graph/wrr-audit.kg.yaml` — a primeira instância (exemplo).

## Pedido

Avaliar promover o **Knowledge Graph SDAAL** + a **governança DEV↔PROD** ao core do Onion (como
`docs/knowledge-base/concepts/` + um comando `/meta:kg` análogo ao `/meta:co-evolve`). Se aprovado, generalizar
o `scripts/kg/` para além do caso WRR e ligar a reconciliação por embedding (MiniLM já disponível).

*Rode `/meta:co-evolve` para gerenciar este sinal.*
