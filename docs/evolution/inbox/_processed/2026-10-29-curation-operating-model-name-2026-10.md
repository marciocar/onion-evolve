# Sinal ao core: o nome do arranjo (operating-model-name-2026-10)

**De:** a curadoria. **Para:** o core. **Data:** 2026-10-29. **Destino:** `core`. **Estado:** proposta revisada por
agente separado. A 1ª versão, que trazia uma cunhagem, foi reprovada com 13 objeções, todas curadas
(`elenxo/REVIEW.md`). Quem decide o nome é o maestro.

## Em uma linha

**Nenhum nome curto de mercado cobre o todo.** Mas **cada peça tem nome de mercado**, e por isso não há o que cunhar:
o arranjo se descreve juntando esses nomes. O nome curto é decisão do maestro, depois de dissecar o **Gas Town**, a
implementação aberta mais próxima.

## A descrição, só com termos de mercado

> Uma **equipe humano-IA** (*human-AI team*, National Academies 2022, a partir de Cuevas et al. 2007) de **papéis
> persistentes donos de repo com sessões efêmeras** (*persistent identity, ephemeral sessions*, Gas Town). Ela é
> coordenada por **quadro-negro** (*blackboard*, Hearsay-II, 1980: o grafo de pendências com dono) e por mensagem
> direta. O core atua como **time de plataforma e de habilitação** (*platform* e *enabling team*, Team Topologies:
> distribui o update e o método). Há **gates determinísticos e revisão adversarial** antes de toda proposta, e
> **human-in-the-loop no gate de decisão**: o maestro decide e sela pelo `/meta:decide`.

Duas correções do que a 1ª versão dizia:

- **A persistência é do papel, do repo e do grafo, não da sessão.** A sessão do core reiniciou e perdeu o contexto, e
  o estado voltou pelo git, pelo grafo e pela memória.
- **O merge é delegado com gates, não selado.** Aqui o merge é disciplina e não trava: não há branch protection, e o
  humano e a sessão usam a mesma conta. Que o humano sela cada merge **não foi medido**.

## O que cada nome cobre (matriz em `evidence/research-names.md`, mais os achados do revisor)

- **Prometem o que não roda,** e servem só como nome do que se quer:
  - agentic AI mesh e agentic organization (McKinsey, de segunda mão), digital workforce (Gartner) e Frontier Firm
    (Microsoft);
  - todos prometem autonomia e escala sem selo humano.
- **Nomeiam uma peça:**
  - blackboard é o grafo;
  - orchestrator-workers são os subagentes de cada sessão;
  - platform e enabling team são o core;
  - human-in-the-loop no gate é o selo;
  - transactive memory é o corpus.
- **Cobrem o humano e a equipe, sem sessões nem gates:**
  - centaur, uma dupla;
  - human-AI teaming, o guarda-chuva mais honesto;
  - mixed-initiative (Horvitz, 1999);
  - agentic engineering (Willison, 2026), que é prática.
- **Cobrem sessões e coordenação:**
  - **agent teams** do Claude Code: experimental, sem retomada de sessão;
  - **Gas Town**: papéis persistentes donos de repo, mailbox, ledger em git, retomada (*Seance*), humanos com
    workspace (*Crew*) e gates. Com `merge_strategy=pr` e `require_review`, ele exige uma aprovação humana no GitHub
    antes do merge (conferido no `mol-refinery-patrol.formula.toml`). O padrão dele é o merge direto.

## As opções de nome curto para o maestro

1. **Company Brain** para o todo, com a divergência declarada.
   - É o termo que o maestro usa ("têm que fazer parte do nosso Company Brain").
   - No mercado, a Glean chama o produto de *enterprise brain*: uma camada de inteligência sobre os dados da empresa,
     com agentes em cima (fonte secundária, a entrevista do CEO).
   - O sentido de mercado é um produto que **indexa** o que existe. O nosso é um corpus de grafos com dono **mantido
     por** sessões com papel. O nome serve se a diferença for dita sempre que ele aparecer.
2. **Nome nenhum:** só a descrição acima, e o arranjo é chamado pelas peças.
3. **Esperar o Gas Town.** Dissecá-lo primeiro: se ele cobrir o arranjo no modo `pr` com `require_review`, o nome de
   mercado mais próximo é o padrão dele ("um Gas Town com revisão obrigatória").

**Recomendação:** a 3, e depois a 1. Dissecar o Gas Town é pré-requisito, porque ele é o único superador com
implementação aberta, e o refutador da 1ª versão já disparou nele.

**Refutador checável da recomendação:**

- se, até a revisita do estudo (2027-01-27), a doc do agent teams deixar de trazer "No session resumption" e passar
  a trabalhar entre repositórios, "agent teams com selo humano" vira o nome de mercado;
- se o Gas Town passar a ter `require_review` ligado por padrão, "Gas Town" vira o nome de mercado da implementação.

## O brain-granaai (só estrutura)

É um **hub adotante com co-evolução**, não uma 2ª instância medida do arranjo:

- 29 grafos do hub, fora do vendor e do framework;
- 166 commits de Onion ou update desde 01/10;
- 8 autores, 5 deles com 39 commits ou mais.

Ali a equipe é de **vários humanos**, e o traço "um humano que decide e sela" não vale como está. Isso importa para o
nome: o Company Brain do hub é multiaudiência, como o #153 já tratou. Fronteira declarada: leram-se carimbo, nomes de
arquivo, contagem de autores e assuntos de commit por grep, sem abrir conteúdo.

## O que o core decide

1. Levar ao maestro as três opções de nome curto.
2. Dissecar o Gas Town, com a família `ferramenta` e o destino `core`.

## Capitalizar

O nome não fatura sozinho. Quem fatura com termos vizinhos é a consultoria (McKinsey), a plataforma (Microsoft,
Salesforce), o analista (Gartner) e o produto de busca corporativa (Glean, *enterprise brain*). Se o Onion vender o
modo de operar, o nome entra na vitrine da kg-ssot, e a decisão é do maestro.

## Não verificado

- As citações literais da McKinsey.
- O abstract literal de Dell'Acqua et al.
- O sentido de "enterprise brain" pela fonte primária da Glean.
- O uso real do Gas Town além das estrelas.
- Claude Squad, OpenHands e Devin com sessões persistentes: não buscados.
- A fração dos merges que o humano de fato selou.
