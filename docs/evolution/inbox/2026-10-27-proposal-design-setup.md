---
title: "Primeiro tijolo da 4ª dimensão (design): ondas contra os 6 critérios do gatilho do core (recomendada: opção 1, fio fino)"
date: "2026-10-27"
from: onion-curation
merged_at: "main 28286a5 (PR #138)"
to: onion-evolve
type: research-proposal
kg: docs/evolution/research/design-setup-2026-10/design-setup-2026-10.kg.yaml
decision_node: D_DESIGN_SETUP_PROPOSAL
trigger: "onion-evolve: Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027 (PR #1403, aberto)"
---

# Sinal: o ciclo de design como primeiro tijolo da 4ª dimensão

> **Quem decide:** o core, que leva ao maestro.
>
> **Direção:** o maestro decidiu que o design será a 4ª dimensão do Onion, e a doutrina muda quando o gatilho medido
> disparar. O selo `D_DESIGN_QUARTA_DIMENSAO_DIRECAO_1027` ainda **não** está na main do core (peer-ref-check rc 1 em
> 18e070c39, segundo a revisão adversarial). Ele está no PR #1403 do core, aberto, e por isso é citado como pendente.
>
> **Gatilho:** é o do core, por referência: `Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027`, no mesmo PR. São 6 critérios, cada
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
- Guarda das ligações (brief → business-context, brief → technical-context, tokens → tema):
  - registrada e exercitada por mutante;
  - **aviso no 1º ciclo** (a migração está mais abaixo);
  - o protótipo `check_context_links.py` serve de base.
- **Valor sozinha:** todo adotante parte do brief que já tem e sai com um design-context ligado aos outros contextos e
  auditado.

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

- **Migração.** Os `brief.md` de hoje não têm `derives_from` nem `technical_bridge`, e uma guarda grave reprovaria todos.
  - No 1º ciclo a guarda é **aviso**.
  - O setup oferece acrescentar os campos ao brief que existe, com dry-run e sem tocar a prosa.
  - A guarda vira **grave** quando os dois adotantes migrarem.
- **Sem business-context.**
  - O setup pergunta público, tom e personalidade e oferece o stub do `onion-product-context`, com confirmação.
  - Se recusado, grava `derives_from` vazio, e a guarda avisa "brief sem fonte de negócio". Não inventa dado de mercado.
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
