# Onda O6: proposta do proponente (SAC-73)

> **Papel:** proponente. Esta onda **não edita grafos e não abre PR**. Um juiz independente refuta depois.
> Base: `origin/main` em `02076e54` (2026-10-09), com a O5 já aplicada (PR #1000). Planilha:
> [`o6-proposta.csv`](o6-proposta.csv), com **155 linhas** sobre **141 nós** em **50 grafos**, uma linha por
> (nó, regra). Nó novo: [`o6-novos-nos.yaml`](o6-novos-nos.yaml).
>
> **Convenção da planilha:** `valor_novo` traz o valor **inteiro** do campo depois da troca (em P5-va e PEND),
> não um diff. Nas linhas `ao-maestro-trace-host`, `valor_novo` é só a **recomendação**, prefixada pela opção:
> `(a)` remover o trace e registrar na narrative, `(b)` descrever, `(c)` `remoto@sha:caminho`, `(m)` misto.

## Contagens

| Regra | Proposta | Linhas |
|---|---|---:|
| P1 | `dev-sem-comando` | 2 |
| P2 | `binario-dev` | 7 |
| P2 | `binario-prod` | 1 |
| P4 | `marcar-path-conteudo` | 3 |
| P5-va | `reescrever-va` | 50 |
| P5-trace | `reescrever-trace` | 8 |
| P5-trace | `ao-maestro-trace-host` | **72** (47 `(c)`, 22 `(b)`, 2 `(a)`, 1 `(m)`) |
| HEADROOM | `reconciliar` | 1 (+1 nó novo) |
| PEND | `add-locality` | 4 |
| PEND | `reescrever-source` | 7 (1 F6, 2 âncoras do waha, 4 D5) |

### Universo da P5, medido

Mesma regex de **classe** do `kg-migrate-v3` (`ABS_FS_RE`: absoluto de sistema no início de token, ou `~/`),
sobre os 146 `.kg.yaml` rastreados fora de `fixtures`, carregados com PyYAML.

| Campo | Nós | Linhas | Observação |
|---|---:|---:|---|
| `verified_against` | **52** | 50 | os 2 que faltam (`E_m3_…`, `E_SKILL_INSTALL_…`) são P4: o marcador cobre o nó inteiro |
| `trace` | **80** | 80 | 8 reescritos, 72 ao maestro |
| `provenance.*` | 3 | — | exatamente os 3 da P4; nada mais sobra |

Os números batem com os "cerca de 52" e "cerca de 80" do juiz da O5. A conferência de universo roda no fim
do gerador e devolveu `faltando []` nos dois campos.

**Guardas que o gerador aplica antes de escrever** (o gerador fica fora do commit, porque carrega como
literais os trechos antigos, com caminhos de máquina e pastas privadas):

1. todo `valor_novo` fora das linhas `ao-maestro-*` e P4 é recusado se ainda casar `ABS_FS_RE`;
2. `valor_novo` e `evidencia` são recusados se contiverem nome de pasta de adotante que difere do id;
3. a lista de pastas é derivada do `members.yaml` (basename do `local_path` ≠ `id`, hoje 7), e não escrita à mão.

## P1: `dev-sem-comando`

| Nó | Rótulo O5 → O6 | Nota |
|---|---|---|
| `E_ESTUDO_O_CLAUDE_CODE_RECUSA_O_QUE_NAO_PROVA` | `dev-sem-versao` → `dev-sem-comando` | versão 2.1.289 no method; comando ausente no nó e no commit |
| `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` | `dev-sem-versao` → `dev-sem-comando` | versão 2.1.286 na source; o label nomeia `grep -ao` (ver caso difícil 2) |

Os dois nasceram DEV. Nada muda no grafo: o method já diz "comando não registrado". Só o rótulo do desfecho
deixa de mentir.

## P2: binário com rótulo `derivado`, `leitura` ou `juízes`

**Critério aplicado, igual para todos:** *comando registrado* quer dizer ferramenta, alvo e argumento
suficientes para re-rodar e obter o **número** que o nó cita. Pode estar no nó ou no arquivo versionado que o
locator cita. A ferramenta sozinha (`strings`, `grep`) não basta.

Fui procurar o comando também nos arquivos de origem: `poda-instrucoes-protocolo-2026-09.md` l.3,
`radar-baselines.yaml`, o resíduo `feat-model-ladder…` l.22, o deepdive l.3-8, `probe-premodelswitch.md` e o
resíduo do PR #616. Nenhum registra a linha de comando. Nenhuma das versões (2.1.233, 2.1.258, 2.1.259 e
2.1.289) está instalada hoje (há 2.1.293 a 2.1.296), então não dá para re-medir e registrar agora.

