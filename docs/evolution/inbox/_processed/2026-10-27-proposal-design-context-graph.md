---
title: "Primeiro tijolo da 4ª dimensão (design): ondas contra os 6 critérios do gatilho do core (recomendada: opção 1, fio fino)"
date: "2026-10-27"
from: onion-curation
merged_at: "main 668e13b (PR #140, emenda da onda 1 com o grafo do design-context)"
to: onion-evolve
type: research-proposal
kg: docs/evolution/research/design-setup-2026-10/design-setup-2026-10.kg.yaml
decision_node: D_DESIGN_SETUP_PROPOSAL
trigger: "onion-evolve: Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027 (main do core @ e88591e3, PR #1403)"
---

# Sinal: o ciclo de design como primeiro tijolo da 4ª dimensão

> **Quem decide:** o core, que leva ao maestro.
>
> **Direção:** o maestro decidiu que o design será a 4ª dimensão do Onion, e a doutrina muda quando o gatilho medido
> disparar. O selo está na main do core desde o PR #1403. O peer-ref-check deu EXISTE nos três nós em
> `e88591e3e5041bed4cd375cc26be84e4c9d2ebfd`:
> - `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml#D_DESIGN_QUARTA_DIMENSAO_DIRECAO_1027`, a decisão;
> - `#Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027`, o gatilho;
> - `#Q_DESIGN_CONTEXT_PRIMEIRA_CLASSE_1027`, a construção.
>
> O maestro escolheu a **opção 1**, com uma observação: o design também deve ter **grafo**, "possivelmente independente
> mas ligado" aos outros contextos. A emenda F (`PLAN-F.md`) trata disso e já está abaixo.
>
> **Gatilho:** é o do core, por referência: `Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027`. São 6 critérios, cada
> um medido por um comando, e todos fecham juntos na mesma medição. O estudo não tem gatilho próprio: o
> `Q_DESIGN_DIMENSION_TRIGGER` foi retirado (`E_OBJECAO_OWN_TRIGGER_BROKEN`).
>
> **Revisão adversarial:** este sinal já incorpora a do PR #138. As 6 objeções que sobreviveram estão no grafo como nós
> `E_OBJECAO_*`.

## Os 6 critérios do gatilho do core e onde cada onda os cumpre

| critério do core | o que exige | onda |
|---|---|---|
| (1) entrada | `.claude/commands/design/setup.md` existe e parte do `docs/design-context/brief.md` **que já existe** (não o gera) | 1 |
| (2) skill resolvedora | `.claude/skills/onion-design-context/SKILL.md` | 1 |
| (3) frescor | `docs/design-context` no `context-freshness.md` **e** no `context-freshness-metric.sh` | 1 |
| (4) ligações por lint | a guarda nova no `lint-artifacts.sh` e no `lint-selftest.sh`, com o mutante (sem a ligação) saindo rc 1 | 1 |
| (5) saída completa | a partir do setup, num projeto real: `test -d …/foundations`, o lint de tokens em rc 0, mais o deck **e** os componentes gerados por `/design:deck` e `/design:identity` | 2 |
| (6) dois adotantes | dois repositórios do members.yaml passando no (5) | 2 |

## As opções

### Opção 1 — Fio fino em três ondas (RECOMENDADA)

**Onda 1: a entrada (critérios 1 a 4)**
- `/design:setup` no molde do `onion-wizard`:
  - **parte do `brief.md` que existe.** Se não houver brief, cria o stub mínimo da skill, com confirmação;
  - três perguntas críticas: a cor ou marca principal; o público e o tom, lidos do business-context; e o alvo de tema,
    detectado do repositório;
  - dry-run antes de gravar, nunca sobrescreve, e reexecutar não duplica;
  - termina no gate de tokens.
