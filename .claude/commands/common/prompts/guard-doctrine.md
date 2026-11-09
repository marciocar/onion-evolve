# 🛡️ Doutrina da forja de GUARDAS

O conjunto que uma guarda pede — irmão do [`forge-doctrine`](forge-doctrine.md), que forja
**comando-com-framework**. Guarda é outro animal: não tem superfície invocável (ela **dispara
sozinha**), não produz conhecimento (ela **barra**), e o que a mata não é falta de uso — é
**passar verde**.

**Por que esta doutrina existe, medido em 2026-10-02:** forjar guarda é o procedimento **mais
repetido** desta casa — **206 famílias de bancada** e **13 guardas com `--selftest` próprio** (pré-leva; esta forja soma a 14ª) — e era
o único **sem superfície**. Cada forja relia um molde escolhido de memória, e a sessão decidia o
substrato por lembrança. O `/meta:forge` tem medidor; a forja de guarda não tinha.

## As 7 peças de uma guarda

| # | peça | o que ela compra | modo de falha se ausente |
|---|---|---|---|
| 1 | **o DEFEITO MEDIDO** | a guarda nasce de dano observado, com data e evidência | guarda de hipótese: custo de manutenção sem dívida que a pague |
| 2 | **o MOLDE medido** (censo, não memória) | o substrato certo — hook `Stop`, `PreToolUse`, check de lint, regra embutida | copia-se o 1º molde lembrado e o veto nasce no lugar errado |
| 3 | **o ARTEFATO** | o veto propriamente dito | — |
| 4 | **as DUAS POLARIDADES** no `--selftest` | acusa o defeito **e** cala no caso honesto | guarda que só tem o caso positivo é superfície: ninguém sabe se ela acusa o inocente |
| 5 | **o MUTANTE** | prova que o caso **morde** | caso decorativo — passa verde com a cura revertida, e dá licença |
| 6 | **o REGISTRO** | ela dispara | guarda exercitada e morta: o censo mede exatamente isto |
| 7 | **o TETO declarado** | quem lê sabe o que ela **não** vê | guarda que parece cobrir a classe e cobre uma redação |

## As cláusulas

### 1. Sem defeito medido, não se forja
Guarda é dívida de manutenção permanente. A pergunta não é *"isto seria bom vigiar?"* — é *"que dano
já aconteceu, quando, e com que evidência?"*. Sem resposta datada, o desfecho correto é **nó com
gatilho nomeado**, não guarda. É a objeção `N=1` que sobreviveu a refutação na forja de comandos.

### 2. O MUTANTE é o que separa guarda de enfeite — e ele não se detecta por grep
Reverta a cura e **exija que o caso reprove**. Medido nesta casa: um caso de bancada com
`grep -qF "onion_regen <alvo> 21"` passava **verde** com o alvo trocado para `21x`, porque `-qF` é
substring; só a **deleção** da linha reprovava. O caso cobria metade do que anunciava, e meia
cobertura **dá licença**. O censo de guardas **não** vê isto — por isso a cláusula é de julgamento.

### 3. O VOCABULÁRIO é o defeito dominante, não a lógica
Medido 3× num dia: em guarda de lista, o que falha é a **lista de formas**, não o algoritmo. Três
consequências práticas:
- **o motor do padrão decide a sintaxe**: `[[:space:]]` é POSIX do `grep` e o `re` do Python o trata
  como *nested set* — a 1ª redação do `background-state-needs-evidence` (veto de prosa
  aposentado em 2026-10-14 pela sonda `background-task-probe.sh`) ficou **cega ao `ps`** que ela
  existia para exigir;
- **o locale do hook não é o seu**: `Viola..es` casa em UTF-8 e **não** em locale `C`, que é o do
  hook. Rode a bancada com `LC_ALL=C`. **E meça com o BINÁRIO do script, nunca com a ferramenta da
  shell** — medido em 2026-10-02 ao forjar este próprio conjunto: um caso reprovou por `n[ãa]o` em
  locale `C` (o `ã` tem 2 bytes, o conjunto casa 1), eu "refutei" o diagnóstico rodando `grep` na
  shell interativa — onde ele é uma **função que chama o ugrep**, que casa por caractere em qualquer
  locale — e quase **reverti a cura certa**. Com `/usr/bin/grep` a conta fecha: `rc=1` em `C`, `rc=0`
  em `C.UTF-8`;