| Nó | Plano | Status | Proposta | Por quê |
|---|---|---|---|---|
| `E_INSTRUCTIONSLOADED_PAYLOAD_MEDIDO_0903` | PROD | confirmed | `binario-dev` | `strings` sem o termo contado ("15 ocorrências" de quê?) |
| `E_FALLBACK_NATIVO_MEDIDO_0903` | PROD | confirmed | `binario-dev` | `strings` sem padrão |
| `E_DEEP_RESEARCH_EMBUTIDO_E_A_BASE` | PROD | confirmed | `binario-dev` | a extração do script não está registrada |
| `E_PREMODELSWITCH_DISPARO_MEDIDO_0902` | PROD | confirmed | `binario-dev` (0.7) | caso difícil 3 |
| `C_CREATE_SKILL_EXECUTA_GIT_DIFF_A_CADA_INVOCACAO` | PROD | superseded | `binario-dev` | o script node não está registrado |
| `C_RAIO_X_PUBLICA_ALVOS_FALSOS_DE_SKILLS` | PROD | superseded | `binario-dev` | comando ausente |
| `E_CONTRATO_DE_HOOKS_EXPLODIU` | PROD | confirmed | `binario-dev` (0.55) | caso difícil 4 |
| `E_RESPAWN_JA_EXISTIA_E_A_CASA_NAO_SABIA` | PROD | confirmed | **`binario-prod`** | **achado da busca pela classe.** `claude respawn --help` verbatim no nó, versão 2.1.278, saída gravada em `data/claude-help-2.1.278.txt`. Hoje está sem `locality` |

Em todas as linhas, o method passa a `medição: … , comando não registrado` e a `locality` a `web`, como já se
fez nos `dev-sem-versao` da O5.

**Varredura da classe.** Busquei nós PROD com versão de binário em `source`, `locator`, `method` ou
`verified_against` e classe diferente de `medição`. Ela devolveu 10 nós: os 7 do juiz, o `E_RESPAWN…` e dois
**falsos positivos** que deixei fora:

- `D_F2_MOTOR_WORKFLOW_ONION_RESEARCH_E_SKILL`: o claim é sobre o workflow, e o binário é incidental;
- `E_REGRA65_CEGA_AO_PROCESSO_0902`: mede o processo contra o disco, e a leitura do corpo do commit está
  certa.

## P4: caminho-conteúdo

**Marcador proposto:** a chave `x_path_is_content: true` no nó, mais uma linha na `narrative` começando por
"Caminho como conteúdo:" e dizendo por quê. O contrato v4 deixa `x_*` livre no nó (`kg-contract-v4.schema.json`,
`pattern: ^x_`), e nenhum dos três nós tem `narrative` hoje.

**Dois ajustes à forma, para o maestro.**

- **Booleano ou string?** Prefiro uma **string** (`x_path_is_content: "citação verbatim de terceiro"`). O
  motivo viaja com a chave, e a guarda pode exigir que ele seja um de três (citação, vetor ou receita). Com
  booleano, a guarda precisa ler a prosa. Não apliquei: a forma do brief é o booleano.
- **"Não é desta máquina" tem de ser mecânico.** A guarda futura (P3) deve recusar o marcador quando o
  caminho marcado contiver home de conta (`/home/<x>`, `/root`) ou o hostname. Do contrário, o marcador vira
  a porta pela qual o caminho de máquina volta.

| Nó | Classe | Caminho é desta máquina? |
|---|---|---|
| `E_m3_portabilidade_executada` | receita | **Não.** Os dois diretórios de binários de sistema de qualquer Linux, e um HOME temporário inexistente de propósito |
| `E_SKILL_INSTALL_PROMPT_AND_CURL` | citação de terceiro | **Não.** O `~` é o do leitor da página do fornecedor |
| `E_F4_CLAUDE_JSON_CONCORRENTE` | citação de terceiro | **Não.** O caminho é texto do CHANGELOG oficial, entre aspas |

O `E_m3` segue PROD com method `derivado … não reverificado`. Isso está fora da P4, mas vale nomear: a receita
roda hoje (`env -i … bash` sobre `.claude/validation/*.sh`), e uma re-medição transformaria o nó em
`medição` de verdade. Não rodei, porque não estava no mandato.

## P5-va: 50 reescritas

Os padrões de troca, todos determinísticos e conferidos no gerador por substring exata:

