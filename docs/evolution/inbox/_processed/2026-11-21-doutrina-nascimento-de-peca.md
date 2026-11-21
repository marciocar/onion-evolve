---
title: "Proposta de doutrina: nascimento de peça — o critério «ok» e a delegação do merge (card SAC-479)"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: doctrine-proposal
family: pratica
request: "Core → curadoria (2026-11-21): montar a proposta de texto da doutrina de nascimento de peça (critério «ok» + delegação do merge antes de a peça nascer), medindo o corpus do core (members.yaml, briefs de carta, D_SERVICE_REPOS_OWNER_VPS_OPS_1120, a memória das sessões donas que merjam o próprio repo) e o padrão de mercado (onboarding de serviço, ownership, CODEOWNERS). Entregar como sinal."
reviewed_for_public: true  # relido pelo core em 2026-11-21 como se publicado: só cita arquivos, selos e scripts do core e fontes públicas de mercado; o caso de cliente aparece só como regra, sem nome
---

# Proposta de doutrina — nascimento de peça

A curadoria **propõe**; o core sela. Nada aqui é selado. Esta peça **costura** decisões já seladas numa
doutrina nomeada e fecha o único ponto ainda aberto: o critério verificável de «peça ok» e o momento em
que o merge passa à sessão-dona.

## 1. O que foi medido no corpus do core

As peças do ecossistema nasceram **ad hoc**, uma decisão por peça, sem uma doutrina única que dissesse
*quando* uma peça está pronta e *quem* merja o quê. A linhagem:

- **O campo de peça** — `members.yaml` ganhou `piece: true` + `owner_session` + `sponsor` (campo novo,
  **não** `kind:` novo, porque `kind: piece` reprovaria o `members-validate.sh`, cujo enum é fechado):
  `docs/evolution/federation/members.yaml` (cabeçalho, bloco `piece:`), `D_BACKBONE_OWNER_1112`
  (2026-11-12) e o brief `docs/evolution/review/feat-piece-owner-session.md:(achado 1)`.
- **A delegação do merge** — `owner_session` é a **lista fechada** do merge pela sessão:
  `D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118` (2026-11-18) — "cada sessão merja os PRs do próprio repo,
  inclusive guarda, pelo caminho verificado com revisão separada; os atos do maestro chegam prontos para
  ele autorizar com uma palavra". O `ops/pr-merge-verified.sh` só deixa mergear quem é `kind: source` ou
  declara `owner_session`, e o dono do remote tem de ser o do core.
- **Serviço** — `D_SERVICE_REPOS_OWNER_VPS_OPS_1120`
  (`docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml:785`, 2026-11-20): os repos de serviço têm
  `onion-vps-ops` como dona registrada; ela merja os próprios PRs pelo caminho verificado; **deploy e
  produção seguem do maestro**.
- **Cliente/privado** — `D_PRIVATE_OWNER_SESSIONS_1119` (2026-11-19): o repo de cliente (outro dono) fica
  **sempre fora** da lista; o slug real vive fora do repo (`~/.config/onion/private-owner-sessions.tsv`).
- **A carta de arranque e o aviso** — o `baton-pulse.sh` resolve o dono por nome e dá `PIECE_OWNED`,
  `PIECE_UNOWNED`, `PIECE_OWNER_NAME_MISMATCH`, `PIECE_UNMEASURED`, **com o card de arranque em texto**
  (ex.: `cd ~/onion-vps-ops && claude --name onion-vps-ops`), e **avisa, nunca bloqueia**:
  `.claude/validation/baton-pulse.sh:580,640-646`; briefs `feat-piece-owner-session.md` e
  `feat-vps-ops-piece.md`.
- **O pin honesto** — o `onion_version` do registro só se carimba (`ops/registry-pins.sh --seal`)
  **depois** do merge do update da própria peça, nunca antes: `feat-vps-ops-piece.md:(achado 1)`.
- **O PR de nascimento vai ao maestro** — "o `members.yaml` é guarda: marcar a peça amplia o que a batuta
  cobra e **o que a delegação alcança** → merge do maestro, dito no corpo do PR":
  `feat-vps-ops-piece.md:(achado 2)`.

**O que falta:** uma doutrina que (a) nomeie o critério verificável de «peça ok» como uma lista única, e
(b) diga explicitamente quem merja **antes** de a peça existir — hoje isso vive espalhado em achados de
brief, não em doutrina.

## 2. O padrão de mercado (fonte primária)

- **Ownership declarada no repo, antes do merge — CODEOWNERS + branch protection (GitHub).** O dono é
  declarado num arquivo versionado; "Require review from Code Owners" exige a aprovação do dono **antes**
  do merge; uma aprovação de qualquer dono listado basta; vale o CODEOWNERS do branch base. Rulesets
  (nov/2025) complementam, não substituem.
  — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- **Onboarding de serviço com porta verificável — Production Readiness Review (Google SRE, cap. 32).** O
  serviço passa por uma **lista** (checklist do PRR) **antes** de a propriedade (SRE) ser assumida; a
  saída é a lista de correções exigidas antes da transferência de dona. GitLab exige concluir um PRR para
  onboardar um serviço.
  — https://sre.google/sre-book/evolving-sre-engagement-model/
