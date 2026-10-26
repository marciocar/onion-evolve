---
branch: research/codex-spikes-seal
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 02a46c590ec9c6ba1ec2c47ed9ff35641fa423673bd282a1253e23ee4093ddac
reviewed_code_sha256: aa561ead62ecb80bf2a2db38cb67f8cc86dd68baf888771a42dadeaef9fed351
findings_total: 9
findings_real: 8
tokens: 0
duration_min: 0
findings_fixed: 8
verdict: CORRIGIDO
elenxo: nao
reviewer: "a própria sessão que escreveu o diff (1 agente), conferindo cada nó contra evidence/ da curadoria"
nota: "tokens e duração não medidos (0). Passada da autora sobre o próprio diff, não revisor independente."
---

# Passada adversarial: `research/codex-spikes-seal`

## O que muda

O grafo `docs/evolution/research/codex-as-core-2026-10/codex-as-core-2026-10.kg.yaml` sobe de 62 para 80 nós, e a
`SYNTHESIS.md` ao lado é a projeção dele. O que entra:

- **9 evidências `E_SPIKE_*`**, conferidas contra `onion-curation@da53ec3` (os spikes S1, S2 e S3) e
  `onion-curation@bc30bce` (a emenda C);
- **6 perguntas com o teste que as fecha**, das quais uma já nasce superada;
- **2 vereditos por peça novos** e **1 recomendação nova**.

Pela Aufhebung, cinco nós ficaram `superseded`, cada um com aresta SUPERSEDES:

- `C_PIECE_HOOKS_DETERMINISTIC_BLOCK_MISSING_1026`;
- `C_PIECE_SKILLS_COMMANDS_UNJUDGED_1026`;
- `C_ELENXO_NOT_EQUIVALENT_NO_NEW_DOOR_YET_1026`;
- `E_OBJECAO_24_EXIT2_STATE_UNPROVEN_IN_0164`;
- `Q_CODEX_IGNORE_USER_CONFIG_LAYER_1026`.

Também foram regeneradas as projeções `docs/backlog.md` e `docs/onion/kg-read-index.tsv`.

Este PR leva ainda três selos de decisão do maestro, todos gravados pelo `kg-decide-seal.sh` e cada um com rc 0.
As respostas vieram do /meta:decide da sessão principal e foram repassadas a esta sessão; esta sessão não viu a
pergunta ao maestro.

- `Q_CODEX_RUNS_ONION_CORE_AS_NEW_DOOR_1026` passou a `done`: ainda não; curar e re-medir.
- `D_CODEX_HOOKSJSON_FIX_POR_PR_DO_CORE_1026` foi criado e liga a `E_SPIKE_S4_PORT_HOOKS_JSON_REJECTED_1026`. O
  TETO do grafo subiu de 80 para 81, com o nó declarado no cabeçalho.
- `D_SGE_PENDENTES_POS_UPDATE_76CCB2F8_1026` foi criado em `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml` e
  liga a `E_FORK_VS_AGENTE_NOVO_PAR_3_RESULTADO_1026`. Não há nó melhor sobre as pendências do sge.

## Achados

Cada um vem com o que foi conferido e o que foi feito.

1. **REAL, corrigido.** A falha aberta 2 aconteceu em 4 rodadas, não nas 2 que o relato cita.
   - Conferido: `runs/S1-3-c` tem `command_execution 'git push origin main'` com exit 0 ("Everything up-to-date").
     `runs/S1-3-w` tem `echo hello > MARKER.txt` com exit 0 e `marker=exists`.
   - Feito: o nó `E_SPIKE_FAILOPEN_IGNORE_USER_CONFIG_1026` diz 4 e diz que a forma JSON `deny` falha igual.
2. **REAL, corrigido.** "Remoto igual" não discrimina nas rodadas da emenda B.
   - Conferido: `remote_before = e41e40c` em todas as `runs-b`. Esse commit foi empurrado pelo `runs/S1-2-c` do 1º
     lote.
   - Feito: o nó do S1 declara que a prova do bloqueio do push é a ausência de `command_execution`, não o remoto.
3. **REAL, corrigido.** Há um rastro do veto que o relato omite.
   - Conferido: o `stderr.txt` das 9 rodadas que barraram traz `ERROR codex_core::tools::router: ... blocked by
     PreToolUse hook`.
   - Feito: nó `E_SPIKE_S1_BLOCK_SIGNAL_NOT_IN_RC_OR_JSON_1026`, que o trata como log e não como contrato.
4. **REAL, registrado.** O `permission_mode` recebido é `bypassPermissions` mesmo sob `workspace-write` com
   aprovação `never` (S1-1). Logo o campo não distingue o modo.