| De | Para |
|---|---|
| raiz do core | `<raiz do clone>`, ou `onion-evolve@<sha>` quando a O5 já usava esse sha no locator |
| binário instalado por caminho | `binário do Claude Code <versão>` |
| clone de adotante | o id do `members.yaml`, ou `<adotante-sem-registro>` |
| clone de produção do bridge | "clone de produção do onion-bridge" |
| infra do host (Caddy, systemd, procfs, boot, reboot-required, venv) | descrição sem prefixo |
| scratch temporário | "sandbox temporário" e equivalentes |
| comandos verbatim (`cd <raiz> && …`, `find . …`) | o argumento de caminho vira placeholder; o resto fica verbatim |

**Âncoras com sha, reaproveitadas da O5 ou medidas agora:**

- `onion-evolve@27179d37` e `@9e75a73d`;
- `onion-plugins@22b859fc`;
- `8320b1c3:` para o `kg-freshness.md` (o F3 do juiz da O5);
- `onion-logto@a0ce0fd`, com o `console.sh` l.30-37 conferido no `gh api`;
- `af4a420a~1` no `E_REEXTRACAO`, que corrige também o "de HEAD" do `verified_against`, a mesma âncora
  móvel do F6.

**Dois casos de vetor ou placeholder reescritos pela forma, e não marcados como P4:**

- `E_DEFEITO_…` (`/usr/bin/gh` → "gh por caminho absoluto"): é a mesma forma que a O5 aprovou no locator, e
  o literal sobrevive no `_case` de `lint-selftest.sh`;
- `A_CAMINHO_DE_MAQUINA_…` (`/home/<conta>/` → "prefixo de home de conta"): é um placeholder de padrão, não
  um caminho.

Os IDs de pastas privadas que apareciam no `verified_against` também saíram, por exemplo no
`Q_VPS_EXPOSURE_…`, onde estavam fora do caminho.

## P5-trace: 8 reescritos, 72 ao maestro

**Fato que decide o risco, medido no `kg-trace-resolve.sh`:** caminho absoluto **já é pulado**
(`/*) SKIP_ABS`) pelo julgamento e pelo `--emit-index`. Isso tem duas consequências:

- nenhum dos 80 traces de hoje alimenta a perna de leitura, e nenhuma proposta abaixo tira função dela;
- trocar um absoluto por um **relativo que não existe no repo** faria o alvo passar a ser julgado e
  reprovaria como `TARGET-MISSING` (HARD, sem baseline). É por isso que um caminho do host nunca pode virar
  "relativo".

A forma `remoto@sha:caminho` é contada como não-caminho, porque o `@` reprova o filtro de caracteres. Então
ela é segura no gate.

**Reescritos (8).** O alvo está neste repo, ou o sha já estava no próprio trace, ou é binário (selo `web`):

- `Q_ONION_KG_MCP_NEXT`;
- `E_GRANAAI_DOCTRINE`: os 4 sinais estão versionados no `_processed` do core;
- `SY4_…`: o `~/` era descrição do conteúdo do documento;
- `E_L2`: o commit já estava no trace, e só a pasta vira o nome do remoto;
- `E_LSTREE_…`: o remoto já estava nomeado no trace;
- `REC_PIN_DRIFT_…`, com `gustavo-pulga@21ff04f`;
- `E_MEDIDO_LOCAL_TIER10_…` e `E_OBJECAO_EXIT2_…` (binário). Ver P-a.

**Ao maestro (72), em três famílias:**

- **(R) repo remoto alcançável, 47 linhas.** São onion-bridge (30), onion-logto (8), onion-waha (6),
  onion-vps-vaultwarden (2) e arandek (1). A P5-trace prevê só "no repo" e "só no host", e esta é uma
  **terceira via**, por isso não a decidi. A recomendação `(c)` vem com sha **medido**: `gh api
  commits?until=<verified_at>&path=<caminho>`, com o arquivo conferido em `contents?ref=<sha>`.
  - **Ressalva forte:** 11 nós do bridge são de antes de 2026-08-08, quando o clone de produção divergia do
    repo (`C_producao_nao_e_o_repo`). Neles o sha é "o que o remoto tinha", e não necessariamente "o que
    rodava". Por isso a confiança é 0.5.
  - **O waha** foi versionado um dia depois dos nós de 07-31 e 08-01, em `86662e01`. O nó irmão
    `D_engine_noweb_confirmed` já documenta isso.
