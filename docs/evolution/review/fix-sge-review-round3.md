---
branch: fix/sge-review-round3
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 0
tokens: 139336
duration_min: 9
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: subagente refutador novo (general-purpose, brief com o código e sem a conclusão), sondas executadas em repos e fixtures descartáveis e comparadas com o bash real
nota: "Os 4 achados de origem vêm da 3ª passada adversarial do adotante sge sobre o update fb36b24becfa (PR #160 dele), todos reproduzidos antes da cura. A passada sobre a CURA deu 0 real e 3 menores: um medido como não observável no hook (cura tentada, revertida por não morder), dois anteriores ao diff, declarados."
---

# Passada adversarial: `fix/sge-review-round3`

## O que muda

Quatro achados do sge sobre o update `fb36b24becfa`, cada um REPRODUZIDO com o código de `origin/main` antes da cura:

1. **`kg-trace.sh --out` com destino diretório.** Reproduzido: `--out dir/` saiu rc 1 com
   `mv: '…/.kg-read-index.rUNJok' and '…' are the same file` (o nome vazio fazia o mv mirar o próprio temporário);
   `--out <dir existente>` saiu rc 0 e deixou `.kg-read-index.IynR8s` (395 KB) oculto dentro do diretório.
   Cura: logo depois da normalização do destino, antes do mkdir e do mktemp, barra final ou diretório existente
   saem rc 2 com mensagem pt-BR. Caso (j6g) e mutante (j6g-MUT).
2. **Família a2a_rt sem trap.** Reproduzido com uma falha simulada que sai cedo (cópia da bancada com
   `record_fail; return` logo depois do `mktemp -d`): o sandbox `tmp.*` ficava no TMPDIR. Com o
   `trap 'rm -rf "'"${sb}"'"' RETURN` das irmãs, só sobra o arquivo de outra origem (ver Limites).
3. **`kg-read-leg.sh` e `((cmd) <<E`.** Reproduzido: o caso (r3) novo reprovou com o hook da main (o corpo do
   heredoc avisou `C_NO_DO_SED`). Cura: `_dparen_end` decide como o bash, pelo par do 2º `(`: `))` colado é
   aritmética, `)` seguido de outra coisa é subshell. Caso (r3) e mutante (r3-MUT); (r) e (r2) seguem verdes.
4. **`remeasure-contract.sh` e a linha da base.** Medi o `kg_gate.py` vendorizado do sge (4.33.0) num sandbox
   sem `.kg-ssot/`: **rc 2** (`GATE BROKEN missing baseline`). A afirmação "sairia rc 2" estava certa para a
   AUSÊNCIA; o defeito era outro: desde a 4.16.0 a base é PASTA, e o `is_file()` dava a pasta do sge por
   "ausente; sairia rc 2" enquanto o gate do sge sai rc 0. Cura: a base se escolhe como o `main()` do gate
   (pasta, ou o `gate.json` legado quando a pasta falta) e se lê pelo `read_base` do vendor. No sge a linha
   passou a `0 grafo(s) na dívida MUST travada`. O script não decide pelo rc do gate, mas a frase promete um
   rc, então o caso (l) mede o rc do próprio gate ao lado da frase, e o mutante (l-MUT) reverte ao `is_file()`.

## Achados

| # | Severidade | Achado | Desfecho |
|---|---|---|---|
| 1 | menor | `_dparen_end` não trata `$'…'` com escape: `((echo $'x\'))') <<'EOF'` é subshell no bash e a função o lia como aritmética | cura tentada com caso; o mutante não mordeu: com ou sem a cura o hook CALA nesse comando (a aspa que fica aberta também esconde o corpo do tokenizador). Sem efeito observável, revertida; teto |
| 2 | menor (anterior ao diff) | `--out ''` dá rc 0 e manda o índice ao stdout, ignorando o `--out` | declarado: comportamento antigo, a saída segue correta |
| 3 | menor (anterior ao diff) | `--out <symlink pendurado>`: o mv troca o link por arquivo regular | declarado: o índice nasce onde o caminho aponta pelo nome, e nada se perde |

O refutador confirmou sem defeito: `--out .`, `..`, `./`, `/`, `dir/.`, symlink para diretório (com e sem barra),
`//`; nenhum `.kg-read-index.*` largado. O trap RETURN não dispara em retorno de função aninhada nem em `$(…)`
(sem functrace); a família não usa `.`/`source`. Na base, 12 casos (pasta, pasta vazia, legado, legado ilegível,
`gate` como arquivo, symlink pendurado, ausente…) com a frase batendo o rc real do gate.

## Mutantes

- (j6g-MUT) as duas linhas da guarda removidas → o temporário oculto volta → (j6g) cai.
- (r3-MUT) `_e = None` (todo `((` aritmético, a forma anterior) → o corpo do subshell avisa → (r3) cai.
- (l-MUT) `if base.is_file():` → a pasta sai "ausente, rc 2" com o gate rc 0 → (l) cai.

## Limites declarados

- `((` sem par na mesma linha (aritmética ou subshell multilinha) segue lido como aritmética: declarado no hook.
- `except Exception` na leitura da base contra `Broken/OSError/ValueError` no gate: uma exceção de outro tipo
  daria traceback (rc 1) no gate e "rc 2" na frase; o refutador não achou entrada que a provoque.
- Fora do escopo, achado na reprodução do item 2: a bancada cria `_FIXTURE_NODE="$(mktemp)"` no carregamento do
  arquivo e não o apaga; sobra um `tmp.*` de 218 bytes por corrida, com ou sem falha.
