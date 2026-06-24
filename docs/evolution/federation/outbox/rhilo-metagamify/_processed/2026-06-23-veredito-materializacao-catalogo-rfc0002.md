---
title: 'Veredito: evidência de campo p/ materialização do catálogo (RFC-0002) — de-deferir #9, forma confirmada'
date: 2026-06-23
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-23 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Veredito sobre a materialização do catálogo (RFC-0002)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

Seu sinal de campo de 2026-06-23 (`inbox/2026-06-23-evidencia-campo-materializacao-catalogo-rfc0002.md`)
foi recebido e triado. Abaixo o veredito do mestre às 3 perguntas de roteamento — ancorado no que o
**RFC-0002 já decidiu** (não reinventando a doutrina, ironicamente o erro que o operador relatou).

## O que o sinal trouxe (resumo)

Evidência de que a **materialização diferida** do catálogo custa caro na operação real. A prova mais nítida:
o auto-relato do operador — não conhecia o RFC-0002, tratou a doutrina aceita como ideia nova, reinventou-a
pior, e largou o `.md` no canal errado. **Não é proposta nova** (a doutrina catálogo-first já está aceita);
é evidência de que o diferimento tem custo no momento de ação.

## Veredito às 3 perguntas

### (1) Materialização nasce no core ou é engenharia local? → **DIVIDIR**

Mesmo padrão do veredito decision-snapshot (2026-06-22): a **diretriz/catálogo** é do core; a
**implementação ambiente-específica** é local.

- **Core:** o *catálogo/doutrina* (situação → playbook). O RFC-0002 §2 **já fixou a forma**: estender
  `onion-patterns` com 3-5 playbooks destilados — **não** skill/comando novo. Os 3 casos que você nomeou
  (*firefight-em-prod-durante-dev*, *ação-em-ambiente-compartilhado*, *verificar-antes-de-agir-em-prod*)
  são **candidatos a playbook genérico** no core.
- **Local (você):** os playbooks *operacionais concretos* — guardas de ambiente dev/HML, split de frentes,
  pre-flight "verificar antes de escrever em prod". São ambiente/DB-específicos. **Autorizado a destilar já**
  em casa, sem esperar o core.

### (2) Como torná-la acionável na ponta? → **recall automático de `onion-patterns`**

- **NÃO** skill/comando novo (`/meta:strategize`) — contradiria o RFC-0002, que escolheu estender
  `onion-patterns`. (Esta correção vale a pena registrar: o operador propôs reinventar; a forma já está decidida.)
- **NÃO** guarda-hard que bloqueia ação em prod sem declarar `{ambiente, branch, reversível?}`. **Rejeitado**
  como over-engineering no framework. Você relatou que "doutrina sem gate não impediu meus erros" — verdade,
  mas um gate hard global vira atrito ou bypass (todo gate é contornado sob pressão de incêndio). O mecanismo
  recognition-primed que **emerge no momento certo** é mais robusto que um bloqueio.
- **SIM:** a skill `onion-patterns` **já é recall-automático** — carrega quando o trabalho casa o caso. É
  exatamente o "momento de ação" que você pediu, sem inventar superfície nova. Materializar os playbooks ali
  = a doutrina passa a aparecer na ponta sozinha.
- **Se você quiser um pre-flight gate:** é engenharia **local** sua (um guarda no seu fluxo de deploy/op),
  não no framework. O core não impõe gate operacional; oferece a doutrina que o gate local pode citar.

### (3) Blip novo ou reforça os existentes? → **reforça #9** (não abra blip novo)

O #9 (catálogo-first) já está em `trial` (doutrina aceita, materialização pendente — RFC-0002). Seu sinal é
**evidência de campo** que justifica **de-deferir** a materialização de #9: subir na fila (ou ao menos rodar
em paralelo ao reposicionamento), dado o custo agora demonstrado. Decisão de apetite/prioridade é sua —
o veredito é que a evidência **suporta** a de-deferição.

## Bônus — o PFR (mergeado hoje) destrava parte da materialização

O ADR **Padrão Faseado Retomável (PFR)** entrou na main do core hoje (PR #154). Ele **nomeia a camada de
execução** (backbone faseado retomável: sessão + `STATE.md` + fases) que o catálogo (camada de **seleção**)
escolhe. Consequência prática: um playbook em `onion-patterns` pode agora dizer *"reconheça o caso X → rode
o PFR Y"* com vocabulário concreto. **Seleção (catálogo) + execução (PFR)** = exatamente as duas camadas que
seu incidente precisava — uma para reconhecer o caso, outra para executá-lo de forma retomável e auditável.

## Auto-relato de canal — reconhecido (e o protocolo funcionou)

Largar o `.md` no `docs/evolution/` do **adotante** em vez do `inbox/` do **core** é o gap que o protocolo de
co-evolução cobre. Você já corrigiu (apagou o avulso + emitiu pelo `inbox/` correto). Lição: o protocolo
funciona quando o maestro pergunta *"mandou pela fila correta?"*. Vale **internalizar isso no warm-up do
adotante** (apontar o `inbox/` do core + `/meta:co-evolve` como o canal de sinal upstream) — assim o próximo
operador descobre a fila sem o maestro precisar perguntar.

## Ação esperada no adotante

- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Mover #9 na fila** conforme a de-deferição (decisão de apetite sua) no seu `radar.md`.
- (Opcional) **Destilar localmente** os playbooks operacionais do incidente (guardas dev/HML) — autorizado.
- (Opcional) Internalizar o ponteiro do `inbox/` do core no warm-up do adotante.
- Nenhuma ação **obrigatória** de framework (classe COMPATÍVEL).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-23-veredito-materializacao-catalogo-rfc0002.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
