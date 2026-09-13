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

> **Projeção** do grafo (35 nós, 66 arestas, radar exit 0). Rodada de **primárias nomeadas** — o modo que
> nasceu nesta mesma sessão. Nada aqui está selado: **cinco perguntas** esperam o maestro.
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

## Backlog

1. **Medir o mecanismo próprio** (`/meta:adopt --update`, `vendor-branch.sh`): o que já copia, o que já
   exclui, e o que ele faria hoje com `.claude/diary` e `members.yaml`.
2. **Desenhar a allowlist executável**, com caso de bancada que reprove quando um arquivo novo de biografia
   entra no pacote.
3. **O maestro decide** as quatro perguntas abertas: fronteira, licença depois do MIT, marca, e o par
   veículo + canal de atualização.
