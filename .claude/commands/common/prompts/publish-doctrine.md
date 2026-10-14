# 🚪 Doutrina do /meta:publish — publicar uma porta sem travar o core

Fragmento canônico do [`/meta:publish`](../../meta/publish.md). A superfície **referencia**, não
copia. Lente que carrega quando você toca o motor ou os materializadores:
`.claude/rules/publish-lens.md`.

**Por que existe, medido em 2026-10-09/10 (F3 do plano das portas, SAC-92):** havia três caminhos de
publicação e nenhum era o certo de ponta a ponta. O `ops/materialize-door.sh` lia `origin/main` desde
2026-09-25, mas parava antes do commit, e o pin voltava ao core por um PR de registro a cada
publicação. A skill `onion-publish` montava os plugins da **árvore de trabalho** de quem rodava, então
uma branch de PR aberta iria a público. E o onion-mini não tinha maquinaria. Somava-se o workflow
`onion-door-staleness`, com teto 0, que deixava a main vermelha depois de todo merge até alguém
publicar. A decisão do maestro (nó `D_MATRIZ_DE_PORTAS_2026_10`) foi publicar **sob demanda, por
comando, sem nunca travar o desenvolvimento**.

## As cláusulas

### 1. A fonte é `origin/<integração>`, sempre, inclusive o motor
O motor (`ops/publish-door.sh`) destaca uma worktree em `origin/main` e roda **os materializadores dela**,
não os do disco de quem chama. Assim, o que viaja e o código que decide o que viaja vêm do mesmo commit
mergeado. O **registro** (papel, destino, ids de adotante) também é lido da ref, não da árvore de
trabalho: uma edição não commitada do `remote:` mandaria a porta para outro destino. Se `origin/main`
não resolver, a rodada aborta com rc 3, e o HEAD local nunca serve de substituto, porque ele pode ser
a branch de um PR aberto. O `--from <ref>` existe para **ensaiar uma branch** (ver o efeito de uma cura
antes do merge) e é recusado junto com `--push` e com `--clone`, para que um commit de branch não
mergeada nunca fique num clone de onde um push seguinte o levaria.

### 2. Verifica-se o que foi MONTADO, não o que se pretendia montar
Antes de qualquer commit no clone da porta, quatro conferências sobre o bundle:
- **vazamento:** os termos da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente),
  inclusive o `client-terms.txt`; os ids de adotante com prefixo `onion-`, que aquela regra ignora por
  desenho (o ponto cego já medido duas vezes); e caminho de máquina `/home/<conta>/`, com a conta
  **derivada** dos `local_path` do registro e de quem roda. Lista de exemplos tolerados não entra:
  falharia pelo vocabulário. Todos os termos são derivados, porque nome escrito no script já seria o
  vazamento. A varredura mora em `.claude/validation/door-leak-scan.sh`, e o lint roda o mesmo código
  em todo PR, nas raízes que viajam: é a REGRA 106 (Superfície que viaja passa pela varredura de
  vazamento da publicação). Ela existe porque, em 2026-10-13, dois ensaios na mesma noite reprovaram
  três portas aqui no fim, por vazamento que tinha entrado com o lint verde. Agora o PR barra antes;
  a varredura da publicação continua sendo a última rede;
- **paridade de papel:** o carimbo montado diz o papel pedido e o pin de `origin/main`. Nos plugins, todo
  `provenance.json` aponta o pin;
- **o gate da própria porta:** o lint dela tem de dar 0 HARD (o mini não leva lint, por desenho). Nos
  plugins vale `claude plugin validate --strict` no catálogo e em cada plugin;
- **o core intacto:** HEAD e árvore do checkout iguais antes e depois, e nenhuma worktree deste motor sobrando (worktree de outra sessão nascendo no meio não é alteração dele).
As três primeiras rodam antes de qualquer commit: reprovação aborta com rc 1, sem commit e sem publicação. A do core roda no fim, porque é sobre o efeito da rodada inteira: rc 1 no ensaio, rc 4 se a porta já tiver sido publicada.

