---
branch: docs/adopter-gate-inert
pr: 623
date: 2026-08-16
reviewed_diff_sha256: b890693ecc740743e6cbb3d3bcc721db9b3a1a60fb6bdb969c26b262762fe9b1
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 0
duration_min: 45
verdict: CONFORME-COM-CAUSA-RAIZ-ACHADA
reviewer: passada por EXECUÇÃO em 3 adotantes reais (2 estados de falha + 1 vivo) — a sonda encontrou defeitos NELA MESMA nas duas primeiras rodadas
REVISOU: true
---

# Resíduo — `docs/adopter-gate-inert`

Investigação do não-uso (escolha do maestro) + o verificador de gate + a costura no
`/meta:adopt`. Os três achados vieram de **rodar**, não de ler.

## Achado 1 — a causa raiz estava no instalador, não no adotante

`install-onion-githook.sh` tem never-clobber em `core.hooksPath`: com husky no caminho,
ele avisa no stderr e **sai 0**. A adoção reportava sucesso com o gate morto. Instalar
nunca foi sinônimo de proteger — e o exit code dizia "fiz a minha parte", não "a guarda
está viva". É a mesma classe do `echo "MERGED"` de hoje cedo, num artefato de junho.

## Achado 2 — a sonda deu falso positivo na 1ª execução real

No metagamify ela declarou "bloqueio provado" porque o lint reprovava e o commit falhou —
mas quem barrou foi o **husky**, não o gate do Onion, que nem executou. Atribuir a outro o
mérito de barrar é exatamente o que a sonda existe para pegar. Corrigido: só afirma
bloqueio se o **nosso** hook comprovadamente executou; senão declara "não avaliado".

## Achado 3 — a sonda tocaria o índice de quem verifica

A v1 fazia `git add` no índice real. Rodando dentro do `/meta:adopt`, um `git add`
pendente do adotante entraria no commit-sonda e seria commitado junto — e depois "desfeito"
por um reset que ele não pediu. Corrigido com `GIT_INDEX_FILE` temporário. **Ferramenta de
verificação que altera o estado de quem verifica não é verificação, é dano.** Provado: com
mudança staged no alvo, o índice ficou idêntico antes e depois.

## Verificação por execução (3 adotantes reais)

| alvo | veredito | exit |
|---|---|---|
| granaai | gate VIVO — hook executou **e barrou** com lint reprovando | 0 |
| metagamify | INERTE — hook do Onion em `.githooks` que o git ignora (`hooksPath=.husky`) | 1 |
| onion-pedro | INERTE — `hooksPath=.githooks` sem pre-commit lá | 1 |

Nenhum deixou rastro: sonda apagada, HEAD original preservado nos três.

## Limite declarado

O **bloqueio** só é provado quando o lint do alvo já reprova por conta própria — não existe
gatilho HARD portátil entre adotantes, e inventar um testaria a sonda, não o gate. Quando o
lint está limpo, o script diz "bloqueio não exercido" em vez de contar como aprovado.

E um limite de processo, não de código: o PR anterior (#622) foi **fechado** quando o
monitor já armado mergeou a base com `--delete-branch` — a correção `--keep-branch` chegou
minutos depois. **Corrigir o artefato não retroage sobre o trabalho já disparado.**

## Achados 4 e 5 — os que o CI encontrou depois do primeiro push

**4. Provar gate onde não há gate reprovava o contexto errado.** O `lint-selftest.sh`
exercita o instalador num repo temporário sem commits e sem lint; o fail-closed novo tentava
provar o gate ali e matava a suíte sob `set -e`. Conserto semântico: a prova só se aplica
quando existe `.claude/validation/lint-artifacts.sh` no alvo e o repo tem HEAD — nos dois
casos inaplicáveis, declara "prova adiada" e sai 0. Bancada depois: **0 falhas, 0 pulados**.

**5. O meu mecanismo de merge mentia no diagnóstico.** `gh pr checks` sai não-zero quando um
check FALHA, e o script traduzia qualquer rc≠0 como "não consegui ler os checks" — mandando
procurar problema de acesso onde havia regressão. Curado: captura sem morrer, decide pelo
conteúdo. Revalidado contra o próprio #623.

**Falha de processo, registrada porque é a causa dos dois:** rodei `lint-artifacts.sh` antes
de subir e **pulei** `lint-selftest.sh` — script separado, >10 min. A bancada existe para
pegar exatamente isso, e só não pegou antes porque não a rodei.