5. **REAL, declarado.** A emenda C não tem artefato para três pontos do relato.
   - Conferido: `runs-c` não tem `args.txt` nem cópia da configuração do usuário. O `S4-CTRL` não guardou o
     arquivo-sinal. E o RESULTS.md chama de "provável" e "não isolado" o que o pedido do coordenador afirmava como
     fato ("o próprio Codex gravou").
   - Feito: `E_SPIKE_PROJECT_TRUST_ONLY_PERSISTED_1026` ficou com confiança 0.6. Ele separa o que a evidência
     sustenta (nas S4 o `hooks.json` nem é lido, porque o mesmo arquivo malformado não dá erro de parse) do que é
     só relato. O que falta virou `Q_CODEX_PROJECT_TRUST_WHO_WRITES_1026`.
6. **REAL, corrigido.** A frase do fail-open na doc estava sendo lida como "vale também para os hooks gerenciados".
   - Conferido: o WebFetch devolveu a frase começando em reticências, dentro da seção dos hooks gerenciados.
   - Feito: o nó diz "sugere" e declara que o contexto completo não foi conferido. A peça de hooks deixou de
     afirmar isso.
7. **REAL, corrigido.** O contrato do kg-ssot reprovou duas vezes por forma.
   - Primeiro, o `provenance.method` sem o prefixo `medição:`.
   - Depois, um label com 285 caracteres, acima do teto de 280.
   - Os dois foram ajustados, e o contrato agora dá ✓.
8. **REAL, corrigido.** A pergunta sobre o `hooks.json` do porte nasceria aberta, mas a emenda C já a mediu.
   - Feito: ela foi trocada pela evidência `E_SPIKE_S4_PORT_HOOKS_JSON_REJECTED_1026`. A correção, que é do repo
     onion-codex, virou `Q_ONION_CODEX_HOOKS_JSON_FIX_IN_PORT_1026`.
   - Conferido: `hooks-A0.json` é idêntico ao `.codex/hooks.json` de `onion-codex@a216791`, e o erro de parse está
     no `--json` do `S4T-A0` e do `S4T-A1`.
9. **NÃO REAL.** Suspeita de que o S1-0 seria bloqueio do sandbox, e não hook pulado.
   - Conferido: o `deny.py` grava o stdin no `hook.log` antes de decidir, e o `hook.log` não existe no S1-0. A
     rodada S1-1 difere só pela flag `--dangerously-bypass-hook-trust` e disparou. Portanto o hook não foi
     invocado, e o sandbox só impediu a execução depois.

Também conferido, sem achado:

- **Ordem do pré-registro:** 257a1ee (20:21Z) < DIAG1 (20:37Z) < 027a89f (20:40Z) < runs-b (20:43Z) < 886cd6d
  (20:48Z); e 97fa177 (20:57Z) < 42defa7 (21:04Z).
- **Integridade:** o `SHA256SUMS` confere nos dois commits.
- **S3:** as linhas citadas do porte existem (`onion/SKILL.md` l.33, 34, 57 e 146; `engineer-start/SKILL.md`
  l.35), e o S3X tem 13 `command_execution`.
- **S2:** zero `file_change` e zero `command_execution`, e `marker2=absent`.
- **Comparação com o Claude Code:** só cita os nós do corpus (`E_PRETOOLUSE_BARRA_SOB_BYPASS`,
  `E_PROVA1_WORKSPACE_HOOK_RUNS_WITHOUT_BASH_1016`, `E_CONTRATO_DE_HOOKS_EXPLODIU`) e declara não medidas as
  condições das falhas 1 e 3.

## Mutantes

Não se aplica: o diff é de dados de grafo e de prosa, sem guarda nova. O que faz o papel do mutante são o radar
(`--integrity --schema`, exit 0, 80 nós e 111 arestas), o contrato (✓) e o `kg-machine-path-check` (0 acusações).
O contrato reprovou duas vezes antes de passar (achado 7), o que mostra que ele mordia este diff.

## Limites declarados

- A passada é da própria autora, sem revisor independente nem Elenxo de terceiro.
- As medições são da curadoria: uma versão do Codex, um modelo e uma rodada por caso. Este core não re-rodou o
  Codex.
- A sugestão de que o `CLAUDE.md` precisa de emenda fica fora do diff, para o maestro decidir. O texto que diz que
  o `exit 2` "não existe fora do Claude Code" fica parcialmente defasado pelo S1. Ela está registrada como aresta
  CONSTRAINS sobre `C_POSTURA_ACOPLAMENTO`.