- **zero-por-vocabulário é pior que não medir**: lê-se como "não há". O 1º dogfood do próprio
  `guard-census.sh` devolveu **0 casos** para três checks que têm `--selftest`, porque contava duas
  convenções de asserção e a casa tem cinco.

### 4. A guarda erra para o lado de CALAR, nunca de acusar
Falso positivo treina a sessão a ignorar o veto, e veto ignorado é pior que veto ausente. Quando a
guarda **não sabe**, ela declara que não sabe (o idioma `ISENÇÃO`/`NÃO MEDIDO` desta casa), jamais
afirma conformidade. É o P0 da REGRA 30.

### 5. Guarda que terceiro dispara à distância é superfície, não proteção
Medido em 2026-10-02: a REGRA 22 julgava **intake não-confiável**, então qualquer adotante podia
deixar o gate do core vermelho só mandando um sinal. Antes de selar, pergunte **quem controla a
entrada** que a guarda lê.

### 6. O registro é parte da forja, não o passo seguinte
O censo mede as duas mortes: **registrada e sem `--selftest`** (dispara sem ser exercitada) e **com
`--selftest` e não registrada** (exercitada e nunca dispara). O 1º dogfood do censo acusou a guarda
que estava sendo forjada **naquele instante** na segunda categoria.

