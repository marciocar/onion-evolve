# Distinguir a contradição a resolver da contradição a preservar

> Camada 1 (fiel à fonte, zero derivação). Sandbox de discussão — não é a KB do core.

Dado um par de proposições em conflito: é uma incompatibilidade a resolver, ou uma tensão genuína a preservar? A literatura oferece vários **discriminadores parciais** — nenhum deles um critério geral único — e três achados que explicam por que a classificação automática total é impossível.

## Discriminadores parciais

**1. Sensibilidade à informação.** Um conflito **dissolve** sob informação completa e raciocínio ideal, ou **persiste**? A discussão de dilemas morais distingue o conflito que some quando se conhece todos os fatos daquele que persiste apesar deles (McConnell, 2022, SEP *Moral Dilemmas*). Filtro factual barato, aplicado primeiro.

**2. Teste do resíduo.** Williams (1965; 1981): um dilema genuíno **não é "solúvel sem resíduo"** — mesmo a decisão correta deixa um resto moral (*regret*, a obrigação preterida que continua a reivindicar). No wording verbatim, os conflitos de valor não são "neither systematically avoidable, nor all soluble without remainder". Um conflito que resolve limpo *era apenas aparente*. É um teste **pós-hoc**: só se sabe depois de decidir e observar o resíduo (ou sua ausência).

**3. Restrição hard vs. soft.** Em otimização/CSP, restrições **hard** definem o espaço factível (violação = infeasibilidade = resolver); **soft** são penalidades negociáveis que definem a **fronteira de Pareto** (múltiplas soluções não-dominadas = trade-offs a manter) (Le Digabel & Wild, 2015). Quando restrições hard são conjuntamente insatisfazíveis, o **minimal unsatisfiable core** (MaxSAT core-guided) **localiza exatamente** o subconjunto conflitante (Ansótegui et al., 2013) — localização algorítmica do ponto de falha.

**4. Dissolubilidade por meio multifinal.** Kruglanski et al. (2015): **contrafinalidade** = um meio serve um objetivo e mina outro (trade-off estrutural); **multifinalidade** = um meio serve vários objetivos e **dissolve** conflitos de meta aparentes. Antes de tratar como tensão irredutível, testa-se se existe uma ação que satisfaz ambos os polos.

**5. Limiar por objetivo (satisficing).** Simon (1955): sob racionalidade limitada, decisores **satisfazem** (um *aspiration threshold* por dimensão) em vez de otimizar num score único — o que permite que valores **incomensuráveis coexistam sem colapsar numa escala comum**. Cada dimensão só precisa cruzar seu limiar de "bom o bastante".

## A taxonomia mais operacional — e o único sinal mensurável

Tetlock (2003): trade-offs **rotineiros** (secular×secular) são resolvíveis e percebidos como fáceis; **trágicos** (sacro×sacro) são dilemas genuínos e os mais estressantes; **tabu** (sacro×secular) provocam ultraje moral, e a própria tentativa de comparar já é corruptora — a **"constitutive incommensurability"** (termo de Tetlock). Sinal mensurável: **dificuldade de decisão + carga emocional** discriminam o tipo (Hanselmann & Tanner, 2008). Mas "sacro" é **constitutivo/autorado**: quem marca o que é sacro é o próprio agente, não uma medição.

## Por que a classificação total é impossível

**A incomensurabilidade é autorada, não descoberta.** Chang (2002; 2017) adiciona uma quarta relação — **"on a par"** (nem melhor, nem pior, nem igual) — o domínio das *hard choices*. São difíceis **não** por ignorância nem incomensurabilidade, mas porque o agente exerce agência: **o compromisso cria razões**. *Caveat:* Chang distingue **incomensurabilidade** de **incomparabilidade** e sustenta que itens *on a par* **são comparáveis**.

**As disciplinas discordam do default para o mesmo fenômeno.** Frankfurt (1988) trata a ambivalência volitiva como **"disease of the will"** (frase literal): a saúde é ser *wholehearted*, RESOLVENDO o conflito por identificação. Isto é o oposto exato da defesa da ambivalência (Feldman & Hazlett, 2013, *In Defense of Ambivalence*) e do pluralismo de valor irredutível de Berlin/Williams (Mason, 2023, SEP *Value Pluralism*). Mesmo fenômeno (querer A e não-A), **veredito default oposto**, e nenhuma meta-regra de quando aplicar cada um. A DBT (Linehan, 1993) ilustra o risco simétrico: prescreve *both/and* — sintetizar sempre — onde Frankfurt resolveria sempre.

**Nem toda persistência é saudável.** Higgins (1987): discrepâncias self-actual/ideal produzem dejeção, self-actual/ought produzem agitação, e o padrão **crônico-duplo approach-avoidance** é **disfuncional** — modo-de-falha a detectar, não tensão a celebrar.

## A licença lógica não dá o critério

O dialetheísmo (Priest, Berto & Weber, 2022) dá a **licença formal** — uma contradição verdadeira não faz o sistema explodir — mas **não** um critério geral de *quais* contradições são verdadeiras; os casos paradigmáticos são autorreferência/paradoxo, sem procedimento geral de identificação.

**Estado da questão.** Não há critério geral único na literatura. Os discriminadores existentes são **parciais** e convergentes; os sinais mais confiáveis (resíduo de Williams, assinatura afetiva de Higgins) são **pós-hoc**; e a fronteira do "sacro" é **autorada, não descoberta** (Tetlock, Chang). A classificação permanece **em aberto**.

## Referências

- McConnell, T. (2022). *Moral Dilemmas.* SEP. https://plato.stanford.edu/entries/moral-dilemmas/
- Williams, B. (1965). *Ethical Consistency*; (1981) *Moral Luck.*
- Le Digabel, S. & Wild, S. (2015). *A taxonomy of constraints in simulation-based optimization.* arXiv:1505.07881.
- Ansótegui, C. et al. (2013). *Iterative and core-guided MaxSAT solving: A survey.*
- Kruglanski, A. et al. (2015). *The Architecture of Goal Systems.* https://www.sciencedirect.com/science/article/abs/pii/S2215091915000024
- Simon, H. A. (1955). *A Behavioral Model of Rational Choice.* QJE.
- Tetlock, P. E. (2003). *Thinking the unthinkable: sacred values and taboo cognitions.* Trends in Cognitive Sciences.
- Hanselmann, M. & Tanner, C. (2008). *Taboos and conflicts in decision making.* https://sjdm.org/~baron/journal/bb5/bb5.html
- Chang, R. (2002). *The Possibility of Parity*; (2017) *Hard Choices.*
- Frankfurt, H. (1988). *The Importance of What We Care About* (inc. *Identification and Wholeheartedness*).
- Feldman, S. & Hazlett, A. (2013). *In Defense of Ambivalence.* https://philarchive.org/archive/FELIDO-3v2
- Mason, E. (2023). *Value Pluralism.* SEP. https://plato.stanford.edu/entries/value-pluralism/
- Higgins, E. T. (1987). *Self-Discrepancy: A Theory Relating Self and Affect.*
- Linehan, M. (1993). *Cognitive-Behavioral Treatment of Borderline Personality Disorder* (DBT dialectics).
- Priest, G., Berto, F. & Weber, Z. (2022). *Dialetheism.* SEP. https://plato.stanford.edu/entries/dialetheism/
