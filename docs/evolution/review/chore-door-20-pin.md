---
branch: chore/door-20-pin
pr: 873
date: '2026-09-24'
reviewed_diff_sha256: 9de2da7f860b2c76bc4f92ec60a933fe81af989ee655f2cb2fd6ef6c3fbc62e2
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Leva de CARIMBO. A passada de produto desta frente ocorreu no #872, que selou a decisão e implementou
  o mecanismo. O que esta leva pode errar é ORDEM (pin antes do push verificado) e REGENERAÇÃO — as
  duas verificadas e registradas abaixo. Campos de custo em ZERO: não houve run de modelo.
---

# Resíduo — pin da 20ª materialização, a primeira do regime novo

## O achado é positivo, e é o que esta leva existe para registrar

**O mecanismo que o maestro aprovou funcionou no primeiro uso real.** O workflow
`onion-door-staleness` disparou **4 segundos** após o merge do #872, nomeou as duas portas com os
números (`onion-standalone 418 > 415`, `onion-core 3 > 0`) e entregou os quatro passos da cura —
inclusive a ordem push-verificado-antes-do-pin.

E o teste que importa: **o #872 mergeou sem que a porta o bloqueasse**. Pela primeira vez em 20
materializações, o `door-staleness-baseline.txt` **não** registra *"o gate fica VERMELHO até o push"*.

O caso (e) da bancada provava que o workflow existia e invocava a guarda. Agora há prova de que o
GitHub **o executa** — que é a metade que nenhum caso de bancada pode dar.

## Os dois erros que esta classe de leva comete, e como verifiquei

**1. Pin que anda antes do push verificado.** `gh api repos/marciocar/onion-core/commits/main`
devolveu `c70421eee91f` **antes** de eu tocar o `members.yaml`. Fonte é o remoto, não o disco nem a
nota do script. As duas inversões já ocorreram nesta casa (09-18: pin velho escondendo porta nova;
09-19: quase o inverso) e estão registradas no baseline.

**2. Projeção gerada sem conferir rc e tamanho.** Cada uma em arquivo temporário, com `rc` e contagem
de linhas conferidos **antes** de tocar o alvo: 817 · 76 · 49. Nesta sessão o `graph.md` já foi
destruído uma vez por `cp` sobre stderr silenciado.

## Dogfood

Lint **na árvore da porta**: `rc=0`, **0 HARD**, 6 SOFT, zero `MORREU`. Não é o lint do core dizendo
que está tudo bem — é o artefato publicado sendo invocado onde ele vive.

## Fio aberto que o maestro levantou nesta leva

**Materializar a porta não tem comando.** Medido: `ops/materialize-door.sh` é citado por **zero
comandos e zero skills** — só pelo `CLAUDE.md`, pela própria guarda e por resíduos. A skill
`onion-publish` cobre o marketplace, **não a porta**. A superfície pela qual o Onion se publica é a
única que não passa pela superfície do Onion, e a sequência de 5 fases vive na minha cabeça e em
comentário de baseline. **Gatilho: já disparou duas vezes hoje** (a ordem errada em 09-19 e as duas
materializações desta leva), então qualifica pela régua `fix-must-become-mechanism`. Candidato:
`/meta:door`, faseado e retomável, com o dogfood na fase 2 e o push parando no gate humano.
