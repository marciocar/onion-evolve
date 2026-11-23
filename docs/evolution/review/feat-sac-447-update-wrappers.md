---
branch: feat/sac-447-update-wrappers
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 9f678cc5c50f51a12173b285d0c1f27f11aaa175afeb553cdedfbb190f1e0c80
reviewed_code_sha256: 648d6cd1a3140fd50efe881fcdff47193ad15227d58c52b21cfc20b39e4842a5
findings_total: 11
findings_real: 11
findings_blocking: 2
tokens: 185000
duration_min: 21
findings_fixed: 10
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador INDEPENDENTE (agente separado, brief sem a conclusão do condutor; rodou a bancada, 19 mutantes próprios e 10 cenários adversariais em cópias na pasta dele, sem tocar no repo da sessão do hub nem em serviço) REPROVOU com 2 bloqueios e 9 limites; o condutor curou 10 e declarou 1, re-rodou a bancada (44 → 68 casos) e a família do auto-teste com os mutantes"
nota: "tokens e duração são os do refutador (184.864 tokens, ~21 min de execução); a passada própria do condutor não foi medida. Depois da passada, o pré-voo do pr-finalize acusou produtor|grep -q (classe pipefail) em 3 vereditos; a cura troca o pipe por here-string ou arquivo, sem mudar a lógica, com a bancada (68) e o mutante da unit carregada re-rodados pelo condutor"
---

# Passada adversarial: `feat/sac-447-update-wrappers`

## O que muda

- `ops/update-persona-hub.sh` (novo, core-only): o update repetível da persona do Slack (`onion-slack-persona`) e do
  worker do hub (`onion-brain-hub`), no molde do `ops/update-bridge.sh`. Ensaio por padrão, `--apply`, `--restart`,
  conferência no boot da invocação nova, desfazer impresso. O worker passa a rodar numa worktree própria
  (`BRAIN_HUB_DIR=/home/marcio/worktrees/brain-granaai/hub-worker`), e o wrapper recusa subir sem ela, imprimindo o
  ato de migração do maestro.
- `ops/testing/update-persona-hub-selftest.sh` (novo): bancada com git de verdade em `/tmp` e systemd falso, 68 casos
  em 8 seções.
- `ops/moat-targets.tsv`: unit `onion-brain-hub`, o clone de código e a unit instalada apontam o wrapper; linha `ato`
  com `--apply,--restart`.
- `.claude/validation/lint-selftest.sh`: família `update_persona_hub` (a bancada com a contagem exata e 44 mutantes,
  cada um rodando só a seção do caso); `ops/testing/selftest-family-times.tsv` com a família.

## Achados

1. **BLOQUEIA, curado.** O desfazer impresso trazia `(npm ci --ignore-scripts em <clone> se o lock voltou)`: colado,
   o subshell roda `npm ci` na pasta de quem cola, e o `npm` ignora as palavras soltas (medido pelo refutador: rc 0 e o
   `node_modules` da pasta atual apagado). Cura: `(cd /home/marcio/onion-brain-hub-app && npm ci --ignore-scripts
   --no-audit --no-fund)`, incondicional depois do reset, no ensaio e no apply. Caso novo confere a forma.
2. **BLOQUEIA, curado.** A bancada tinha 44 casos e o lint 25 mutantes, mas 19 peças críticas sobreviviam a mutantes
   (npm ci falhando, religamento re-armado depois do npm ci, unit carregada com o `BRAIN_HUB_DIR` novo, as três
   checagens fixas da unit, worker inativo, `NRestarts` da persona, invocação nova do hub, a condição de código no
   alvo do NOOP, `cat-file`, formato do id, branch main). Cura: casos para cada uma (npm falso que falha, daemon-reload
   que não carrega, start sem invocação nova, um ramo por desvio de unit, NOOP com código atrás) e um mutante por peça
   no lint (44).
3. **LIMITE, curado.** A checagem da unit era lista de proibidos na coluna 0: ` ExecStartPre=+…` com espaço na frente
   e ` User=root` passavam (o systemd lê a linha). Cura: ALLOWLIST fechada de diretivas, no molde da do
   `slack-persona.sh`: linha com espaço na frente recusa, valores fixos para User, ExecStart, WorkingDirectory,
   grupos, diretórios; `Environment=` uma atribuição por linha, sem aspas, de nomes conhecidos (caso com
   `LD_PRELOAD`; o mutante que tira o filtro de nomes reprova). A unit real do repo
   (medida no clone servido) passa, e o `systemd-analyze verify` dela sai rc 0.