> **O refutador que reprova aponta o que supera** (SAC-151, maestro 2026-10-15: "um juiz de sim ou
> não sem tentar superação em uma pesquisa pode restringir possibilidades de crescimento e
> inovação; é preciso ter medição e critérios claros"). O subagente que REFUTA a guarda devolve, para
> cada reprovação, o critério pré-registrado com o comando que a checa e a superação
> `{classe, achada, o_que, medida}`. Ou seja, o padrão, o substrato ou a guarda existente que cobriria a classe sem o defeito apontado. A sessão confere com
> `bash .claude/validation/judge-verdict-check.sh <vereditos.json>` (rc 1 = reprovação recusada e
> contada), e a superação achada vira nó.

## A camada nativa: o `permissions.deny` portátil

Desde 2026-11-08 o `.claude/settings.json` carrega uma lista pequena de atos irreversíveis e de leitura de
segredos. Ela é a 1ª camada e o hook é a 2ª: nenhuma substitui a outra, e nenhuma é fronteira de segurança.

- **O que entra:** regra sem caminho de máquina e sem nome de cliente, porque ela viaja (as portas que levam settings
  e a adoção nova o copiam; o `--update` soma, e o deny nunca encolhe). Regra local mora em `settings.local.json`. O
  `--diff` do relatório do `--update` nomeia cada regra nova e os `allow` do alvo que ela anula, por comparação de texto.
- **O que fica fora de propósito:** o que a casa faz todo dia (`reset --hard`, `branch -D`, `worktree remove
  --force`, `--force-with-lease`, `rm -rf` de pasta de trabalho) e o que já tem veto por hook com caminho verificado
  (merge e push na main: num repo sem o script verificado o hook avisa em vez de vetar, e o deny tiraria essa saída).
- **Medido em 2.1.319:** a regra `Read` alcança comando conhecido no Bash **quando o arquivo é nomeado** (`cat`,
  `grep`, `rg`, `sed`, `base64`), e também inspeção (`ls` e `stat` do arquivo: use `test -f`). Vale em
  `bypassPermissions`. Script chamado pela linha **não** é visto, e é assim que o merge verificado e a publicação de
  porta seguem andando.
- **`Read(...)` de caminho do home vira bloqueio do sistema sob sandbox.** O Claude Code a aplica como negação de leitura
  do sandbox: o processo do Bash não lê aquele caminho, inclusive quando o leitor é a maquinaria. Com a regra do
  `hosts.yml` do `gh`, `gh auth status` e o credential helper do git quebram (medido). A exceção
  `sandbox.filesystem.allowRead` no mesmo caminho vence a negação (medido em fixture e na curadoria, em uso real). A regra
  com glob do `.env` não mostrou efeito sob sandbox: não conte com ela, em nenhum dos dois sentidos. Regra de caminho absoluto nega de verdade, e `test -r` ainda responde legível: decida por abertura real do arquivo. Decisão do maestro de
  2026-11-09, «Manter as 12 e avisar sandbox»: a lista fica, e o `--update` avisa quem tem sandbox, sem escrever no bloco
  dele. O que cada adotante libera é dele.
- **Retirada:** o deny só soma, então regra errada não sai sozinha. A regra listada em `deny-retired.tsv` sai do adotante no
  `--update`, nomeada no relatório. Limite: é por texto, então regra do adotante idêntica à aposentada também sai.
- **A regra `Read` do `.env` também barra `Write` e `Edit`, inclusive arquivo novo.** Custo aceito pelo core em nome
  do maestro (2026-11-08, revogável): criar ou editar `.env` com segredo não é trabalho de agente. `.env.example` segue
  livre, e o `cp .env.example .env` do setup e o `>> .env` passam pelo Bash.
- **O que ela NÃO cobre, medido:** busca recursiva sem nomear o arquivo (`grep -rn X pasta` devolve o `.env` de
  dentro), `bash -c '…'`, `eval`, refspec `+`, `rm -Rf`, `find -delete`, interpretador (`python3 -c`), `tar`, `xxd`,
  glob (`cat .e*`), sufixo fora da lista (`.env.foo`), script que faz por dentro, `git -C . push origin x -uf` (flag
  combinada no fim, com `-C`), `git push -uvf`, `-vuf`, `-quf`, `-uqf` e o `-q` no meio do grupo do clean (`-qfdx`,
  `-fqdx`, `-qdfx`, `-fdqx`, `-qfdX`). Lista de formas não fecha contra variação; o que fecha
  é o sistema operacional.
- **Em adotante com sandbox ligado (medido em fixture com `bwrap` real):** `.ssh`, `.aws` e `.gnupg` somem para o processo;
  `.netrc` e o `.credentials.json` do Claude dão *Permission denied*; `source .env` e `cat .env` andam. Nada do que viaja em
  `.claude/` lê os caminhos negados, fora o `hosts.yml`. Em ssh, espere falha no push (`ssh -i` avisa que a chave não é
  acessível); de ponta a ponta **não foi medido**. Assinatura gpg falhou no sandbox com e sem o deny, porque o processo não
  grava no home: o efeito isolado do deny sobre ela **não foi medido**.
- **Custo:** o curinga atravessa espaços, então a menção dentro de `git -C . …` cai junto: `git -C . commit -m "… git
  push --force …"`, `-m "… git clean -x …"`, `git -C . log --grep 'x push -f y'` (no `git commit` sem `-C` não cai).
  E `rm -f my-report /`, porque `-*r*` lê o `r` do nome, e `git -C clean status -x`, com pasta chamada `clean`. Saída: o maestro roda fora da sessão (`!`).

## O que esta doutrina NÃO promete

- **Não garante que a guarda pegue a classe** — só que ela pegue a **forma** que o caso descreve. A
  cláusula 3 existe para isso ser dito, não escondido.
- **Não substitui o Elenxo.** Guarda nova muda o gate de todos; a passada adversarial é onde se
  descobre que ela acusa o inocente.
- **Não sabe medir mutante.** Cláusula 2 é julgamento, e assumida como tal.

## 🔗 Referências

- Medidor (peça 2): `.claude/validation/guard-census.sh` · superfície: [`/meta:forge-guard`](../../meta/forge-guard.md)
- Irmã para comandos: [`forge-doctrine`](forge-doctrine.md) · bancada: `run_guard_forge_selftests`
- Moldes mais exercitados (o censo diz o atual): `.claude/hooks/rule-title-in-prose.sh` (hook `Stop`),
  `.claude/validation/ladder-integrity-check.sh` (check de lint)