### 3. Papel divergente recusa
O registro (`members.yaml`) e o carimbo **publicado** da porta têm de concordar antes de materializar,
porque foi lendo uma fonte em vez da outra que a onion-core perdeu 85 arquivos em 2026-09-30. Trocar o
papel de uma porta é ato deliberado: `--role <novo> --force-role-change`. A primeira publicação da
onion-core como `source` (decidida na matriz) é esse caso. Depois dela, o `role:` do registro é
alinhado na leva seguinte (REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela)).

### 4. O push é confirmação explícita, e a conferência é no remoto
Sem `--push` a rodada é **ensaio**: monta, verifica, commita num clone descartável e para. A superfície
só passa `--push` depois de perguntar ao maestro (I3: um escritor por repo, e publicar é ato voltado ao
público), e passa junto o `--expect-pin` do ensaio: se a integração andou entre o ensaio e o "sim", a
rodada recusa, porque o pin publicado tem de ser o pin confirmado. O clone começa **exatamente** em
`origin/<ramo>` (o do maestro, via `--clone`, só se estiver limpo inclusive do ignorado, em dia e com o
nome e o origin da porta), e o push leva **exatamente um** commit, o verificado. Depois do push,
`git ls-remote` tem de devolver o commit empurrado; se não devolver, rc 4, que significa "publicado, mas
uma pós-condição falhou" e nunca se confunde com o rc 1 de "nada publicado". Se alguma verificação não
pôde ser medida (por exemplo, sem a CLI `claude` nos plugins), o `--push` é recusado, porque publicar
sem medir é afirmar o que não se sabe.

