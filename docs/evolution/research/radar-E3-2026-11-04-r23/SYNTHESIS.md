---
title: Radar E3 r23 — o delta do Claude Code 2.1.318 contra o Onion
date: 2026-11-04
kg: docs/evolution/research/radar-E3-2026-11-04-r23/radar-E3-2026-11-04-r23.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão do core, com um juiz subagente independente)"
tokens: 608654
agents: 2
duration_min: 25   # do esqueleto (13:18 UTC) ao fim da aplicação, pelos carimbos dos arquivos
review_after: 2026-12-04
type: research
mode: cc-update
---

# Radar E3 r23 — o delta do Claude Code 2.1.318

Rodada 23 do radar do Claude Code (eixo E3 do radar de mundo: a medição do que cada versão nova do Claude Code muda no Onion).

**Versões:** a baseline estava na 2.1.317; o disco e o processo estão na 2.1.318. O delta tem uma versão,
com 84 itens, copiados byte a byte em `data/2.1.318.txt` (diff contra o CHANGELOG oficial vazio,
re-medido em 2026-11-04). O grafo tem 24 nós: 2 do esqueleto, 16 da rodada, 1 nó novo de omissão e 5 superações do juiz.

## O que toca a casa (medido no vivo)

- **Quem serve está atrás.** O host está na 2.1.318, o revisor do CI na 2.1.314 (pin v1.0.265, sha
  `6d5ae526`) e o bridge na 2.1.310 (SDK 0.3.310), sete versões do SDK publicadas atrás no npm (seis seções
  do CHANGELOG). A v1.0.268 da action (sha `c0949c50`) instala o CLI 2.1.318. Ação proposta:
  `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_318_E_PIN_DO_REVISOR_PARA_V1_0_268_1104`. O deploy do bridge é do maestro.
- **As correções para quem roda sem terminal não chegam ao `/chat`.** Três itens da 2.1.318 tratam do
  arquivo de estado do usuário em homes que só rodam o CLI sem terminal: o arquivo inválido deixa de ser
  trocado pelo padrão e passa a impedir o início, a limpeza guarda um backup, e o arquivo deixa de ser
  reescrito a cada run. É o retrato das homes de chat do bridge (`ops/chat-runner.sh` l.363 e l.634), mas o
  binário delas é o 2.1.310 do SDK. Vai junto com a subida do SDK.
- **Processos em binário apagado e o daemon de fundo.** Seis processos da conta do maestro no host rodam
  binários que a limpeza de versões já apagou: quatro reservas de dois `claude daemon run` (2.1.312 e 2.1.314),
  uma conversa na 2.1.312 e a visão `claude agents` na 2.1.314. As reservas têm a versão como nome de processo,
  e por isso o `pgrep -x claude` não as vê. O ator do item do `spawn ENOENT` é o daemon de fundo, que já roda a
  2.1.318 e recebe a correção. O `remoteControlAtStartup` liga o Remote Control na sessão interativa, que não é
  host `claude remote-control`.
- **A receita de reinício é `claude --continue`.** O hook `session-version-drift.sh` (l.45), o censo de
  frescor e a REGRA 65 (Radar de mundo com baseline DATADA por eixo) mandam reiniciar por `--continue`. De
  2.1.314 a 2.1.317 ele podia perder a conversa anterior depois de uma chamada de ferramenta malformada. Quem
  reinicia hoje relança a 2.1.318, que corrige; a única conversa viva na janela da regressão é um `--resume` na
  2.1.316. Ação proposta: `Q_CENSO_DE_SESSOES_EM_BINARIO_DELETADO_1104`: o hook só avisa a própria sessão, e o
  censo tem de achar os processos pelo executável, não pelo nome.
- **O fim do login ficou legível.** `claude auth status` agora traz `loginExpiresAt`; no host o login
  claude.ai acaba em 22 dias, e nenhuma peça do core lê esse prazo. O revisor do CI usa chave de API, então não
  é alcançado. Ação proposta: `Q_CENSO_AVISA_O_FIM_DO_LOGIN_1104`.
- **Retomar workflow não paga de novo.** Até a 2.1.317, retomar um workflow depois do limite de uso re-rodava
  agentes já concluídos, o contrário do que a skill de orquestração promete (`SKILL.md` l.69 e l.317). A
  2.1.318 torna a promessa verdadeira nesse caso. Sem ação.
- **Subagente em fundo e o corte de 3 minutos.** O corte de 180 s já valia na casa por uma flag do servidor:
  113 comandos de subagente movidos ao fundo de 27 a 29/10 (2.1.311 e 2.1.312) e 34 hoje. Na 2.1.318 ele vira
  constante para todos os provedores e só desliga com cache de prompt off ou de 1 h; os subagentes da casa usam
  cache de 5 min. O preâmbulo do agente de execução manda esperar por PID (l.26), mas não nomeia o corte. Ação
  proposta: `Q_PREAMBULO_NOMEIA_O_CORTE_DE_3_MIN_1104`.
