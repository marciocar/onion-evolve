---
title: "Proposta: preâmbulo do agente de execução — resíduo com sha carimbado e git simples com rc à parte (cards SAC-422 e SAC-434)"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: doctrine-proposal
family: pratica
request: "Core → curadoria (2026-11-21): medir o fragmento .claude/commands/common/prompts/execution-agent-preamble.md contra o que os agentes erraram (resíduo com reviewed_code_sha256 manual; timeout curto que matou o lint; git encadeado com rc perdido; agente parado esperando tarefa de fundo) e propor o texto. SAC-422 + SAC-434 juntos."
reviewed_for_public: true  # relido pelo core em 2026-11-22: só o preâmbulo, sem cliente, pessoa, segredo ou incidente
---

# Proposta — preâmbulo do agente de execução (SAC-422 + SAC-434)

A curadoria **propõe**; o core sela. Nada aqui é selado. O preâmbulo é **core-only** (vive em
`.claude/commands/common/prompts/execution-agent-preamble.md`), então a mudança é do core.

## 1. Medido — o preâmbulo de hoje × os quatro erros

Os quatro erros nomeados, cruzados com o texto atual:

| erro | o preâmbulo já cobre? | lacuna |
|---|---|---|
| **resíduo com `reviewed_code_sha256` manual** | **parcial** — l.25 manda usar o gerador `--skeleton` e conferir `--schema`; l.35 manda "apagar `reviewed_code_sha256`" só no rebase | **não diz, em regra, que o sha é CARIMBADO pela máquina e nunca digitado** — e o agente digita |
| **timeout curto que matou o lint** | **parcial** — l.26 manda `timeout <s>` em primeiro plano | **não avisa que o lint varre a KB e passa de 120s**; um teto curto/default mata |
| **git encadeado com rc perdido** | **estreito** — l.26 diz só "Nunca `\| tail` para medir rc" | **não cobre `&&`/`;`/pipe em geral**; git encadeado perde o rc (push que falhou parece sucesso) |
| **agente parado esperando tarefa de fundo** | **sim** — l.26 (bg não acorda subagente encerrado, 4 casos 2026-11-05) e l.27 (pedido de aprovação pendura, medido 2026-11-12) | só reforçar, não reescrever |

**A máquina do resíduo já está certa** (a lacuna é só o preâmbulo não impor seguir): o
`review-artifact-check.sh` deixa `reviewed_diff_sha256: pendente` no esqueleto e **o `pr-finalize`
carimba**; o `reviewed_code_sha256` "só existe carimbado — apague a linha, o pr-finalize a escreve"
(`.claude/validation/review-artifact-check.sh:200-202,225`). O checador ainda **computa** o sha esperado e
compara (l.379-386). Logo um sha **digitado à mão** é não-verificável e vai ser rejeitado ou sobrescrito —
digitar é o erro.

A casa já tem o precedente do rc perdido por pipe: a guarda `bash-empty-result-guard.sh` reprova
`2>/dev/null` a montante de uma contagem porque "um comando que FALHOU e um objeto que NÃO EXISTE produzem
o mesmo 0" — a mesma classe do git encadeado. (Bati nessa guarda duas vezes nesta sessão; é real.)

## 2. Texto proposto (os bullets a ACRESCENTAR/trocar no bloco `---8<---`)

> **SAC-422 — resíduo: o sha é carimbado, você nunca o digita.** Os campos `reviewed_diff_sha256` e
> `reviewed_code_sha256` do resíduo **são escritos pela máquina**, não por você: o `--skeleton` deixa
> `reviewed_diff_sha256: pendente` e **apague** qualquer `reviewed_code_sha256` — **o `pr-finalize` carimba
> os dois** ao fechar. **Nunca digite um hash à mão** (ele é não-verificável; o `review-artifact-check.sh`
> computa o esperado e o rejeita, e o `pr-finalize` o sobrescreve). Na re-revisão por rebase: volte o diff
> a `pendente` e apague o code — nunca recompute o hash você mesmo.
>
> **SAC-434 — git em forma simples, rc lido à parte.** Rode cada comando git **sozinho**, um por chamada:
> **nunca** encadeie git com `&&`, `;` ou pipe, e **nunca** meça o resultado através de um pipe (`| tail`,
> `| grep`, `2>/dev/null` antes de uma contagem) — um comando que falhou e um objeto ausente dão o mesmo
> `0`/vazio, e um `push` que falhou parece sucesso. Leia o **código de saída à parte**, na linha seguinte
> (`git push origin <branch>` e, depois, cheque `$?`); se um pipe for inevitável, leia `${PIPESTATUS[0]}`,
> não `$?`. É a mesma regra que a guarda `bash-empty-result-guard.sh` já impõe para contagens.
>
> **Reforço do teto (o lint é lento).** O lint de pré-commit **varre a KB e passa de 120 s**; não envolva
> o commit/lint num `timeout` curto nem no default — ele mata a varredura no meio. Feche pelo
> `ops/pr-finalize.sh --push`, que já espera a vaga de passo pesado (l.28); se precisar rodar o lint
> direto, dê um teto que **folgue** a varredura. (Permanece: subagente **nunca** faz `run_in_background` e
> "aguardo o monitor" — o aviso de fim não acorda um turno encerrado; e **nada que peça aprovação humana**.)

## 3. Veredito

**Veredito proposto: `costurar`.** Acrescenta duas regras (SAC-422, SAC-434) e afia duas que já existem
(teto do lint, bg-wait), todas apontando para maquinaria que **já existe e está certa** (o carimbo do
`pr-finalize`, a guarda de rc). Não é `absorver` (nada novo a construir) nem `rejeitar`/`parquear`.

*Guarda opcional (se o core quiser trava, não só texto):* um check que reprove um resíduo cujo
`reviewed_*_sha256` esteja preenchido com hash **numa branch cuja revisão é nova** (sinal de digitação à
mão) — mas o `review-artifact-check.sh:202` já chega perto disso. Deixo como nota, não como pedido.

*O que o core sela:* o texto dos bullets e se quer a trava extra. Registro no corpus da curadoria se
pedirem; entregue como sinal.

---

Orquestrado com 🧅 Onion Evolve
