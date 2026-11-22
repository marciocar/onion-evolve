---
branch: fix/preflight-selects-fixtures
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 14
findings_real: 12
findings_blocking: 6
tokens: 237032
duration_min: 7
findings_fixed: 8
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: dois subagentes general-purpose (opus), mandato de refutar, só leitura (diff inteiro; depois o delta do --jobs)
nota: "A passada refutou a 1ª forma (superfície só do 1º nível citado pelo lint) com juízes chamados por checks, lib/, utils/ e check apagado escapando; curados por fecho e candidatos da base. Duas premissas do comentário estavam erradas e foram corrigidas. O custo de parede de fixtures no pré-voo fica como limite declarado, medido no dogfood."
---

# Passada adversarial: `fix/preflight-selects-fixtures`

## O que muda

O `ops/testing/preflight-families.sh` ganha o bloco da superfície das regras. Ele deriva a superfície por fecho a
partir do `lint-artifacts.sh` do índice. Quando o diff a toca, o bloco soma `fixtures`, `sweep_fixtures` e
`lint_hard_file`. O bloco da porta mini e o mapa das linhas da bancada deixam de tratar o Python que cai como
"não toca". Uma BASE que o git não resolve agora sai com rc 2.

A bancada ganha os casos de `preflight_families` (g, h, h2, h3, i, j, j2, j3, k-MUT) e o caso (e2).

## Achados

1. **Real, bloqueante, curado.** Um juiz chamado por outro check citado escapava: `design-context-check.py`, os
   `plugin-*-check.sh` e `kg-fixture-paths.sh`, 13 ao todo. A superfície agora é um fecho, coberto pelo caso (h2).
2. **Real, bloqueante, curado.** Arquivos em subpasta escapavam: `lib/pt-br-words.txt` e `lib/status-factor.awk`.
   A busca agora desce em todos os níveis de `.claude/validation/`, coberto pelo caso (h2).
3. **Real, bloqueante, curado.** Arquivos de `.claude/utils/` que o lint carrega escapavam: `kgssot-tools.sh` e
   `safe-count.sh`. Eles agora casam pelo caminho a partir de `utils/`, coberto pelos casos (h) e (i).
4. **Real, bloqueante, curado.** Apagar um check que o lint ainda chama não selecionava nada. Os candidatos agora
   vêm também da base, coberto pelo caso (h3).
5. **Real, bloqueante, curado.** Com BASE inválida, o diff saía vazio e vazio contava como "não seleciona". A BASE
   agora é verificada uma vez, para os três blocos, coberto pelo caso (j3).
6. **Real, bloqueante, curado.** No 1º bloco (linhas da bancada), um traceback do Python virava "nenhuma família".
   Agora sai com rc 2, coberto pelo caso (j2).
7. **Real, curado.** Algumas `.txt` são configuração de regra (`claude-md-size-ceiling.txt`), não baseline. Agora
   só os `*-baseline.txt` ficam fora.
8. **Real, corrigido no texto.** A premissa "o mapa não enxerga" estava errada. O mapa liga `fixtures` ao lint,
   mas junto com outras ~80 famílias, e o pré-voo não usa o mapa.
9. **Real, mantido e declarado.** `sweep_fixtures` não julga regra. Fica porque a sessão que encomendou a cura
   pediu, e custa ~0 s. O comentário agora diz isso.
10. **Não acolhido: derivar as famílias pelo mapa.** As ~20 famílias que citam `fixtures/` são quase todas de
    grafo (kg_*) e não julgam o lint. `lint_hard_file` roda o lint pelo SANDBOX e o mapa não a liga ao lint. A
    lista curta fica, conferida pelo caso (g).
11. **Não acolhido: separar código de comentário no lint.** O revisor mediu que só 4 nomes aparecem apenas em
    comentário, então o ganho seria pequeno.

## Segunda passada: o delta do `--jobs auto`

O dogfood serial na cabeça do #1735 passou de 50 minutos. Por isso o `preflight-run.sh` passou a mandar
`--jobs auto` quando a lista tem `fixtures`, e o caso (l) entrou na bancada. Um segundo refutador revisou só esse
delta.

12. **Real, corrigido no texto.** O motor usa `min(jobs, famílias)` workers, então a fatia de fixtures tem de 2 a 6
    partes, não nproc. O comentário passou a declarar esse limite. Tirar o teto do motor muda a bancada inteira e
    fica fora deste PR.
13. **Real, limite declarado.** Um pré-voo que segura uma vaga do lease pode ocupar até `_j` vagas do semáforo da
    bancada. A exposição é a mesma do pre-commit, que já roda com `--jobs auto`. O total segue limitado pelas 8
    vagas da máquina.
14. **Real, já existia, declarado.** Com `ONION_SELFTEST_FULL=1`, o pré-voo segue serial.

O refutador verificou que não há deadlock entre o lease e as vagas. Também verificou que o caso (l) distingue o
mutante e que a soma sob `--jobs --families` está certa. Um mutante pelo `mutate-and-restore`, que tira a linha do
`case`, foi morto.

## Mutantes

Os mutantes foram plantados pelo `ops/mutate-and-restore.sh` no `preflight-families.sh`, e a família
`preflight_families` matou todos (helper rc 1):

- o ramo 0 do bloco das regras;
- o ramo "não decidi" do bloco das regras;
- o fecho (`todo.append`);
- os candidatos da base (`ls-tree`);
- o casamento por `utils/`;
- o prefixo `fixtures/`;
- a exclusão da bancada;
- a exclusão dos `*-baseline.txt`;
- a verificação da BASE;
- o rc do mapa das linhas;
- o ramo "não decidi" do mini.

A 1ª passada pegou um mutante sobrevivente no ramo "não decidi": o grep solto casava o aviso do stderr e o
`sweep_fixtures`. A asserção agora julga só a última linha, por token exato.

## Limites declarados

- **Custo de parede.** `fixtures` é a família mais cara da bancada (4306 s somadas no CI), e o pré-voo a roda sem
  faixas nem `--jobs`. Um PR que toca a superfície das regras (131 de 272 arquivos de `validation/` e `utils/`)
  paga isso no fechamento. O tempo medido no dogfood está no PR.
- **Fora da superfície, declarado.** `vendor/` (a kg-ssot vendorizada tem gate próprio) e os dados de `docs/`
  (por exemplo `members.yaml`).
- **Casamento pelo nome em `.claude/validation/`.** Dois arquivos de mesmo nome em pastas diferentes entram juntos.
  O erro é para o lado de rodar mais.

## Correção da declaração (22/11)

O revisor desta passada foi um agente separado do autor, como dizem o campo `reviewer:` e o corpo, mas o
frontmatter não declarava `elenxo_isolado: true`, e o `ops/pr-merge-verified.sh` recusa o merge de PR de guarda
sem esse campo. Acrescentei só a declaração. O código revisado não mudou: o diff volta a `pendente` e o hash do
código foi apagado, para o `pr-finalize` carimbar de novo.
