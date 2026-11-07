---
branch: feat/private-repo-name-guard
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 12c1eaa0f2f9e778968282b3fb22b2a27ecd3edf3673f5f2dd23e6f0acc5d3b7
reviewed_code_sha256: e3d46bfb3ad6ff8fe1c7f4ac716c01cac4e8f57a939916462cc15be35aeab824
findings_total: 8
findings_real: 6
findings_blocking: 2
tokens: 0
duration_min: 25
findings_fixed: 6
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. Nenhum nome real entrou no diff: a bancada usa nomes inventados e o grafo cita só hashes curtos e contagens."
---

# Passada adversarial: `feat/private-repo-name-guard`

## O que muda

- Nasce a REGRA 119 (O diff não acrescenta nome de repo ou de clone de adotante não federado), com o
  helper `.claude/validation/private-name-check.sh`. Ela só se aplica à fonte.
- O conjunto proibido é derivado em tempo de execução, sem lista à mão. Entram o nome de cada diretório
  irmão do checkout principal que é clone git com carimbo do Onion, o nome da origin dele e os caminhos
  do mapa local de membros. Saem os ids, remotes e local_paths do `members.yaml`. Somam-se os termos da
  lista de clientes, menos as variantes de membro federado.
- Julga as linhas acrescentadas contra o merge-base com a origin/main e o caminho dos arquivos novos.
  Nunca imprime o termo: a saída é arquivo, linha e hash curto, e o caminho sai com o termo trocado por
  `<hash>`.
- No CI não há máquina: a guarda julga pela lista do segredo e diz isso (SOFT SO-LISTA). Sem a lista
  também, ela declara NAO-VERIFICADO.

## Dogfood

- **Replay do defeito.** Rodei a guarda no commit `9ea6af77e` (04/11) contra o pai dele, com a lista de
  termos vazia, que era o estado daquele dia. Ela acusa as 3 linhas do vazamento (hash `925bcbd1`). O nome
  vinha da origin do clone, não do nome do diretório.
- **Árvore viva.** Acrescentei numa linha o nome real do clone do mapa: HARD, com o hash `43b05e10` e sem o
  termo na saída. Depois reverti.
- **Falso positivo na história da main** (`--base` antes de cada data, sobre a `0a6f15f36`): desde 24/10
  (864 commits) houve 0 achados. Desde 01/10, a 1ª redação deu 38 achados e a atual dá 5, em 4 arquivos,
  todos nomes de clone não federado. Esses 5 são passivo da main que a guarda não cobra.

## Achados

1. **BLOQUEANTE, curado (fail-open).** Os termos da lista chegavam ao juiz pelo stdin, mas o stdin do
   `python3 -` é o próprio heredoc do script. A guarda rodava com **zero** termos declarados e não dizia
   nada. Quem pegou foi o caso "acusa: termo da lista declarada" do selftest. Agora os termos vão por um
   arquivo temporário 0600 e nunca passam por argv.
2. **BLOQUEANTE, curado (falso positivo em massa).** Termo da lista que é variante de grafia de um membro
   federado (o mesmo nome com ponto ou hífen) reprovava toda menção nova a esse membro: foram 33 dos 38
   achados da 1ª medida. Agora a comparação com o federado é pela forma normalizada.
3. **Real, curado (falso positivo).** O nome derivado depois de hífen casava dentro de outro
   identificador, como `hero-<nome>` numa classe CSS do site. Agora o derivado não casa depois de hífen ou
   sublinhado. Seguido de hífen ele ainda casa (`<nome>-wt`), porque ali ainda nomeia o clone.
4. **Real, curado.** Na máquina, sem a lista de termos (por exemplo sob `env -i`), a guarda julgava só pela
   derivação e não dizia isso. Agora sai SOFT SEM-LISTA.
5. **Real, curado (bancada).** Os casos do selftest vazavam arquivo stageado de um caso para o outro, e um
   caso de caminho contaminava os casos "cala" seguintes. Agora cada caso começa com `reset --hard` e
   `clean`.
6. **Real, curado (bancada).** A REGRA 59 (Modo que a produção consome é exercitado pela bancada)
   reprovou no `pr-finalize`: o lint consome `--tsv`, e a bancada só o exercitava por dentro do selftest
   do helper. A família ganhou o caso ponta a ponta em `--tsv`, com nomes inventados.
7. **Teto, declarado.** Ficam fora mensagem de commit, corpo de PR, clone fora do pai do core, repo que
   só existe no remoto, abreviação e nome derivado com menos de 4 caracteres. O hash de um nome curto
   correlaciona, mas não esconde.
8. **Não é defeito.** Um clone novo na máquina, ainda sem registro, tem o nome barrado no core até entrar
   no `members.yaml` (ou entrar com id neutro, como no #1522). Isso é o desenho.

## Bancada

A família `private_name` roda o selftest do helper (18 casos com nomes inventados). Roda também os dois
mutantes pedidos, com âncora que reprova se não casar: o que não deriva e o que imprime o termo. Os dois
morrem. Por fim, confere o registro no dispatcher. A família `shell_pipefail_robustness` fica verde: os
vereditos leem por here-string.
