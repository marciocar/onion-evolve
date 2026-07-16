---
title: 'Pipeline spec→vertical→treino validado no campo + produtos deriváveis + pesquisa de colaboração'
date: 2026-07-16
from: gustavo-pulga (consumidor / workspace BetaHauss)
to: core (onion-evolve)
type: signal-feedback
flow: upstream (consumidor → core)
evidencia: sessão 2026-07-15/16 (dogfood de consultoria+treino); docs/tornak/{skills,site,graph,retro}; docs/onion/graph/colaboracao-onion.kg.yaml; docs/knowledge-base/concepts/colaboracao-moderna.md
---

# Sinais ao core (2026-07-16) — pós-treino

> **Client-safe:** este sinal fala do *framework*, não do cliente. Sem nome/dado de cliente, sem estratégia interna.

## Sinal 1 — o pipeline spec→vertical→skills→treino se prova NO CAMPO
Um engajamento real de consultoria+treino foi entregue **inteiro a partir de specs**: descoberta
(reuniões→EXTRACT→consolidação→KG) → **vertical** (book/SSOT + hub `+` helpers) → **plugin/skills** →
**docs + deck de treino auto-guiado** (progressive disclosure, botão copiar, exemplos preenchidos, HTML
offline premium). Público **não-técnico** aprendeu a *usar* primeiro e *criar* aos poucos. Tese confirmada:
**uma boa spec é um multiplicador de artefatos** (um input → skill, plugin, doc, manual, slide, onboarding).
**Proposta ao core:** reconhecer "spec-as-code → N-artefatos" como capability de primeira classe do Onion
e mapear o caminho canônico (quais comandos/skills cobrem cada salto do pipeline hoje, e onde há buraco).

## Sinal 2 — absorção + auditoria de skill de terceiro (design vertical)
Uma skill de identidade de marca trazida por um colaborador (`betahauss-design`) foi **absorvida, auditada
(adherence-lint) e teve a fonte trocada** — CDN de fonte → **fonte embutida (data-URI), HTML self-contained
offline**. Virou a "face de design" da vertical, sem tocar no conteúdo (book).
**Proposta ao core:** um **fluxo padrão de absorção+auditoria de skill de terceiro** (importar → auditar
aderência → trocar fontes p/ self-contained/offline → registrar no KG/diário).

## Sinal 3 — retro/feedback como spec-as-code
Instrumento de retrospectiva do processo criado **versionado no repo**, híbrido (NPS + CSAT por fase +
4 eixos certo/errado/fantástico/caro + Start/Stop/Continue + depoimento), como **par perguntas/respostas**
(um-escritor-por-arquivo, I3 — sem colisão de merge). Coleta em andamento com o colaborador.
**Proposta ao core:** avaliar uma **skill "retro/feedback"** que gera o par, agrega notas e emite migalha/sinal.

## Sinal 4 — produtos/ferramentas que o Onion pode DERIVAR (backlog p/ triagem)
Desta experiência caem candidatos concretos de produto do core:
1. **Gerador de vertical** — scaffold `book + hub + helpers` (generalizar o bootstrap interno de vertical).
2. **Gerador de deck de treino/onboarding auto-guiado** — spec → HTML progressive-disclosure, botão copiar,
   exemplos preenchidos, offline premium.
3. **Skill de retro/feedback como spec-as-code** (Sinal 3).
4. **Perfil "colaborador visitante"** no onboarding do core (SSH + acesso repo-only + canal de recados),
   fechando os sinais de provisionamento já enviados em 2026-07-14.
5. **Fluxo de absorção+auditoria de skill de terceiro** (Sinal 2).
6. **KG-dogfood-para-consultoria** produtizado — mapear um engajamento de cliente como KG SDAAL (2 camadas)
   como método repetível de diagnóstico.
  7. **Convenção "SSOT com partição de visibilidade"** + gate client-safe determinístico (Sinal 6).
**Proposta ao core:** triar estes 7 no backlog de evolução (`/meta:evolve`) e marcar quais viram vertical/skill.

## Sinal 5 — pesquisa de "colaboração moderna" anexa (KB + KG)
Rodamos pesquisa profunda sobre **colaboração moderna assistida por IA** (async via repo, spec/docs-as-code,
dogfooding, KG como memória compartilhada, onboarding auto-guiado, ciência de retro/CSAT/NPS) e destilamos em
**KB** (`docs/knowledge-base/concepts/colaboracao-moderna.md`) + um **KG dogfood** do processo de colaboração
Onion (`docs/onion/graph/colaboracao-onion.kg.yaml`, radar íntegro).
**Proposta ao core:** absorver a KB como referência e considerar promover o KG de colaboração a artefato do core.

## Sinal 6 — método: SSOT com PARTIÇÃO DE VISIBILIDADE (interno × client-safe)
Este é o método que sustentou tudo acima e merece virar convenção do core. **Descrevo o mecanismo, não o
conteúdo** — nada da estratégia interna dos consultores aparece aqui.
- **Uma SSOT, duas projeções.** O repositório dev guarda TUDO (material 🔒 interno + artefatos client-safe).
  Da mesma fonte derivamos duas vistas: a **interna** (completa) e a **client-safe** (a interna *despida*
  do que é estratégia/negócio dos consultores). Ex. do padrão: um documento-síntese tem par
  `*-INTERNA` (fica) e `*-cliente` (sai) — mesma origem, projeção diferente.
