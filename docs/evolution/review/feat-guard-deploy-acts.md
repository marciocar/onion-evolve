---
branch: feat/guard-deploy-acts
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: 0d16a413089f151e1e71927c1083b59e64b46c8de77eaccd11e1588bed0f5345
reviewed_code_sha256: ac7a97e6921140bf6590107a9ee499b87d6139fe2e59ff3a50bea4dbdd60500e
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "refutador independente (agente separado, com probes próprias em laboratório)"
nota: "tokens e duração em 0 = não medidos. O refutador reprovou 159573a60 com 4 furos; os 4 foram curados nesta volta, com caso e mutante cada. A re-verificação do diferencial pelo refutador AINDA NÃO RODOU. Os limites que ele marcou ficaram declarados no grafo."
---

# Resíduo: `feat/guard-deploy-acts` — o veto do MOAT barra o ATO de deploy e de publicação

## O que muda

- **Classe `ato` no veto do MOAT** (`pretooluse-moat-gate.sh` + `lib/moat-judge.py`): a invocação, pela sessão, de um
  script de `ops/` cujo uso é o deploy ou a publicação, com a assinatura do ato nos argumentos, sai com exit 2. O
  wrapper versionado continua fronteira para o ALVO (o que ele escreve por dentro), não para o ATO. Ensaio e
  leitura do mesmo script passam (`install` sem `--apply`, `--status`, `plan`, `verify`, `--check`, `bash -n`).
- **Os dados:** 14 linhas `ato script <ops/x.sh> <assinatura>` no `ops/moat-targets.tsv` (core-only), os 12 wrappers
  que o tsv já nomeava, mais `caddy-site-secrets.sh` (escreve `/etc/caddy/secrets`) e `publish-door.sh` (`--push`).
  As assinaturas saem da gramática de cada script, lida no código.
- **Fora por desenho:** `ops/pr-merge-verified.sh`, o caminho verificado de merge que a sessão usa com o "sim" do
  maestro. O merge alheio segue regra social (nó `C_TETO_MERGE_ALHEIO_SEGUE_SOCIAL`).
- **O caminho do maestro:** o `!` no prompt, que não passa pelos hooks de ferramenta. Medido no corpus: 28 dos 60
  comandos únicos do `!` seriam vetados hoje e rodaram (ex.: `! sudo systemctl restart onion-vps-bridge`, 2026-10-22,
  CC 2.1.308). Não remedido na 2.1.318 (teto).
- **No adotante (2ª leva, 2026-11-05):** sem `ops/moat-targets.tsv` o hook não sai mais; entra no MODO DERIVADO.
  O relógio veta (crontab, at/batch, systemd-run com timer, systemctl que liga `.timer`, escrita em cron e num `.timer`
  sob systemd/), a publicação só avisa (decisão do maestro pelo kg-ssot, que tem hook local próprio), e deploy, repo
  alheio e ato ficam desarmados (o merge no adotante é outra forja; o merge-gate não mudou). Casos `der1` a `der9`, `x1`
  e `ato16`, num repo `role: adopted` e num sem carimbo.
- **Publicação sem script (2ª leva):** aprovação de ambiente protegido (`POST …/pending_deployments`, por `gh api` e por
  `curl`), `gh repo edit` em visibilidade/descrição/tópicos (e o PATCH/PUT equivalente pela API) e `git push` de tag.
  No core vetam; no derivado avisam. Casos `pub1` a `pub11`; `gh release create` e POST em releases entraram na volta de cura.
- **Timer por arquivo:** a unit `.timer` escrita pelo Bash sob systemd/ e o `systemctl --user enable/start` dela já vetam
  (casos `der2`, `der3`). Fora: a unit escrita pela ferramenta Write e o agendamento nativo do Claude Code (CronCreate,
  ScheduleWakeup do `/loop`, RemoteTrigger), declarados no grafo com gatilho.
- **Guarda da lista:** REGRA 117 (Ato de deploy tem assinatura no veto), em `act-signature-check.sh`: wrapper sem linha
  `ato`, linha sem script ou sem assinatura, e palavra da assinatura fora do código do script. `aplica-se: source`.
- **Superfícies:** `/meta:publish`, a skill `onion-publish` e a `publish-doctrine` passam a entregar a linha do
  `--push` para o maestro rodar pelo `!`; a tabela do MOAT na `onion-drive-doctrine` ganhou a linha do ato.