- Skill `onion-design-context`, no molde das outras três, com `design` no `resolve-context-dir.sh`.
- `docs/design-context` no `/meta:context-freshness` e na métrica `context-freshness-metric.sh`.
- **O grafo do design-context (emenda F): o PRIMEIRO contexto com grafo próprio.** Hoje nenhum contexto tem grafo
  (0 `.kg.yaml` em `docs/*-context`), e isso vale também para o kg-ssot. O setup cria
  `docs/design-context/design-context.kg.yaml`:
  - **o grafo e o `.md`:** o `brief.md` continua **escrito à mão**, com frontmatter `projection_of:` (que aponta o
    `design-context.kg.yaml`) e `review_after`, e cita os ids dos nós entre crases. **Gerar o `.md` a partir do grafo
    não está na onda 1.**
  - **o precedente do kg-ssot é disciplina, não mecanismo** (`E_KGSSOT_PRECEDENT_IS_DISCIPLINE`, informado e medido
    por ele). Os 4 contextos dele não têm `.kg.yaml` próprio: cada `.md` é escrito à mão com `projection_of` e
    `review_after`, sem ferramenta nem gate. A deriva que ele mediu: 11 de 98 ids citados não resolvem no
    technical-context, e 2 de 6 no design-context. A emenda F dizia "o mesmo molde do kg-ssot", e isso fica corrigido
    aqui (o `PLAN-F.md` é pré-registro com sha256 e não muda).
  - **dependência da onda 1, cujo dono é o kg-ssot** (`Q_PROJECTION_CHECK_DEPENDENCY`): o checador de projeção
    (`kg_projection_check`, ou um modo do `kg_trace`). Ele lê o `projection_of`, confere que todo id citado existe nos
    grafos listados e reprova a deriva. Ainda não existe, e o piloto do design seria o 1º caso dele. A migração tem três
    degraus:
    - (a) `projection_of` e `review_after` no `.md`;
    - (b) um grafo próprio, com `trace` para as seções do `.md`;
    - (c) só depois, e de forma opcional, gerar o `.md` a partir do grafo.

    A decisão é do maestro e do core;
  - **nós:** pelas respostas de contrato do kg-ssot, no **contrato v4.16** (a versão do contrato; o pacote do kg-ssot
    está na 4.33.0), sem mudança no contrato:
    - camada `domain`: marca e token como `entity`, contraste como `invariant` (quando verificado) ou `rule` (quando é
      diretriz), tema aplicado como `state` e política de uso da marca como `policy`;
    - camada `audit`: a escolha da paleta como `decision`, que faz `TRACES_TO` para a marca, com o selo do maestro; o
      arquivo de tokens como `artifact`; e o brief como `claim`. O brief como `claim` foi escolha do laboratório e não
      estava fixado no PLAN-F;
  - **tokens:** ficam no JSON W3C DTCG. O nó os cita por `trace:` (o arquivo) e por `provenance.locator` (o JSON
    Pointer, como `#/color/brand/primary`);
  - **ligações:** são `external_edges` relativas à raiz:
    - o brief `TRACES_TO` o posicionamento e o público do business-context;
    - o invariante de contraste `CONSTRAINS` o tema do technical-context;
    - o tema `TRACES_TO` a decisão, ou `DEPENDS_ON` quando a dependência é de build.

    Os grafos ficam independentes, mas ligados.
