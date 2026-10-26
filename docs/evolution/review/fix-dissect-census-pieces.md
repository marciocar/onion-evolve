---
branch: fix/dissect-census-pieces
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: b72c7bf2f6ff60dd24037cf38223f875e2a23d2a5ac14fb82507ec057d62649b
reviewed_code_sha256: a2f6045ca84cbdf8042a3187872fe7cfcff8b9ebeb4a592e9183a21ebf382a82
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: self (agente de execução, passada sobre o diff inteiro e fixtures de borda)
nota: "tokens não medidos (passada feita na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/dissect-census-pieces`

## O que muda

`.claude/validation/dissect-census.sh` passa a ler `meta.x_dissect_pieces` (lista em fluxo ou em bloco, a forma
que o checador `dissect-object-check.py` já aceita desde o #1368). Com peças, cada uma tem o seu veredito
(`x_dissect_verdict`, ou o apelido `x_piece_verdict`), a nova seção `peças` do markdown lista id, veredito e
estado de cada uma, a coluna veredito junta as peças com `+`, e cada peça negativa (parquear/rejeitar) passa
pelas mesmas regras de superação e critério do veredito único. O julgamento do negativo virou a função
`_neg_why <grafo> [<id>]`. Sem id, ela faz o mesmo de antes (o 1º nó com veredito). Peça recusada sai como
`veredito-SEM-SUPERACAO(<peça>:<motivos>)`, e o `--check-verdict` sai 1 nomeando a peça. Peça declarada sem
veredito sai como `pecas-SEM-VEREDITO(<peças>)`, numa seção própria.

## Achados

1. **REAL, corrigido**: o defeito do brief. Com peças, o censo lia só o 1º veredito. Medido contra o censo do
   `origin/main` com a fixture da bancada: `rc-sem=0`, ou seja, a peça parquear sem superação passava no
   `--check-verdict`.
2. **REAL, corrigido antes do commit**: a primeira redação deixava a linha antiga das parqueadas
   (`[ "${verdict}" = "parquear" ]`) valer também com peças. Um estudo com uma peça só, que parqueia, entraria
   duas vezes na lista. Agora ela só vale sem peças (`[ -z "${pieces}" ]`).
3. **Não é defeito, fica declarado**: mudar o título da seção "a corrigir" para incluir as peças mudaria a saída
   sem peças. Por isso as peças sem veredito ganharam uma seção própria, e a saída sem peças fica byte a byte
   a mesma.

Bordas medidas à mão (fixture temporária): peça que não é nó do grafo vira `pecas-SEM-VEREDITO(D_NAO)`;
`x_dissect_pieces: []` cai no caminho de antes; lista em bloco na mesma indentação da chave é lida; uma peça
rejeitar com superação real (evidência `SUPPORTS`, confirmada) conta, e a peça seguinte, que parqueia sem
superação, é recusada sozinha. O veredito de uma peça não vaza para a outra.

## Mutantes

- **(op-p2m)**: o ramo das peças desligado (`elif [ -n "${pieces}" ] && [ "ONION_MUTANTE" = "" ]`), ou seja, o
  censo volta a ler só o 1º veredito. Nesse caso a peça parquear sem superação passa (`rc-sem=0`), e o (op-p2)
  reprova. Âncora conferida por `cmp`: mutante não plantado é fail.
- Os mutantes que já existiam na família (og-d1m, og-e1m, og-e1m2, og-k1m-*) continuam verdes. A âncora do
  og-d1m (`elif [ "${verdict}" = "rejeitar" ] …`) ficou intacta.

## Limites declarados

- O `--tsv` continua com **uma linha por estudo**. As peças aparecem na coluna veredito (juntas com `+`) e no
  estado, não em linhas próprias. Mudar o número de linhas quebraria quem conta o TSV.
- A forma das peças (2 ou mais, ids distintos, veredito fora das peças) é julgada pelo **checador**, não por
  este censo. Aqui uma lista de uma peça só é lida como lista.
- A comparação byte a byte "sem peças = antes" usa um golden da linha do `--tsv`, medido contra o censo do
  `origin/main` em 2026-10-26, mais o diff do markdown no corpus real deste repo. Nesse diff só a linha da
  régua padrão mudou, e por causa do local do script copiado, não do código.
