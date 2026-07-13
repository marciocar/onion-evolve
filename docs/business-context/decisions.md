# 🗂️ Registro de Decisões Estratégicas

> Mecanismo de rastreio das decisões de negócio em aberto. Cada card é uma pergunta que você resolve **escolhendo** uma opção ou **descrevendo** livremente. Versionado no git → cada sessão avança daqui, não recomeça. Spec-as-code aplicado às decisões de negócio (dogfood do próprio Onion).
>
> **Status:** `aberto` (a decidir) · `hipótese` (inclinação registrada, não fechada) · `ratificado` (decidido, com data).
> **Como usar:** numa sessão, `/catch-up` aponta aqui; você diz "avançar D_" e escolhe/descreve; eu atualizo o card e propago para `strategy.md`/`personas.md` etc.

---

## D1 — Postura comercial

**Pergunta:** o Onion vira comercial? Como reconciliar "não é produto, não distribuído" com "fazer dinheiro / vender como ouro"?

- ( ) Pivot explícito para comercial
- (•) **Camadas: mini-funil aberto + captura adjacente (serviço/certificação/curadoria)** ← inclinação
- ( ) Exploratório (registrar opção, não decidir)
- ( ) Não-comercial, foco em sustentação

**Status:** `hipótese` · **Lean:** camadas (BMAD/Wardley + selo SAFe/EOS). **Trava:** decidir o modelo **antes** de abrir publicamente (guardrail anti-relicenciamento). **Refina:** falta escolher gatilho de "abrir".

## D2 — Moeda-dado / federação de contexto

**Pergunta:** o modelo usa "compromisso de dado" (adotantes contribuem contexto → flywheel de federação)?

- ( ) Sim, sem restrição forte agora
- (•) **É hipótese — registrar e decidir depois** ← escolhido
- ( ) Sim, mas local-first + destilado
- ( ) Não por ora — só moeda-financeira

**Status:** `aberto` · **Nota:** colide com a fronteira **P5 (mitigação de inferência)** do `discuss/onion-pessoal-marcio` — se dados entram no modelo, privacidade/inferência vira restrição de produto. Resolver P5 destrava/bloqueia esta.

## D3 — Onion Pessoal / leigo final + mentoria

**Pergunta:** perseguir a linha consumidor (Company Brain N=1) e mentoria (Evolução + Pessoal)?

- (•) **Registrado como hipótese de maior incerteza** ← escolhido
- Requisitos: **super storytelling + branding + posicionamento** (muda comprador e promessa).

**Status:** `aberto` · **Depende de:** acionar `@branding-positioning-specialist` + `@storytelling-business-specialist` quando amadurecer. Ligado a `discuss/onion-pessoal-marcio` e `discuss/onion-mobile-app`. **Não** comprometer como pilar sem esse trabalho.

## D4 — Priorização das receitas

**Pergunta:** qual sequência de camadas pagas perseguir?

- (•) **Formalizar treino/consultoria → certificação → compliance-pack → assinatura SOTA** ← inclinação
- ( ) Compliance-pack primeiro (cunha de maior valor, ciclo longo)
- ( ) Perseguir em paralelo (risco "todo e o nada")

**Status:** `hipótese` · **Lean:** sequencial (receita mais próxima primeiro). **Refina:** definir marco que dispara passar de uma pra próxima.

## D5 — Preço / ticket

**Pergunta:** como precificar cada camada?

**Status:** `aberto` · **Diretriz da pesquisa:** ticket premium ($129+) > pipoca ($5–10) para maestro solo; vender selo/curadoria/serviço, não o texto; preço por outcome só depois de instrumentar (ver `metrics.md`). **Falta:** hipótese de número por camada.

## D6 — Comprador primário

**Pergunta:** quem é o comprador-alvo primário?

- Candidatos: empresas c/ sistemas internos (P3) · times regulados (P4) · dev solo (P5) · leigo/pessoal (P6).

**Status:** `aberto` (a validar) · **Sinais:** P4 (regulado) é a cunha de maior valor + whitespace; P3 é o volume org mais provável. **Falta:** escolher 1 primário para focar mensagem/GTM.

---

## Decisões já ratificadas (fora deste registro)

Vivem no `CLAUDE.md` / `docs/analysis/onion-review-2026-05.md` (identidade canônica 2026-05-18): Claude Code-only, 3 dimensões peer, workflows faseados invariantes, `.onion/` e v4.0 FASES 5-9 abandonados. Este registro **não** as reabre — trata só do eixo comercial/GTM novo.
