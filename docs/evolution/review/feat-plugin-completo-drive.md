---
title: "Resíduo da passada adversarial — a condução de plano-grafo viaja no plugin"
date: 2026-09-06
branch: feat/plugin-completo-drive
reviewed_diff_sha256: 62b0aa45769079cd3166afe397946cd46bb96297fb44266e50b8d0ddca6c7689
findings_total: 22
findings_real: 20
tokens: 428117
duration_min: 11
verdict: REPROVADO-E-CURADO
kg: docs/onion/graph/onion-plugin-publication-2026-08.kg.yaml
---

# Resíduo da REGRA 56 — três revisores adversariais REPROVARAM o PR, e o que isso comprou

Três workers adversariais (opus, mandato de REFUTAR, default REPROVADO na dúvida) atacaram lentes
diferentes do mesmo diff: **o predicado**, **o porte ao plugin** e **a doutrina**. Os três voltaram
**REPROVADO**. O gate mecânico estava **verde** (lint 0 HARD, bancada 1063/0) o tempo inteiro — é a
demonstração mais limpa que esta sessão produziu de *"lint-verde ≠ pronto"*, e ela caiu justamente
sobre o PR que publica a doutrina que diz isso.

## O achado que sozinho justificava a passada

**Os motores empacotados estavam NASCIDOS MORTOS** — e um deles já estava assim em `main`.

A reescrita PATH-PORTABILITY do assembler troca `.claude/validation/x.sh` por
`${CLAUDE_PLUGIN_ROOT}/validation/x.sh`. Em markdown isso é certo (o Claude Code substitui a variável
antes de o comando rodar). Dentro de um `.sh` é **expansão de shell em runtime** — e o ambiente do
Bash tool **não exporta essa variável**:

```
$ echo "CLAUDE_PLUGIN_ROOT=[${CLAUDE_PLUGIN_ROOT:-<UNSET>}]"
CLAUDE_PLUGIN_ROOT=[<UNSET>]
$ env -u CLAUDE_PLUGIN_ROOT bash plugins/onion/validation/kg-backlog-project.sh --check
plugins/onion/validation/kg-backlog-project.sh: line 43: CLAUDE_PLUGIN_ROOT: unbound variable
```

`kg-backlog-project.sh` está publicado assim **desde que entrou no bundle**. Meu porte replicaria a
classe mais duas vezes. **A minha "prova por execução" tinha exportado a variável à mão** — medi no
caminho que eu uso, não no que o consumidor usa (`testar-no-caminho-errado-e-nao-testar`).

**Cura no ASSEMBLER, não nos três artefatos:** todo `.sh` empacotado que cita a variável recebe, após
o shebang, `: "${CLAUDE_PLUGIN_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"` — resolve a
raiz pelo próprio arquivo, respeita a variável quando ela de fato vem do ambiente (hooks), e a
profundidade do `../` é calculada por arquivo. **15/15 scripts empacotados agora sobrevivem.**

**Cura estrutural do MECANISMO** (o que impede a volta): família nova `plugin_runtime`, a primeira
desta bancada que executa a **cópia empacotada** num host sintético sem `.claude/` do Onion. Era
`bancada-espelha-o-runner` invertido — a bancada espelhava o runner do CORE e nunca o do CONSUMIDOR.

## O predicado de selo: sete caminhos de AUTO indevido, medidos

A 1ª versão passava numa bancada de 8 casos. O revisor mediu **sete** formas de obter `AUTO` sobre um
nó que o maestro selou:

| ataque | por que passava |
|---|---|
| `id:` entre aspas na base | parser regex sobre TEXTO |
| aresta REFUTES **forjada dentro de um `label: \|`** | idem — varria o arquivo inteiro |
| `verified_at`/`verified_against` citados em bloco literal | idem |
| grafo **renomeado** / nó **movido** entre grafos | busca presa a UM path |
| clone **raso** (`--depth 1`) | história truncada "prova" que o nó é novo |
| `origin/main` local **defasado** | ref local tratado como estado do remoto |
| `--base` sem valor | `shift 2` sem aridade ⇒ **laço infinito mudo** |

**Cura estrutural, não extensão de lista:** o grafo passou a ser lido por **PyYAML** (estrutura, não
texto — mata os três primeiros de uma vez); a precondição (1) varre **todos** os `*.kg.yaml` da base,
árvore **e** história; repo raso e base não-provada-fresca **param**; o parser de flags valida aridade.

A bancada foi de **8 para 19 casos, 18 negativos**. Os dois mutantes que o revisor mostrou
**sobrevivendo** (apagar a varredura da árvore; aceitar qualquer `edge_type`) agora morrem — o
primeiro exigiu um caso desenhado para isolá-lo (`(k3)`: id que só existiu **entre aspas** na base,
onde `git log -S` é cego por construção e só a leitura YAML da árvore acusa).

E a família nova nasceu **vacuamente verde**: o `bash "${f}"` dentro do `while` comia o stdin do laço
e testou **2 de 15** scripts declarando aprovação. Só a contagem impressa e conferida contra o
`grep -rl` pegou. Cura: `</dev/null` + a cobertura virou asserção.

## A doutrina prometia o que o código não entrega

