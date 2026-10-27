---
branch: fix/rule36-skip-binary
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 5
tokens: 97044
duration_min: 3
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose novo, com brief cético e sem a conclusão do autor
nota: "tokens e minutos são os do subagente revisor (176 s); 2 dos 7 achados foram verificações sem defeito"
---

# Passada adversarial: `fix/rule36-skip-binary`

## O que muda

A busca por substring da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) e a família
`sub` do `door-leak-scan.sh` (o passo (5a) da publicação, e a REGRA 106 (Superfície que viaja passa pela
varredura de vazamento da publicação)) ganham `-I`: arquivo binário fica fora da busca. Motivo medido:
um GIF de 837 KB vendorizado casava por acaso um termo privado de 3 letras. Com o mesmo GIF e a mesma
lista, o lint de antes dá 1 HARD e o de agora dá 0.

## Achados

| # | severidade | achado | estado |
|---|---|---|---|
| 1 | média | o comentário novo do `door-leak-scan.sh` dizia que `word` e `home` "seguem lendo binário". Medido: com `-o` e sem `-a` o GNU grep suprime a linha casada de binário, então essas famílias já eram cegas a binário antes do PR | corrigido: o teto declara o ponto cego nas três famílias |
| 2 | baixa | texto com um NUL perdido e arquivo esparso perdem a cobertura com `-I` | declarado no teto (os dois comentários) |
| 3 | baixa | "binário fica fora" exagerava: binário sem NUL, ou com o 1º NUL depois de MBs, ainda casa | corrigido: o critério agora é "NUL que o grep vê antes do casamento" |
| 4 | baixa | a bancada não fixa a afirmação sobre `word`/`home` em binário | aberto: a afirmação virou declaração de teto, não garantia, e não tem o que fixar |
| 5 | info | o branch estava atrás da `origin/main` | corrigido (rebase) |
| 6 | — | Latin-1 (C e UTF-8), SVG de ~600 KB e UTF-16 sem regressão | verificado, sem defeito |
| 7 | — | `projection-safety.sh` filtra por extensão de texto; `ops/publish-door.sh` delega ao `door-leak-scan.sh` | verificado, sem defeito |

## Mutantes

- (e) o lint do sandbox sem o `-I` volta a acusar o binário;
- (f-MUT) o `door-leak-scan.sh` sem o `-I` volta a acusar o binário.

O revisor rodou a família e confirmou que os dois mordem, que o sandbox (`mktemp -d` +
`_archive_staged`) não toca a árvore viva e que a lista real não entra (`ONION_CLIENT_TERMS_FILE`
sintético).

## Limites declarados

Texto legível dentro de binário (EXIF/XMP, PDF ou `.tar` sem compressão, sqlite) não é visto por
nenhuma das buscas. Isso pede um passo próprio de extração por formato, e fica declarado, não
implementado.