4. **LIMITE, curado.** `BRAIN_HUB_DIR` podia vir duas vezes (`Environment="A=1" "BRAIN_HUB_DIR=…"`), e no systemd a
   última vence. Cura: a allowlist recusa aspas e conta o nome (uma vez só); dois casos.
5. **LIMITE, curado.** O `systemd-analyze verify` rodava depois do stop: a reprovação deixava código novo com a unit
   antiga no ar. Cura: a unit gerada passa pela allowlist e pelo verify ANTES de parar qualquer coisa, no ensaio
   também; o caso confere que nada foi parado nem trocado.
6. **LIMITE, curado.** Um NOOP que não se prova (crash antigo, `NRestarts > 0`, journal rotacionado) travava o wrapper
   sem saída. Cura: `--restart` (o `--apply` que religa em dia), como o do `update-bridge.sh`; a recusa do NOOP aponta
   para ele. Casos para hub e persona.
7. **LIMITE, curado.** Reflog expirado fazia religar a cada rodada. Cura: a régua é o maior entre o reflog e o mtime
   de `.git/HEAD`, do ref da main, do `ORIG_HEAD` e do `node_modules/.package-lock.json`. Caso com
   `git reflog expire --expire=now --all`.
8. **LIMITE, curado.** Uma pasta só com o `.git` copiado e a config passava pela conferência da worktree. Cura: git só
   leitura na própria worktree (`--no-optional-locks ls-files` e `ls-files --deleted`): tem rastreados e nenhum falta.
9. **LIMITE, curado.** O efeito da migração era pior do que o declarado: o worker retoma cada fio pelo id da sessão,
   que mora no diretório de projeto do caminho, e a 1ª mensagem de cada fio aberto volta como erro. Cura: o ato de
   migração ganhou o passo de copiar os `.jsonl` do diretório de projeto antigo para o novo (com o
   `CLAUDE_CONFIG_DIR` da unit).
10. **LIMITE, curado.** Nada impedia rodar junto com o `ops/update-bridge.sh`, que refaz o `node_modules` servido. Cura:
    o wrapper segura também `/tmp/onion-update-bridge.lock` (aberto com `>>`, sem truncar); caso com a trava ocupada.
11. **LIMITE, declarado.** O `npm ci` só roda se o `package-lock.json` mudou entre o sha de antes e o alvo; um
    `node_modules` que já estava defasado antes não é refeito. Fica no cabeçalho do wrapper como teto (5).

## Mutantes

A família `update_persona_hub` do auto-teste roda a bancada inteira (68 casos, a cópia limpa passa antes) e 44
mutantes, cada um numa cópia do wrapper e rodando só a seção do caso que ele derruba. Os dois que sobreviveram na 1ª
redação (a máscara do id e a linha "listening") foram curados antes do refutador: o caso da máscara passou a pôr o id
no diff, e a prova do hub passou a procurar o `hub=` dentro da linha "listening".

## Limites declarados

- O guarda das variáveis `ONION_UPH_*` fora do modo de teste não tem mutante: sem ele, o caso rodaria o ensaio contra a
  produção desta máquina. A conferência do backup da unit também não (defesa dupla).
- Religar o hub corta o turno em curso; a worktree do worker não é sincronizada aqui com a main do hub; a prova de vida
  é a linha "listening" e o socket, não um turno de verdade (cabeçalho do wrapper).
- O ensaio contra a produção foi rodado pelo condutor (só leitura, mais o fetch declarado no clone do worker): persona
  em dia (NOOP), hub recusado porque a worktree do worker ainda não existe, com o ato de migração impresso. O `--apply`
  não foi rodado: é ato do maestro.

## Re-revisão pós-rebase (2026-11-23)

Conflito só na lista `SELFTEST_CORE_ONLY_FAMILIES` do `lint-selftest.sh`: a main ganhou famílias novas e o PR acrescenta `update_persona_hub`; resolvido pela união das duas listas, sem mudar nenhum caso. Projeções geradas ficaram com a versão da main e se regeneram no fechamento.
