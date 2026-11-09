---
branch: fix/public-surface-machine-data
pr: 1559
date: 2026-11-09
reviewed_diff_sha256: 8f60b663f9ddcebf645d6243098162cedc06d1e40a03995bb67da54e020859e8
reviewed_code_sha256: 23d11678278685f4691d625e1c34b135ff4b0413642ec24c28b8227543f4cc3d
findings_total: 14
findings_real: 14
findings_blocking: 4
tokens: 0
duration_min: 0
findings_fixed: 14
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador independente da sessão do core, no head c31b3def7, e o autor nas curas
nota: "O refutador reprovou o head c31b3def7 com 2 bloqueantes e 6 ressalvas, e as curas abaixo vieram depois dele: elas não passaram por nova refutação independente. tokens e duration_min não foram medidos."
---

# O refutador reprovou a guarda de dado de máquina, e a cura levou as 12 entradas junto

## O que muda

- `docs/evolution/federation/members.yaml`: saem host, dois IPs, a porta SSH alternativa e o nome do arquivo de chave.
- `.claude/diary/`: as 12 entradas `protected` viram `public`, sem nomes nem dados de máquina no corpo, por decisão do maestro (`D_MD_PROTECTED_DIARY_RECLASSIFIED_PUBLIC_1109`). 3 arquivos renomeados, e 4 entradas limpas de IP, host e chave.
- `docs/evolution/outbox/diary/`: o espelho perde os mesmos valores.
- `.claude/validation/public-machine-data-check.sh`: REGRA 120 (Registro da federação e diário sem dado de máquina no repo público), com bancada e mutantes.
- `.claude/utils/kg/machine_path.py`: reconhece a forma do nome de máquina.

## Achados

Do autor, antes do refutador:

1. **Bloqueante, curado.** Sem `host:` no registro, a REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe) ficaria cega no CI.
2. **Bloqueante, curado.** Numeração de seção no formato de IP seria acusada.
3. **Curado.** O índice regenerado perdia o título.
4. **Curado.** O teto citava uma contagem anterior à limpeza.

Do refutador:

5. **B1, bloqueante, curado.** A regra barrava adotante privado. A guarda agora só julga `role: source` e cala em porta; a família entrou em `SELFTEST_CORE_ONLY_FAMILIES`.
6. **B2, bloqueante, curado.** Conflito com a main nas linhas `personality_*`: rebase mantendo a main.
7. **R1, curado.** Falha aberta e fronteira da regex ganharam cenário e mutante: ilegível, `ls-files` falho, sem python, fora de git, lista vazia, sem classe.
8. **R2, curado.** A fiação tem caso, a função é citada na bancada, e guarda ausente na fonte com registro é HARD.
9. **R3, curado.** Porta não é classe: o título do PR diz IP, host e chave, e o teto declara a porta.
10. **R4, curado.** Zero à esquerda, forma com hífens, IP colado em letra, CGNAT e nome de arquivo agora são acusados.
11. **R5, curado.** Token de produto e cópias de `known_hosts` calam; número de versão ambíguo tem saída por `machine-data-ok: <motivo>`.
12. **R6, curado.** O espelho foi limpo e entrou no escopo.

Do autor, na cura:

13. **Curado.** A 1ª versão dos cenários reusava a mesma caixa, porque o contador rodava em subshell. Dois cenários reprovaram por isso, e a caixa passou a vir de `mktemp`.
14. **Curado.** O nome de arquivo com hífen antes do host escapava da fronteira da classe. O cenário `nome` achou isso, e hífen e sublinhado viraram separadores só para o nome.

## Mutantes

33 mutantes, com a cópia limpa verde no mesmo arranjo, cada um exigindo que o cenário reprove: fronteiras da regex, classes, escopo, papel, fiação e falha fechada. A família passa 55 de 55.

## Limites declarados

- O histórico do git segue público, e os valores e nomes antigos aparecem nas linhas removidas deste diff.
- A guarda só lê o registro, o diário e o espelho. Outros 34 arquivos rastreados ainda citam os mesmos dados.
- Porta de rede, host fora da forma, IPv6 e nome de chave sem `.ssh/` não são vistos.
- O marcador `machine-data-ok` é honra visível no diff, sem contagem nem catraca.
- `local_path` e caminhos da máquina em comentários ficam: dois hooks de veto e cinco scripts leem o campo.
- Uma referência a `2026-07-16-avell-rescue-doc-predicted-session` segue numa das 12, para não quebrar a âncora: o nome é da marca do notebook, não de cliente ou pessoa.
- A guarda não busca nomes de cliente. A limpeza dos nomes nas 12 foi conferida por uma varredura pontual, não por mecanismo.