- **"Falta uma ⇒ PARA" era falso para a 4ª precondição.** O script nunca lê o `STATE.md`; faltando a
  (4) ele sai **0** e apenas imprime um lembrete. A KB — que é a SSOT e a cópia que viaja — afirmava
  que o predicado decidia as quatro. **É a metade humana que faz o maestro VER o flip.** Reescrito com
  uma tabela explícita de o-que-é-mecânico, e `exit 0` agora diz *"dispensa selo SEPARADO"*, não
  *"selado"*.
- **O teto era otimista.** Ficaram **nomeadas** as frestas que sobrevivem: **PR empilhado** (a base é
  `origin/main`; um nó já revisado num PR aberto e derrubado no PR de cima sai AUTO — quem empilha
  passa `--base`), e a **(2) não separa medição de opinião** (`verified_against: "eu pensei melhor"`
  passa; é auto-atestação de quem quer o AUTO).
- **"A revisão do PR é o selo" não se sustenta nesta casa** — o gate de PR é um revisor *automático e
  adversarial*, não o maestro. Corrigido: o selo é o **merge**, e é a linha do `STATE.md` que põe o
  flip diante dele.
- **Contagem errada na justificativa:** eu escrevi "três refutações no mesmo dia"; o grafo tem **duas**
  verificáveis. Corrigido para o que se mede.
- **O contra-argumento mais forte foi incorporado, não descartado:** se o nó nasceu no PR, ele é
  **rascunho do driver**, e a saída normal é **corrigir o rascunho** — Aufhebung preserva posição que a
  *casa* sustentou, não erro de vinte minutos de quem está escrevendo. Isso virou o **caminho
  preferido** no topo do §4.1; a exceção ficou para quando a refutação carrega método que vale guardar.
- **Sincronia:** a tabela de vereditos do `/meta:kg-freshness` também ganhou a exceção — cópia
  não-atualizada de tabela é a classe "tabela de doutrina que mente" que esta casa já pagou.

## O porte ao plugin, além do achado principal

- **Refs mortas no consumidor:** a KB `onion-kg-ontology-hierarchy` passou a **viajar** (era citada
  como fonte da "honestidade declarada" do realign e não estava no bundle); as demais (`ADR`,
  fixtures, `fios-abertos`, bancada) foram marcadas **core-only** em vez de fingirem resolver.
- **O default dos motores é o SSOT privado do core.** Num host instalado, `realign` sem argumento
  falhava com "grafo ausente" e nada mais. A mensagem agora nomeia que aquilo é *só o default do core*
  e ensina `git ls-files '*.kg.yaml'`; a prosa do comando inverteu a ordem (o caminho normal é passar
  o grafo **deste** repo).
- **A justificativa da exclusão do `/meta:kg-inbox` estava PARCIALMENTE FALSA — e eu a havia selado
  como nó "medido".** Eu escrevi que "o produtor da fila vive em `ops/`, logo ninguém alimenta"; o
  próprio comando, curado um dia antes, diz que num repo adotado **a proposta nasce à mão** e que a
  ausência do cabeçalho **nunca** é motivo de rejeição. O bloqueador real é mecânico e outro: o
  `allowed-tools` cita `.claude/utils/adopt/starter-kg-inbox.sh`, caminho de meta-fábrica barrado pela
  **REGRA 61 (Fronteira de MOAT: manifesto de plugin publicável não vaza meta-fábrica nem grafo
  privado)**, que ficaria **nu** no bundle e cai na classe ALLOWED-TOOLS da **REGRA 74 (Caminho
  `.claude/` NU dentro de plugin só resolve no core, com catraca)**. **A exclusão estava certa; o
  argumento estava errado** — e a diferença importa para quem reabrir o fio. Nó corrigido **no lugar**
  (nunca esteve em `main`), que é o caminho preferido que o próprio §4.1 acabou de escrever.

## Achado lateral que fica aberto

Trocar o predicado para YAML real revelou que **4 `.kg.yaml` versionados são aceitos pelo `kg-radar` e
rejeitados pelo PyYAML** (aspas não escapadas em `label:`/`trace:`, um `\$` como escape). O radar
parseia texto; logo a "verdade" do corpus é a do awk, não a do YAML — e foi essa fresta que permitiu o
ataque da aresta forjada. Registrado como `Q_CORPUS_TEM_GRAFO_QUE_O_YAML_REJEITA` com gatilho nomeado.
No predicado, grafo ilegível vira leitura **degradada por texto**, que super-inclui e portanto erra
para o lado do **PARA**.

## Placar

| | antes | depois |
|---|---|---|
| casos da família `seal_exception` | 8 (7 negativos) | **19** (18 negativos) |
| mutantes sobreviventes | 2 | **0** |
| scripts empacotados que morrem sem a variável | **3** (1 já em `main`) | **0** (15/15 provados) |
| famílias que executam a cópia empacotada | **0** | 1 (`plugin_runtime`) |

**Veredito:** REPROVADO na 1ª passada, curado em 20 dos 22 achados. Os 2 não curados são frestas
**declaradas** no teto do §4.1 (PR empilhado; a (2) não julga se a medição ocorreu) — nomeadas em vez
de fechadas, porque fechá-las exige, respectivamente, saber o PR de baixo e ler a mente de quem
escreve o campo. É por isso que a 4ª precondição continua sendo do maestro.
