---
title: "Distribuir o método vivo: o veículo não se escolhe sem o canal de atualização, e a fronteira tem de ser allowlist executável"
date: 2026-09-13
kg: docs/evolution/research/distribuicao-metodo-vivo-2026-09/distribuicao-metodo-vivo-2026-09.kg.yaml
run_id: wf_9aae7383-5af
tokens: 1355653
agents: 16
duration_min: 19
genre: decision
mode: primaries
review_after: 2026-10-13
---

# Distribuir o método vivo, sem distribuir a vida

> **Projeção** do grafo (52 nós, 91 arestas, radar exit 0). Rodada de **primárias nomeadas** — o modo que
> nasceu nesta mesma sessão. As **cinco perguntas foram respondidas pelo maestro em 2026-09-14**; o que
> resta aberto está na última seção, com gatilho nomeado.
> Retorno do run versionado em [`data/`](data/).

## A pergunta

O maestro vai dar consultorias e quer entregar ao cliente uma **versão pública do Onion para forkar e
evoluir sozinho**. Onde passa a fronteira entre a **doutrina** (REGRAs, knowledge-base, gramática do grafo,
exemplos — o que deve viajar) e a **biografia** deste repo (diário, grafos da vida, `members.yaml`, achados
de segurança de adotantes, material sob NDA — o que não pode viajar)?

## Custo declarado

| Item | Valor |
|---|---|
| Run · tokens · agentes | `wf_9aae7383-5af` · 1.355.653 · 16 |
| Fontes | **7 primárias nomeadas**, 7 alcançadas, 0 inalcançáveis |
| Claims | 33 → **26 ancoradas**, 7 rejeitadas na ancoragem |
| Elenxo | 26 objeções, 24 sobrevivem · 3 lacunas fechadas, 7 abertas |
| Custo por nó | ≈ 39 mil (35 nós) |

## O que ficou provado

**1. Veículo e canal de atualização são uma escolha só, não duas.** A doc do GitHub é explícita: um repo
criado de **template** nasce com um commit e **histórias não relacionadas** — *"you cannot create pull
requests or merge between the branches"*. Um **fork** carrega toda a história do doador e **mantém o vínculo
upstream**. Quem escolhe template contrai, no mesmo ato, a dívida de construir um segundo mecanismo de
atualização.

**2. O desenho com precedente é gerar por filtro, não copiar e apagar.** O GitLab mantém os dois lados
**fisicamente separados no próprio repositório**, com diretório dedicado, e publica o espelho aberto a partir
daí. A alternativa — forkar o tronco e apagar as pastas na entrega — é a classe que esta casa já registrou
como incidente: o "temporário" que evapora.

**3. Atualização nunca resolve colisão em silêncio.** Copier marca o conflito inline por padrão, oferece
`.rej` como alternativa, e **avisa que editar o arquivo de respostas à mão quebra a premissa do mecanismo**.
O Cruft exige revisão antes de aplicar. Convergência de duas ferramentas independentes: **a colisão vai ao
humano**.

**4. O que viaja tem de rodar.** O GitLab declara um piso: o lado aberto tem tudo que é essencial para
operar em escala real. Aqui o piso já foi violado uma vez, e está medido: o `review-artifact-check.sh`
**nunca foi vendorizado**, e por isso nenhum adotante tem resíduo da REGRA 56 (PR aberto carrega RESÍDUO da
passada adversarial). Não foi prática que não pegou — foi **capacidade que nunca enviamos**.

**5. Licença de software não protege nome.** A Apache 2.0 exige aviso proeminente em arquivo modificado
(§4b) e **não concede marca** (§6). A política da ASF confirma na prática: derivados existem sob marca
própria. Quem protege o nome é a marca, não a licença.

## As três medições locais que derrubam premissas — inclusive minhas

1. **A licença já está decidida, e não como se queria.** O `LICENSE` do repo e dos **5 plugins publicados** é
   **MIT** — concessão irretratável, já pública. Sob MIT o cliente **pode revender o framework**, que é o
   único limite que a pergunta declarou querer. **Não decidir é decidir pelo permissivo.**
2. **O precedente que eu citei não existe.** Eu disse que o `onion-standalone` nasceu por *export curado por
   papel* via `--role standalone`. Medido: o `adopt` vivo aceita `adopted` e `hub`. "Standalone" é papel de
   **membro da federação**, não flag do gerador. Repassei o corpus sem conferir contra o código.
3. **Não existe filtro nenhum hoje.** O diário está em `.claude/diary` com **127 arquivos**, dentro do
   diretório que o `/meta:adopt` vendoriza, e `grep -c exclude` no `adopt.md` dá **zero**.

## O gate, antes de qualquer veículo

**A partição tem de virar allowlist executável — o que COPIA —, nunca denylist do que exclui.** A doutrina
local já mede que guarda por lista falha pelo **vocabulário**, e denylist falha **aberta**: um arquivo novo
de biografia entra no pacote por padrão. Allowlist falha fechada.

