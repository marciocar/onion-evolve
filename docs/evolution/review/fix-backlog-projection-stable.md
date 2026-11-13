---
branch: fix/backlog-projection-stable
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 3057a27b1c9de789cb5c46784d1f49870dc3f7d076d2c571605b661e1aee4fe0
reviewed_code_sha256: c09f9e022cbb62997312d03948fc1e67c0fbb86503bfa8b6f57d48115f051734
findings_total: 7
findings_real: 7
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: agente de execução (passada própria; o brief proibiu lançar agentes, então a passada independente fica PENDENTE para a sessão principal antes do merge)
nota: "tokens e duração não medidos (0 = não medido). Achados 1 e 2 bloqueavam e foram curados no PR; 3 a 7 são limites declarados abaixo. Falta o refutador independente."
---

# Passada adversarial: `fix/backlog-projection-stable`

## O que muda

- **`kg-backlog-project.sh --write`**: o render vai para um temporário único AO LADO de `docs/backlog.md` e troca
  por `mv` (rename, mesmo sistema de arquivos), com o modo do destino preservado. Antes era `render > "$OUT"`.
- **`regen-ssot-projections.sh`**: o mesmo para as quatro projeções do laço (`testing-state.md` entre elas), o
  índice de leitura e o `lint-rules.md`. Um `trap EXIT` apaga o temporário se a rodada for interrompida.
- **`lint-artifacts.sh`** (`--fix` da REGRA 62 (Projeção GERADA em sincronia com a fonte)): `mv` no lugar do `cp`
  por cima do backlog.
- **Bancada**: família `ssot_projections`, casos (h), (h-MUT), (i) e (i-MUT).

## A causa medida

Num clone em `scratchpad/backlog-repro`, com amostras do tamanho de `docs/backlog.md` a cada 50 ms durante uma
rodada de `--write`:

| | amostras | cortadas |
|---|---:|---:|
| antes (origin/main) | 533 | 187 (9, 16, 25 … 1930 de 1944 linhas) |
| depois | 608 | 0 |

O render leva segundos (um fork de sed, cut e iconv por linha), e durante ele o arquivo no disco fica cortado
no meio de uma tabela. Quem lê nessa janela, no MESMO checkout, pega a metade. Os geradores em paralelo, cada
um no seu arquivo, deram saída idêntica (4 de 4, mesmo md5), e o laço `_regen` isolado deu 3 voltas idênticas:
o gerador é determinístico. Não há nome fixo em `/tmp` (todos `mktemp`), nem `head` sob pipefail no caminho.

## Achados

1. **(curado, bloqueava)** `wait` do processo de fundo nos casos novos sem `|| true`, numa família que roda
   sob `set -e`: um gerador com rc≠0 abortaria a família em vez de reprovar o caso.
2. **(curado, bloqueava)** o comentário dizia "render que falha deixa o vivo intacto", e o rc do render é o do
   último comando: uma falha no meio de um laço não é vista. O comentário diz agora o limite.
3. **(limite)** SIGKILL no meio deixa um `.backlog.md.XXXXXX` oculto (o `trap` não roda). Aparece no
   `git status`; o pr-finalize stageia por lista explícita e não o leva.
4. **(limite)** uma sessão vizinha que rode `git add -A` na janela de milissegundos entre o `mktemp` e o `mv`
   pode stagear o temporário.
5. **(limite)** `_foreign_gen` do `pr-merge-verified.sh` ainda escreve com `cat tmp > destino`. A cópia é de um
   arquivo pronto (milissegundos, não segundos), e fica fora deste PR.
6. **(limite)** `--markdown` sai 0 mesmo se o render cair no meio; não muda aqui.
7. **(limite, não medido)** o `testing-state.sh` descarta a série inteira se a última linha do
   `selftest-runs.jsonl` estiver sendo escrita (json.loads falha). Seria uma 2ª fonte de oscilação, só por
   entrada. Não reproduzi.

## Mutantes

- (h) e (i) **reprovam na origin/main** (rodada com os dois scripts de lá): o leitor parado no meio viu
  `metade-1` e o cabeçalho do backlog no lugar de `ANTIGO`.
- (h-MUT) e (i-MUT) põem de volta o redirecionamento direto, e o leitor vê a metade: os casos são load-bearing.
- Os casos são determinísticos: o gerador (ou o 1º `iconv` do render) avisa e PARA até o caso mandar seguir.

## Limites declarados

Os itens 3 a 7 acima. Falta a passada independente.
