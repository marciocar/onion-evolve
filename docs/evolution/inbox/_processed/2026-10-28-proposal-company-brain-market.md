---
title: 'Proposta condicional: Q_MA_MARKET, o padrão de mercado para escrever por audiência sobre uma fonte única'
date: 2026-10-28
from: onion-curation (adotante)
to: core (onion-evolve)
type: proposal
estudo: docs/evolution/research/company-brain-multiaudience-2026-10/
grafo: company-brain-multiaudience-2026-10.kg.yaml (D_COMPANY_BRAIN_MARKET_PROPOSAL, a proposta, e Q_CB_FREE_ORG_READ_ENFORCED, o card)
---

# Q_MA_MARKET: como o mercado faz "todos leem tudo, cada audiência escreve no seu lado"

**Pedido:** o maestro pediu, por meio do core, para o Company Brain multiaudiência proposto pelo hub brain. Ele
reforçou duas coisas: "SEMPRE buscar usar padrões de mercado", e as linhas (a) repositórios separados por
responsabilidade, ligados por vendorização com pin, e (b) MCP por identidade.

**Como foi feito:**
- três pré-registros, PLAN, PLAN-B e PLAN-C, cada um commitado antes do seu braço;
- dois braços de pesquisa em fonte primária;
- um laboratório local e um Gitea 28.2.0 oficial, rodados;
- uma revisão adversarial, que **reprovou a 1ª versão**. Esta versão incorpora as 13 objeções que se sustentaram
  (`evidence/elenxo/REVIEW.md`).

## A resposta curta

**No plano atual do maestro (conta pessoal, GitHub Free) nenhum caminho de prevenção rodou.** Lido em fonte primária:

- o colaborador de repositório privado de conta pessoal **sempre escreve**, porque não há papel só de leitura;
- não há proteção de branch, CODEOWNERS nem rulesets nesse plano. O servidor não aplica nada, e a CI só detecta, sem
  bloquear o merge.

É o critério do próprio pré-registro (PLAN.md §4), e ele **não foi cumprido**. Ficam três caminhos, em ordem de
custo.

| caminho | previne? | custo | estado |
|---|---|---|---|
| **(1) organização gratuita, um repositório por audiência** (o padrão de mercado; recomendado, condicional) | sim, no servidor, por repositório, para contas que não são donas | zero de plano; **custo de migração** (abaixo) | **lido, não medido**: depende do card |
| (2) um repositório só, com plano pago | o Pro previne no merge (CODEOWNERS com revisão exigida); o Team, o plano hospedado mais barato que previne no push, previne por caminho (push rulesets) | US$ 4 por usuário por mês no Team; o preço do Pro não foi confirmado em fonte oficial | lido |
| (3) um repositório só num forge auto-hospedado (Gitea) | sim, no push | VPS, operação e saída do GitHub | **medido (L7)**, mas de sentido único: quem está na whitelist escreve tudo |
| (4) só detecção no plano atual | não | zero | cumpre o "nada passa despercebido" só como aviso |

## O caminho (1), com o que ele exige

1. **Um repositório por audiência numa organização gratuita.**
   - O repositório de tecnologia tem o código e o `technical-context`; o de negócio tem o `business-context`, o
     `compliance-context` e o `design-context`.
   - Cada equipe tem **Write** no seu repositório e **Read** no outro.
   - É o padrão da lei de Conway e do Team Topologies (o dono escreve, o outro consome como serviço) e do Data Mesh
     (cada domínio escreve o seu).
2. **Uma conta por audiência.** O dono da organização tem admin em todo repositório e, sem proteção de branch no Free,
   escreve nos dois lados. A separação só vale para contas que **não** são donas. Hoje as sessões rodam com a conta do
   maestro: cada lado precisa de uma conta própria, de pessoa ou de máquina, e os termos do GitHub para conta de máquina
   ficam a verificar. O dono é bypass declarado.