- **O `plugin validate` não muda o gate.** A correção é para catálogo de nome próprio; o do core é o
  `marketplace.json` padrão, e `claude plugin validate --strict .` segue passando.
- **O `claude plugin` e o refresh de token.** Até a 2.1.317 os comandos `claude plugin` podiam sair antes de
  salvar um refresh de token lento e deslogar a próxima execução. A casa os ensina aos adotantes nos READMEs
  gerados (`marketplace-readme.sh` l.40 e l.52-56, `plugin-readme.sh` l.84) e roda o `validate` em laço na
  publicação (`publish-door.sh` l.885). Impacto baixo; sem ação.
- **A extensão do VS Code não sobe mais sozinha.** Ela segue na 2.1.306, onze versões publicadas atrás, e
  desde a 2.1.318 o CLI aberto no terminal do editor não a instala nem a atualiza. Ação proposta:
  `Q_SUBIR_A_EXTENSAO_DO_VSCODE_PELO_EDITOR_1104`.
- **Sem superfície no core:** mods (effort no fork, registro da resposta, `prompt.submit`, `turn.step`), o hook
  `Setup` (os 26 hooks do core, 20 sem `onFailure`, estão em 10 eventos, nenhum `Setup`), `deniedMcpServers`,
  `allowedProviders`, `claude mcp add`/`remove`, comandos que só o Claude invoca (0 no core), runner, gateway,
  nuvem, Claude Tag e Code Review. O fim da correção da 2.1.288 (o pensamento anterior ao retomar conversa
  iniciada na 2.1.286 ou antes) foi medido sem impacto: as três sessões retomadas vivas começaram na 2.1.303,
  2.1.308 e 2.1.311.
- **Guarda de deriva de binário:** `cited_directive` rc 0 na 2.1.318.

## Juiz

Subagente opus independente, não-fork, com critérios pré-registrados (`data/judge-verdicts.json`, CU1 a CU6):
22 veredictos, **17 SUSTENTA, 4 EXAGERA, 1 REPROVA**, 5 superações, `judge-verdict-check` rc 0 e nenhuma
reprovação recusada. As cópias e as citações batem byte a byte com o CHANGELOG.

- **Exageros corrigidos:**
  - o nó do binário apagado, reancorado no daemon de fundo: seis processos, não dois;
  - a dica do `--continue`: o processo na 2.1.314 é o `claude agents`;
  - a pergunta do censo: achar os processos pelo executável;
  - o corte de 3 minutos, que já valia por flag do servidor, medido nos transcripts.
- **A reprovação:** omissões do delta. O daemon de fundo (l.24) entrou no nó do binário apagado, o `claude
  plugin` e o refresh de token (l.14) ganhou nó, e o fim da correção da 2.1.288 (l.66) foi medido sem impacto.

Cada superação virou nó `C_SUPERACAO_20261104_…` com aresta TRACES_TO ao nó superado.

**Aufhebung:** SUPERSEDES de quatro nós da r22 (a rodada 22 do radar do Claude Code, de 2026-11-03),
confirmados pelo juiz no CU4: as versões de quem serve, a pergunta da subida (alvo velho), a extensão do VS
Code e a guarda de deriva. Os demais nós da r22 seguem valendo.

## NÃO-VERIFICADOS

- A perda de conversa pelo `--continue` (regressão da 2.1.314): não reproduzida no core.
- A duração do pre-commit e da bancada cheia; também se a sonda de tarefas de fundo enxerga um comando movido
  ao fundo dentro de um subagente.
- Se o daemon reaproveita ou descarta as reservas pré-lançadas antes da subida.
- Se o `claude plugin validate` renova token.
- Os subagentes que param em vez de trocar de modelo quando a mensagem é sinalizada e a opção é «Ask each time»:
  a chave dessa opção não foi achada nos settings; o core tem hooks PreModelSwitch e PostModelSwitch, sem caso
  reproduzido.
- A compactação ociosa que trocava a conversa por uma resposta que não era resumo: o core tem o hook PreCompact,
  sem caso reproduzido.
- Os comandos personalizados que falham e não imprimiam nada no `claude -p` e no SDK: o revisor do CI usa
  prompt, não comando; o `/chat` do bridge não foi medido.
- O erro de ferramenta MCP chamada antes de carregar, que agora devolve o schema: sem `.mcp.json` no core; não
  exercitado com os conectores do host.
- Os itens de rede compartilhada e de login de outra máquina na mesma home (`Not logged in`, settings
  perdidos): o host roda várias sessões na mesma home, mas sem home de rede; nenhum caso medido.
- Se alguma home de chat do bridge já teve o arquivo de estado do usuário inválido.
- O aviso em stderr do `claude -p` 10 dias antes do fim do login: nenhum `claude -p` em texto achado no core;
  não exercitado.

## Valeu a pena

24 nós; quatro tarefas novas propostas e uma que supera a subida da r22. O achado de mais peso veio do juiz: o
corte de 3 minutos dos subagentes em fundo não é novo na casa (147 comandos já movidos ao fundo), e o preâmbulo
não o nomeia. O custo em tokens é somado pelo coordenador.