- **Fronteira guardada por gate DETERMINÍSTICO, não por disciplina.** Antes de qualquer artefato cruzar
  para o cliente **ou para o core**, roda-se um `grep` de termos sensíveis → **tem que dar 0**. É o que
  torna a partição confiável e repetível (não depende de lembrar). Este próprio sinal passou pelo gate.
- **O que pode virar documentação/material do cliente** é só a projeção client-safe; **o que é assunto
  interno** (estratégia, precificação, vínculos comerciais, notas de raciocínio) **nunca** é empacotado —
  o cliente recebe apenas o pacote client-safe (skills + book via zip/repo de distribuição), **jamais o repo dev**.
**Proposta ao core:** convenção "**SSOT com partição de visibilidade**" + um **comando/skill de gate
client-safe** (o `grep`=0 como check versionável) no fluxo que gera artefatos voltados a cliente/core.

## Sinal 7 — os DOIS KGs por fronteira de confiança: como foram usados, alimentados e pesquisados
A partição de visibilidade se materializa em **dois KGs SDAAL distintos, por camada de confiança** —
esta foi a decisão-chave do período e responde diretamente "como os KGs foram usados":
- **KG do engajamento** (`docs/tornak/graph/*.kg.yaml`, ~90 nós/140 arestas): modela o domínio do
  cliente + as teses da consultoria. **Contém nós 🔒 confidenciais explicitamente marcados** ("nunca
  exibir em artefato voltado ao cliente"). **Fica no repo dev** — nunca sai. *Alimentado* em LOTES
  iterativos (construir→pausar→perguntar→responder) a partir de extrações/consolidação/notas; *gate* =
  radar de integridade por fase.
- **KG de colaboração** (`docs/onion/graph/colaboracao-onion.kg.yaml`, 26 nós/31 arestas): modela o
  **processo meta-Onion** (papéis, canais, invariantes) + as teses sobre o que funciona. **Sem nenhum
  dado de cliente** → **shareable ao core**. *Alimentado* neste período por: (a) as 5+3 migalhas do
  diário, (b) o instrumento de retro, (c) os **findings da deep-research** (LOTE 2), que **refutaram**
  o "NPS-preditor" e o "spec −50%" e **validaram** o I3/delivery-without-commit (KPR) — com a
  RECONCILIAÇÃO (`REFUTES`/`SUPERSEDES`) registrando o grafo **se autocorrigindo**. Decisão registrada:
  `D_KG_SEPARADO` (manter o KG de colaboração fora do KG-cliente).
- **Por que dois e não um:** manter os dois separados garante que a estratégia confidencial (que vive no
  KG-cliente) **jamais** contamine um artefato framework-facing. O KG é *append-mostly* e *soberano*
  (veredito por radar determinístico), o que torna a separação auditável.
**Proposta ao core:** convenção "**um KG SDAAL por camada de confiança**" (engajamento-confidencial ×
meta-shareable) e considerar promover o KG de colaboração a artefato de referência do core.

## Sinal 8 — responsabilidades assimétricas + AUTORIZAÇÃO de quem fala com o core (relações ainda não formalizadas)
Ponto que **ainda não está formalizado** no core e apareceu forte no período:
- **Vínculos assimétricos com a entidade entregadora.** Os dois consultores têm **relações distintas**
  com a marca sob a qual o serviço é entregue. O framework **não precisa conhecer os detalhes** desses
  vínculos — mas o **modelo de papéis precisa acomodar a assimetria** (co-autoria no produto, papéis
  distintos na operação e no acesso).
- **Autorização de fala com o core é assimétrica e de fronteira de confiança.** Só o **maestro** relaya
  e tria sinais ao core; o **colaborador visitante** *entrega* sinais como arquivos (inbox) mas **não
  relaya nem acessa o core**. A fronteira é reforçada pelo **próprio SO** (sem acesso ao core), não só
  por convenção — e coincide com o **I3 "entrega-sem-commit"**, agora **validado externamente pelo KPR**
  (colaboração através de fronteiras de confiança: o conhecimento cruza, o commit não).
- **Relações em aberto (para o core resolver):** perfil "colaborador visitante" + o **boundary de
  autorização** (quem pode relayar) não estão descritos no onboarding do core; a assimetria de vínculo
  com a marca não tem lugar no modelo de papéis; e falta a convenção de *como* um visitante sinaliza sem
  poder relayar (hoje: arquivo no inbox + o maestro transporta).
**Proposta ao core:** formalizar no onboarding (a) o **perfil de colaborador visitante**, (b) o **boundary
de autorização de relay** (maestro-only), e (c) o reconhecimento de **vínculos assimétricos** consultor↔marca
sem exigir que o framework conheça seus detalhes.

> Nota de transporte: os sinais anteriores (2026-07-13, 2026-07-14) já estão em `inbox/_processed/`
> (relayados). Este é o único pendente — relay individual pelo Marcio (Gustavo não relaya).
