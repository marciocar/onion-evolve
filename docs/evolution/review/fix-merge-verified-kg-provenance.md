---
title: 'Resíduo — o pr-merge-verified recusa o rebase quando o .kg.yaml cita commit da própria branch'
date: 2026-10-09
branch: fix/merge-verified-kg-provenance
reviewed_diff_sha256: f0417801e256c5a5af172132f1eb6be2a009753bf0ca65108e621ba0fc23ca4e
reviewed_code_sha256: 522c51334a0e7047407906e2e5ed08e1a90538afc04ff48eb46efa43422d3006
findings_total: 4
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 50
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-80, nó Q_REBASE_QUEBRA_PROVENANCE_DA_BRANCH, conduzido pelo /meta:drive (degrau AUDIT) a partir do
  sinal 2026-10-08-rebase-merge-breaks-kg-provenance de um adotante. Defeito medido lá: o .kg.yaml do PR
  citava caminho@sha de commit da própria branch, o merge por rebase (modo padrão do
  ops/pr-merge-verified.sh) reescreveu o sha, e 6 provenance ficaram fora da main com radar, lint e CI
  verdes. Cura selada pelo maestro: prevenção no script. Antes do merge, se o PR toca *.kg.yaml, a
  guarda lê as linhas ADICIONADAS (git diff base...head, flags canônicas) e extrai @<sha> de 7 a 40 hex
  só do VALOR de uma chave source: (bloco, ou mapa em fluxo, cortado no fim da string citada). O git
  classifica: não resolve = fora do escopo, contado; ancestral da base = nada; senão = commit da
  branch. Sem --merge-commit recusa antes de qualquer efeito, nomeando sha e arquivo e mandando usar
  --merge-commit; com a flag, depois do merge provado confere a ancestralidade de cada sha contra
  origin/<base> e sai rc 3 se falhar (a forma do --assert-ancestor). PR sem .kg.yaml não faz leitura
  de git. Bancada pr_merge_verified com LC_ALL=C: 36 de 36, 9 casos novos (kg-a, kg-b, kg-b2, kg-c,
  kg-c', kg-d, kg-e, kg-f, kg-g), cada um rodado também contra um mutante que tira a parte da cura que
  ele protege, e todos os mutantes reprovaram: m0 (sem a guarda) em a/b/b2/c/f/g, manc (sem o teste
  de ancestralidade) em c', mscope (sem o filtro .kg.yaml) em d, mfield (todo @sha da linha, não só o
  source) em e. Dogfood fora da bancada: sandbox git com SUT e mutante lado a lado (a recusa, o merge
  com --merge-commit conferido, e o modo de falha com a base recebendo cópia linearizada, rc 3); e o
  diff REAL do core de main~1200 a main, onde a guarda achou a única provenance com @sha do corpus
  (d56f685c no radar-E3 r8), que de fato não é ancestral daquela base. Passada adversarial própria,
  caçando FALSO POSITIVO: (1) sha em label, narrative e locator não dispara (caso kg-e; no corpus vivo
  há 1 @hex fora de source:, num verified_against, e não foi tocado); (2) hex que não é sha
  (deadbee1) não resolve e só é contado (kg-e); (3) num mapa em fluxo, o @sha da branch dentro do
  method: ao lado do source: não vaza para a extração (kg-c). Achado real e curado no mesmo PR: o
  auto-rebase do SAC-78 rebaseava a branch de PR CONFLICTING, o que reescreve o commit citado mesmo
  com --merge-commit; agora o auto-rebase para com mensagem nomeada quando há sha da branch citado
  (kg-f). Segundo achado real, medido pelo CI (faixa 4 da bancada): a família merge_dispensa tem um
  dublê de gh fail-loud que não previa a leitura dos arquivos do PR, e a guarda nova, fail-closed
  nessa leitura, matava os casos (a)(b)(c)(f) dela. A guarda está certa e o dublê estava incompleto
  ([[fail-closed-exposes-incomplete-harness]]): o dublê passou a responder um PR sem .kg.yaml, e as
  famílias merge_dispensa e pr_merge_verified rodaram 43 de 43 com LC_ALL=C. Eu tinha rodado só a
  família pr_merge_verified antes do push, e a outra família que executa o mesmo SUT ficou de fora.
  Tetos declarados: linha de block scalar (narrative: |) que comece com "source:" e cite
  commit real fora da base dispara (só recusa, com a saída --merge-commit); sha curto ambíguo,
  maiúsculo, ou citado por URL sem @ fica fora; o texto diz "própria branch" também para commit de
  outra branch não mergeada, que é igualmente provenance fora da main; com .kg.yaml no PR a guarda é
  fail-closed (precisa de clone local do repo e da API de arquivos do PR, até 3000 arquivos). Prosa
  coerente: a linha de provenance da .claude/rules/kg-grammar.md cita a recusa. Sem Elenxo,
  declarado: guarda estreita de script de serviço, com mutante por caso. Commit com --no-verify como
  checkpoint, por ordem do maestro; validação = família tocada + mutantes + pr-finalize + CI.
---

# Resíduo — `fix/merge-verified-kg-provenance`

Ver `nota:` no frontmatter.
