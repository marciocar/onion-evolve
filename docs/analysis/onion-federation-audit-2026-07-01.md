# Onion Federation Audit — 2026-07-01

> **Status:** efêmero / backlog-ativo (segue [analysis/README.md](README.md)) — auditoria **focada em federação**
> (estado real vs RFC-0003 + saúde do doc-bridge + bitrot da maquinaria gated). Removível quando o backlog
> for executado; as conclusões duradouras migram para a KB
> [`federation-usage-modes.md`](../knowledge-base/concepts/federation-usage-modes.md) (criada nesta sessão a partir do §6).

## 0. Sumário

◆ Dimensões: 6 (FED-1..FED-6) ◆ Padrão: fan-out-and-synthesize + adversarial verification
◆ Workers: 13 (6 auditores sonnet/haiku + 6 juízes opus + 1 completeness critic sonnet)
◆ Budget: ~719k tokens ◆ Duração: ~10,7 min ◆ Run ID: `wf_48c138b0-5f6`
◆ Achados: **27 brutos → 21 sobreviventes** (6 refutados/vetados pelo juiz) → **18 itens de backlog** após dedup no fan-in
◆ Dogfood real executado pelos workers: `diary-index.sh` (exit 0, INDEX vazio correto), `trust-topology-check.sh`
(modo-de-falha exercitado — revelou o blocker #1), `federation-contract-validate.sh` contra as 2 fixtures
(good→0, bad→1 ✓), `bash -n` + comportamento-sem-ledger dos scans (falha graciosa exit 2 ✓).

**Veredito de topo:** o núcleo mecânico da Federação formal está **saudável** (scripts rodam, fixtures passam,
cross-refs resolvem); os problemas reais são (a) **um bug de código** que inutiliza a topologia granular de
confiança, (b) **guard de identidade do adopt estruturalmente vazio**, e (c) **drift sistemático de
registro/vocabulário** entre members.yaml, RFC-0003, KB e comandos — 3 namespaces de "role" nunca nomeados
como eixos distintos.

## 1. Backlog priorizado

Legenda: 🔴 blocker · 🟡 recommended · 🟢 opportunistic · ✅ = quick-fix aplicado nesta sessão

| # | Sev | Dim | Achado (evidência resumida) | Padrão-doutrina | Esforço | Ação/atuador |
|---|-----|-----|------------------------------|-----------------|---------|--------------|
| 1 | 🔴✅ | FED-2 | `id_in_list()` em `trust-topology-check.sh:79-95` **nunca casava** os campos do bloco `trust:` do members.yaml — regex esperava indentação de 4 espaços (real: 6) e não removia comentário inline antes de comparar. `can_receive_from/can_advise_to/can_correct_to/diary_readable_by/exposes_downstream` estavam **mortos**; só as regras grosseiras por role funcionavam. Provado por dogfood: cópia do schema com `can_correct_to: [onion-evolve]` populado ainda retornava BLOQUEADO. | spec-as-code SSOT (consumidor deve ler o schema real) | S | **Aplicado (mesma sessão):** regex `^[ ]+` (indentação livre) + `sub(/#.*$/)` antes da comparação; 11 cenários dogfoodados + **modo `trust-topology` novo no lint-selftest** (11 guardas permanentes, sandbox via `--repo`). |
| 2 | 🔴✅ | FED-3 | Guard de identidade do `/meta:adopt` (adopt.md:259) era **estruturalmente vazio**: consultava `onion-version.sh`, que imprimia `role: source` **hardcoded** — e o script é vendorizado para todo adotante. Rodar `/meta:adopt` de uma instância adotada **passaria no guard**. | cross-ref íntegra / registro reflete a realidade | M→S | **Aplicado (mesma sessão):** `onion-version.sh` agora deriva o papel da **presença do stamp** `.claude/.onion-version` (stamp presente → lê `role:` de lá; sem campo → `adopted` fail-safe). O guard do adopt (inalterado) passa a abortar de verdade em instância adotada. **Modo `onion-version` novo no lint-selftest** (3 guardas de regressão). |
| 3 | 🔴✅ | FED-3+FED-4 | KB `multi-repo-federation.md` §3 documentava o members.yaml em schema **v1 obsoleto** (`version: 1`, `role: producer\|consumer\|lib`) — e é a fonte que `/meta:federation-register` copia ao bootstrapar ledger. Replicaria schema superado pela RFC-0003/members.yaml v2. | spec-as-code SSOT | S | **Aplicado:** §3 atualizado para `version: 2` + tiers, com nota separando role-de-membro de producer/consumers-de-contrato. |
| 4 | 🔴✅ | FED-5 | Pin drift: `members.yaml:32` dizia `onion_version: 025225e286d8` (sync 06-24); o stamp real do adotante diz `a458a0fc6b71` (06-30). Registro 6 dias atrás da realidade. | registro reflete a realidade | S | **Aplicado:** pin atualizado + data de sync. |
| 5 | 🔴✅ | FED-5 | `adopted_at` diverge: members.yaml diz 2026-06-17, stamp do adotante diz 2026-06-30. **Ressalva do fan-in:** semânticas provavelmente diferentes — members.yaml registra a 1ª adoção (histórico correto); o `--update` **re-carimba** `adopted_at` no stamp (perde o histórico). A causa-raiz pode ser o `--update` sobrescrever o campo. | registro reflete a realidade + semântica de campo única | S | Decisão do maestro: (a) `--update` preserva `adopted_at` original e adiciona `updated_at`, ou (b) members.yaml adota o mesmo significado do stamp. Anotado comentário no members.yaml. |
| 6 | 🟡✅ | FED-1+FED-2 | RFC-0003 usa o nome `trust_topology` (linhas 49, 193) para o campo que members.yaml, `trust-topology-check.sh` e `types.md` chamam de `trust:`. O próprio comentário do members.yaml:24 citava o nome errado. | cross-ref íntegra | S | **Aplicado:** RFC alinhada ao nome real `trust:` (com nota); comentário do members.yaml corrigido. |
| 7 | 🟡✅ | FED-2 | RFC-0003 §5 linha 206 pergunta o formato do trust-log — mas `docs/evolution/trust-log.md` **já existe**, é gerado por `log_attempt()` (trust-topology-check.sh:109-128) e tem entradas reais. Pergunta respondida, não riscada. | registro nunca atrás da realidade | S | **Aplicado:** linha marcada como resolvida apontando o artefato real. |
| 8 | 🟡✅ | FED-1 | `personality_summary`/`personality_last_sync` preenchidos **à mão** no members.yaml para os 2 membros, mas a RFC declara o campo "auto-gerado por `/meta:personality-sync`" — comando e `.claude/identity/` **não existem** (F2 gated). Registro à frente da maquinaria. | registro nunca à frente da realidade | S | **Aplicado (opção b):** marcado como "seed manual pré-F2, substituir no 1º sync real". |
| 9 | 🟡 | FED-1 | O commit `f07fe90` ("RFC-0003 Fase 1") entregou junto F1 (diary) + campo de F2 + **Trust SDAAL inteiro de F3** — antes do gate de F1 (10 entradas/1 semana; real: **0 entradas**). Maquinaria construída à frente do sequenciamento da própria RFC (bitrot-risk: adapters nunca exercitados com relay real). | gated até gatilho (sequenciamento da RFC) | S | Decisão do maestro: anotar no roadmap (ou diary entry) a antecipação de F3 + gate F1 pendente. Não ativar nada novo. |
| 10 | 🟡✅ | FED-1 | `trust-topology-check.sh` **não tem `--dry-run`**: toda invocação (inclusive dogfood/CI) grava em `trust-log.md` sem marcação de teste — mina a auditabilidade ("log mistura ruído de teste com sinal real"). Confirmado nesta auditoria: o dogfood do worker gravou 2 linhas no log de produção (revertidas no fan-in). | auditável | S | Adicionar `--dry-run` (imprime veredito, não loga) antes de o script entrar em dogfood/CI recorrente. |
| 11 | 🟡 | FED-3 | Hierarquia de tiers (T1 hub "tem seus próprios adotados"; T2 adota um hub) **não tem mecanismo** no `/meta:adopt`: guard trava a `role: source` e `adoption-lifecycle.md` só conhece "[Core] dirige". A RFC §5 marca a dúvida; a doutrina operacional nem reconhece que ela existe. | cruzamento eixo-a-eixo sem doutrina | M | Registrar decisão (hub-driven adoption sim/não) na revisão da RFC; refletir na matriz do adoption-lifecycle e, se sim, num modo do adopt. |
| 12 | 🟡✅ | FED-3 | Template de onboarding do members.yaml só documenta `role: hub\|standalone` com `parent: onion-evolve` fixo — **não expressa um T2** (`role: consumer, parent: <hub-id>`). | SSOT incompleta | S | Adicionar variante `role: consumer` ao template + nota do gap T2 (RFC §5). |
| 13 | 🟡 | FED-3 | `co-evolution-reference.md` (tabela gated) e os 5 `federation-*.md` usam `producer`/`consumer` como papel do **membro** — vocabulário que a RFC-0003 substituiu por tiers. Colisão terminológica plantada (dormente enquanto gated). | contradição terminológica entre docs irmãos | S | Nota de escopo na RFC (ou ADR-satélite): producer/consumer **de contrato** é eixo ortogonal ao tier de membro e permanece. |
| 14 | 🟡✅ | critic | **Gap apontado pelo completeness critic:** nenhuma dimensão varreu `docs/analysis/*backlog*` como classe. Evidência do próprio critic: `onion-coevolution-backlog-2026-06-18.md` (item 4) ainda registra "#9 → trial", mas o catálogo #9 foi materializado no PR #164 (06-24, confirmado no CHANGELOG). Backlogs stale re-flagam trabalho já feito (mesmo padrão do seed S1). | registro reflete a realidade (classe: backlogs) | S | Varredura dedicada de `docs/analysis/*backlog*/*evolution*` cruzando itens vs git log; curar/remover per ciclo de vida de analysis. |
| 15 | 🟢 | FED-1 | Gates F2 ("personality legível") e F5 ("demanda real") não são mensuráveis mecanicamente — diferente de F1/F4 (contagens objetivas). | gate mensurável | S | Na revisão da RFC (2026-10-01): proxies mensuráveis ou marcar como decisão humana explícita. |
| 16 | 🟢 | FED-2 | Dead schema (coerente com gating): `diary_classifications_shared`, `specializations`, `exposes:` não são lidos por nenhum consumidor executável hoje — destinam-se a F2/F4. | gated até gatilho — prontidão registrada | S | Nenhuma ação agora; revalidar quando F2/F4 ligarem. |
| 17 | 🟢 | FED-2 | `factory.md`/`interface.md` do Trust SDAAL prescrevem resolução via `resolve_trust_adapter()`, mas o script real é monolítico/inline — a doc da abstração descreve design que o código não implementa. | spec-as-code SSOT | M | Decisão: nota "implementação simplificada pré-adapter" na factory, ou refatorar quando F3 ligar de fato. |
| 18 | 🟢 | FED-3 | Modelo de classificação de dados (private→collective) nunca cruza com `mode: regulated` — sem doutrina de defaults conservadores para membros regulados. | lacuna eixo-a-eixo | S | Adendo à RFC antes do aceite: default restritivo (nunca public/collective sem revisão) para `mode: regulated`? |

**Fechado no fan-in (contra-veredito com evidência de 1ª mão):** o achado FED-6-0 (menção textual ao design-v1
em `onion-federation-design-v2:5,13`) sobreviveu ao juiz, mas a menção em texto-plano **é o próprio fix**
aplicado no PR #188 (commit `72e55e5`, delink deliberado preservando história) — não é pendência. Registrado
como *wontfix consciente*.

## 2. Achados por dimensão (síntese dos workers)

- **FED-1 (gates vs real):** F4/F5 e `--to peer` de fato não existem (gating respeitado ✓). Mas `f07fe90`
  entregou F1+campo-de-F2+F3-inteiro num commit só, antes do gate de F1 (0/10 entradas de diário).
  `diary-index.sh` dogfoodado: exit 0, INDEX vazio correto.
- **FED-2 (consistência tripla):** bloco `trust:` granular **inoperante** por bug de parsing (item #1);
  seeds S3/S4 confirmados; dead schema coerente com gating; divergência factory-vs-script.
- **FED-3 (taxonomias):** os 4 artefatos usam eixos genuinamente diferentes, nunca cruzados; **3 namespaces
  de "role"** identificados (ver §3); matriz de reconciliação produzida (→ §6/KB).
- **FED-4 (bitrot dos gated):** núcleo mecânico **saudável** — `federation-contract-validate.sh` ✓ (fixtures
  good→0/bad→1), scans com falha graciosa sem ledger ✓, cross-refs dos 5 comandos todos resolvem ✓. Único
  apodrecimento real: o schema v1 na KB (item #3, corrigido).
- **FED-5 (doc-bridge):** pin 6 dias atrás (corrigido), `adopted_at` ambíguo (item #5). 3 achados do worker
  haiku foram **refutados pelo juiz** (ver killed) — o tier haiku gerou mais falso-positivo, o que valida o
  investimento no juiz opus.
- **FED-6 (links/ADRs):** **zero links mortos** na superfície de federação; proibição A2A runtime íntegra em
  toda a superfície; vocabulário downstream/upstream/handoff migrado (as menções "ex-flow A/B" são o
  breadcrumb exigido pelo próprio ADR).

## 3. Alertas transversais (3+ achados, mesma causa)

1. **Três namespaces de "role" sem reconciliação nomeada** (itens #3, #6, #12, #13): (i) role de **contrato**
   (`producer:`/`consumers:` em contracts/, ativo e correto); (ii) role de **membro** (tiers RFC-0003 em
   members.yaml); (iii) role de **stamp** (`source`/`adopted` no `.onion-version`). Nenhum doc os declara
   como eixos distintos — a causa comum de metade do backlog. **A KB de síntese criada nesta sessão nomeia
   os 3 e é o fix estrutural.**
2. **Sync manual do registro falha silenciosamente** (itens #4, #5, #7, #8, #14): members.yaml, RFC e backlogs
   ficam atrás (ou à frente) da realidade porque a sincronização é manual. Candidato a **guard determinístico**:
   script que compara `members.yaml` vs stamps reais dos `local_path` (mesmo padrão inventory.sh↔lint).
3. **Maquinaria à frente do gate** (itens #8, #9, #16, #17): F3 construído antes do gate F1; campos de F2/F4
   semeados à mão. Não é violação do gating *externo* (Federação formal continua desligada ✓), mas dilui o
   sequenciamento interno da RFC e cria superfície de bitrot não-exercitada.

## 4. Invariantes verificadas (juiz adversarial)

- ✅ **A2A runtime:** nenhuma contradição em toda a superfície de federação.
- ✅ **Gating da Federação formal:** nenhum achado propôs ativação pré-gatilho (2 propostas nessa direção foram vetadas).
- ✅ **Um escritor por repo:** 1 achado (FED-5-2) foi **vetado** justamente por propor que o core editasse o
  repo do adotante — o veto funcionou como desenhado.
- 6 refutações totais: FED-5-2 (mischaracterização de guidance opcional como mandato + veto), FED-5-3
  (evidência era artefato de branch em checkout, não ausência real), FED-5-4 (má leitura de "processado"),
  FED-6-1 (breadcrumb "ex-flow" é exigência do ADR, não violação), FED-6-2/FED-6-3 (🟠 do Carteiro refere-se
  ao distribuído, que segue corretamente a-desenhar).

## 5. Próximos passos

1. **#1 e #2 são os únicos blockers de código** — corrigir `id_in_list()` (S) e o guard do adopt (M), cada um
   com caso novo no lint-selftest (converter o achado em guard determinístico permanente — doutrina de dogfood).
2. Decidir a semântica de `adopted_at` (#5) — provável fix no `--update` (preservar original + `updated_at`).
3. Executar a varredura de backlogs stale (#14) como mini-run dedicado.
4. Levar #9, #11, #13, #15, #18 para a **revisão da RFC-0003** (review_after 2026-10-01 — ou antecipar, dado o volume).
5. Anúncio downstream (via `/meta:co-announce`) quando os quick-fixes + KB forem commitados — o adotante
  rhilo-metagamify é afetado pelo pin corrigido e pela KB nova.

## 6. Insumos para a síntese (consumidos pela KB `federation-usage-modes.md`)

A matriz de reconciliação produzida pelo worker FED-3 (tier × modo de adoção × maquinaria × status) foi
absorvida e expandida pela KB [`federation-usage-modes.md`](../knowledge-base/concepts/federation-usage-modes.md)
— incluindo a regra de reconciliação (eixos de adoção = momento; tier = vida em rede; in-place ⇒ sem tier),
os 3 namespaces de role (§3.1) e a tabela única de gatilhos de graduação com estado real verificado por esta
auditoria.
