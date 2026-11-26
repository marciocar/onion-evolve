---
kg: docs/evolution/research/onion-evolve-persona-2026-11/onion-evolve-persona-2026-11.kg.yaml
run_id: wf_ee5183a3-68f
tokens: 1886284
agents: 24
duration_min: 12.7
mode: primaries
date: 2026-11-26
---

# A Persona do Onion Evolve: uma sessão dedicada a evoluir o Onion

Projeção do grafo `onion-evolve-persona-2026-11.kg.yaml`. A fonte da verdade é o grafo; aqui está o resumo.

**Pergunta** (`Q_ONION_EVOLVE_PERSONA_2026_11`): o maestro pediu, em 26/11/2026, uma sessão que trabalhe só para evoluir o
Onion e fechar pontas soltas. Ela deve ser ativa, propositiva, organizada e executiva, priorizar por dor real com
evidência, conferir cronogramas, ajudar quem orquestra com a batuta e passar por uma autodescoberta de cerca de 30 ciclos
antes de começar. Deve decidir com Personas, humanas inclusive, com refutação independente, sem deixar de cumprir o que
o maestro diz. A pesquisa responde a quatro perguntas: (1) o termo de mercado, (2) os padrões e casos reais, (3) os
riscos medidos e (4) o MVP que cabe no Onion.

## O que a rodada sustenta

- **Governança com código aberto e datado.** O agente "Chief of Staff" do MemberJunction (PRs 5842 e 6041):
  - a permissão do usuário é o teto, e a governança nunca a amplia;
  - uma política por ação decide entre `Allow`, `RequireApproval` e `Deny`;
  - um wake gate em camadas chama o LLM só quando as camadas anteriores não decidem, e um batimento forçado acorda o
    agente de tempos em tempos;
  - wakes por evento são agrupados.
- **Carta e estado por persona.** O "agentic product owner" do agent-teams (PR 287):
  - a carta define metas, sinais e cercas;
  - na partida, a sessão carrega a carta, a visão, as afirmações, o ledger e os aprendizados; sem carta válida, ela
    começa em modo rascunho;
  - cada persona tem o seu ledger.
- **Riscos medidos.**
  - O Project Vend, da Anthropic, em que um agente gerenciou uma loja real: ele foi manipulado a dar descontos, a loja
    não deu lucro, houve deriva de identidade, e uma camada "CEO" do mesmo modelo não ajudou.
  - No TheAgentCompany, o melhor agente completou 30,3% das tarefas, com os piores resultados em Admin e Finanças.
  - No Darwin Gödel Machine, o próprio paper declara o risco de o agente otimizar a métrica.
- **Desenho clássico.** No Viable System Model, o Sistema 4 olha o futuro e propõe, e o Sistema 5 decide pela
  identidade. No AI co-scientist, o humano fixa a meta e as restrições.

## MVP que a evidência sustenta (`C_ELENXO_PERSONA_MVP_RECOMMENDATION_1126`, open)

- A persona é o Sistema 4: propõe, prioriza e confere cronogramas.
- O maestro, ou um Delphi com pessoas e agentes, é o Sistema 5: decide.
- A carta da persona fica versionada no KG-SSOT.
- A persona acorda pela campainha e pelo pulso silencioso da batuta.
- A política de aprovação fica fora do alcance da própria persona. No MemberJunction, o agente pode editar a própria
  política, o que é captura pelo proponente.
- O Elenxo (o método de refutar antes de selar) da persona roda com modelo e contexto distintos dos dela.
- Há um teto de gasto.

## O que a rodada NÃO sustenta (5 objeções bloqueiam)

1. **O termo de mercado.** Só há nomes de projeto ("Chief of Staff Agent", "agentic product owner", "steward-like").
   "Agentic AI" é o gênero, não o papel.
2. **A independência do refutador.** Um papel separado sobre o mesmo modelo repete o colapso proponente = aprovador.
   O nó `D_NEED_REFUTADOR` continua aberto.
3. **A autodescoberta de cerca de 30 ciclos.** Nenhuma fonte a trata. O Darwin Gödel Machine só melhora com um
   avaliador externo, e o Onion não tem um placar de "valor de evolução". Sem critério de parada, o número é
   preferência.
4. **Copiar o MemberJunction como está.** O agente dele pode afrouxar o próprio freio.
5. **Uma persona que decide sem se subordinar ao maestro.** As fontes põem a decisão na identidade e no humano.

Também ficam abertos: a transferência das medidas de 2025 para os modelos de novembro de 2026, e o Apêndice H do Darwin
Gödel Machine, sobre hacking do avaliador, que não foi lido.

## NÃO-VERIFICADOS

17 afirmações foram rejeitadas na ancoragem (16 exageradas e 1 sem citação) e estão contadas em
`E_LACUNAS_ONION_EVOLVE_PERSONA_1126`. Não houve fonte inalcançável. A fonte do Hacker News era só um título com 1 ponto
e nenhum comentário.

## Valeu a pena?

1.886.284 tokens ÷ 78 nós ≈ 24 mil tokens por nó, em 12,7 minutos. É bem abaixo dos 42 mil por nó medidos no modo
primárias em 2026-09. A rodada fechou 8 de 10 lacunas, e 2 seguem abertas: o termo de mercado e o enquadramento da
comunidade.

Orquestrado com 🧅 Onion Evolve
