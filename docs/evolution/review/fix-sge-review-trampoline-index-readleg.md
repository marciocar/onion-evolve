---
branch: fix/sge-review-trampoline-index-readleg
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 39eb11378905cdfd9ad35a6032600ee09c35e9f332a47e8e1ece872c20bf7560
reviewed_code_sha256: f3ee745be06f62303c8fa2131514d241352a38b0df53cc4c5bdb2487e32d0d5d
findings_total: 6
findings_real: 6
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão de execução (passada inline, sondas executadas contra o hook real e repos git descartáveis)
nota: "tokens 0 = não medido: a passada foi inline na sessão de execução, sem subagente. Os três defeitos de origem vêm da revisão adversarial do adotante sge sobre o update para o pin 76ccb2f8aef4; os 6 achados abaixo são da MINHA passada sobre a cura deles (o 6º, pré-existente, veio da prova do gate)."
---

# Passada adversarial: `fix/sge-review-trampoline-index-readleg`

## O que muda

Três defeitos menores que a revisão adversarial do adotante sge achou ao revisar o update para o pin
`76ccb2f8aef4`. Cada um foi REPRODUZIDO antes da cura, com o código de `origin/main` (46ee7a4f):

1. **Trampolim de worktree** (`.githooks/pre-commit`, `.githooks/pre-push`,
   `.claude/utils/adopt/githook-pre-commit-onion.tpl`). Com o hook da worktree presente e NÃO executável,
   o bloco caía em silêncio no hook do checkout principal. Reprodução: a bancada antiga ASSERTAVA isso no
   caso (b2) ("segue o do principal"); com o novo (b2) e o código antigo, o commit ANDA pelo hook do
   principal (`0|andou|…/main/.githooks/pre-commit|muda`). Decisão: **falhar fechado** (exit 1, mensagem
   com o `chmod +x`), e não rodar por `bash`. Por quê: o bit perdido é o defeito real. Se o PR o leva à
   main, o git IGNORA hook não executável e o gate some inteiro no principal. Rodar por `bash` provaria o
   hook e esconderia exatamente esse bit. A `prove-gate-blocks.sh` espelha: hook da árvore não executável
   sob o trampolim é NÃO PROVADO (rc 3), nomeando o modo.
2. **`kg-trace.sh --emit-index --out`**. No rc 3 com destino ausente (ou vazio), um `: > <destino>` CRIAVA
   o índice vazio num caminho de erro. Além disso, entre o teste `-s` e a escrita, truncaria o que outro
   processo gravasse. Reprodução: `kg_trace.py` falso com rc 3 → `kg-read-index.tsv` de 0 byte nascia.
   Cura: o rc 3 não toca no destino em caso nenhum. O dia 1 não precisa do arquivo, porque a REGRA 84
   (Índice de leitura do KG em sincronia com os traces) dá SOFT sem índice e o hook cala sem ele (lido em
   `check_kg_read_index_sync`). Caminhos conferidos: rc 0 (temporário ao lado, mv), rc 0 com temporário
   vazio (exit 2, intacto), rc 2 e qualquer outro (intacto), rc 3 (intacto), sinal (trap apaga o
   temporário).
3. **Perna de leitura × guarda do .env "pelo ast"** (`kg-read-leg.sh` × `pretooluse-env-guard.sh`). O
   acoplamento concreto: a perna carrega o `segments` da guarda pelo `ast`. (a) **Falso positivo cruzado,
   reproduzido:** o `segments` é de um VETO, que erra para fechar e lê o corpo de heredoc como comando.
   `cat > notas.md <<'EOF'` com uma linha `sed -i … src/alvo.ts` no corpo (ou a mensagem de um commit por
   heredoc) fazia o lembrete avisar como se fosse edição (4 de 4 sondas avisaram no código antigo). (b)
   **Contrato frágil e não declarado do lado da guarda:** o `ast` só leva constante em MAIÚSCULAS com alvo
   único. Uma constante renomeada para minúsculas faz o ramo calar com a bancada da guarda verde. Cura: a
   perna tira o corpo de heredoc com regra própria (calar vence), o contrato fica declarado nos dois
   cabeçalhos e o caso (s) o prende, comparando o `segments` carregado pelo loader REAL do hook com o da
   guarda executada inteira.

## Achados

