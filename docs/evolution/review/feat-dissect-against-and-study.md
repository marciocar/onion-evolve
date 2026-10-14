---
branch: feat/dissect-against-and-study
date: 2026-10-14
reviewed_diff_sha256: 61e18bef4304731a34cda45211576a696d97c080a213875246eea385dd36755a
reviewed_code_sha256: e615064be83f3a8cbaf39fcfa4f03d904b1349cc2e62a210eefbef3c9592f25a
findings_total: 7
findings_real: 3
findings_fixed: 3
tokens: 180000
duration_min: 70
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (subagente de execução, sem refutador separado), default reprovado — gate mecânico: família dissect (30 casos, 11 novos), 11 mutantes por ops/mutate-and-restore.sh, bancada nova contra os SUTs de origin/main (11 de 11 reprovam), dogfood em repo de rascunho com os grafos reais + fixture de estudo + fixture de régua por alvo, kg-contract-check nas fixtures, lint-artifacts
---

# Régua por alvo e modo estudo no /meta:dissect (SAC-135) sob o refutador

Implementa as decisões do maestro de 2026-10-14 (`D_DISSECT_REGUA_POR_ALVO` e
`D_DISSECT_MODO_ESTUDO`, no grafo `docs/evolution/research/dissect-forge-2026-10/`): `--against
<repo>` muda a régua de N1/N3/N4 e manda o plano para o repo do alvo; `--study` para no N2 sem
veredito, com uma `question` "adotar?" aberta. A pergunta da passada: **o que esta mudança pode
quebrar, e o que ela pode deixar passar calada?**

## Achado 1 — o evolve-census conta vencidas pela ÚLTIMA coluna do censo (REAL, curado por construção)

Acrescentar `régua` e `estado` à tabela do `--markdown` no fim teria tirado o `frescor` do `$NF`, e o
`evolve-census.sh` (l.113) conta vencidas exatamente por `$NF`. O número de vencidas cairia a zero
em silêncio. Cura: as colunas novas entram **antes** do frescor na tabela, e o caso **(m)** cobra que
o frescor siga a última coluna (mutante que troca `$6` por `$9` reprova). No `--tsv`, as colunas
novas entram no **fim** (8 e 9), e as 1–7 seguem onde estavam. Medido no dogfood: o evolve-census
leu `5 declarada(s) · 0 vencida(s)` do censo novo.

## Achado 2 — régua de outro repo medida no repo errado (REAL, é o defeito que a mudança cura)

Na versão antiga, um plano escrito para o repo do alvo era medido contra o forge-census **deste**
repo. Se o alvo tem o mesmo nome aqui, o plano sai `COMPLETO` com as peças de outro repo. O caso
**(p9)** prova: o `alvo` tem a peça 5 no hub e não no repo do alvo; com `--against-root` o leitor
mede `5:falta`, e o mutante que aponta o forge-census para o hub devolve `5:existe`. E a raiz do
alvo **não é adivinhada** a partir do nome (a cláusula 1 do forge-census: 3 erros medidos em
2026-09-28). Sem a raiz, o plano sai `NAO-MEDIDO` com rc 3, **(p8)**.

## Achado 3 — repo do alvo que o forge-census não mede culparia o PLANO (REAL, curado)

A 1ª forma do `_fc_of` deixava o tsv vazio quando o forge-census do alvo falhava, e o plano saía
`INCOMPLETO(alvo-fora-do-forge-census)`, culpando quem escreveu o plano por uma medição que não
houve. Cura: a falha do censo vira `NAO-MEDIDO(forge-census-nao-mediu-o-repo-do-alvo)`, rc 3, e o
caso **(p10)** a cobra (o mutante que engole a falha reprova).

## O que o gate pegou e a passada não (curado)

A 1ª rodada do `lint-artifacts.sh` saiu com **3 HARD**, todos desta mudança: a REGRA 60 (Identificador de
código em INGLÊS) pegou `repo_alvo` e `tsv_alvo` no leitor (renomeados para `target_repo` e
`target_tsv`), e a REGRA 80 (Números do harness saem de SSOT gerada, nunca de comentário) pegou o
`testing-inventory.md` desatualizado pelos 11 casos novos (regenerado pelo gerador). Na 2ª rodada:
0 HARD, e os 8 SOFT são passivos já existentes no main.

## Hipóteses refutadas pela medição (não eram defeito)

- **"O censo fica mais lento"** — medido sobre os 448 grafos rastreados: 4041 ms antes, 4119 ms
  depois (+2%). Os `sed` novos só rodam nos grafos que se declaram dissecação.
- **"A KG-SSOT reprova as chaves novas"** — `kg-contract-check.sh` na fixture de estudo não acusa
  `x_dissect_mode` nem `x_dissect_against`: o prefixo `x_` é o que o contrato v4 pede.
- **"O `/meta:forge` quebra com o rc 3 novo"** — a carga do forge é `dissect-plans.sh . || true`; o
  rc não interrompe, e a linha `NAO-MEDIDO` diz o que passar.
- **"Os grafos reais mudam de leitura"** — as 3 dissecações do core saem `régua onion · estado
  veredito`, e o único plano (Conductor) segue `COMPLETO` com `4:existe · 7:existe`.

## Tetos declarados (não curados, ditos)

- O censo confere que o estudo tem **alguma** `question` aberta, não que o texto dela seja
  "adotar?". Marcador é auto-atestado, como o resto do censo.
- Só a forma `x_dissect_mode`/`x_dissect_against` é lida (sem a forma herdada sem prefixo): nenhum
  grafo herdado as tem, e chave nova sem `x_` já reprova no contrato v4.
- `--study` com `--level` diferente de 2 é recusa **na prosa** do comando; não há medidor que leia a
  linha de comando. O censo pega o efeito (estudo acima do N2 sai `estudo-INCOERENTE`).
- Um estudo parado no N0 ou N1 (nível reprovado não sobe) sai `estudo` com o nível real na coluna.
