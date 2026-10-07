---
title: "O resíduo da passada adversarial só é cobrado DEPOIS do gh pr create, e no adotante o aviso promete um gate que não existe"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin fe8359e38b43)
to: core (onion-evolve)
flow: upstream
severity: low
decision_owner: core (maestro sela)
---

# Avisar depois não fecha a classe, e o aviso do adotante cita uma REGRA que não julga ali

O pedido é para o core **decidir pela lente do Onion**: medir antes de curar, registrar a decisão como
nó no grafo, passar pelo Elenxo, preferir mecanismo a conselho e declarar o teto. Este sinal traz o
caso e a medição. A escolha é do core.

## O que aconteceu (2026-10-07, PR #2 do onion-kg-ssot)

A sessão rodou `gh pr create` sem `docs/evolution/review/<branch>.md`. O `bash-empty-result-guard.sh`
(PostToolUse) disparou `PR-SEM-PASSADA-ADVERSARIAL` **com o PR já aberto**. O custo foi um segundo
commit e um segundo push só para o resíduo. Na mesma sessão, a mesma família de hooks pegou outros três
retrabalhos depois do ato (`$?` lido após pipe 2×, e REGRA citada sem título). O maestro pediu: "que
isso não se repita de forma errada, ser eficientes e eficazes".

## O que foi medido no core (HEAD `38fdbc7e`)

1. **O teto já está declarado.** O `bash-empty-result-guard.sh` diz que "PostToolUse é posterior por
   definição" e que um PreToolUse que negasse antes "foi PROJETADO E REFUTADO em 2026-08-06 (N pós-cura
   = 0; ~1 em 3 merges seria travado; e PreToolUse é substrato NÃO-VERIFICADO neste repo). Reabre só com
   um merge cego novo."
2. **Uma premissa daquela refutação caiu.** Desde 2026-09-02, o `pretooluse-merge-gate.sh` é "o 2º veto
   REAL da casa" (exit 2 antes de executar). O PreToolUse(Bash) deixou de ser substrato não-verificado.
3. **A refutação foi sobre MERGE, não sobre CREATE.** O critério de reabertura ("merge cego novo") não
   cobre este caso. Para `gh pr create`, o predicado candidato é barato e determinístico: o artefato
   `docs/evolution/review/<slug>.md` existe no diff? Não envolve hash nem estado de CI. A medida que
   decide é a taxa de falso-positivo, por exemplo um PR legítimo que nasce antes da revisão (draft).
4. **Defeito à parte, no adotante:** `_tem_gate_r56()` testa só se `review-artifact-check.sh` EXISTE.
   Com `role: adopted|hub|standalone`, a REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)
   sai `⊘ fora de escopo: repo-derivado`, por desenho, porque "o adotante tem o ritual dele" (comentário
   em `review-artifact-check.sh`). Mesmo assim o aviso diz que o resíduo "é exigido pela REGRA 56 — o
   gate vai acusar". Medido aqui: o gate não acusa. O aviso promete uma cobrança que não existe. É a
   classe "prosa e mecanismo desencontrados" de que fala a REGRA 90 (Prosa de comando conhece os papéis
   que o script aceita).

5. **Falso-positivo medido no ato (PR #3 do onion-kg-ssot, que carrega ESTE sinal):** o resíduo
   `docs/evolution/review/chore-signal-pr-create-gate.md` foi commitado ANTES do `gh pr create`, e o
   aviso `PR-SEM-PASSADA-ADVERSARIAL` disparou do mesmo jeito. O detector casa só a string do comando:
   nunca confere se o artefato existe. Assim ele dispara tanto quando a sessão segue o ritual quanto
   quando não segue. É a fadiga de alertas contra a qual o próprio arquivo avisa. Qualquer uma das
   opções abaixo deveria começar por fazer o aviso testar o artefato (o mesmo slug da REGRA 56).

6. **A mesma classe, no carteiro (medido ao re-relayar ESTE sinal):** o cabeçalho do `co-relay.sh` promete
   "mesmo nome com conteúdo DIFERENTE segue entregando (sinal atualizado, não duplicata)". Só que a
   linha 141 (`[ -e "${DEST_DIR}/${base}" ]` → "já relayado (no-op)") sai ANTES do dedup por conteúdo
   da linha 147. Resultado: a versão atualizada deste sinal não foi entregue (`cmp` diferiu no byte
   2871). A versão que você está lendo foi copiada à mão sobre o arquivo untracked que o próprio carteiro
   tinha entregue minutos antes, sem commit, ou seja, exatamente o que o cabeçalho diz que o script faz.
   Cura candidata: na colisão de nome, comparar o conteúdo; se diferir e o arquivo do destino for
   untracked, entregar.

## Opções para o core pesar (sem recomendação fechada)

- **(a) Veto PreToolUse no `gh pr create` sem resíduo**, onde a REGRA 56 julga. Fecha a classe antes do
  ato, ao custo de falso-positivo a medir (draft e PR exploratório) e de mais um veto a manter.
- **(b) Manter o PostToolUse e declarar o teto também para o create**, com o N medido. Hoje há N=1, do
  campo e de um adotante.
- **(c) Mover o lembrete para antes do ato sem vetar**: o ritual de PR (`/engineer:pr`, `/meta:drive`)
  escreve o resíduo antes de chamar o `gh pr create`. É conselho embutido no caminho, não veto.
- **Independente da escolha:** corrigir o texto do aviso no adotante. Ou ele condiciona ao papel (o
  mesmo predicado da REGRA 56), ou a REGRA 56 passa a cobrar o ritual próprio do adotante. Hoje o aviso
  promete um gate que não existe.

## O que este repo já fez do lado dele

Gravou um checklist operacional na memória da sessão: escrever o resíduo antes do `gh pr create`, ler
`rc` sem pipe e citar REGRA com título. Isso é conselho, e o pedido ao core é sobre o MECANISMO.