- **A ligação QUEBRADA é pega pelo gate do contrato, sem regra nova. A ligação AUSENTE pede uma regra da vertical**
  (`C_GUARD_BECOMES_GATE`). Foi medido em laboratório, com o `lab_graph.sh`, um repositório git por caso e tudo
  commitado. A saída literal está em `evidence/lab-graph/`:

  | caso | `kg_validate --corpus` | `kg_trace` | `lint-design-tokens` | `check_design_context` |
  |---|---|---|---|---|
  | 1. ligação íntegra | 0 | 0 | 0 | 0 |
  | 2. nó-alvo removido | **1, `dangling-external`** | 0 | 0 | 0 |
  | 3. token com alias some do JSON | 0 | 0 | **1, alias órfão** | **1** |
  | 4. arquivo de tokens removido | 0 | **1, `trace-target-missing`** | 1 | 1 |
  | 5. token que existia, citado só pelo grafo, some | 0 | 0 | 0 | **1, só ele pega** |
  | 6. brief sem ligação e sem falta declarada | 1, `orphan-node` | 0 | 0 | **1** |
  | 7. brief sem ligação, falta declarada por `question` | 0 | 0 | 0 | 0 |
  | 8. business-context no disco mas fora do índice | **1, `dangling-external` ×2** | 0 | 0 | 0 |
  | 9. mutante: locator aponta um grupo | 0 | 0 | 0 | **1** |
  | 10. mutante: locator com percent-encoding | 0 | 0 | 0 | 0 (resolve) |
  | 11. mutante: grafo que é lista | 1 | 1 | 0 | **2, sem traceback** |

  - O `check_context_links.py` da emenda C sai de cena.
  - O `check_design_context.py` é o checador da vertical de design. Ele faz duas coisas:
    - **o locator de token:** a única peça que pega o token citado só pelo grafo e o locator que aponta um grupo;
    - **a ligação obrigatória do brief:** ou ele tem uma `external_edge` para o business-context, ou um `question`
      aberto com `x_missing_context: business-context` declara a falta. O gate só pega a ligação quebrada. Sem esta
      regra, o brief com qualquer aresta interna passaria.
  - O contraste continua no `lint-design-tokens.sh`.
  - **Ordem de migração (caso 8):** o business-context tem de estar commitado antes do design. Se não estiver, até o
    caso íntegro reprova.
  - **Pendente com o kg-ssot** (`Q_KG_SSOT_LOCATOR_CHECK`): a checagem do locator entra no `kg_trace` do contrato ou
    fica na vertical de design do core? O contrato é do kg-ssot, e a curadoria não decide.
- **Valor sozinha:** todo adotante parte do brief que já tem e sai com um design-context em grafo, ligado aos outros
  contextos pelo gate e auditado.

**Onda 2: a saída mínima nos dois adotantes (critérios 5 e 6)**
- A partir do setup, o `/design:identity` materializa pelo design-sink o tema e os **componentes mínimos** em HTML e CSS
  (botão, cartão, alerta e tipografia). Tudo local e sem Storybook.
- O `/design:deck` passa a ler o tema e o embute no HTML offline.
- O ciclo roda no jogo-da-vida e no portal-gamificacao, que já têm design-context e passam no lint de tokens, mas não
  têm deck nem componentes.
- **Valor sozinha:** o primeiro material e os primeiros componentes saem na identidade do projeto. Com isso dá para
  medir o gatilho inteiro.

**Onda 3: enriquecer (fora do gatilho)**
- Style Dictionary como 2º conversor do design-sink. É o gatilho escrito no README do próprio design-sink para ele virar
  adaptador.
- Storybook local, só onde houver frontend.
- pptx e docx por modelo, depois da prova da peça de decks do Cortex.
- Pontes externas opcionais.

**O que fica de fora:** nada do que o gatilho exige.

**Por que esta é a recomendada:** é a única que liga cada onda a critérios do gatilho e deixa o gatilho medível no fim
da onda 2, com custo baixo e nada externo no núcleo.

### Opção 2 — O ciclo inteiro numa onda só

As ondas 1, 2 e 3 de uma vez.

**Custo:** alto e concentrado.

**O que destrava:** tudo junto.

**Risco:** construir o Storybook e os conversores antes de o primeiro adotante rodar a entrada.

### Opção 3 — A dimensão completa já

A opção 2 mais a doutrina da 4ª dimensão escrita agora.

**Contra:** contraria o selo do maestro, que liga a doutrina ao gatilho. Não é recomendada.

## Local ou externo, em todas as opções (emenda E: "não quero dependências externas como no caso do Gamma")

| onde | roda 100% local, com ferramenta aberta | depende de rede ou de serviço externo |
|---|---|---|
| ondas 1 e 2 (núcleo) | setup, brief, tokens em arquivo, gate, design-sink, resolvedor, frescor, guarda das ligações, `/design:identity`, `/design:deck` em HTML offline e componentes em HTML e CSS | nada. O `/product:presentation` usa o Gamma (SaaS) e **não** entra no ciclo |
| onda 3, instalação | Style Dictionary (Apache-2.0), Storybook local, python-pptx e python-docx, depois de instalados | **instalação pela rede**: `npm create`, o registro do shadcn e o pip baixam pela rede uma vez. O Storybook 10.6 tem **telemetria ligada por padrão** e **checa atualização pela rede** ao rodar; o desenho fixa `--disable-telemetry` e `--no-version-updates` (nomes informados pela revisão, não lidos aqui) |
| pontes opcionais | — | Figma Variables pela API (Enterprise), Tokens Studio com sincronização paga e Chromatic (hospedagem paga do Storybook). Nunca são requisito |