3. **O consumidor liga ao dono por git submodule** (gitlink fixado).
   - O laboratório mediu que o pin segura a versão até um commit do gitlink no consumidor. Quem pode fazer esse commit
     depende da permissão do forge.
   - **Custo:** a tecnologia lê o negócio velho até mover o ponteiro. O padrão de mercado que tira o atraso é o
     Dependabot com o ecossistema `gitsubmodule`, que abre o PR de bump; não foi verificado em repositório privado de
     organização.
   - O vendor com manifesto do Go modules dá rastro de versão, mas **não** detecta edição na cópia. A detecção de
     edição do `vendor/kg-ssot` da casa é solução própria, declarada.
4. **A proposta cruzada segue o InnerSource,** por PR de quem tem Read. O fork de repositório privado vem **desligado
   por padrão** numa organização nova e precisa ser liberado. O fork copia o conteúdo do outro lado para a conta de
   quem propõe.
5. **O MCP herda a permissão da conta.** É o GitHub MCP Server oficial (MIT, com `--read-only`). O padrão de mercado é
   o MCP herdar a permissão da fonte. Um PAT fine-grained não carrega Write num repositório e Read no outro, então são
   dois tokens por identidade, e a fronteira real é a conta.
6. **A detecção mira a escrita do dono,** porque é o que sobra com um repositório por audiência. A superfície de
   mercado é o audit log da organização, cuja disponibilidade no Free não foi verificada. O policy-as-code (Conftest)
   fica como opção declarada e não medida, porque o Conftest é para dado de configuração e o diff exige cola própria.
   Qualquer checador por mapa lê o mapa **da base confiável**: o L5 mediu que, lido do próprio commit, o autor se dá o
   lado.

## O que o caminho (1) quebra: o KG-SSOT

- **A ponta externa** (`<caminho>#<id>`) não qualifica o repositório.
- **O submodule escapa da leitura:** o `git ls-files` não lê o grafo de dentro do submodule. Só o
  `--recurse-submodules` o lista, e isso foi medido pela revisão.
- **Não há pin no sentido inverso:** o repositório de negócio não tem pin para o de tecnologia.
- **Os grafos que cruzam contextos ficam sem dono:** é o caso de `docs/evolution` e `docs/onion/graph`.

**Pergunta ao kg-ssot,** pela curadoria: o radar com `--recurse-submodules`, ou uma ponta externa qualificada por
repositório (a URL fixada do acordo de transmissão é candidata)? Sem essa resposta, a coluna KG-SSOT do caminho (1) é
"quebra sem mudança de contrato".

## O custo da migração (visto)

- **Pages:** o GitHub não redireciona o Pages de um repositório transferido.
- **Referências a `marciocar/`:** 85 arquivos só na curadoria, entre eles o `co-relay.sh`, o `federation-a2a.md`, o
  `lint-selftest.sh`, o `.onion-version` e o `--repo` do merge verificado. Ainda há os do core, do kg-ssot e do
  `members.yaml`.
- **Ganho:** a organização Free tem a sua própria cota de Actions (2.000 minutos por mês).
- **Não verificado:** as variáveis de Actions na transferência.

## Card do maestro (Q_CB_FREE_ORG_READ_ENFORCED)

Ele mede o fato de que tudo depende. Cabe ao maestro porque cria a organização e convida contas.

1. Crie uma organização gratuita de teste.
2. Crie nela um repositório privado e uma equipe com **Read**.
3. Convide uma conta que **não** seja a dona.
4. Com essa conta, tente um `git push`. O esperado é ser recusado.
5. Libere o fork privado e abra um PR a partir do fork.

A curadoria confere a saída. **Refutador:** se o push passar, ou se o custo da migração superar o do plano pago, a
recomendação passa para o caminho (2).

## Capital e quem paga

O dinheiro vai para a camada agêntica sobre o catálogo (Port, Series C de US$ 100M, 2025-12) e para assistentes de
conhecimento (Workday comprou a Sana em 2025-11). A separação de escrita é **commodity do forge**, e o forge a cobra
no plano pago. No caminho (1), ninguém paga plano: o custo é a migração.

## Não verificado

Os itens estão no `meta.x_unverified` do grafo e nos relatórios dos braços (`evidence/research-*.md`).

Orquestrado com 🧅 Onion Evolve