Passada adversarial sobre a cura (sondas executadas contra o hook real, num sandbox com índice):

1. **REAL, CURADO.** `$((1<<2))` era lido como heredoc de delimitador `2`, e o `sed -i` da linha seguinte
   calava (falso negativo novo, introduzido pela cura). Sonda: `x=$((1<<2))\nsed -i … src/alvo.ts` deu
   `avisou=0`. Cura: `<<` seguido de dígito não abre corpo. Agora avisa, e está no caso (r).
2. **REAL, DECLARADO.** `bash <<EOF … sed -i … EOF`: o corpo É código executado, e a perna cala. É a
   direção escolhida para lembrete (calar vence apontar errado). O veto da guarda segue julgando esse corpo
   como comando, porque ele não usa a cura.
3. **REAL, DECLARADO.** A falha fechada do trampolim barra TODO commit numa worktree em que o `-x` mente
   para baixo (montagem `noexec`, `core.fileMode=false` com checkout sem o bit). A mensagem diz o conserto,
   e `--no-verify` segue como escape humano declarado.
4. **REAL, DECLARADO.** Hook da worktree como symlink QUEBRADO, ou diretório, dá `-f` falso e é tratado
   como ausente: cai no principal, como antes. Fora do escopo do achado do sge (o arquivo existe e não é
   executável); fica nomeado.
5. **REAL, DECLARADO (pré-existente, não tocado).** O 1º ramo da perna (o regex de `.kg.yaml` sobre o
   comando cru) segue vendo menções a `.kg.yaml` dentro de corpo de heredoc. É aviso de menção a grafo,
   não de edição, e mudá-lo é outra leva.

6. **REAL, CURADO (pré-existente, achado pela prova do gate).** A `prove-gate-blocks.sh .` no core dava
   "controle rc 1 sem HARD medida". Com `bash -x` num clone sem `origin`, a causa: a guarda
   anti-commit-na-default-branch do `.githooks/pre-commit` (core-only) lia `symbolic-ref
   refs/remotes/origin/HEAD | sed` sob `pipefail` + `set -e`, e sem `origin` o hook morria ali, rc 1 sem
   uma palavra. É a mesma classe do caso (g) da família githook no template. Cura: `|| true` dentro do
   grupo, antes do pipe. Caso (i) e mutante (i-MUT) na família githook.

Sondas que confirmaram a cura: here-string `<<<` não abre corpo (avisa); dois heredocs na mesma linha
(`<<A <<B`) consomem os dois corpos em ordem e o `sed -i` depois avisa; heredoc sem terminador cala;
`<<EOF` dentro de aspas cala o resto (silêncio, na direção certa).

## Mutantes

- `githook-trampoline: (b2-MUT)`: o bloco com o `-x` de volta na condição (a forma anterior) faz o commit
  passar pelo principal, e o (b2) acusa.
- `prove-gate-blocks: (MUT-trampx)`: sem a falha fechada na prova, o (o2) perde o veredito.
  `(MUT-tramp)` teve a âncora reindentada (o `H=` agora vive dentro do `if` do `cmp`).
- `kg-trace: (j6c-MUT)`: o `: >` de volta no rc 3 faz o (j6c) cair.
- `kg-read-leg: (r-MUT)`: com o `segments` cru, o corpo do heredoc volta a avisar.
- `kg-read-leg: (s-MUT)`: com `KEYWORDS → keywords` na guarda, o (s) acusa `NameError` no `case` depois de
  `then`. A 1ª redação do corpus (8 comandos) NÃO mordia: o `all(... KEYWORDS ...)` é preguiçoso e só
  avalia com palavra-chave antes do `case`. O 9º comando existe por isso.
- Antes/depois: com os arquivos de `origin/main` no lugar, (b2), (j6c) e (r) reprovam. Com a cura, as
  famílias tocadas passam 121/0.

## Limites declarados

- O (s) cobre o contrato no corpus de 9 comandos, não no espaço inteiro: uma constante que só o caminho
  de um comando fora do corpus usa escaparia. O cabeçalho da guarda declara o contrato para quem edita.
- `1 << n` com variável segue lido como heredoc `n` (silêncio).
- Os achados 2 a 5 ficam nomeados aqui e nos comentários dos arquivos, sem nó próprio: nenhum tem dano
  medido em campo.