## Migração, ausências e contraste

- **Migração (revista pela emenda F: as ligações moram no grafo, não em campos do brief).**
  - O `brief.md` que existe hoje (o do core, o do portal-gamificacao) continua como narrativa, sem campo novo e sem tocar
    a prosa. O setup cria o nó do brief no grafo, com `trace: docs/design-context/brief.md`.
  - As ligações entram como `external_edges` quando o alvo existe.
  - No 1º ciclo, a ligação que falta é **aviso**: vira uma `question` aberta no grafo, e nada reprova.
  - Ela vira reprovação pelo `kg_validate --corpus` quando os grafos dos outros contextos existirem. Enquanto eles não
    existem, não há alvo para a aresta, e o setup não a grava.
- **Sem business-context.**
  - O setup pergunta público, tom e personalidade e oferece o stub do `onion-product-context`, com confirmação.
  - Se recusado, o grafo do design nasce sem a aresta para o posicionamento e com a `question` aberta "falta o
    posicionamento: o brief foi escrito sem fonte de negócio". O ciclo não fica bloqueado, e nenhum dado de mercado é
    inventado.
- **Contraste do CTA.**
  - O setup mede a cor da marca contra o branco e contra o quase preto, e escolhe o texto que dá 4,5:1, como o core fez
    no laranja.
  - Se nenhum der, propõe um tom mais escuro da marca para `action.primary` e deixa a cor original como acento. O gate
    decide.

## Régua de mercado (pré-registro §3: padrão = 3 de 4 critérios)

| fonte | adoção | licença aberta | trajetória datada | sem conta paga | resultado |
|---|---|---|---|---|---|
| formato de tokens do W3C 2025.10 | sim (o core e o Style Dictionary usam) | especificação aberta | sim (28/10/2025) | sim | **4 de 4: padrão** |
| Style Dictionary | não medida | Apache-2.0 | sim (5.7.1, 24/10) | sim | **3 de 4: padrão** |
| shadcn/ui CLI | sim (cerca de 126,7 mil estrelas) | MIT | **não** (página sem data) | sim | **3 de 4: padrão** |
| Storybook | não medida | não lida | só a versão (10.6), sem data | sim no uso local | **não fecha 3 de 4 com o que foi lido** |
| Tokens Studio | não medida | não lida | **não** (página sem data) | só o básico; temas e sincronização são Pro | **não é padrão aqui**: ponte opcional |
| Figma Variables (API REST) | não medida | não (proprietário) | não lida | **não** (Enterprise) | **não é padrão aqui**: ponte opcional |

## Veredito por peça (pré-registro §4)

| peça | veredito |
|---|---|
| tokens DTCG em arquivo | **o core já tem** (`docs/design-context/`) |
| gate de tokens | **o core já tem** (`lint-design-tokens.sh`) |
| tema por variável CSS | **o core já tem** (`design-sink/tokens-to-css-vars.sh`) |
| configuração versionada, modo sem perguntas, detecção, nunca sobrescrever | **costurar** no `/design:setup`, no molde do `onion-wizard` |
| skill resolvedora, frescor, guarda das ligações | **costurar**, no molde dos outros três contextos |
| Style Dictionary | **costurar** na onda 3, como 2º conversor do design-sink |
| Storybook | **costurar** na onda 3, opcional, só com frontend e com a telemetria desligada |
| Figma Variables, Tokens Studio pago, Chromatic, Gamma | **não transfere** para o núcleo: ponte opcional, pelo critério de só local |

## Não verificado

- O comportamento real dos wizards de mercado na reexecução: foi lido, não rodado.
- O checador de ligações em escala: só há o protótipo.
- O suporte completo do Style Dictionary à 2025.10.
- Os preços do Tokens Studio.
- Quem financia o shadcn/ui.
- Os nomes das opções de telemetria do Storybook.
- A medida dos dois adotantes, feita pelo core no disco, sem a origin/main deles.

Via de bilhetagem: nenhuma foi medida.