Medido nesta sessão, para dimensionar: ≈ **138 mil linhas** de framework distribuível contra ≈ **151 mil** de
autobiografia e projeto. O que "sobra" é maior que o que viaja — não é resíduo a varrer.

## NÃO-VERIFICADOS

- **Licença (`Q_LICENCA_APOS_MIT_JA_CONCEDIDA`):** a fonte fechou — PolyForm Internal Use é a que cabe no
  caso ("usa e modifica internamente, não distribui, não sublicencia"). A **decisão** não: MIT já saiu, não
  retroage, e o corpus é majoritariamente **prosa**, para a qual licença de software é a forma errada (a
  thoughtbot usa Creative Commons no playbook).
- **Marca (`Q_MARCA_ONION_TITULARIDADE_NAO_MEDIDA`):** nada foi medido sobre titularidade ou registro do
  nome "Onion". A licença apenas **não concede**; ela não protege.
- **Fronteira executável (`Q_FRONTEIRA_EXECUTAVEL_NO_ADOPT`):** separação física no tronco ou allowlist no
  gerador — as duas com precedente, nenhuma implementada.
- **Plugin como veículo (`Q_VEICULO_E_CANAL_DE_UPDATE_SAO_UM_PAR`):** o canal de plugin entrega **consumo**
  (install ≠ adopt), e a pergunta pede um repo que o cliente **evolui**. Marketplace privado e distribuição
  por organização existem, mas resolvem privacidade, não evolução.
- **O mecanismo próprio não foi medido:** nenhuma claim tocou o `/meta:adopt --update` nem o
  `vendor-branch.sh` — e a memória já os registra como **papel-cego**. O Elenxo é explícito: antes de nova
  rodada externa, **medir o que já existe aqui**.
- **A fronteira em quem publica método:** as duas claims que tocariam o corte doutrina × vida interna
  **caíram na ancoragem** por exaustividade indevida.

## valeu-a-pena

**≈ 39 mil tokens por nó**, contra 291 mil da varredura larga na outra pergunta. Mas o que justifica a rodada
não é o preço: é que ela **derrubou três premissas** com as quais eu ia desenhar — a licença já concedida, o
precedente inexistente e a ausência de filtro. Qualquer proposta de veículo feita sem isso teria nascido
sobre chão falso.

## A medição do mecanismo próprio (2026-09-14) — e os três parafusos apertados

O Elenxo impôs: antes de nova fonte externa, **medir o que já existe aqui**. Medido, e o resultado
derruba a terceira premissa da seção anterior.

**A fronteira de diretório JÁ estava resolvida** (`E_ADOPT_JA_E_ALLOWLIST_MEDIDO`). O `/meta:adopt` não
copia árvore: usa **allowlist de 11 pathspecs** mais `git archive HEAD` — duas barreiras em série.
Rodado num diretório vazio: **680 arquivos, zero biografia**. O `grep -c exclude` que eu citei como
prova de ausência de filtro deu zero **porque o desenho não usa denylist** — exatamente o que a rodada
recomendou.

**Eram quatro cópias da mesma lista, não três** (`E_QUATRO_COPIAS_DA_MESMA_LISTA_DUAS_DRIFTADAS`), e as
**duas guardas** estavam defasadas do transporte: `.claude/rules` e `.claude/workflows` viajavam sem ser
varridos por nome de cliente nem por link core-privado.

**O que vaza hoje vaza dentro de diretório permitido** (`E_BASELINES_SAO_INDICE_DO_REPO_PRIVADO_E_JA_CHEGARAM`):
os `*-baseline.txt` são índice nominal do repo privado — 32 paths, 5 deles do grafo pessoal do maestro —
e **já chegaram a 5 adotantes**. Não são link, então a REGRA 45 (Link vendorizado não aponta caminho
core-privado, com catraca) não os vê.

**E o `roles.yaml` não resolvia isto** (`E_ROLES_YAML_E_OUTRA_GRANULARIDADE`): ele mapeia papel para
plugins e comandos; o corte da consultoria é papel para **pathspec**. Eu tinha proposto ligá-lo ao
`adopt` como se resolvesse.

**Os três parafusos, apertados neste PR:**

1. **SSOT única** em `.claude/utils/adopt/vendor-manifest.sh`, consumida pelas quatro superfícies. As duas
   guardas passam a **derivar** as raízes do transporte, com fail-loud se a SSOT não responder.
2. **A fronteira desceu do diretório ao arquivo:** `--stub-baselines` cura na **emissão** (o passivo do
   core não vira dívida do cliente) e `--check-bundle` reprova se um baseline emitido citar caminho
   privado.
3. **`--role` nasce no transporte** (`adopted|hub|standalone`), com papel desconhecido falhando alto. O
   corte por papel — tirar a meta-fábrica do `standalone`, como o `onion-standalone` provou — fica
   **nomeado e não implementado**: é execução, não decisão.

