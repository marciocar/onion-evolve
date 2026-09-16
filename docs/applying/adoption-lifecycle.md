# Ciclo de vida da adoção Onion — cenários por modo

> Cruza as **operações** do ciclo de vida (adoção → update → revisão → sincronização) com os **modos** de
> adoção. Usa a [linguagem ubíqua](../evolution/README.md#linguagem-ubíqua) (Core, instância adotada, Onion
> de \<repo\>, sessão do \<repo\>, vendoring). **Vivo/revisável** — marca o que é real vs a-desenhar
> (legenda: 🟢 implementado · 🟠 parcial/a-desenhar). Aprofundamento de visão: [concept-map §card 6](../analysis/onion-vision-concept-map-2026-06.md).

## Os dois eixos (não confundir)

1. **Modelo de controle** — _como_ o Onion vive no alvo:
   - **install (durável):** o framework é **vendorizado** (copiado) para dentro do alvo → vira uma **instância adotada** soberana. Tem ciclo de vida completo (este doc).
   - **in-place (efêmero):** o alvo é só montado como working dir; **nada é instalado**. **Sem ciclo de vida** (sem update/revisão/sync — o repo não vira Onion).
2. **Cenário do alvo** — _o estado_ do alvo: **greenfield** (sem código) · **legacy** (tem código → engenharia reversa + worktree) · **regulated** (+ compliance).

> O ciclo de vida abaixo é do modelo **install**. O **in-place** não tem ciclo — é uma sessão efêmera.

## Matriz rápida (operação × o que muda por modo)

| Operação | greenfield | legacy | regulated | Quem dirige |
|---|---|---|---|---|
| **Adoção** | scaffold + install | + reverse-eng + worktree `onion/adopt` | + `compliance-context` (ISO/SOC2/PMBOK) | **[Core]** (source-driven), por path |

> **T2 (consumer-de-hub) também é core-driven** (RFC-0003 §5, decisão 2026-07-02): o maestro roda
> `/meta:adopt` do core e registra `parent: <hub-id>` no members.yaml — o hub **não** roda adopt.
> *Hub-driven adoption* é gatilho futuro (1º T2 real + dor de roteamento via core).
| **Update** | `--update` (delta diff-based) | idem | idem | **[Core]** dirige · instância revisa/commita |
| **Revisão** | diff da cópia segura (tmp→diff→aplicar) | idem (+ atenção a customizações locais) | + gate de compliance | maestro + Claude local da instância |
| **Sincronização** | gitflow do alvo + registro no Core | idem | idem | **sessão da instância** ([repo]) |

---

## 1. Adoção (1ª vez)

**Comando:** `/meta:adopt <path|git-url> [--mode greenfield|legacy|regulated] [--integration-branch <nome>] [--in-place]` 🟢

- Roda da **[Core]** (lê `role: source`), opera no alvo por path. Carimba `.onion-version` (proveniência).
- **Por modo:** greenfield = scaffold dos 3 contextos; legacy = `/docs:reverse-consolidate` + install em **worktree** (isola a árvore do legado); regulated = + `docs/compliance-context/` populado.
- **Direção (fora-pra-dentro vs dentro-pra-fora)** e **consentimento:** o alvo precisa **saber** da nova config — nada espalhado sem consciência. 🟠 *a-desenhar* (card 6).
- **Dois modos de comando** (saídas distintas):
  - **Onion autônomo** → **auto-emite um relatório** (o que foi feito · novidades · do que a instância é
    capaz agora · próximos passos) **no canal downstream do alvo** (`docs/evolution/inbound/`, git-visível),
    e o hook "you have mail" o sinaliza na sessão do alvo. 🟢 *implementado* (adopt v1.7.0).
  - **Consumidor no comando** → **onboarding assistido** (o Claude+Onion local da instância guiando, consciente). 🟠 *a-desenhar*.
- **Limpeza de IDE legada** (`.cursor/.windsurf/copilot`) = **opção** com etapas bem definidas (nunca cego). 🟠 *gap — não implementado*.

## 2. Update (puxar evolução do framework)

**Comando:** `/meta:adopt --update <path-da-instância>` 🟢

