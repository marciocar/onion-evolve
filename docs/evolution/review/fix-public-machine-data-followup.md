---
branch: fix/public-machine-data-followup
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 6
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 6
verdict: FIXED
elenxo: false
reviewer: autor, curando os pontos do refutador do PR #1559
nota: "Os seis pontos vieram do refutador que aprovou o PR #1559 com ressalvas. As curas são do autor e não passaram por nova refutação independente. A bancada completa local não rodou, por ordem do brief: o gate final é o CI. tokens e duration_min não foram medidos."
---

# A guarda de dado de máquina fecha os pontos que o refutador deixou

## O que muda

- `.claude/validation/public-machine-data-check.sh`: o marcador só vale para IP; o papel do carimbo é normalizado e checado contra o vocabulário; o papel é lido antes de exigir python e a classe.
- `.claude/validation/lint-selftest.sh`: 7 cenários e 15 mutantes novos na família da guarda.
- `docs/evolution/review/docs-diary-review-2026-10-14.md`: a referência renomeada e os dados de máquina que restavam.
- O grafo da forja registra que os nomes seguem nas outras entradas.

## Achados

1. **Curado.** `machine-data-ok` calava a linha inteira, inclusive host e chave. Agora só tira a classe `ip`.
2. **Curado.** `role: "source"`, com aspas ou CRLF, isentava calado. Aspas e CR saem antes da leitura, e papel fora do vocabulário de `write-stamp.sh` vira SOFT `PAPEL-NAO-RECONHECIDO`, não silêncio.
3. **Curado.** Sem python ou sem `machine_path.py`, um adotante dava rc 2 antes de a guarda olhar o papel. A ordem foi trocada.
4. **Curado.** Os mutantes vivos de `HOST_FORM` (`\d{6,}`, `\d{4,}`, `\d{1,}`) e de `DASH_RE` (sem bordas, sem `re.I`) agora morrem.
5. **Curado.** A revisão de 2026-10-14 citava o nome antigo de uma entrada e ainda trazia host e IP.
6. **Curado.** Faltava registrar o alcance da limpeza de nomes: `C_CEILING_ADOPTER_NAMES_REMAIN_1109`.

## Mutantes

A família passa 75 de 75, com 46 mutantes que reprovam e a cópia limpa verde no mesmo arranjo. O `--selftest` passa 40 de 40 em `LC_ALL=C`.

## Limites declarados

- Papel fora do vocabulário gera SOFT e não bloqueia: bloquear um adotante por carimbo estranho repetiria o defeito que barrava adotante privado. Quem tem carimbo não é o core.
- Nomes de adotante seguem em 36 entradas do diário, no índice e em 8 arquivos do espelho, e a guarda não os busca.
- O marcador aceita qualquer motivo e continua sem contagem.
- O histórico do git segue público.