- **Mapa para o Onion:** o critério «peça ok» ↔ o PRR (porta verificável antes de a propriedade passar);
  a delegação do merge ↔ CODEOWNERS + branch protection (dono declarado **antes** de o merge ser
  delegado, caminho verificado como o "required review"). A diferença do Onion: a lista é **fechada** e o
  remote tem de ser do dono do core; e os gates são **deterministas** (`members-validate.sh`,
  `baton-pulse.sh`), não julgamento.

## 3. Texto proposto da doutrina

> ### Nascimento de peça
>
> Uma **peça** é um repo/serviço estratégico do ecossistema com **sessão Onion própria** que o defende e
> um **patrocinador humano**, registrada no `members.yaml` com `piece: true` + `owner_session` + `sponsor`
> (campo, não `kind:` novo). **Nascer** é passar a ser peça registrada e ganhar a delegação do merge.
>
> **A. Critério de «peça ok» (a porta de nascimento — todos verificáveis, o PRR do Onion).** A peça nasce
> quando TODOS passam:
> 1. **Registro válido:** entrada no `members.yaml` com `kind` (natureza), `remote` e os três campos de
>    peça; `bash .claude/validation/members-validate.sh` **rc 0**.
> 2. **Dono nomeado:** `owner_session` declarado; o `baton-pulse.sh` resolve `PIECE_OWNED` (sessão viva com
>    o nome) **ou** `PIECE_UNOWNED`/`PIECE_UNMEASURED` com o **card de arranque** pronto. O pulso **avisa,
>    nunca bloqueia**: a peça pode nascer sem a sessão ligada, desde que o card exista.
> 3. **Patrocinador humano:** `sponsor` declarado.
> 4. **Revisão separada do PR de nascimento:** brief em Conventional Comments, `review-triage-check.sh`
>    rc 0, verdict aprovado, **bloqueios = 0**.
> 5. **Pin honesto:** o `onion_version` do registro só se carimba (`ops/registry-pins.sh --seal`)
>    **depois** do merge do update da própria peça — nunca antes (declarado ≠ verificado).
>
> **B. Delegação do merge (o antes e o depois do nascimento).**
> - **O PR de nascimento** — o que registra a peça no `members.yaml` (um **guarda**: amplia o que a batuta
>   cobra e o que a delegação alcança) — **NÃO** é mergeado pela sessão-dona nascente: ela ainda não está
>   na lista fechada do `pr-merge-verified.sh`, e o ato **cria** a própria delegação. Vai ao **maestro**
>   (ou ao core, `kind: source`), dito no corpo do PR. É o ovo-e-galinha: não se delega o merge por um PR
>   que o delegatário merja.
> - **Depois do nascimento** — com `owner_session` na lista fechada, o merge dos PRs do **próprio repo da
>   peça**, inclusive guarda, passa à **sessão-dona**, pelo **caminho verificado** com revisão separada
>   (`ops/pr-merge-verified.sh`, que recusa CI vermelho/pendente).
> - **Fica sempre com o maestro:** **deploy e produção**; e **repo de cliente/outro dono** nunca entra na
>   lista (o caso privado vive fora do repo, `D_PRIVATE_OWNER_SESSIONS_1119`).
>
> **C. Invariante.** A propriedade é declarada no registro **antes** de o merge ser delegado (como
> CODEOWNERS); e nenhuma peça nasce sem passar a porta A (como o PRR). O pulso da batuta é o lembrete, não
> a trava.

## 4. Veredito e onde vive

**Veredito proposto: `costurar`.** A maior parte já está selada (A.1–A.3, A.5, B); a doutrina **nomeia** o
padrão e **fecha** os dois pontos que viviam só em achado de brief: o **critério «ok» como lista única**
(porta A) e a **regra explícita do merge antes/depois do nascimento** (B). Não é `absorver` (não há
mecanismo novo a construir — os gates já existem) nem `rejeitar`/`parquear`.

*Onde vive (proposta):* uma cláusula de doutrina na KB do core (ex.: `onion-federation-and-adoption.md`
ou uma peça nova "piece-birth"), ligada ao cabeçalho do `members.yaml` (que já descreve os campos), à
doutrina do baton e ao caminho de merge verificado. Medições creditadas: `feat-piece-owner-session.md` e
`feat-vps-ops-piece.md`.

*O que o core sela:* o texto e o lugar. Se quiser, a curadoria registra a proposta no próprio corpus
(`.kg.yaml` + PR) — mas, como foi pedida como sinal, entrego assim e aguardo.

---

Orquestrado com 🧅 Onion Evolve
