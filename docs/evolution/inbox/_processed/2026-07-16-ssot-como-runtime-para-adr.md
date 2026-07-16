---
tipo: sinal-upstream
origem: rhilo-metagamify (adotante)
destino: onion-evolve (core)
data: 2026-07-16
assunto: "Para a ADR sobre SSOT — as lições de OPERAÇÃO (o SSOT como runtime, não artefato)"
fluxo: feedback (adotante → core)
relacionado:
  - docs/evolution/inbox/2026-07-16-kg-sdaal-dogfood-ouro.md
  - .claude/commands/meta/kg.md
  - .claude/validation/kg-radar.sh
---

# 🎯 Para a ADR sobre SSOT — o SSOT precisa ser RUNTIME, não artefato

> **Contexto:** o primeiro sinal ("o ouro") cobriu a **técnica** (schema, radar, frescor). Este cobre a
> **operação** — o que descobrimos ao *usar* o SSOT para entregar, na mesma sessão. É a matéria-prima direta
> da ADR. A descoberta central é constrangedora e por isso vale ouro: **montamos um SSOT canônico e, minutos
> depois, eu (o próprio autor) NÃO operei a partir dele — três vezes seguidas.** A ADR precisa endereçar isso.

## 1. A falha-mestra: construir o SSOT ≠ operar a partir dele

Fiz um catch-up e afirmei que "a ação 4 estava pendente" — reconstruindo do git/memória, o **jeito velho**.
O SSOT já dizia `E_ABANDON_APPLY_PROOF [confirmed]: "dreno IMPLEMENTADO E PROVADO"`. Consultei? Não. Depois
propus consolidar do zero — o SSOT já tinha `C_CONSOLIDATION_MAP` (a estratégia de 2 lanes). Consultei? Não.
**O SSOT virou entregável, não runtime.** Sem uma *forcing function*, o consumidor (humano OU IA) re-deriva
à mão e ignora a fonte da verdade que ele mesmo montou. **A ADR tem que tratar o SSOT como o programa que se
EXECUTA, não um documento que se arquiva.**

## 2. O SSOT apodrece em TODAS as camadas — inclusive as meta/entrega

O primeiro ouro alertou sobre nós `plane: PROD` stale. Mas descobrimos pior: o nó de **estratégia de entrega**
(`C_CONSOLIDATION_MAP`, DEV) também estava stale — apontava para branches `consolidate/*` que (a) não tinham
os fixes novos, (b) não descendiam do prod atual; e os refs `origin/fix/*` que ele citava **nem existiam** (eram
branches locais, não pushadas). **Conclusão para a ADR:** não é só a camada PROD que rot — é QUALQUER claim que
referencie um artefato móvel (branch, commit, deploy, config). O carimbo de frescor (`verified_at`) precisa valer
para nós DEV também, não só PROD.

## 3. A disciplina que FUNCIONOU: KG-first → drive-to-verify

O que salvou foi um loop de dois passos, que proponho como **o ciclo canônico de operação do SSOT**:
1. **KG-first:** para qualquer pergunta de estado/decisão, **consultar o grafo primeiro** e citar o id do nó.
   O KG me apontou certo (`C_CONSOLIDATION_MAP`, `E_FIX_*`, `D_BACKLOG_4ACHADOS`).
2. **Drive-to-verify:** confirmar o nó contra o **estado vivo** (git/dump/código) ANTES de agir. Foi isso que
   pegou a staleness das branches. git/dump = **verificar**, nunca **re-derivar**.
O KG dá o mapa; a verificação confirma que o mapa é atual. **Nenhum dos dois sozinho basta** — o KG sozinho
me enganou (stale), o git sozinho me fez esquecer o que o SSOT já sabia. A ADR deveria prescrever ESSE par.

## 4. Falta uma projeção "state-board" (o SSOT não é consultável para operação)

O radar dá **atenção/integridade/reconciliação** — mas não responde "o que está feito / pendente / o próximo".
Tive que escrever um `kg-state.py` (projeção do grafo: alavancas vivas×inertes, implementado×a-aplicar, questões
abertas, top-atenção). **Proposta para a ADR/core:** um `kg state` de 1ª classe (projeção de estado-de-trabalho),
irmão do radar. Sem ele, o "consultar o KG primeiro" não é ergonômico e o operador cai no re-derivar.

## 5. O mecanismo que faltou: KG-first NÃO está ligado aos loops

`catch-up` e `warm-up` reconstroem de git/memória e **não abrem o KG** — foi o buraco exato que me fez errar.
**Proposta:** quando existir um `.kg.yaml`, os comandos de contexto DEVEM consultá-lo PRIMEIRO (é o SSOT de
"onde estamos", acima do git). O SSOT precisa estar **cabeado no runtime dos comandos**, não à parte.

## 6. A visão confirmada: LLM = VM, MD = Bytecode

O maestro nomeou bem: o `.kg.yaml` é o **bytecode**; o LLM é a **VM** que deveria **executá-lo** — ler o estado
nele, inferir a próxima transformação a partir dele, e **atualizá-lo** (append-mostly) a cada passo. Meu erro foi
rodar raciocínio ad-hoc *olhando de lado* pro bytecode. A ADR pode ancorar aqui: **o SSOT só entrega valor
quando é o substrato de execução, com um ciclo obrigatório read(KG)→verify(vivo)→act→write(KG).**

## Resumo — as posições que sugiro para a ADR

1. **SSOT = runtime, não artefato.** Definir o ciclo obrigatório read→verify→act→write.
2. **Frescor em todas as camadas** (`verified_at` + gate de stale) — DEV e PROD, qualquer claim com artefato móvel.
3. **KG-first + drive-to-verify** como o par canônico (nem só grafo, nem só git).
4. **`kg state`** (projeção de estado-de-trabalho) como 1ª classe, irmão do radar.
5. **Cabear o KG-first** nos loops (`catch-up`/`warm-up`/`work`).
6. **A metáfora operacional** (VM/bytecode) como o "porquê".

> Se a ADR fixar UMA coisa: **o SSOT tem que ser CONSULTADO E VERIFICADO como primeiro ato de toda operação —
> senão até quem o construiu o ignora, como eu ignorei, 3× na mesma sessão.**

— sinal do adotante `rhilo-metagamify`, sessão 2026-07-15/16 (companheiro do "ouro" do dogfood).
