---
title: 'Relay: pipeline spec→vertical→treino provado no campo + retro fechada + 7 produtos deriváveis'
date: 2026-07-30
from: gustavo-pulga (consumidor / workspace BetaHauss) — relay pelo maestro (Marcio)
to: core (onion-evolve)
type: signal-feedback
flow: upstream (consumidor → core)
relay_of: 'inbox/_processed/2026-07-16-treino-vertical-colaboracao-produtos.md (lado do adotante) + retro do processo fechada 2026-07-29'
client_safe: true
evidencia: 'engajamento de consultoria+treino (cliente anonimizado); vertical/skills/decks/KG do adotante; docs/knowledge-base/concepts/colaboracao-moderna.md; KG de colaboração (radar íntegro); retro/RESPOSTAS-GUSTAVO.md'
---

# Relay ao core — pós-treino + retro fechada

> **Client-safe (gate `grep`=0):** este sinal fala do *framework*, não do cliente. **Sem nome de cliente,
> sem marca que o identifique, sem estratégia interna dos consultores.** O maestro relaya; o colaborador
> visitante entrega mas não relaya (Sinal 8). O depoimento e o uso como case têm consentimento **condicionado
> à anonimização do cliente + revisão antes de publicar** — atado a qualquer material de marketing derivado.

## Evidência nova desde o rascunho — a RETRO do processo (fechada 2026-07-29, verificada)

O colaborador respondeu a retro completa (par perguntas/respostas versionado, um-escritor-por-arquivo/I3).
**Client-safe por construção.** Números e veredito reais:

- **NPS-parceiro: 10.** *"Uma vez entendido o processo de construção, ele vira ferramenta poderosíssima de
  construção de ferramentas — você para de fazer entregáveis um a um e passa a construir a máquina que os produz."*
- **CSAT: 10 nas 8 fases** (Descoberta/EXTRACT · Consolidação · KG SDAAL · Book/SSOT · Skills+plugin · Decks ·
  Colaboração assíncrona · Véspera+entrega), cada uma com comentário concreto.
- **Manter (✅):** fórmula dos decks (cartão copiável + exemplo preenchido + offline premium) · escada de
  instalação sem ponto único de falha · book como fonte-única com gate de exclusividade · RECADOS +
  um-escritor-por-arquivo (zero colisão) · radar determinístico (contradições emergem no motor).
- **Consertar (❌) — atrito de campo real:** (a) provisionamento **SSH** com pegadinha (`user@host` ausente →
  "Invalid user") que empurrou o visitante pro Claude Code local; (b) **binários pesados no git** (PDF ~20MB +
  dezenas de PNGs) até decidir o gitignore; (c) **teto de cota/sessões** da conta compartilhada p/ ~6 pessoas
  no desenho "uma conta só"; (d) **duplicação de docs de instalação** por canal (precisou de rodada de consolidação).
- **Wow (🤩):** animar mídia real do cliente com IA (bloco pedido pelos participantes) · a **skill obedecendo o
  book na frente do time** (desviou sozinha de uma trava de exclusividade de categoria) · ver a spec virar
  plugin→skill→treino de ponta a ponta.
- **Caro (💸):** placeholders `[A CONFIRMAR]` do book de exemplo (só destravam com o book oficial) · polish
  visual dos decks além do ponto de retorno.
- **Start/Stop/Continue:** *Start* scaffoldar vertical por gerador · *Stop* binário pesado no git + doc de
  instalação duplicado por canal · *Continue* cartão-copiável+exemplo-preenchido e RECADOS/I3 na colaboração.

## Sinal 1 — o pipeline spec→vertical→skills→treino se prova NO CAMPO
Um engajamento real de consultoria+treino foi entregue **inteiro a partir de specs**: descoberta
(reuniões→EXTRACT→consolidação→KG) → **vertical** (book/SSOT + hub + helpers) → **plugin/skills** →
**docs + deck de treino auto-guiado** (progressive disclosure, botão copiar, exemplos preenchidos, HTML
offline premium). Público **não-técnico** aprendeu a *usar* primeiro e *criar* aos poucos. Tese confirmada
(e ratificada pela retro, CSAT 10): **uma boa spec é multiplicador de artefatos** (um input → skill, plugin,
doc, manual, slide, onboarding).
**Proposta:** reconhecer "spec-as-code → N-artefatos" como capability de primeira classe e mapear o caminho
canônico (quais comandos/skills cobrem cada salto do pipeline hoje, e onde há buraco).

## Sinal 2 — absorção + auditoria de skill de terceiro
Uma skill de identidade de marca trazida por um colaborador foi **absorvida, auditada (adherence-lint) e teve
a fonte trocada** (CDN → **fonte embutida data-URI, HTML self-contained offline**). Virou a face de design da
vertical sem tocar no conteúdo.
**Proposta:** fluxo padrão de **absorção+auditoria de skill de terceiro** (importar → auditar aderência →
trocar fontes p/ self-contained/offline → registrar no KG/diário).

## Sinal 3 — retro/feedback como spec-as-code
Instrumento de retrospectiva versionado, híbrido (NPS + CSAT por fase + 4 eixos + Start/Stop/Continue +
depoimento), como par perguntas/respostas (um-escritor-por-arquivo, I3 — sem colisão). **Ciclo agora COMPLETO:
coletado e fechado** (a retro acima é a prova de que o instrumento funciona ponta a ponta).
**Proposta:** skill "retro/feedback" que gera o par, agrega notas e emite migalha/sinal.

## Sinal 4 — os 7 produtos deriváveis, agora RANQUEADOS pela disposição do colaborador
Da experiência caem candidatos concretos de produto do core. **A retro adicionou o sinal de quem topa tocar
o quê** (co-decisão registrada):