Bancada: família `vendor_manifest` com 8 casos, incluindo mutante que reprova quando a lista literal volta.

## O que o maestro selou em 2026-09-14

Quatro perguntas foram apresentadas com opções e recomendação; as quatro voltaram decididas.

| Selo | Nó | O que ficou |
|---|---|---|
| **Veículo** | `D_VEICULO_STANDALONE_PUBLICO_MAIS_ADOPT` | `onion-standalone` **público** como vitrine **mais** o `/meta:adopt` rodando no repo **do cliente** — com a ressalva dele: *"com todos os comandos e funcionalidades do core atual"*. O reenquadramento que sustenta: `/meta:adopt` com `onion/vendor` **já é** fork-com-atualização, e melhor que template — o update chega por merge e a customização do cliente vira **conflito git real**. |
| **Corte** | `D_CORTE_E_TUDO_INCLUSIVE_META_FABRICA` | Viaja **tudo, inclusive a meta-fábrica**. A consequência está nomeada e assumida: o standalone é público, logo isto publica a máquina de fabricar Onion para qualquer um. Defensável pela doutrina da casa — o fosso é o mecanismo verificável, o dogfood e a autobiografia, não o código. A evidência que fechou: a maquinaria **já** transfere (9 de 11 adotantes) e a prática **não** (grafo autoral 3 de 7), então mandar só o motor repete o que não pegou. |
| **Licença** | `D_LICENCA_DUAL_CODIGO_MIT_DOUTRINA_CC` | **Dual**: código segue MIT (a concessão já saiu e não retroage); método sob **CC BY-NC 4.0** — `LICENSE-DOCS` neste PR, com a tabela no README. Precedente medido: a thoughtbot licencia o playbook assim, pela mesma razão declarada. |
| **Marca** | `D_MARCA_MEDIR_ANTES_DE_DECIDIR` → `Q_MARCA_DEPOSITAR_CLASSE_42_AGORA` | Medir antes. A rodada rodou: **R$ 880,00, ou R$ 440,00 com CNPJ ME/EPP/MEI**, classe 42, especificação pré-aprovada — o preço mais baixo que converte o frágil direito de precedência (art. 129 §1º) em propriedade oponível. **Não selado**, e a razão é honesta: a colidência real de "onion" na base do INPI **não foi medida** — a busca exige sessão de navegador. São 10 minutos do maestro em `busca.inpi.gov.br/pePI`. |

E dois selos derivados: `D_LIMPAR_BASELINES_NO_PROXIMO_UPDATE` (os 5 adotantes se curam no próximo
`--update` de cada, não em cinco PRs hoje — gatilho de reabertura: algum deles virar público ou ganhar
terceiros) e `D_SCRUB_POR_FORMA_CURADO_ANTES_DE_PUBLICAR`, abaixo.

## O vazamento que a decisão de publicar encontrou

Medir antes de publicar achou **nome comercial de um cliente real de PoC em dois arquivos que viajam para
todo adotante** (`E_VAZAMENTO_REAL_DE_CLIENTE_NA_SUPERFICIE_QUE_VIAJA`). A REGRA 36 (Superfície VENDORIZADA
sem nome comercial de cliente) nunca cobrou, e a razão é estrutural: ela deriva os termos do `members.yaml`,
então **cliente que nunca foi registrado é invisível para ela**. É a classe
`guarda-por-lista-falha-pelo-vocabulário` — em guarda de lista o defeito dominante é o vocabulário, não a
lógica.

O nome saiu do texto no mesmo PR, e a guarda passou a asserir **forma**: `vendor-scrub-form-check.sh` pega
ampersand corporativo (com um lado de 2+ caracteres, o que já exclui M&A e Q&A) e âncora de contexto
(`PoC`/`cliente`/`adotante`/`empresa` seguida de nome próprio). Forma gera **candidato**, nunca veredito: o
legítimo vai para um baseline que **só encolhe**, candidato novo é HARD. **Teto declarado:** nome comercial
sem ampersand e sem âncora continua invisível — alargar o padrão mataria a guarda de falso-positivo.

## Backlog

1. **Levar o `onion-standalone` público ao core atual completo** — é o veículo selado, e a publicação em si é
   ato do maestro (outward-facing).
2. **Implementar o corte por papel** no `--role standalone`, agora que o transporte tem papel — mesmo com o
   corte selado em "tudo", o mecanismo continua existindo para quem quiser menos.
3. **Busca de colidência no INPI** (10 minutos do maestro) — é a condição declarada de
   `Q_MARCA_DEPOSITAR_CLASSE_42_AGORA`.
4. ~~Medir o mecanismo próprio~~ · ~~desenhar a allowlist executável~~ · ~~o maestro decide as quatro
   perguntas~~ — **feitos**: a medição virou a SSOT `vendor-manifest.sh`, a allowlist é ela, e as quatro
   perguntas estão na tabela acima.