- **(H) só no host, 23 linhas.**
  - **Remover e registrar na narrative `(a)`:** os 2 efêmeros, o plano do harness (já apagado) e um
    `final.json` em scratch temporário.
  - **Descrever `(b)`:** config de sistema (Caddy, systemd, needrestart, reboot-required), `.env` (segredo,
    nunca versionado), o repo do librechat sem remoto, o `offsite-cron.sh`, que nunca foi ao remoto, e o
    código do bridge que **não existia no remoto** na data (`gh api` devolveu NENHUM commit).
  - `C_producao_nao_e_o_repo` e `E_producao_alcancou_o_repo` **não** podem apontar o remoto, porque o claim
    deles É o clone de produção.
- **(M) misto, 2 linhas:**
  - `E_ESPELHO_CADUCO_…`: a metade do repo vira relativa, e a 2ª cópia do members.yaml, que é o próprio
    claim, vai à narrative;
  - `REC_STAGING_…`: o remoto do `marcio-pessoal` é declarado "não publicado", então não o cito.

**8 nós PROD** estão entre os ao-maestro: `F_ID_3_SUPERFICIE`, `F_ID_4_MGM`, `Q_ISOLAMENTO_…`,
`I_UPGRADE_…`, `Q_A_SENHA_…`, `E_A_SAIDA_DO_BACKUP_…`, `Q_MAIS_UM_IMUTAVEL_GATED` e
`D_engine_noweb_confirmed`. Todos são da família (R).

## HEADROOM: re-medido e reconciliado

Medi às 2026-10-09T23:13Z:

- `free -m`: available **24276** de 32094 MiB;
- `swapon --show`: swap 3592 de 8191 MiB (44%);
- `docker inspect`: os `mem_limit` dos 6 containers batem com o label, e o admin tem 512m;
- `docker stats --no-stream`: **505 MiB** no stack e ~3004 MiB nos 34 containers.

O juiz da O5 mediu às 22:21Z (available 24169) e bate. O claim do presente, "é apertado", **não se sustenta
hoje**: a causa de agosto era nomeada (VS Code e ~7 claudes).

- **Nó novo `E_HEADROOM_RAM_MEDIDO_1009`:** PROD, `medição`, `host`, convenção (a), label com 262
  caracteres. Passei-o pelo `kg-contract-check.sh` num grafo de teste, junto com o antigo como superseded e a
  aresta: conforme.
- **Nó antigo:** passa a `superseded`. Ele já está em DEV desde a O5.
- **Fica ao maestro** o destino da aresta `CONSTRAINS → D_STACK_PADRAO_ONION_VPS`, porque ela mudaria de
  sentido se fosse para o nó novo.

## Pendências da O5

| Item | Resultado |
|---|---|
| **4 sem `locality`** | Todos `repo`: `E_NAO_HA_NAO_USO_…` (o remoto do gustavo-pulga tem `21ff04f`), `E_V1_COMMITS` (**o remoto do arandek ficou alcançável**: `1aa794f9` e `88d93f26` existem, coisa que o juiz da O5 não alcançava), `E_LOCALE_FRAGIL_…` e `E_ADOCAO_ROBUSTA_F1` (scripts e resíduo do repo) |
| **F6, `E_REEXTRACAO`** | **Confere.** `af4a420a` nasceu o nó e trocou a cópia. Em `af4a420a~1` (`9f403c2a`) a l.80 é `function D3n` (cópia 2.1.290) e em `af4a420a` já é `function Ltr`. `HEAD` hoje daria a cópia errada. A source passa a `git show af4a420a~1:…` |
| **F1, `onion-vps-waha@c92ff68`** | **Não há sha certo no remoto.** `marciocar/onion-waha` tem **um** commit (`86662e01`, 08-02). `c92ff68` é o HEAD do clone local e nunca foi enviado, e o README do remoto não tem a seção de 08-19. **Rebaixo a âncora do README a host**; a base do nó segue `repo` (o resíduo R56 e o commit `21e62755`). **Alternativa ao maestro:** um push no onion-waha validaria `c92ff68` sem mudar o nó |
| **Achado novo da mesma classe** | `ENT_whatsapp` cita `onion-vps-waha@3408d82`, que também dá **422**. Em `86662e01`, anterior ao nó, as l.12 e l.16 do compose têm exatamente o que o locator cita: reescrito |
| **D5** | 4 trocas da pasta pelo remoto: `onion-vps-logto@` → `onion-logto@` em 3 nós (`I_CONSOLE_…` method, `E_logto_now_critical_2026_08` source e `E_W8_CONSOLE_AUTOOFF_VIVO` source) e `onion-vps-waha@86662e0` → `onion-waha@86662e0` em `E_lid_addressing_root_cause`. Todos os shas foram conferidos no `gh api`. O librechat não tem remoto e fica pelo nome da pasta |

