---
title: Radar E3 r20 — o delta do Claude Code 2.1.312 contra o Onion
date: 2026-10-28
kg: docs/evolution/research/radar-E3-2026-10-28-r20/radar-E3-2026-10-28-r20.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão, com um juiz subagente independente)"
tokens: 164048
agents: 1
duration_min: 35
review_after: 2026-11-27
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** `tokens` é só o juiz (164.048, 54 chamadas, 8,6 min, medidos pelo harness).
> Os tokens da rodada, que rodou como subagente da sessão, não ficaram expostos a ela. `agents: 1` é o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.312: 39 itens em 42 linhas. A baseline era 2.1.311, e disco e processo estão em 2.1.312.

- **Quem serve está atrás.** O /chat do bridge segue no SDK 0.3.310 (CLI embutido 2.1.310), duas versões atrás, então o
  delta da 2.1.311 e o da 2.1.312 **não chegam** a quem serve por ele.
- **O revisor subiu uma.** O revisor do CI foi para o pin v1.0.263 (CLI 2.1.311, commit `3892b25d7`), que era a metade do
  pin da SAC-259 (a tarefa de subir o SDK do bridge e o pin do revisor, aberta pela r19, a rodada anterior deste
  radar).
- **O que já está publicado:** o npm tem o SDK 0.3.312 (CLI 2.1.312), e a action tem a v1.0.264. Os 2 commits da v1.0.264
  só trocam versões e a descrição do input `plugins`, que o workflow da casa não usa.

O SDK do bridge vive num repo alheio, e o deploy dele é do maestro. Por isso nada foi subido, só registrado.

## O que toca a casa

- **Versões de quem serve** (`E_HOST_NA_2_1_312_BRIDGE_NA_2_1_310_REVISOR_NA_2_1_311_1028`). Ação proposta:
  `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_312_E_PIN_DO_REVISOR_PARA_V1_0_264_1028` (**SAC-261**, a tarefa de subir o SDK do bridge para 0.3.312 e o pin do revisor para v1.0.264). Ela substitui o alvo da
  SAC-259, que recebeu um comentário apontando para a nova.
- **Linha 9, comando com nome inválido** (`E_NOME_DE_COMANDO_FORA_DO_KEBAB_CARREGA_NA_2_1_312_1028`).
  - Antes da correção, um comando com nome inválido derrubava todos os outros e podia deixar `claude -p` sem saída.
  - O core tem quatro templates com sublinhado e os README fora do kebab-case. Todos carregam na 2.1.312.
  - Quem roda sem a correção, sem cabeça: o revisor do CI (2.1.311), no checkout do PR com os 166 comandos, e o bridge
    (2.1.310). Por isso o pin v1.0.264 deixa de ser só paridade.
  - Não está medido se a action ou o bridge carregam os comandos do projeto.
- **Linha 7, skills com `paths:` depois de um `cd`** (`E_SKILLS_COM_PATHS_E_O_CD_PARA_DENTRO_1028`).
  - O core tem duas skills com `paths:` casando `.claude/**`: `onion-patterns` e `onion-validation`.
  - Vistas do checkout principal, as 15 worktrees de agente trazem cada uma um `.claude/skills` próprio. Isso é a skill
    por diretório da linha 7, e ela aparece em duplicata.
  - O efeito não foi reproduzido.
- **Linha 6, o Write não sobrescreve arquivo grande lido pela metade**
  (`E_WRITE_NAO_SOBRESCREVE_ARQUIVO_GRANDE_LIDO_PELA_METADE_1028`).
  - A superfície é o `.claude/rules`, cuja maior regra tem 12.507 bytes.
  - Também são superfície os CLAUDE.md de 26.246 bytes das 15 worktrees, que contam como arquivo de subdiretório vistos do
    checkout principal.
  - O limiar de "muito grande" não é público.
- **Extensão do VS Code do host segue em 2.1.306** (`E_EXTENSAO_VSCODE_SEGUE_NA_2_1_306_1028`), seis versões atrás. Os
  itens de VS Code (linhas 28 e 29) não a alcançam. A pergunta da r19 (SAC-260, a tarefa de decidir se a extensão entra no censo de versões ou só sobe quando
  usada) segue de pé.
- **core.hooksPath absoluto: a 2.1.312 não muda nada** (`E_HOOKSPATH_SEGUE_ABSOLUTO_NA_2_1_312_1028`).
  - As issues 85039 e 88747 seguem abertas.
  - A worktree desta rodada regravou o `.git/config` com o valor absoluto.
  - O trampolim dos hooks de git segue sendo o que torna esse valor inofensivo.
