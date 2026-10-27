---
branch: fix/sge-review-round2
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: b698d7cc3f48e3887dbdc4738e6777908e29729ac540fc93938a6419b48e1f56
reviewed_code_sha256: 4fc36b320348fa5eac2434d34f1214515713f2c64e0bc6189b55afa2eb4a629d
findings_total: 10
findings_real: 5
tokens: 123564
duration_min: 7
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador novo (general-purpose, brief com o código e sem a conclusão), sondas executadas em repos e fixtures descartáveis
nota: "Os 4 defeitos de origem (M1-M4) vêm da revisão adversarial do adotante sge sobre o update para o pin c012991f32f6 (PR #158 dele). Os 10 achados abaixo são da passada sobre a CURA deles: 4 do refutador curados, 1 da bancada (paridade do bloco no pre-push), 5 menores declarados como teto."
---

# Passada adversarial: `fix/sge-review-round2`

## O que muda

Quatro achados da revisão do adotante sge sobre a maquinaria do core no update `c012991f32f6`. Cada um foi
REPRODUZIDO com o código de `origin/main` (`c012991f3`) antes da cura:

1. **M1, trampolim e `core.hooksPath` relativo.** Repo descartável, worktree com o pre-commit sem `+x`:
   com `hooksPath=.githooks` o git imprime `hint: … ignored because it's not set as executable` e o commit sai
   **rc 0**; com o absoluto, o trampolim barra com rc 1. É limite do git, e nenhum código de hook alcança o caso.
   A cura declara o limite no bloco do trampolim (`.githooks/pre-commit`, `.githooks/pre-push` e o template
   `githook-pre-commit-onion.tpl`). A guarda barata por outro caminho **já existia** e não tinha caso:
   `prove-gate-blocks.sh` resolve o hook por `rev-parse --git-path hooks`, que honra o relativo na worktree, e
   recusa o não executável com rc 3. Caso novo (o3) e mutante (MUT-relx). O bit perdido JÁ commitado (modo
   100644) segue sem guarda no commit do relativo, e isso está declarado.
2. **M2, o `mkdir -p` do `kg-trace.sh --out`.** Reproduzido: rc 3 e `new/deep/` ficava na árvore. A cura
   mede o ancestral mais alto que o script cria e desfaz a cadeia (rmdir, só vazio) em todo caminho de erro,
   pelo trap EXIT. Caso (j6e) e mutante (trap sem o desfazer).
3. **M3, `kg-read-leg.sh` e heredoc.** Reproduzido: com o hook da main, `echo "a<<b"` seguido de `sed -i` e
   `cat <<$X … $X` seguido de `sed -i` calavam (os quatro sub-casos do (r2) vazios). A cura troca a regex por
   uma varredura que segue aspas, comentário, aritmética e lê a palavra do delimitador literal, como o bash.
   O par `$((1<<2))` do (r) segue verde. Caso (r2) e mutante (r2-MUT).
4. **M4, o label do `ONION_INSTALLED`.** Forma do grafo real do sge: x_pin e label citam `c012991f32f6`, e o
   label cita também o pin da adoção `ba0d2d423c17`. A cura troca no label o token exato do pin antigo,
   quando ele aparece uma vez. Caso (i5) com três ramos e mutante. Os casos (i3) e (i4) mudaram de
   expectativa, porque afirmavam o comportamento antigo (label intocado).

## Achados

| # | Severidade | Achado | Desfecho |
|---|---|---|---|
| 1 | real | `--out novo/../velho/x/idx.tsv`: o desfazer subia por `novo/..` e **apagava `velho/`**, vazio e pré-existente, deixando `novo/` | curado: `realpath -m` antes de medir a cadeia, e o destino segue o caminho normalizado. Caso (j6f) e mutante |
| 2 | real | label com o pin antigo DUAS vezes (`Histórico: X -> fff0001, agora X`): as duas viravam o novo, e a história mentia | curado: só troca com uma ocorrência; repetido, rc 3 e intocado (i5c) |
| 3 | real | `cat << 2` é heredoc no bash, e a regra do dígito o lia como deslocamento (o corpo avisava). Já existia antes | curado: fora de aritmética, `<<` é sempre heredoc; `$[…]` entra como aritmética. Casos q6 e q7 do (r2) |
| 4 | real | `$'it\'s'` desalinhava a aspa, e o heredoc seguinte não era reconhecido | curado: `$'…'` com escape |
| 5 | real (da bancada) | `githook-trampoline (p)`: o bloco do `.githooks/pre-push` divergiu do pre-commit | curado: o mesmo comentário nos três arquivos |
| 6 | menor | `"pin X desde 2026-01"`: a data do dono passa a mentir depois da troca | teto declarado: a frase é do dono, e o motor troca só o token |
| 7 | menor | aspas aninhadas dentro de `"$(…)"` desalinham a varredura | teto declarado no hook: o tokenizador da guarda desalinha igual, e o efeito medido no hook é silêncio |
| 8 | menor | `((cat <<EOF` sem espaço é lido como aritmética | teto: raro, e o efeito é o corpo não ser tirado |
| 9 | menor | diretório que outro processo cria entre a medida e o mkdir pode sair no desfazer, se estiver vazio | teto declarado no comentário (o rmdir nunca apaga conteúdo) |
| 10 | menor | label com a forma curta do pin (7 hex) e o x_pin longo: o label não troca (rc 3), enquanto verified_against troca por prefixo | erra para calar; declarado |

O refutador confirmou o comentário do M1 com a medida dele (rc 0 no relativo, `HOOK-RAN rc=1` no absoluto).

## Mutantes

- (j6e-MUT) trap sem `_oundo` → o rc 3 larga o diretório → (j6e) cai.
- (j6f-MUT) sem a normalização → `velho/` apagado → (j6f) cai.
- (r2-MUT) a varredura sem seguir aspas → o `<<` entre aspas engole o `sed -i` → (r2) cai.
- (i5-MUT) sem a troca no label → (i5a) cai.
- (MUT-relx) sem conferir o `+x` do hook resolvido → a prova (o3) não nomeia o modo.

## Limites declarados

- M1 não tem cura no hook: com o relativo, o git não executa o arquivo. O bit perdido COMMITADO só é visto pela
  prova do gate no `--update` e por `git ls-files -s .githooks/pre-commit`.
- Os itens 6 a 10 acima.
