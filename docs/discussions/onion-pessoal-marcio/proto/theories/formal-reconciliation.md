# A máquina formal de revisão de crenças e argumentação

> Camada 1 (fiel à fonte, zero derivação). Sandbox de discussão — não é a KB do core.

Como um corpo de crenças muda diante de informação nova ou contraditória? Décadas de trabalho em revisão de crenças, manutenção de verdade, proveniência e argumentação formal entregam a maquinaria — separada em peças maduras.

## Revisão de crenças: AGM e belief bases

AGM (Alchourrón, Gärdenfors & Makinson, 1985) fixa o **contrato**: três operações — expansão, revisão, contração — e postulados de racionalidade (sucesso, consistência, **mudança mínima**). *Caveat:* AGM **não** é agnóstico quanto à representação — é comprometido com belief **SETS** logicamente fechados. A representação alternativa é o **belief base** (Hansson): um conjunto sintático **não-fechado**, finito e explícito. A **kernel contraction** de Hansson remove α tirando ao menos um elemento de cada **α-kernel** (subconjunto **mínimo** da base que implica α). AGM diz *o que* uma boa revisão satisfaz, não *como* revisar.

## Quem sobrevive: entrincheiramento epistêmico

Gärdenfors & Makinson (1988): ao contrair, abandona-se a crença **menos entrincheirada**; um teorema de representação estabelece que um operador satisfaz os postulados AGM **sse** existe uma ordem de entrincheiramento. *Caveat:* o entrincheiramento é **uma de várias** construções AGM-equivalentes (partial meet, esferas de Grove, safe contraction) — um nome canônico, não o único mecanismo.

## Crença graduada e revisão iterada

Darwiche & Pearl (1997) abandonam belief sets por **estados epistêmicos** que carregam a ordem de plausibilidade adiante, permitindo revisão **iterada**. As *ranking functions* / OCF de Spohn dão crenças **graduadas** (graus inteiros de descrença), não binárias. A iteração sobre ranking functions respeitando os postulados DP é **Turing-completa** (resultado publicado, *Iterated Belief Change, Computationally*, KR 2022, arXiv:2202.08856).

## O rastro de justificação: TMS, ATMS e proveniência

TMS (Doyle, 1979): cada crença carrega **justificativas** (support-lists) apontando às crenças que a sustentam; o status IN/OUT propaga; a rede de justificação é o registro de *por que* se acredita em algo. *Caveat:* o dependency-directed backtracking é disparado por detecção de **contradição** (nogood), não por retração comum de premissa. ATMS (de Kleer, 1986): rotula cada crença com os **ambientes** (conjuntos de assumptions) sob os quais vale, computa combinações em paralelo, e mantém **nogoods** (conjuntos inconsistentes mínimos) para nunca reprocessar contextos já provados contraditórios — o que permite manter múltiplos contextos coexistindo sem escolher. Proveniência: o W3C PROV (Entity/Activity/Agent) dá vocabulário; o framework de **semiring** (Green, Karvounarakis & Tannen, 2007) anota cada tupla com um polinômio onde multiplicação = uso conjunto (AND) e soma = uso alternativo (OR).

## Argumentação: aceitabilidade, estrutura e bipolaridade

Dung (1995): um grafo de argumentos + relação de **ataque**; a extensão **grounded** é cética, **única, mínima e determinística** (mesmo grafo → mesmo veredito), a **preferred** é crédula/maximal. ASPIC+ (Modgil & Prakken, 2014) dá **estrutura**: regras *strict* vs. *defeasible*, e três modos de ataque — **undermining** (nega a premissa), **rebutting** (nega a conclusão) e **undercutting** (nega a aplicabilidade da regra). **Caveat importante:** o **undercutting é preference-independent** e **sempre** sucede como *defeat*; as preferências (ordem de superioridade) só convertem em derrota os ataques do tipo **rebutting** e **undermining** — não o undercut, que derrota incondicionalmente. A argumentação **bipolar** (Cayrol & Lagasquerie-Schiex, 2005) estende Dung com uma segunda relação — **suporte** — disjunta e oposta ao ataque; um BAF é a tripla (Argumentos, Ataque, Suporte).

## Argumentação bipolar quantitativa (QBAF)

QBAF com semântica gradual **agregativa** (Potyka & Booth, 2024; Munro et al., 2026): cada argumento tem peso-base em [0,1] e a aceitabilidade é computada em três passos (agrega atacantes, agrega apoiadores, combina) num **grau contínuo** Deg(a), em vez de aceito/rejeitado. *Caveat:* as semânticas graduais ainda **divergem entre si** (resultados contra-intuitivos; convergência só provada recentemente para certos casos cíclicos) — **não há uma canônica**.

## Tolerância a contradição: paraconsistência

A Lógica do Paradoxo (Priest, 1979) rejeita o *ex falso quodlibet*: uma contradição **não trivializa** o sistema. As LFIs (Logics of Formal Inconsistency) internalizam um **operador de consistência**, marcando quais fórmulas são consistentes/contestadas (Carnielli et al., 2020). Revisão de crenças **paraconsistente** casada com entrincheiramento já existe (2024, arXiv:2412.06117) — não é território virgem.

## O achado empírico: humanos revisam de forma inconsistente

A maquinaria acima é **normativa**. Empiricamente, humanos revisam crenças inconsistentes de maneira que **não** segue os postulados de racionalidade (*How Do People Revise Inconsistent Beliefs?*, arXiv:2506.09977, 2025) — uma lacuna entre o agente logicamente ideal e o sujeito real.

## Referências

- Alchourrón, C., Gärdenfors, P. & Makinson, D. (1985). *On the Logic of Theory Change.* Journal of Symbolic Logic.
- Hansson, S. O. (1993-1999). *Theory Contraction and Base Contraction Unified* (Kernel Contraction). JSL.
- Gärdenfors, P. & Makinson, D. (1988). *Revisions of Knowledge Systems Using Epistemic Entrenchment.*
- Darwiche, A. & Pearl, J. (1997). *On the Logic of Iterated Belief Revision.* Artificial Intelligence.
- *Iterated Belief Change, Computationally* (KR 2022). https://arxiv.org/pdf/2202.08856
- Doyle, J. (1979). *A Truth Maintenance System.* Artificial Intelligence.
- de Kleer, J. (1986). *An Assumption-based TMS.* Artificial Intelligence.
- Green, T., Karvounarakis, G. & Tannen, V. (2007). *Provenance Semirings.* https://dl.acm.org/doi/10.1145/3034786.3056125
- Dung, P. M. (1995). *On the Acceptability of Arguments...* Artificial Intelligence.
- Modgil, S. & Prakken, H. (2014). *The ASPIC+ framework for structured argumentation.* Argument & Computation.
- Cayrol, C. & Lagasquerie-Schiex, M.-C. (2005). *On the Acceptability of Arguments in Bipolar Argumentation Frameworks.*
- Potyka, N. & Booth, R. (2024). *An Empirical Study of QBAFs for Truth Discovery.* https://orca.cardiff.ac.uk/id/eprint/170179/
- Munro et al. (2026). *Aggregative Semantics for QBAFs.* https://arxiv.org/html/2603.06067v1
- Priest, G. (1979). *The Logic of Paradox.* Journal of Philosophical Logic.
- Carnielli, W. et al. (2020). *Paraconsistent Logics for Knowledge Representation (LFIs).* https://philarchive.org/archive/CARPLF-3
- *Paraconsistent Belief Revision...* (2024). https://arxiv.org/pdf/2412.06117
- *How Do People Revise Inconsistent Beliefs?* (2025). arXiv:2506.09977.
