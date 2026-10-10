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
  vazamento;
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
e nada mais fica bloqueado por ela.

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

- **Não publica a 1ª materialização do onion-mini.** O registro dele tem pin `n/a`, e o README e o
  CLAUDE.md didáticos são da F5 (SAC-94). Até lá o motor recusa (rc 2), porque o repo dela guarda a destilação curada, sem `.claude/`, e substituí-la é a própria 1ª materialização.
- **Não roda as REGRAS 19/72–79/61 sobre um bundle temporário de plugins.** Isso é da F4 (SAC-93),
  junto com a saída de `plugins/` do core. Até lá elas seguem no lint do core.
- **Não vê conta de OUTRA máquina.** As contas vêm dos `local_path` do registro, de quem roda e das
  contas humanas do passwd local; uma conta que só existe noutra máquina fica fora. É o teto declarado
  da derivação.
- **Não mede a defasagem por papel.** O `--status` conta os commits das raízes que viajam para
  qualquer papel; para standalone, plugins e mini ele pode contar commit que não chega nelas.
  Superestima, nunca subestima, e é informativo.
- **Não atualiza o clone local da porta nem o `members.yaml`.** A REGRA 92 lê o clone local, então
  depois de uma troca de papel ele precisa de `git pull` por quem o mantém.
