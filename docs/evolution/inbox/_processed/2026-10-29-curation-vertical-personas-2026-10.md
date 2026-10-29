# Sinal ao core: personas por vertical, cortadas pelo uso real (vertical-personas-2026-10)

**De:** a curadoria. **Para:** o core. **Data:** 2026-10-29. **Destino do estudo:** `core`.
**Estado:** proposta, revisada por agente separado. A 1ª versão foi reprovada com 23 objeções, todas curadas
(`elenxo/REVIEW.md`). Aqui nada é selado: quem decide é o maestro, e quem sela é o core.

## Em uma linha

O padrão de "sessão de vida longa com papel, pares e grafo de coordenação" **já roda entre repositórios**: a
curadoria e o kg-ssot são o caso n=1, cada uma dona do próprio repo. O que dá certo no mercado é coordenação **com
verificador** numa tarefa decomponível. Personalidade e papel escrito no prompt não rendem ganho medido.

O que tem uso real **entra**. O que só tem doc ou payload sintético entra como **experimento com critério de saída**.
O resto **sai**.

## A tabela por peça (critério da emenda C, classes da emenda E)

| peça | uso real nosso | uso real de mercado | classe | o que fica |
|---|---|---|---|---|
| persona = sessão de vida longa, dona de um repo | sim, entre repos: 22 rodadas de update (6 em 27 e 28/10), 43 PRs da curadoria desde 27/10, 3 bancadas de release entre sessões | nenhuma plataforma mantém sessão viva; persiste identidade, permissão e memória | **entra** | as sessões que já existem (core, curadoria, kg-ssot, sge), com o `/warm-up` e o `/catch-up` que já rodam |
| warm-up nativo (`--agent` com `initialPrompt`, `memory: project`) | nenhuma sessão da família roda com `--agent` | só a doc | **experimento** | saída: uma sessão declarada roda com agente de prompt vazio mais `initialPrompt` e mantém o comportamento do `/warm-up`. Atenção: o prompt do agente **substitui** o prompt padrão do Claude Code |
| especialistas = ferramentas da sessão | sim: os 51 agentes em uso | o orquestrador com operários da Anthropic: +90,2% na avaliação interna, ~15× os tokens | **entra** | a persona herda o recorte do inventário P2 |
| escopo de escrita **entre** repos | sim: o I3 (um escritor por repo) é o modo de operar da família. Já houve violação, o commit cross-repo na branch errada que o co-relay curou | Data Mesh: a regra é executada pela plataforma | **entra** | um repo por dono, como o #153 propôs para o hub |
| escopo de escrita **dentro** de um repo | nenhum | CODEOWNERS com caminho protegido, que exige branch protection, ausente no plano atual em repo privado | **experimento**, por camadas | (a) checagem de caminho no commit: o pre-commit do git recusou a escrita feita por Python fora do escopo (P3, medido), e tem de rodar também no CI do PR; (b) hook PreToolUse por `agent_type` (P1e, payload sintético); (c) sandbox `denyWrite` com `allowUnsandboxedCommands: false` e `failIfUnavailable` (lido, não medido; em bypass a nova tentativa sem sandbox passa sem prompt) |
| coordenação entre pares pelo grafo com dono | **parcial**: 36 nós; o core fechou 6 e o maestro 2, a curadoria e o kg-ssot fecharam 0; o grafo fica atrás do vivo | MAST: falha de 41 a 86,7% (projeto 44,2%, **desalinhamento entre agentes 32,35%**, verificação 23,5%); erro de 4,4× centralizado e 7,8× entre pares, sem efeito significativo depois do controle | **entra**, com dois consertos | (1) cada par fecha no grafo o que entregou (a defasagem é a falha medida); (2) o verificador fica no caminho: pré-registro, revisão por agente separado, gates, merge verificado |
| decisor por tipo de decisão | o maestro decide tudo: 11 pendências abertas | RAPID e DACI são doutrina, sem estudo medido | **entra como triagem**, sem decisor novo | das 11 pendências, 5 são decisões, 4 são atos (o maestro executa com o card) e 2 saem da fila (uma pela regra "sem dependência externa", outra para a curadoria, dona da fila). Ver `evidence/cost-and-deciders.md` |
| Agent Card do A2A e vigia roteando por skill | a ida e volta A2A deu dado nas duas pontas só na R3, e a pergunta segue aberta | nenhum: a API de registro não é padronizada | **sai** | volta quando o vigia de eventos e o A2A tiverem uso medido |
| papel e personalidade escritos no prompt | nenhum | 162 papéis no prompt, sem ganho em QA factual | **sai** | o papel vale como mecanismo (ferramentas, escopo, decisão), não como texto |
| agent teams do Claude Code | nenhum | experimental, sem retomada de sessão, ~7× os tokens (doc, não conferido) | **sai** | — |
| verticais sem especialista (marketing, vendas, customer success) | 0 agentes, 0 pendências | — | **sai** | — |

