---
date: 2026-07-16
instance: onion-evolve
type: decision
classification: protected
tags: [co-evolution, backlog, gustavo, vertical, kg-ssot, governance, collaboration]
affects: [meta, product, engineering]
breadcrumb_for: [meta:co-evolve, meta:evolve, meta:create-vertical]
share_with: []
next_recommended: ""
review_after: 2027-01-18
conflict_class: conditional
valid_when: "os sinais 1/2/3/5/6/7/8 do omnibus gustavo (2026-07-16-treino-vertical-colaboracao-produtos) ainda NÃO foram executados no core — quando cada cluster entrar, riscar; quando todos, aposentar"
---

## Signal
Omnibus client-safe do gustavo-pulga/⟨colaborador⟩ (8 sinais), triado 2026-07-16. Majoritariamente
**backlog/assess** (o próprio Sinal 4 pede "triar no `/meta:evolve`"). Verificado contra o core na
triagem — **4.1 já está feito** (`/meta:create-vertical`), o resto é novo. Registro para escolha de
cluster em passo dedicado; **nada executado nesta triagem** além de mover o sinal.

**Estado em 2026-10-20 (re-teste, conditional):** riscados #2 (`/meta:absorb-skill`), #3 (skill `onion-retro`),
4.2 (`/design:deck`), 4.6 (`/meta:kg diagnose`, `D_p6_diagnose_delivered` done), #6 (`D_KG_SEPARADO` done em
`colaboracao-onion-2026-07.kg.yaml` l.245), #7 (`projection-safety.sh --terms`, `D_p7_terms_extension` done) e
#8 (`D_p4_visitor_authority` done), todos no `relay-gustavo-pulga-triage-2026-07.kg.yaml` ou no vivo. **Restam
dois:** #1 (o gap-map de spec→N-artefatos; a capacidade está nomeada como claim `C_SPEC_MULTIPLICADOR`,
confirmed, em `colaboracao-onion-2026-07.kg.yaml` l.207, mas o mapa de quais comandos cobrem cada salto não
existe) e #5 (o KG de colaboração foi promovido a `docs/onion/graph/`, e a KB `colaboracao-moderna` não
existe no core).

## Decision — backlog priorizado (verdict por sinal)
Clusters de maior alavanca marcados 🎯:

- **#6 + #7 🎯 — partição de confiança do SSOT (par coerente):** *"um KG SDAAL por fronteira de
  confiança"* (engajamento confidencial × colaboração shareable, `D_KG_SEPARADO`) + *"SSOT com partição
  de visibilidade"* + **gate client-safe determinístico** (`grep` de termos sensíveis = 0, versionável).
  Estende direto a doutrina KG-SSOT desta sessão. **Candidato a ADR próprio.** Já citado como evidência
  convergente na `[[onion-adr-kg-freshness-gate-2026-07]]`.
- **#8 🎯 — governança do fluxo de co-evolução:** perfil **colaborador-visitante** + boundary de
  **autorização de relay (maestro-only)** + vínculos assimétricos consultor↔marca (o framework não precisa
  dos detalhes, mas o modelo de papéis tem que acomodar a assimetria). Toca `/meta:co-evolve`/`co-relay`/
  onboarding. O I3 "entrega-sem-commit" já valida a fronteira (KPR).
- **#1 — spec→N-artefatos como capability de 1ª classe:** nomear na identidade + **gap-map** (quais
  comandos cobrem cada salto do pipeline descoberta→vertical→skills→treino, onde há buraco). Doutrina/KB.
- **#2 — fluxo de absorção+auditoria de skill de 3º:** importar → adherence-lint → trocar fontes p/
  self-contained/offline → registrar no KG/diário. **Feature (skill/comando)**, não existe.
- **#3 — skill retro/feedback como spec-as-code:** gera o par perguntas/respostas (I3, um-escritor-por-
  arquivo), agrega NPS/CSAT, emite migalha/sinal. **Feature (skill)**, não existe.
- **#5 — absorver KB `colaboracao-moderna` + promover KG de colaboração a artefato do core:** **precisa o
  artefato relayado** (vive no repo do gustavo, não no core). Absorção (docs) quando chegar.

- **#4 — os 7 produtos deriváveis:** meta-backlog. **4.1 (gerador de vertical) = JÁ FEITO** (`/meta:create-vertical`).
  Restam: 4.2 gerador de deck de treino auto-guiado · 4.3 skill retro (=#3) · 4.4 perfil colaborador-visitante
  (=#8) · 4.5 fluxo absorção skill 3º (=#2) · 4.6 KG-dogfood-para-consultoria produtizado · 4.7 convenção
  SSOT-partição-visibilidade (=#6).

## Done nesta sessão
- Sinal triado (verdicts acima) e movido para `docs/evolution/inbox/_processed/`.
- Lição aplicada: lido **inteiro** antes de triar ([[read-full-content-before-triage]]) — quase o descartei
  como "tema diferente" na 1ª passada.

## Next crumb
Os clusters #6+#7 e #8 foram entregues (ver o Estado no Signal). Restam #1 (gap-map: uma tabela de quais
comandos cobrem cada salto descoberta→vertical→skills→treino, e onde há buraco) e #5 (absorver a KB
`colaboracao-moderna`, que depende do artefato relayado). Quando os dois entrarem, aposentar esta migalha.
Ver `[[2026-07-16-kg-sdaal-dogfood-gold-backlog]]` (o backlog irmão do rhilo).

## Re-testada em 2026-10-20 — PARCIAL: (conditional, só o `valid_when`) 6 dos 8 sinais entraram. Para #1 e #5 busquei por comportamento, não só por nome, em `.claude/`, `docs/onion/`, `docs/knowledge-base/` e nos `.kg.yaml` ("gap-map", "spec→N", "N-artefatos", "cada salto", "qual comando cobre", "cobertura do pipeline", "deriváveis", arquivos `*colabora*`). Achei só o claim `C_SPEC_MULTIPLICADOR`, o nó `E_RESEARCH` (a pesquisa de colaboração moderna, dentro do KG) e os sinais em `_processed/`. Nenhum mapa de cobertura e nenhuma KB. Os dois seguem abertos.