| # | Produto | Disposição declarada |
|---|---------|----------------------|
| 2 | **Gerador de deck de treino/onboarding auto-guiado** (spec → HTML progressive-disclosure, copiar, offline) | **colaborador topa tocar** (montou os decks; molde existe) — **maior prontidão** |
| 3 | **Skill de retro/feedback como spec-as-code** (Sinal 3) | **colaborador topa tocar** (baixo esforço; a retro já é o protótipo) |
| 5 | **Fluxo de absorção+auditoria de skill de terceiro** (Sinal 2) | **colaborador topa tocar** (a skill de design é contribuição dele) |
| 1 | **Gerador de vertical** — scaffold book + hub + helpers | prioridade alta, **em dupla com o maestro** |
| 4 | **Perfil "colaborador visitante"** no onboarding do core | ele é o caso de teste natural — **topa validar** |
| 6 | **KG-dogfood-para-consultoria** produtizado | valioso; **mais do maestro**, ele apoia como usuário |
| 7 | **Convenção "SSOT com partição de visibilidade"** + gate client-safe determinístico (Sinal 6) | método transversal (sustenta todos) |

**Proposta:** triar os 7 no backlog de evolução (`/meta:evolve`); começar pelos de maior prontidão (#2, #3, #5).

## Sinal 5 — pesquisa de "colaboração moderna" anexa (KB + KG)
Pesquisa profunda sobre colaboração moderna assistida por IA (async via repo, spec/docs-as-code, dogfooding,
KG como memória compartilhada, onboarding auto-guiado, ciência de retro/CSAT/NPS) destilada em **KB**
(`docs/knowledge-base/concepts/colaboracao-moderna.md`) + um **KG dogfood** do processo de colaboração
(radar íntegro).
**Proposta:** absorver a KB como referência e considerar promover o KG de colaboração a artefato do core.

## Sinal 6 — método: SSOT com PARTIÇÃO DE VISIBILIDADE (interno × client-safe)
O método que sustentou tudo. **Mecanismo, não conteúdo.**
- **Uma SSOT, duas projeções:** o repo dev guarda tudo (🔒 interno + client-safe); derivam-se a vista
  **interna** (completa) e a **client-safe** (a interna despida de estratégia/negócio). Padrão: doc-síntese
  com par `*-INTERNA` (fica) e `*-cliente` (sai).
- **Fronteira por gate DETERMINÍSTICO, não disciplina:** antes de um artefato cruzar p/ cliente **ou core**,
  roda-se um `grep` de termos sensíveis → **tem que dar 0**. Este relay passou pelo gate.
- **Só a projeção client-safe** vira material do cliente; o interno nunca é empacotado; **o repo dev jamais sai**.
**Proposta:** convenção "**SSOT com partição de visibilidade**" + **comando/skill de gate client-safe**
(o `grep`=0 versionável) no fluxo que gera artefatos p/ cliente/core.

## Sinal 7 — dois KGs por fronteira de confiança
A partição se materializa em **dois KGs SDAAL distintos, por camada de confiança**:
- **KG do engajamento** (repo dev do adotante): domínio do cliente + teses da consultoria; **contém nós 🔒
  confidenciais marcados**; **fica no dev, nunca sai**; alimentado em lotes iterativos; gate = radar por fase.
- **KG de colaboração** (`docs/onion/graph/colaboracao-onion.kg.yaml`, sem dado de cliente → **shareable**):
  processo meta-Onion (papéis, canais, invariantes); alimentado por migalhas do diário + o instrumento de
  retro + findings de deep-research que **refutaram** "NPS-preditor" e "spec −50%" e **validaram** o
  I3/entrega-sem-commit — com `REFUTES`/`SUPERSEDES` registrando o grafo se autocorrigindo. Decisão:
  `D_KG_SEPARADO`.
- **Por que dois:** garante que a estratégia confidencial jamais contamine artefato framework-facing.
**Proposta:** convenção "**um KG SDAAL por camada de confiança**" (engajamento-confidencial × meta-shareable);
considerar promover o KG de colaboração a artefato de referência.

## Sinal 8 — responsabilidades assimétricas + autorização de fala com o core
Ainda **não formalizado** no core:
- **Vínculos assimétricos com a entidade entregadora:** os dois consultores têm relações distintas com a
  marca sob a qual o serviço é entregue. O framework **não precisa dos detalhes** — mas o **modelo de papéis
  precisa acomodar a assimetria** (co-autoria no produto, papéis distintos na operação e no acesso).
- **Autorização de relay é assimétrica e de fronteira de confiança:** só o **maestro** relaya/tria ao core;
  o **colaborador visitante** entrega sinais como arquivos (inbox) mas **não relaya nem acessa o core** —
  reforçado pelo **próprio SO** (sem acesso ao core), coincidindo com o **I3 "entrega-sem-commit"**
  (o conhecimento cruza a fronteira de confiança, o commit não). Este relay é a prova viva: o colaborador
  respondeu no repo dele; o maestro transporta ao core.
**Proposta:** formalizar no onboarding (a) o **perfil de colaborador visitante**, (b) o **boundary de
autorização de relay** (maestro-only), (c) o reconhecimento de **vínculos assimétricos** consultor↔marca sem
o framework precisar conhecê-los.

---

> **Nota de transporte:** relay individual pelo maestro (o colaborador visitante não relaya — Sinal 8).
> Os sinais 2026-07-13/14/16 do lado do adotante já estão em `inbox/_processed/` no repo dele. Este relay
> consolida o 2026-07-16 + a retro fechada 2026-07-29. **Consentimento de case/marketing:** SIM, com o nome
> do colaborador (Gustavo Pulga / BetaHauss), **condicionado a anonimizar o cliente + revisão antes de publicar.**