- **Sem efeito no core, medido:**
  - **Linha 24**, o teto de 24 hooks de prompt e de agente: a casa só tem hooks `command`, todos com timeout de 5 s ou
    mais.
  - **Linha 25**, `autoCompactWindow`: o campo só aparece na allowlist de frontmatter, e nenhum agente o usa.
  - **Linha 21**, a troca automática por recusa para nomes não reconhecidos: a casa só usa ids reconhecidos, e a guarda
    de modelo decide pelo id e pela `source`.
  - **Linha 36**, Remote Control: a correção vale no host, onde toda sessão abre o canal do maestro, e nenhuma guarda lê
    esse estado.
  - **Sem superfície:** o gateway OIDC, o texto do limite de 5 horas (nenhuma guarda lê essa prosa), a telemetria,
    Bedrock e afins, o PDF do Read, `/verify`, Claude Tag e o Code Review gerenciado.
  - **Guarda de deriva de binário:** a `cited_directive` segue verde na 2.1.312.
- **Aufhebung:** três SUPERSEDES sobre a r19:
  - o nó das versões de quem serve;
  - a pergunta da subida, cujo alvo envelheceu;
  - o nó da extensão, que dizia "cinco versões atrás".

  E um SUPPORTS para a pergunta da extensão.

## Juiz

O juiz foi **independente**: um subagente `general-purpose`, modelo opus, effort high, não-fork, com mandato REFUTAR. Os
critérios CU1 a CU5 foram gravados antes do lançamento em `data/judge-verdicts.json`.

**Resultado: 15 SUSTENTA, 6 EXAGERA, 0 REPROVA**, com 6 superações. O `judge-verdict-check.sh` saiu com rc 0, sem
nenhuma recusa.

- **Cópia do CHANGELOG:** bate byte a byte com a oficial (`cmp` sem diferença), e as linhas citadas conferem.
- **EXAGERA nos nós:**
  - O `find` das skills excluiu as worktrees sem dizer por quê.
  - A varredura de ausência dizia "zero" para o `pdftoppm`, que existe como fixture da bancada.
  - A mesma varredura dizia "só" para o `oidc`, que aparece em 9 arquivos, entre eles o OIDC do revisor no CI.
  - O nó da extensão da r19 não foi superado, embora a distância relativa dele tenha caído.
- **EXAGERA por omissão:**
  - o Remote Control, que virou nó novo;
  - os CLAUDE.md das worktrees, absorvidos no nó do Write;
  - o revisor do CI como o modo sem cabeça da casa diante da linha 9, absorvido no nó do nome e na pergunta.
- **Superações:** cada uma virou um nó `C_SUPERACAO_20261028_*`, com `TRACES_TO` ao nó julgado.
- **Re-medição antes de aplicar:** a rodada re-mediu no vivo, antes de aplicar, as alegações centrais do juiz: as 15
  worktrees com skills e CLAUDE.md, a linha 12 do `.git/info/exclude`, a lista dos 9 arquivos com `oidc` e as duas chaves
  de Remote Control do settings de usuário.
- **Ressalva do juiz:** o intervalo de 1 ms entre a regravação do `.git/config` e a criação da worktree não se reproduziu
  (na dele foram 7 s). O nó foi reescrito sem o número.

## NÃO-VERIFICADOS

- **Linha 7:** se a descoberta de skills após `cd` muda algo na prática, e se o harness varre diretório ignorado por
  `.git/info/exclude` (as worktrees), com o efeito da duplicata.
- **Linha 6:** o limiar de "muito grande", que não está no CHANGELOG.
- **Linha 9:** o que o CLI considera nome inválido, e se a claude-code-action ou o bridge carregam os comandos do projeto.
- **Linha 8:** o resume no terminal. O maestro usa o terminal, mas a resposta perdida é rara e não foi medida.
- **Linha 30:** rotinas na nuvem com effort. Não se mediu se a casa tem rotinas agendadas.
- **Linhas sem superfície no core,** de tela, de nuvem e de VS Code (4, 5, 12 a 16, 18, 19, 23, 28, 29, 31 a 35): não
  foram medidas uma a uma.
- **Versão do CLI no runner do revisor:** só o pin a afirma, e o revisor está desligado.
