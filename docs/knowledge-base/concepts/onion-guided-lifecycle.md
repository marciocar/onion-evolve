# A Condução do Onion — wizard, scaffold e onboarding como projeção de uma fonte

> KB canônica (vendorizada). Como o Onion **conduz** uma pessoa pelos movimentos da família (criar, adotar,
> promover, atualizar, convidar, transferir, desacoplar) sem que os fluxos de ajuda **dessincronizem** dos
> procedimentos reais. A regra de ouro: **as faces de ajuda são PROJEÇÃO de uma fonte única, nunca fluxos
> paralelos.** Fonte: a topologia em `docs/onion/graph/onion-family-topology-2026-07.kg.yaml`. Guardada pela
> **REGRA 41**.

## A tríade (três funções distintas, uma fonte)

Ajudar alguém no Onion tem **três funções que se confundem se não forem nomeadas** — e a distinção é real
(pesquisa de produto/UX, jul/2026):

| Face | Função | Verbo | O que é |
|---|---|---|---|
| **Wizard** | ajuda a **FAZER** | colher intenção (guiado) | um passo **bounded**, ordem importa, correct-by-construction |
| **Scaffold** | **GERA** a estrutura | produzir (determinístico) | o **artefato** — os geradores que já existem (`adopt`, `write-stamp`, helpers de `create-vertical`) |
| **Onboarding** | ajuda a **CONHECER/USAR** | ensinar/ativar | um **sistema contínuo** (Orient→Activate→Reinforce), multi-sessão |

**Encadeiam:** `SSOT → o Wizard colhe → o Scaffold gera → o Onboarding ensina`.

**Wizard ≠ Onboarding** (a pesquisa é enfática): a métrica do onboarding é *"a pessoa alcançou valor
repetível"*, **não** *"completou o wizard"*. O onboarding é ongoing, multi-sessão, educacional; o wizard é um
passo **dentro** da fase Activate. São **duas skills distintas** (`onion-wizard`, `onion-onboarding`); o
scaffold são scripts que ambas/o wizard chamam; a topologia é a fonte que os três leem.

## A regra de ouro — projeção de UM SSOT (o antídoto à dessincronização)

O maior risco não é a UX — é **os fluxos de ajuda driftarem do que os comandos REALMENTE fazem**. A doutrina
do Onion já resolve isso: **fonte≠derivação.** As três faces são **três leituras da MESMA fonte** (a topologia
no KG): o wizard lê as *transições* para conduzir; o onboarding lê os *papéis* para ensinar; o scaffold é o
*procedimento* que cada transição traceia. Ninguém hand-mantém a topologia em três lugares — todos **projetam**
dela. A **REGRA 41** garante que a fonte não pode mentir (toda transição resolve a um procedimento real; os
papéis batem com `roles.yaml`). É o mesmo padrão do registro de REGRAS (gerado, não escrito à mão).

> **Não é SDAAL** (correção honesta): SDAAL é para *providers intercambiáveis* (Jira↔ClickUp). Aqui há UMA
> fonte projetada de três jeitos — isso é **projeção/CQRS**, o núcleo do Onion. O SDAAL só entra no futuro se
> as faces forem entregues em **canais** distintos (o chat do Claude Code hoje; GUI/web amanhã) → um
> adapter-de-canal. Por ora, forçar SDAAL seria a cerimônia que a doutrina condena — a costura fica **gated**.

## A UX (pesquisa jul/2026) — conversacional, progressiva, resumível

O Onion não é GUI — roda **dentro** do Claude Code. O wizard é **conversacional**, não uma tela:

- **Progressive disclosure:** 3 perguntas críticas + "avançado" adiado (não 50 opções de uma vez — a pessoa
  congela). Contextual: só pergunta o que o papel/transição escolhida exige.
- **Conversacional:** via `AskUserQuestion` (perguntas encadeadas, com recomendação e "Outro").
- **Resumível:** exit/re-entry sem perder trabalho — o padrão faseado `STATE.md` que o `/meta:adopt` já tem.
- **Dry-run-first:** mostra o que vai fazer **antes** de tocar em nada (never-clobber). Preview é o gate.
- **Just-in-time / skill:** o mecanismo pesado mora no script; a skill carrega o essencial sob demanda.
- **Onboarding em 3 fases:** **Orient** (o que é possível — a família, o papel deste repo) → **Activate**
  (a 1ª ação de valor — pode conter um wizard) → **Reinforce** (fixa o hábito com feedback).

## Alinhamento com o [Elenxo](onion-elenxo-doctrine.md) (a forma prova a filosofia)

- **O wizard é auto-refutável:** ele **mostra o raciocínio** da recomendação (por que sugere `hub` e não
  `standalone`) e é **corrigível** — a pessoa pega um erro de recomendação. Porosidade: a condução não esconde
  como decidiu.
- **O onboarding admite o que NÃO cobre:** não finge completude; aponta a fronteira ("isto você aprende
  usando / perguntando").
- **Dogfood-de-fronteira:** a condução se valida rodando a transição num **clone fresco**, não no working dir.
- **Nasce no KG:** a topologia é conhecimento vivo, não prosa — evolui pelo radar, guardada contra drift.

## Os papéis e as transições (a fonte, resumida)

Papéis: **source** (T0, a autora) · **hub** (T1, empresa que controla os próprios projetos) · **standalone**
(T3, solo completo) · **consumer** (T2, projeto de um hub) · **distilled** (onion-mini) · **fonte-desacoplada**
(cliente que owna o próprio framework: `role: source` + `decoupled_from`, corta o `--update` do core).
Transições **ativas** (todas com procedimento real): **criar · adotar · promover-hub · atualizar**
(traceiam `/meta:adopt`) · **convidar** (`invite-collaborator.sh`) · **transferir** (`transfer-ownership.sh`) ·
**desacoplar** (`decouple-source.sh`). A fonte completa vive no KG-topologia; as skills derivam dela — quando
uma transição muda de gated a ativa, o wizard/onboarding refletem **sozinhos** (foi assim: a REGRA 41 só
exigiu que os novos `trace` resolvessem, e as skills passaram a oferecê-las sem edição).