### 5. O selo é o carimbo da porta, e nenhum PR no core depende dele
O pin vive no `.claude/.onion-version` da porta (ou no `provenance.json`, nos plugins), escrito pela
materialização e lido do **remoto** por `--status`, com git puro e sem credencial. O `onion_version`
do `members.yaml` virou **cache**. Por isso a REGRA 85 (Porta pública espelha o core, com catraca) é
informativa por inteiro e o workflow `onion-door-staleness` é relatório: a defasagem continua visível
e nada mais fica bloqueado por ela. Quem quiser o cache em dia roda, na fonte, o carimbador do cache
(`door-seal-pin.sh <porta>`, core-only), que lê o carimbo **pela mesma leitura** do `--status` (uma lib
só, a `door-published-stamp.sh`), nunca do clone local
da porta, porque o motor publica de um clone descartável e o local fica para trás (medido em
2026-10-14, PR #1100). O `--push` termina imprimindo esse comando; abrir o PR do cache é de quem roda,
numa leva própria.

### 6. A versão é rótulo de release: o motor propõe, o maestro sela, a tag mora na porta
Decisão do maestro de 2026-10-11 (nó `D_VERSIONAR_AS_PORTAS_POR_RELEASE`, por pergunta com opções).
- **Rótulo, não verdade.** A versão `onion-vX.Y.Z` é apelido de um pin publicado. Nenhuma guarda a
  lê: a REGRA 85 (Porta pública espelha o core, com catraca), a REGRA 92 (Papel da porta no registro
  concorda com o CARIMBO dela) e o `--status` medem o pin, e o `--status` só **exibe** a versão lida do
  carimbo remoto. Um pin que não é release tem a versão derivada no estilo `git describe`
  (`onion-v1.0.0-31-g<sha>`), que nunca vira campo guardado no `members.yaml`.
- **Toda publicação é uma release.** O `--push` exige `--version X.Y.Z`; sem ele, rc 2. O ensaio
  mostra a **proposta** de bump. O motor a calcula pelo diff de superfície entre a porta publicada e a
  montada: comando, agente, skill ou hook removido ou renomeado, ou chave do carimbo mudada, é
  **major**; superfície adicionada é **minor**; o resto é **patch**. Uma entrada BREAKING no
  CHANGELOG da federação desde a release anterior torna a proposta **candidata a major**. A proposta
  não sai de Conventional Commits (medido em 2026-10-11: zero `!` em 2432 commits). A versão
  selada tem de ser maior que a última tag da porta. Repetir o número de uma release já publicada só
  passa como re-rodada idempotente, quando o conteúdo é o mesmo.
- **A tag mora nas portas.** O motor cria a tag anotada `onion-vX.Y.Z` (com o nome do produto, como
  `kg-ssot-vX.Y.Z`), empurra depois do ramo e a confere no remoto como confere o pin. O core privado
  fica intocado, inclusive de tags, e o passo 8 confere isso. A porta `onion-core` (papel source) é o
  livro-razão das releases.
- **Número único da família, começando em 1.0.0.** Cada rodada lê as tags de **todas** as portas do
  registro: a proposta parte do máximo da família, e o número selado tem de ser maior que ele. A
  exceção é a mesma publicação: uma porta pode tomar um número que já existe noutra se for o **mesmo
  pin** (é como as quatro saem da mesma release); em pin diferente, rc 2. Tags ilegíveis tornam a
  proposta NÃO-MEDIDA, nunca "primeira release". O `--all` agrega as propostas (maior bump sobre o
  máximo) e declara NÃO MEDIDA se alguma porta não chegou à proposta. Os plugins mantêm o `version` do `plugin.json` por conteúdo (é o que
  dirige o update do Claude Code). A versão da família vai em `metadata.version` do `marketplace.json`
  e em `onion_release` de cada `provenance.json`. Nas outras portas ela vai no carimbo (`release:`, pelo
  `write-stamp.sh`).
- **O changelog da release é a mensagem da tag**, gerada pelo motor. Ele compara a montagem com a
  **tag anterior** desta porta (não com a ponta, para que a re-rodada que só recupera uma tag não grave
  um changelog vazio). O intervalo de commits vai do `source_commit` do carimbo da tag anterior ao pin
  novo, filtrado pelos caminhos que a porta mudou. **Os assuntos de commit não viajam**: a porta é sem
  biografia, e um assunto é biografia do core, além de imutável (um só com nome de adotante travaria
  toda release seguinte). Viaja a **contagem por tipo** Conventional, sem os `docs:`; o que mudou de
  fato é a seção de superfície. A seção "Quebras nesta porta" diz **"nenhuma quebra nesta porta"**
  quando ela não quebrou. Do CHANGELOG da federação só viaja a **contagem** de entradas BREAKING, nunca
  o texto. O changelog passa pela **mesma** varredura de vazamento do bundle, porque assunto de
  commit do core é superfície nova de vazamento.
- **API pública por porta**, que é o que dá sentido ao "major": os comandos invocáveis, os agentes,
  as skills e os hooks que a porta distribui (o manifesto do papel), o schema do carimbo e, na porta
  source, o contrato do `members.yaml`.
- **O canal do adotante não muda.** Quem adota recebe mudanças pelo CHANGELOG da federação e pelo
  `/meta:co-announce`, não pelo changelog da porta.

## O destino (peça 5)

O destino de uma publicação é o **carimbo publicado**, conferido no remoto. Não há `write(KG)` por
publicação, e isso é deliberado, porque um nó por publicação traria de volta o PR de registro que a
cláusula 5 removeu. O grafo recebe nó só quando a publicação **ensina** algo: um defeito achado pela
verificação, a troca de papel de uma porta ou um modo de falha novo. Esse nó vai para o
`docs/onion/graph/door-role-parity-2026-09.kg.yaml` na leva seguinte, com `kg-radar` exit 0 e
`kg-contract-check` rc 0. **Contrato de custo:** o motor é determinístico e sem LLM, então `tokens` e
`agents` são 0 por construção. O `run_id` é o pin publicado e a duração aparece no log. Fica declarado
para que a ausência não seja lida como esquecimento.

## O que esta doutrina NÃO promete

- **Não substitui em silêncio o que não reconhece como porta.** A 1ª materialização do onion-mini
  (F5, SAC-94) troca a destilação curada antiga por uma porta gerada, e isso só acontece com
  `--replace-foreign`, que arquiva o conteúdo anterior numa tag `archive/pre-door-<data>` empurrada e
  conferida ANTES da porta. O `--all` nunca repassa a flag.
- **Não roda o lint na porta didática.** O mini não leva o lint por desenho; a verificação dele é o
  `door-mini-check.sh` (allowlist exata, sem ponteiro morto, sem caminho de máquina). Ausência
  declarada no `known_absent` do roles.yaml é tolerada, uma linha por citação, com catraca nos dois
  sentidos, e ela não vale nos arquivos escritos à mão para o mini (README, CLAUDE.md, skill). Teto: o
  checador conta citação por forma — caminho `.claude/…`, documento `docs/….md|yaml|json|txt`, link
  markdown relativo com forma de caminho, `/categoria:comando`, `/categoria/comando`, comando de raiz
  `/nome`, `@agente` e `common:prompts:nome`. Escapam: dependência citada só em prosa livre ("o agente
  de GitFlow"), diretório citado sem arquivo (`docs/knowledge-base/`) e link cujo alvo não tem forma de
  caminho (placeholder de template).
- **Não julga as guardas de plugin na catraca contra origin/main.** Desde a F4 (SAC-93, 2026-10-10)
  o `plugins/` montado não é versionado no core, e as REGRAS 61 (metade do resultado), 72, 73, 74, 75,
  76 (catálogo × raiz), 77 e 79 rodam no passo (5d) sobre o bundle montado
  (`.claude/validation/plugin-bundle-check.sh`). A raiz temporária do checador não é repo git, então
  a CATRACA-VIOLADA da REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca)
  não roda ali; o baseline ainda separa passivo (SOFT) de novo (HARD). A REGRA 19 (Plugins de
  vertical sincronizados com as fontes) foi aposentada: não há mais cópia versionada para sincronizar.
- **Não vê conta de OUTRA máquina.** As contas vêm dos `local_path` do registro, de quem roda e das
  contas humanas do passwd local; uma conta que só existe noutra máquina fica fora. É o teto declarado
  da derivação.
- **Não mede a defasagem por papel.** O `--status` conta os commits das raízes que viajam para
  qualquer papel; para standalone, plugins e mini ele pode contar commit que não chega nelas.
  Superestima, nunca subestima, e é informativo.
- **Não mede todo o contrato que declara como API.** A proposta de bump lê nomes (arquivo
  removido, renomeado ou adicionado na superfície) e as chaves do carimbo. Um comando reescrito com o
  mesmo nome e outro comportamento sai como patch. O contrato do `members.yaml` da porta source não
  entra no diff; o sinal dele é a entrada BREAKING no CHANGELOG da federação. Por isso a proposta é
  proposta, e o número é do maestro.
- **Não publica a família de forma atômica.** O `--all --push` publica porta a porta. Se uma reprovar,
  as outras já saíram com o número. A cura é re-rodar com o **mesmo** `--version` depois da correção:
  a porta que já está na release passa como re-rodada idempotente (ou só empurra a tag que faltou), e
  a que faltava sai. A re-rodada noutro dia também passa: com o mesmo pin e a mesma release, o motor
  confere que a única diferença é a linha `materialized_at` do carimbo e não a trata como conteúdo
  novo; qualquer outra diferença (uma troca de papel, por exemplo) recusa com rc 2. Se `origin/main`
  andou no meio, o `--expect-pin` recusa antes. Teto: com `--clone`, uma tag local que sobrou de uma
  rodada anterior apontando outro commit faz a re-rodada sair rc 4 até ser apagada à mão.
- **A versão derivada do `--status` é aproximação.** O `onion-vX-N-g<sha>` junta a tag da porta com
  a contagem e o sha do core; não é o `git describe` de repositório nenhum. É só exibição.
- **Não atualiza o clone local da porta nem o `members.yaml`.** A REGRA 92 lê o clone local, então
  depois de uma troca de papel ele precisa de `git pull` por quem o mantém.