## Casos difíceis

1. **A terceira via do trace, (R).** Esta é a decisão de maior volume da onda (47 linhas). Se o maestro selar
   "`remoto@sha:caminho` é a forma do trace para repo remoto", as 47 linhas viram aplicação mecânica.
2. **`E_OBJECAO_EXIT2`: ferramenta e termos sem as flags.** O label diz "`grep -ao` … 243". O nó levanta ele
   mesmo a dúvida entre linhas e ocorrências, e é exatamente a informação que falta. Por isso marquei
   `dev-sem-comando`. O nó nasceu DEV, então o desfecho não muda.
3. **`E_PREMODELSWITCH`: procedimento, não comando.** A saída é verbatim e versionada, e o procedimento está
   descrito (sonda no `settings.json`, troca pelo picker). O script da sonda foi removido sem ser versionado.
   Pela letra da regra vai a DEV. Se o maestro aceitar "procedimento com saída verbatim versionada" como
   comando registrado, fica em PROD.
4. **`E_CONTRATO_DE_HOOKS`: o claim de docs não depende do binário.** A lista de eventos e handlers vem da
   doc e do CHANGELOG (web), e o binário é corroboração. A alternativa a `binario-dev` é rotular `leitura:
   CHANGELOG + doc` e manter em PROD, com o binário citado como corroboração não reproduzível. Deixei
   `binario-dev` com confiança 0.55, pela letra da P2.
5. **Binário no trace (P-a).** Tratei `binário do Claude Code <versão>` como reescrita, e não como ao-maestro,
   porque o selo já classifica o binário de versão fixa como `web` (público). Se o maestro ler "só existe no
   host" literalmente (o arquivo está, ou esteve, só no disco), as 2 linhas viram ao-maestro.

## Propostas ao maestro (regra nova, NÃO aplicadas)

- **P5-trace-R:** selar `remoto@sha:caminho` como forma do `trace` para alvo em repo remoto alcançável, com
  sha pela data do nó. Para nós de antes da convergência do repo do bridge, `(b)` descrever.
- **P4-forma:** `x_path_is_content` como **string** do enum {citação, vetor, receita}, e a guarda recusando
  marcador sobre caminho com home de conta ou hostname.
- **P2-procedimento:** decidir se "procedimento + saída verbatim versionada" conta como comando registrado
  (caso 3).
- **P6-label:** `label` (**66 nós**) e `narrative` (**6**) ainda carregam caminho de máquina pela mesma
  classe. O `E_waha_public_route_caddy` tem o caminho no label, dois campos acima do `verified_against` que
  esta onda limpa. Isso é o mesmo argumento da P5 da O5, um nível acima.
- **Push do onion-waha:** `c92ff68` (e o `3408d82` do clone) estão só no host. Um push validaria as âncoras.

## Achados fora do mandato

- **F-O6-1, drift de premissa.** `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` é uma decisão **open** cujo label diz que
  o vhost do console "está ATIVO (sem sufixo `.disabled`)". Hoje o `conf.d` do Caddy tem
  `logto-console.caddy.disabled` (`sudo ls`, 2026-10-09). O console está desligado e a decisão perdeu a
  premissa. Candidato a `/meta:kg-freshness`.
- **F-O6-2.** O F5 do juiz da O5 persiste: a coluna `grafo` desta planilha carrega um nome de arquivo de
  grafo com nome privado. Isso é inevitável até a P6 da O4 (renomear). Nos campos `valor_novo` e `evidencia`,
  nenhum nome de pasta privada aparece, e o gerador recusa.
- **F-O6-3.** Os line numbers do compose do librechat (`7338dcb` l.6, l.16…) no locator do nó novo vêm do nó
  antigo e não foram relidos. O repo não tem remoto, e o isolamento desta sessão bloqueia `git -C` fora da
  worktree. Os `mem_limit` foram medidos no serviço, que é a base do claim.

## Tetos

- **Binários antigos:** não re-medi nenhum binário da P2, porque nenhuma das versões está instalada.
- **Repos fora da worktree:** não li o histórico local de `onion-vps-waha` nem de `onion-vps-librechat`,
  porque o isolamento bloqueia `git` fora da worktree. O HEAD do waha veio de `refs/heads/master`, lido como
  arquivo.
- **Sha de (R):** o sha é o último commit do arquivo no remoto até o `verified_at`. Para nó re-verificado
  depois de nascer, isso é a data da re-verificação, não a do nascimento.
- **Prosa:** não reli a prosa inteira dos 72 nós ao-maestro; julguei pelo trace e pela source.
