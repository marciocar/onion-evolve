# ADR — A superação do Onion é a industrialização da reincidência

- **Data:** 2026-08-16
- **Status:** ACEITA (ratificada pelo maestro em 2026-08-16)
- **Contexto de origem:** atualização do Claude Code (nativo) para 2.1.233 e a pergunta do maestro —
  *o que muda no que usamos, o que ajustar, e qual é a **superação** do Onion diante disso*
- **SSOT:** `docs/evolution/research/claude-code-2.1-onion-2026-08/claude-code-2.1-onion-2026-08.kg.yaml`
  (23 nós, radar exit 0) · **Passada adversarial:** Elenxo dedicado, 47 scripts e 63 grafos medidos,
  veredito por 7 eixos + adendo com verificação independente do binário

## Decisão

> **O Onion não supera por injetar contexto** (skills, comandos, subagentes — a plataforma dá isso e a
> safra de 2026 replica), **nem por "tratar conhecimento como artefato verificável"** (Cruxible e
> AsDecided já fazem, e o primeiro com mais rigor criptográfico).
>
> **Ele supera por INDUSTRIALIZAR A REINCIDÊNCIA:** cada defeito **real e medido** vira guarda
> determinística que roda **fora da janela de contexto**, exercitada por bancada, num catálogo cuja
> **severidade é derivada do comportamento** da guarda — não do que ela declara. E o mesmo loop é
> aplicado contra si mesmo, a ponto de publicar **NÃO CONSTRUIR** sobre a própria cura preferida.
>
> **O mercado otimiza CONTEXTO. Os concorrentes de nicho otimizam PROVA. O Onion otimiza REINCIDÊNCIA:**
> transforma erro invisível em erro **detectável**, com resíduo material auditado por terceiro e
> desacoplado do ator.

## O que foi REFUTADO antes de chegar aqui (e por isso a decisão vale)

A primeira formulação — *"o Onion otimiza verdade: KG como SSOT de runtime, e é o único que trata
conhecimento e decisão como artefato executável"* — **caiu em duas cláusulas centrais**, e as
refutações estão no grafo com aresta `REFUTES`, não editadas para parecer que nunca existiram:

1. **"KG como SSOT de runtime" é falso hoje.** `lint-artifacts.sh:832` afirma que o radar *"valida o
   grafo contra SI MESMO, nunca contra o veredito que o run produziu"*; **nenhum hook lê `.kg.yaml`**;
   quem manda ler são arquivos `.md` de comando — instrução ao modelo, a categoria que esta casa chama
   de **conselho**. A Anthropic ratifica a limitação por escrito: *"treats them as context, not enforced
   configuration"*.
2. **"o único" é falso.** Cruxible (grafo tipado, recibo com content-hash + assinatura, zero LLM no
   caminho de verificação) e AsDecided (`decided gate` bloqueando PR que viola decisão registrada)
   atacam a mesma tese.

## A inversão que a medição revelou

| | linhas |
|---|---|
| Shell **agnóstico** (validation + hooks + utils) — roda em qualquer CI | **26.596** |
| Markdown **acoplado** ao contrato do Claude Code (commands + agents + skills) | **52.655** |

**100% do que REPROVA é agnóstico; 100% do que ACONSELHA é acoplado** — e a plataforma diz da própria
boca que a metade que aconselha não é configuração forçada. Somado a `SendMessage` = **zero** ocorrências
na maquinaria (a capacidade que justificou abandonar o agnosticismo em 2026-05-18), temos
`declarado ≠ verificado` **na direção contrária**: dependência anunciada que não existe.

**Consequência aceita:** a postura de acoplamento continua válida (parar de *gastar energia* em
agnosticismo foi certo), mas sua justificativa muda para a capacidade que a medição prova comprada — o
**`exit 2` determinístico de hook, que barra inclusive sob `bypassPermissions`** e não existe fora do
Claude Code. Corrigido no `CLAUDE.md`.

## O buraco declarado (esta ADR não o esconde)

**A perna de LEITURA do KG não tem mecanismo.** Evidência interna: `kg-read-leg-2026-08/SYNTHESIS.md`
mediu 9 casos reais — **7 falharam por não-consulta**, zero por "consultei e não achei" — e as três
curas candidatas cobriam **1/9, 1/9 e 0/9**: veredito **NÃO CONSTRUIR**. O gatilho real da consulta foi
**humano perguntando** (gate social, não instrumento).

**Não construímos a cura nesta rodada, e a razão é doutrinária:** a superfície nova de hooks (~30
eventos; handlers `prompt`/`agent`; `InstructionsLoaded`, `PermissionDenied`, `FileChanged` disparando
no dano e não no relógio) tornou a cura **construível** — não **justificada**. Construir porque ficou
fácil é **acoplar por conveniência**, que é a refutação da postura no ato de aplicá-la.
**Gatilho de reabertura** (do próprio SYNTHESIS, e não é changelog): fiar o disparo à mão, fresco e
descartável, **2–3× em sessão real, registrando se o veredito injetado MUDOU a resposta**.

## Consequências

**Aceitas:**
- Parar de anunciar "KG como SSOT de runtime" — corrigido na KB canônica, que agora separa
  **escrita = mecanismo** de **leitura = conselho**, com a evidência e o gatilho.
- Parar de justificar o acoplamento por `SendMessage` — corrigido no `CLAUDE.md`.
- O que **não** foi parado, porque a medição refutou a recomendação: a mecânica de empacotamento
  (é **projeção** de SSOT, sem equivalente nativo, e nasceu de defeito de campo de adotante), a
  varredura de memória (o nativo *mantém* o arquivo; o Onion *testa se o conteúdo ainda é verdade*) e
  os `setup-*` (específicos, não scaffolding genérico).

**Riscos, com gatilho observável** (nós `Q_RISCO_*` no grafo): o acervo virar cemitério (52% dos grafos
sem toque há >14 dias); a plataforma comer o gate por baixo (hooks `type: agent` saindo de
experimental); um concorrente mais estreito e mais rigoroso acumular corpus mais rápido.

**Limite de método declarado:** o revisor não executou a bancada (689 asserções são contagem no fonte,
não prova de verde hoje) e não mediu os 4 adotantes locais — se o corpus não transfere, o fosso é
biografia deste repo e não produto. É a medição pendente que mais importa.
