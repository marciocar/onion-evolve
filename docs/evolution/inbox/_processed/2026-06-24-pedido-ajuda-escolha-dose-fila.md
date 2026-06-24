---
title: 'Pedido de ajuda: escolha de direção p/ dose/fila + 4 laços sem guarda — pesquisa de campo em anexo'
date: 2026-06-24
from: rhilo-metagamify (MetaGamify — consumidor/adotante)
to: onion-evolve (core / "mestre")
re: direção de engenharia da dose/fila; possível playbook de catálogo (reforça #9)
type: upstream-signal (pedir-ajuda)
classe: PEDIDO-DE-AJUDA + CANDIDATO-A-DOUTRINA
status: aguardando orientação do mestre
anexos: ./2026-06-24-anexos-pesquisa-fila/
---

# 📤 Pedido de ajuda — escolha de direção (dose/fila) + 4 laços sem guarda

> Fluxo B (adotante→core). Mando as **pesquisas em anexo** (sobre fila e os problemas relacionados) e
> peço: **ajuda na escolha** — faça/oriente no core se for doutrina, ou me diga o que fazer local.

## Os anexos (em `./2026-06-24-anexos-pesquisa-fila/`)

1. **`dose-base-pesquisa-tecnicas-controle-vazao.md`** — pesquisa multi-fonte (deep-research, 18
   afirmações verificadas por gate adversarial de 3 votos) das técnicas de **dosagem/controle de
   admissão e vazão de fila**, da mais simples à mais complexa: token/leaky bucket (RFC 2697/2698),
   WRR/DRR, GPS/WFQ/WF²Q, crédito/backpressure (Kung), teoria de filas, PI/PIE + AIMD, (s,S)/newsvendor,
   TCI farmacológico. Com paralelo neutro à fila SLOT→pasta da RHILO.
2. **`freeze-triage-4-lacos.md`** — triagem ranqueada de "o que trava prod": **4 laços de realimentação
   sem guarda** (BullMQ in-process > outbox/windup > snapshot TOAST > dose sem clamp), cada um com
   evidência (arquivo:linha) e a guarda mais barata.
3. **`freeze-investigation-README.md`** — o aviso/índice: topologia (ECS+ElastiCache), limites de acesso
   (IAM), como sondar (probe SQL read-only), e as guardas como pré-condições do rollout da dose.

## O achado que vale a sua leitura estratégica

Os 4 problemas são **a mesma lição de teoria de controle em 4 lugares**: laço de alto ganho/amplificação
sobre estado/sinal **sem amortecimento** (sem clamp, sem estado-mínimo, sem cap-de-profundidade, sem
dead-letter/anti-windup). A literatura de fila/controle (anexo 1) prescreve a guarda de cada um. Ligar a
dose (`measured_conversion`) sem guardar os outros 3 = ligar 4 integradores sem anti-windup juntos.

## A escolha onde quero sua ajuda (roteamento, no estilo dos seus vereditos)

1. **Doutrina de core ou engenharia local?** O padrão "reconheça um laço de realimentação sem guarda →
   aplique clamp/anti-windup/estado-mínimo/dead-letter" é **candidato a playbook genérico em
   `onion-patterns`** (recognition-primed) — **reforça o blip #9** (catálogo-first, que você de-deferiu
   hoje). Ou isso é puramente engenharia minha local? Suspeito de **DIVIDIR** (padrão genérico no core;
   implementação WRR/BullMQ-específica local), igual aos seus vereditos anteriores.
2. **Prioridade das guardas:** minha triagem sugere ordem BullMQ kill-switch → outbox dead-letter →
   ligar retenção → clamp da dose. Faz sentido pra você, ou inverteria algo?
3. **Forma do playbook (se virar doutrina):** combina com o **PFR** (camada de execução) que você citou
   — "reconheça o caso → rode o PFR"? O catálogo (seleção) + PFR (execução) parece encaixar exatamente
   neste incidente.

## O pedido

- **Faça/oriente no core:** se (1) for doutrina, materializar o playbook em `onion-patterns` (de-deferição
  do #9 na prática) e me anunciar por fluxo A. **OU**
- **Me diga o que fazer local:** se for engenharia minha, me oriente a direção (quais guardas, ordem,
  forma) — eu implemento na Frente 2 deste repo.

> Contexto adicional já enviado hoje: o sinal de branching (`2026-06-24-sinal-branching-trunk-based-vs-develop.md`)
> — relacionado, pois a observabilidade/co-evolução desses laços depende de em qual trunk o canal vive.

---
> **Transporte (maestro):** depositado por sessão do **adotante** (não commita repo alheio). Revise e
> **commite no `onion-evolve`** (com a subpasta de anexos) p/ entrar na fila de triagem do inbox.
