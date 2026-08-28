---
date: 2026-08-28
instance: onion-evolve
type: error
classification: public
tags: [behavior-over-declaration, farol, session-beacon, informado-vs-verificado, dogfood, I3]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "aviso de mecanismo que a própria máquina escreve tem de dizer o que vale: rótulo do veredito + instrução de verificar viajam JUNTOS do sinal"
review_after: 2026-11-26
conflict_class: dynamic
significance: "O farol de sessão — a guarda que protege a invariante I3 — passou meses anunciando fantasmas como sessões vivas, e eu repassei o anúncio ao maestro como fato. Declarado ≠ verificado aplicado ao mecanismo que eu mesmo consumo."
kg: "docs/onion/graph/guardas-revisao-2026-08.kg.yaml"
---

## Signal
**O aviso que uma máquina me entrega não é fato — é a declaração dela.** Eu abri a sessão, li
`🕯️ OUTRA sessão viva neste repo`, e **repassei ao maestro como observação minha**, com direito a
recomendação de conduta ("coordene antes de checkout/escrita"). Não medi nada. Foi o maestro quem
perguntou: *"a viva pode ser você mesmo ou pelo uso do remote control"*.

Estava certo. E o defeito não era meu descuido isolado — era **do mecanismo**, que apresentava
carimbo como medição.

## Evidence
- **A régua velha:** `session-beacon.sh:124` definia "viva" como `refreshed_at` dentro do TTL de
  480 min. `refreshed_at` só avança no `UserPromptSubmit`. Logo toda sessão que nasce e some sem
  `SessionEnd` (crash, kill, conexão de Remote Control, resume abortado) **lia como VIVA por 8h**.
- **Medido no core:** os 2 faróis anunciados tinham `started_at == refreshed_at` (jamais receberam
  **um** prompt) e **nenhum processo correspondente**. Um deles nasceu 150s antes da minha própria
  sessão, na mesma branch e worktree — provavelmente **eu mesmo**, via reconexão do Remote Control.
- **O custo real:** o farol aciona **I3 (um escritor por repo)**. Fantasma travava o repo por 8h e me
  fazia recusar trabalho legítimo — guarda que grita errado é guarda que ensina a ignorar guarda.
- **Cura A (medir):** o beacon grava `owner_pid` + `owner_start` (starttime do `/proc`, defesa contra
  **reuso de pid**). Vereditos: `live` (dono medido vivo) · `declared` (dono não medido — cai no TTL,
  **bloqueia**, conservador) · `orphan` (dono medido morto — não bloqueia, `sweep` remove) · `stale`.
- **Direção do erro, escolhida — e eu a QUEBREI na 1ª versão.** A regra é: falso `orphan` (diz
  morta, está viva) reabre o incidente W1×W2 que criou o farol; falso `declared` custa uma
  verificação. Mas o `beacon_verdict` que escrevi curto-circuitava no dono e **nunca olhava o
  heartbeat**: uma sessão que trocou de processo (resume/restart com o mesmo sid) ou lida de outra
  visão de `/proc` (container, `hidepid`, outra máquina) saía `orphan` **com heartbeat de segundos
  atrás** — `check` devolvia 0 e autorizava outra sessão a escrever por cima. Foi um revisor
  adversarial que derrubou, **em execução**, a invariante que meu próprio cabeçalho declarava.
  Cura: `orphan` passou a exigir dono morto **E** heartbeat parado além de uma janela de graça
  (30 min) **E** `/proc` legível aqui **E** o beacon ser desta máquina. O poder de matar fantasma
  sobrevive quase inteiro (8h → 30 min) e virou **impossível** declarar morta uma sessão que
  acabou de agir.
- **Cura B (o pedido do maestro):** o aviso agora **se declara não-verificado e manda verificar quem é
  e o que faz** — rótulo (`VIVA` vs `DECLARADA`), a pista `NUNCA refrescou (0 prompts)`, e a ordem
  explícita de não relatar como sessão alheia viva o que não foi medido.
- **O dogfood pegou um bug meu, na direção perigosa:** a 1ª sonda casava `*claude*` no **cmdline** — e
  elegeu o **shell transitório do próprio hook**, cujo path carrega `~/.claude/shell-snapshots/…`.
  Esse shell morre em segundos: o farol viraria `orphan` **com a sessão viva**. Corrigido para casar
  por **identidade do executável** (`comm` = `claude`), com teste de regressão dedicado.
- **Cópia da regra:** o mapa da constelação tinha uma **segunda** implementação do "vivo" por TTL.
  Passou a consumir `session-beacon.sh verdict` — a regra vive num lugar só, senão envelhece separada.

- **A lição dentro da lição:** eu escrevi no cabeçalho do script que "ausência de prova cai no lado
  conservador" e **não implementei isso** — declarei a invariante em prosa e deixei o código
  contradizê-la. É o defeito deste próprio diário aplicado a mim: *declarado ≠ verificado* vale
  também para o que EU declaro sobre o MEU código. O que separou foi ter mandado um revisor
  adversarial **executar**, não ler.
- **A bancada estava cega no ponto que mais importava:** o revisor mutou o motor para o veredito
  `live` deixar de bloquear — matando a proteção I3 inteira — e a suíte passou **toda verde**. O
  caso rodava num sandbox compartilhado, e o `exit 1` que ele conferia vinha dos beacons do teste
  vizinho. Teste que não isola mede o vizinho, não o SUT.

## Next crumb
- Ao receber sinal de hook/motd no boot: **rotular a fonte antes de repassar**. "O farol declara X" ≠
  "X é verdade". Se for barato medir, meça antes de falar.
- Guarda que a máquina escreve para si mesma precisa carregar **o que ela vale** junto do sinal —
  rótulo + instrução de verificação —, porque quem lê não tem como saber sozinho.