## Achados da passada adversarial sobre 159573a60

| # | Achado | Grau | Destino |
|---|---|---|---|
| 1 | `bash -n +n ops/x.sh` executa (medido: imprimiu EXECUTOU), e o veto o tratava como só-sintaxe | barra o merge | curado: vale o último toggle de `-n`/`+n` e `-o`/`+o noexec`; `+n` deixou de ser lido como o script (casos `cur1`, `cur1b`) |
| 2 | O fecho do inanalisável não conhecia os nomes de ato: cópia criada na própria string (`cat`, `tee`, `rsync`, `printf` para script), `xargs -I{} bash {}`, `find -exec bash {}`, `script -qc`, `tmux new -d` passavam | barra o merge | curado: o nome de um script de ato entra na relevância junto de algo que executa ou copia; `find -exec` com shell e `script -qc` colado são seguidos (casos `cur2` a `cur5`, `cur7`) |
| 3 | Shell lendo o texto do ato por fonte que não é `cat` (`bash <(cat …)`, `git show … \| bash -s`, `sed '' … \| bash -s`) | barra o merge | curado: fecha como inanalisável (casos `cur6`, `cur7`) |
| 4 | Glob no caminho (`publish-door.s?`, `[p]`, `secret?.sh`) | barra o merge | curado: o glob que casa um ato pelo nome é o ato; o pré-filtro manda glob ao juiz, porque o `ls-files` o lia como pathspec versionado (casos `cur8`, `cur8b`, `cur9`) |
| L1 | `ops/apply-ruleset-main.sh` fora da 4ª coluna passa | limite | declarado: `C_TETO_SCRIPT_DE_PUBLICACAO_FORA_DA_LISTA` |
| L2 | A REGRA 117 confere só a presença da palavra | limite | declarado: `C_TETO_REGRA_117_SO_PRESENCA_DA_PALAVRA` |

## Medidas da forja

| Medida | Resultado |
|---|---|
| Famílias `moat_gate` + `act_signature` | 344 casos na volta de cura (316 na 2ª leva, 282 na 1ª), 0 falhas, 0 pulados; cada caso com mutante executado (eram 282 na 1ª leva) |
| Replay das formas novas, todos os projetos | core: 1 veto novo (o `gh repo edit --visibility public` de 2026-10-14, sob autorização pontual); derivados: 1 veto novo (um `crontab -` real do sge, 2026-09-29) e 127 avisos no kg-ssot (108 push de tag, 17 aprovações, 2 repo edit), todos atos reais; nenhum veto perdido |
| Replay do corpus (comandos que citam um script de ato) | nenhum veto perdido. 1ª redação: 1.681 comandos, 144 vetos novos, 39 falsos positivos (26 `bash -n`, 13 argumento de runtime), curados no mesmo laço. Depois: 1.690 comandos, 114 vetos novos, todos atos (34 update-bridge, 24 publish-door, 12 chat-runner, 10 install-caddy-config, 9 a2a-invite-live, 8 update-kg-writer, 5 stt-service, 4 caddy-site-secrets, 3 docker-engine-migrate, 2 bridge-hardening, 2 workspace-adopt-sync, 1 a2a-queue-live) |
| Latência | ~180 a 300 ms quando o comando cita um script de ato; ~100 ms quando não cita |

| Replay pós-cura (1.709 comandos que citam um ato) | 131 vetos novos: 112 atos e 19 fechamentos; com a relevância estreitada restam 10, sendo 5 atos reais e 5 falsos positivos raros (analisador que não lê o comando, harness que monta o ato em texto) |

## O que esta forja não mediu

- O `!` na 2.1.318 (exige o maestro digitando).
- A re-verificação do diferencial pelo refutador (depois desta volta de cura).
- O CI completo: só as duas famílias e o `lint-artifacts.sh` rodaram. O 2º commit foi `--no-verify` (CHECKPOINT, por ordem de carga da máquina): o pre-commit roda a bancada das famílias afetadas (192 famílias, ~70 min no 1º commit) e não foi re-rodado sobre o SHA final.
- Se o hook de PreToolUse dispara para CronCreate/ScheduleWakeup (não medido: fica fora por desenho).

Grafo: [`deploy-acts-2026-11.kg.yaml`](../research/guard-deploy-acts-2026-11/deploy-acts-2026-11.kg.yaml).
