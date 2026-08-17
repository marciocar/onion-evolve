---
description: >
  Conduz o maestro por um MOVIMENTO da família Onion — criar um repo p/ cliente, adotar um projeto,
  promover a hub, atualizar um adotado. É a face "ajuda a FAZER" da Condução (par da onion-onboarding,
  "ajuda a CONHECER"). Ative quando o maestro quer EXECUTAR um desses e quer ser guiado (ex.: "cria um
  repo pro cliente", "adota o projeto X", "promove a hub", "atualiza o X"), mesmo sem dizer "wizard". NÃO é
  para ensinar/orientar (isso é onboarding) nem para operações fora da topologia.
allowed-tools: AskUserQuestion Read Bash(bash .claude/utils/wizard/*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/onion-version.sh*) Bash(git rev-parse*) Skill
---

# Onion Wizard — a Condução guiada (ajuda a FAZER)

Front-end **conversacional e resumível** dos movimentos da família. Colhe a intenção, mostra o preview e
roteia para o **procedimento real** — nunca reimplementa o que o comando faz.

## A lei (anti-dessincronização)

**Você PROJETA da fonte única, nunca hand-lista os movimentos.** As transições disponíveis vêm do KG-topologia
via `bash .claude/utils/wizard/topology-projection.sh` (TSV: `status  id  trace  label`). Se a topologia mudar
(transição nova, uma gated abrir), você reflete **sozinho** — sem editar esta skill. É fonte≠derivação; a
REGRA 41 garante que cada `trace` ativo é um procedimento que existe. Se o helper degradar (sem python), peça
o movimento à mão — nunca invente a lista.

## O fluxo (progressive disclosure — 3 críticas + avançado)

### 1. Orient (contexto — sem perguntar ainda)
- Papel deste repo: `bash ${CLAUDE_PLUGIN_ROOT}/validation/onion-version.sh | grep '^role:'` (`source` | `hub` | `adopted`).
- Movimentos ativos: as linhas `confirmed` da projeção. Os `open` são **gated** ("em breve" — não execute;
  aponte o caminho manual da doutrina se perguntado).
- **Regra de validade por papel** (diga, não deixe o maestro descobrir errando):
  `source` → cria/adota/atualiza · `hub` → adota/atualiza/promove-N/A · `adopted` puro → **só** `promote-hub`
  primeiro (o PASSO 0 barra adopted; explique o porquê, não só bloqueie).

### 2. Escolher o movimento (AskUserQuestion)
Uma pergunta, opções = as transições **ativas E válidas** para o papel atual (rótulo curto do `label`).
Recomende a mais provável pelo contexto do pedido, com o **motivo** (Elenxo: mostre o raciocínio).

### 3. Colher a intenção (AskUserQuestion, contextual ao movimento)
Só as críticas do movimento escolhido — o resto é "avançado", perguntado só se pedido:
- **adopt/create:** alvo (path/url) · modo (`greenfield` novo · `legacy` com código · `regulated` dado sensível) · escopo (cheio/compliance?).
- **promote-hub:** nenhuma (é o repo atual) — só confirma "esta empresa vai adotar os próprios projetos?".
- **update:** alvo já adotado.

### 4. Dry-run (preview — o gate)
**Sempre** antes de tocar em nada. Para adopt/create/update, roteie com `--dry-run` primeiro e mostre o diff.
Never-clobber é a doutrina; o preview é a confirmação.

### 5. Executar (rotear ao procedimento — o SCAFFOLD)
Após confirmação explícita, **execute o `trace` da transição**, não uma cópia dele:
- `trace` = `.claude/commands/meta/adopt.md` → invoque `/meta:adopt` (via Skill) com os args colhidos
  (create/adopt/update), ou o bloco `--promote-hub` para a promoção.
- O comando faz as fases (cópia/config/stamp/commit durável). Você é o intake guiado, ele é o motor.

## Resumível (STATE.md)
Movimentos longos (adopt faseado) são retomáveis — o próprio `/meta:adopt` já checkpointa em
`.claude/sessions/adopt-<slug>/STATE.md`. Não duplique: delegue e deixe o comando retomar.

## Elenxo — auto-refutável e poroso

> *Elenxo* é o método do Onion: a fonte-única que **se refuta em público** para se superar (5 etapas
> obrigatórias). Definição completa:
> [`onion-elenxo-doctrine.md`](${CLAUDE_PLUGIN_ROOT}/kb/onion-elenxo-doctrine.md).
- **Mostre o raciocínio** de cada recomendação (por que `hub` e não `standalone`) — o maestro pega um erro seu.
- **Admita a fronteira:** o que é gated (convite/transferência/desacople) você **não** executa — diga isso e
  aponte o caminho manual, sem fingir que faz.
- **Dogfood:** para verificar uma adoção, o certo é um **clone fresco** rodando o gate — não o working dir.