## O piloto

- **Piloto 1: o Company Brain do próprio Onion, em dogfood, entre repos.**
  1. As sessões que já existem seguem como personas, sem mecanismo novo.
  2. Os dois consertos da coordenação.
  3. A triagem da fila do maestro.
- **Vertical nova.** A proposta de limiar é **3 pendências abertas da vertical ao mesmo tempo, ou 1 aberta há mais de
  14 dias**. Hoje: design 1 (`Q_COORD_DESIGN_ONDA2_SAIDA_NOS_ADOTANTES`, dono core), compliance 0, negócio 0, produto 0.
  Nenhuma dispara.
- **Piloto 2: o hub multiaudiência.** Reaproveita o #153 (`D_COMPANY_BRAIN_MARKET_PROPOSAL`, um repositório por
  audiência) e o card `Q_CB_FREE_ORG_READ_ENFORCED`, que espera o maestro rodar o PLAN-D. Nada é refeito.

## O custo de N sessões (medido na curadoria)

Nos transcritos de 27/10, a sessão principal leu 239 milhões de tokens do cache, e os subagentes 552 milhões. A
escrita de cache foi de 3 e 9 milhões. O custo dominante é o **contexto relido a cada turno**, não o warm-up.

- **No preço de lista do Opus 5.5:** 27/10 sai por ~US$ 245 a 280 e 28/10 por ~US$ 65 a 72, como teto.
- **Na assinatura:** o limite que manda é o do plano.
- **N personas vivas** custam perto de N vezes isso nos dias ativos.

## O que o core decide

1. **O corte por peça e as classes** da tabela.
2. **O conflito com o I3.** Se uma vertical nova surgir dentro do repo do core, as opções são:
   - (a) um repo por vertical, que mantém o I3 como está e segue o #153 — **recomendada**;
   - (b) uma emenda ao I3, com worktree por persona e escopo por camadas.
3. **O limiar de demanda** para abrir uma vertical nova (proposto acima).
4. **A triagem das 11 pendências do maestro**, que é do maestro.

## Capitalizar

As personas não abrem via de bilhetagem própria. No mercado, fatura a plataforma dona da identidade (Salesforce,
Microsoft). A via que existe é o assento por audiência do hub, que segue o #153.

## Não verificado

- A regra `Edit(...)` deny e o sandbox: lidos, não medidos.
- O pre-commit se pula com `--no-verify`, e o CI do PR não é obrigatório.
- A sessão de outra conta sem canal.
- A escala para N sessões: o caso é n=1.
- O modelo de cada subagente na conta de custo.
- Se a revisão adversarial detecta defeito real: faltam as objeções sustentadas, os escapes depois do merge e os
  falsos positivos.
- Os números do Agentforce são do próprio fornecedor.
- Mais o `x_unverified` de `E_VP_RESEARCH_MARKET`.