- **Deliberado, nunca link vivo** (instâncias são `standalone`/vendorizadas). Roda da **[Core]** (source); a instância (`role: adopted`) **não pode** ser a fonte.
- Computa o delta `pin-da-instância → HEAD do Core`, copia **diff-based/never-clobber** (não toca arquivos do alvo fora do manifesto), re-aplica o Procedimento pós-cópia (hooks/settings) e **re-carimba** o `.onion-version`.
- **Relink:** hoje só implícito via `--update` (reusa `adopted_from`). Relink explícito (re-apontar proveniência) 🟠 *a-desenhar*.
- **Downstream**: o Core anuncia o que muda no [`federation/CHANGELOG.md`](../evolution/federation/CHANGELOG.md); a instância puxa quando quiser.
- **Relatório auto-emitido + notificação** 🟢: o `--update` escreve o relatório do delta no
  `docs/evolution/inbound/` do alvo (canal downstream) e o hook "you have mail" o sinaliza — sem o maestro
  repassá-lo à mão. Fecha o gap "downstream meia-estrada" (`inbox/2026-06-19-flow-a-report-and-bidirectional-mail.md`).

## 3. Revisão

- A **cópia segura** é `tmp → diff → aplicar`: o **diff mostra exatamente o que muda** antes de escrever 🟢. O maestro confirma.
- A instância revisa na **sessão dela** (o Claude+Onion local pode assistir a leitura do diff).
- **regulated:** + gate do `@metaspec-gate-keeper`/compliance antes de aceitar.
- **Drift cosmético de prettier (esperado, benigno):** o vendor chega com o formato do **core**; se o adotante roda `prettier`/`lint-staged`, ele reformata os `.md` ao padrão local no commit → o diff incha com reflow sem mudança de conteúdo. **Não é bug do core** (ele não pode prever a config de cada adotante). Se incomodar, o adotante adiciona os paths do Onion (`.claude/**`, `docs/meta-specs/**`, `docs/knowledge-base/**`) ao `.prettierignore` dele. Sinal recorrente (`inbox/2026-06-17` + `inbox/2026-06-19-mgfy-adocao-update-a0fdf35.md`) → **wontfix consciente**.

## 4. Sincronização

- **Da instância (produto):** usa o **gitflow do próprio repo** — feature → PR → branch de integração (ex. `evolve`, resolvida por [`resolve-integration-branch.sh`](../../.claude/validation/resolve-integration-branch.sh)) → `/git/sync`. É escrita na **sessão da instância** (`um escritor por repo`).
- **Do registro (Core):** após o update, atualizar o pin da instância em [`federation/members.yaml`](../evolution/federation/members.yaml) — o registro **reflete a realidade** (nunca à frente). 🟢 (hoje manual).
- **Proveniência:** o `source_commit` do `.onion-version` é a versão de cada instância (member-version awareness).

---

## in-place — sem ciclo de vida

`--in-place` monta o alvo como working dir e opera **efêmero**: roda PASSO 0 → (reverse-eng opcional) → relatório. **Pula install/update/revisão/sync.** O repo **não** vira Onion. Use para inspeção/operação pontual sem adotar.

## Status / maturidade (honesto)

| Capacidade | Status |
|---|---|
| `/meta:adopt` (3 modos + in-place + `--integration-branch` + `--update`) | 🟢 implementado |
| Cópia diff-based/never-clobber + re-stamp | 🟢 |
| Procedimento pós-cópia idempotente (hooks/settings) | 🟢 |
| Resolução portável da branch de integração | 🟢 |
| Relatório autônomo auto-emitido no alvo (`inbound/`) + notificação "you have mail" bidirecional | 🟢 (adopt v1.7.0) |
| Onboarding assistido (consumidor no comando) | 🟠 a-desenhar (card 6) |
| Direção-aware + consentimento explícito do alvo | 🟠 a-desenhar (card 6) |
| Limpeza de IDE legada (opção, com etapas) | 🟠 gap |
| Relink explícito | 🟠 a-desenhar |
| Update do `members.yaml` (registro) | 🟢 (manual) |

## Referências

- Guias por cenário: [`applying-greenfield.md`](./applying-greenfield.md) · [`applying-legacy.md`](./applying-legacy.md) · [`applying-regulated.md`](./applying-regulated.md)
- Comando: [`.claude/commands/meta/adopt.md`](../../.claude/commands/meta/adopt.md)
- Co-evolução (downstream/upstream/handoff) + linguagem ubíqua: [`docs/evolution/README.md`](../evolution/README.md)
- ADR de adoção: [`onion-adr-repo-adoption-2026-06.md`](../knowledge-base/decisions/onion-adr-repo-adoption-2026-06.md)
- Requisitos de qualidade (card 6): [`onion-vision-concept-map-2026-06.md`](../analysis/onion-vision-concept-map-2026-06.md)
