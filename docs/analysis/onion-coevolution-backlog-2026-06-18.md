---
title: 'Backlog de co-evolução — pendências em aberto (jornada de 2026-06-18)'
date: 2026-06-18
type: evolution-backlog
status: aberto
origin: sessão de co-evolução (inbox triage + /meta:adopt --update fix #99)
---

# Backlog de co-evolução — o que ficou em aberto (2026-06-18)

> Snapshot consolidado das pendências ao fim da jornada que entregou o #97 (robustez do harness) e o #99
> (`/meta:adopt --update` idempotente). Itens datados; números são divergentes-de-snapshot por design
> (`type: evolution-backlog` isenta do lint de contagem). Para retomar: ler este doc + `git log`.

## Entregue nesta jornada (contexto)

- **#97** — pre-commit roda o self-test condicional + fixtures r16 derivam da SSOT (sinal `selftest-harness-robustness`, _processed).
- **#99** — `/meta:adopt --update` re-aplica os passos install-only via "Procedimento de Configuração
  pós-cópia (idempotente)" + helper testável `merge-onion-hooks.sh` + `lint-selftest.sh kind=merge`
  (sinal `adopt-update-skips-phase3`, arquivamento no **#100**).
- Trio "you have mail" verificado implementado/mergeado/funcional (sinal `session-start-inbox-hook-pattern`, _processed).

---

## Pendências priorizadas

### 🟢 Mecânico / rápido

1. ✅ **#100 (MERGED) — #2 arquivada.** `adopt-update-skips-phase3-steps.md` → `_processed/`.
2. ✅ **#3-c FEITO — warm-up aponta para `evolution/inbox`.** O sinal `co-evolution-not-distributed-by-adopt`
   está **totalmente resolvido**: 3-a (starter `docs/evolution/` no adopt) pelo #95; 3-c — `warm-up.md` (seção
   5) + `engineer/warm-up.md` apontam para o inbox + `/meta:co-evolve` (orientam, sem re-contar; o hook conta).
   `product/warm-up.md` deixado de fora de propósito (co-evolução é sinal técnico, não fluxo de produto).
   Mensagem #3 movida para `_processed/` neste mesmo PR.

### 🟡 Decisão de apetite (carrega dívida embutida)

3. ✅ **#1 (MERGED, PR #104) — `--integration-branch` no `/meta:adopt`** (`adopt-gitflow-develop-branch-config`).
   **Eixo corrigido pela diligência:** a premissa original ("setar `git config gitflow.branch.develop`")
   não se sustentava — *nenhum* comando lia essa config para a base do PR (`pr.md` hardcodava `develop`).
   O lever real é o `/engineer:pr` **resolver** a branch de integração via helper
   `resolve-integration-branch.sh` (cadeia: campo `integration_branch` no `.onion-version` → `git config`
   → default detectado `develop`-se-existe-senão principal). SSOT versionado no `.onion-version` dissolve a
   fragilidade "git config é local da máquina". Campo carimbado só quando escolha explícita; helper
   defensivo (tolera ausente/vazio/CRLF), coberto por `lint-selftest.sh` modo resolve (8 cenários).

   - 🚫 **Lint determinístico do schema `.onion-version` — WON'T-DO (verificado), não "adiado".** O
     pré-requisito que este item carregava ("estender o lint para validar o schema do stamp") foi um
     **mis-diagnóstico por analogia de doutrina** ("SSOT → tem que ser lintado"), feito antes de examinar
     os consumidores. Verificação empírica do failure mode de cada campo malformado: `integration_branch`
     → helper degrada seguro; `source_commit` → `--update` re-copia (idempotente) ou `git diff` **falha
     visível** (não silencioso); `role` → orientação humana read-only, corrigível; `mode` → **inerte**
     (nenhum reader); proveniência → inerte. **Nenhum** caminho causa corrupção silenciosa/irreversível.
     **Raiz da mudança:** lint é o guard certo para SSOT **editado à mão que drifta** (inventory, contagens);
     errado para dado **gerado-por-máquina e consumido-na-leitura** como o `.onion-version` — aí o guard que
     encaixa é (a) testar o gerador + (b) **leitura defensiva** nos consumidores (o que o #1 já estabeleceu).
     **Gatilho de revisão:** reabrir *se* a federação passar a **parsear mais campos do stamp por script**
     (vira consumidor determinístico → muda a classe). Resíduo cosmético opcional: `--update` com
     `source_commit` lixo cospe `fatal: ambiguous argument` cru — fix seria 1 linha de guard no `--update`
     (checar formato sha antes do `git diff`), **não** um schema-lint.

### 🔴 Decisão estratégica (pede pensamento, não execução)

4. **RFC-0002 — veredito profundo da camada de meta-estratégia.** O `rhilo-metagamify` enviou (fluxo B,
   doc-bridge) um **ack** ao handoff `onion-strategy-layer-handoff-2026-06-17.md` — mensagem
   `2026-06-17-veredito-strategy-layer.md`, `status: ack (veredito profundo pendente — RFC-0002)`. O core
   **deve** produzir o RFC-0002 em resposta; nunca foi escrito. É o único item que pede *design*, não
   mecânica. Enquanto pendente, o sinal **permanece corretamente no inbox** (não processar sinal
   não-endereçado).
   - ⚠️ **Higiene:** há um move desse arquivo para `_processed/` **não-commitado no working tree local** (de
     sessão anterior) — prematuro. Na `main` o sinal segue no inbox (correto). Resolução do maestro quando
     for commitar o working tree: descartar esse move até o RFC-0002 existir.

## Adendo 2026-06-22 — triagem de 2 sinais do `rhilo-metagamify` (fluxo B)

> Triados na sessão de co-evolução de 2026-06-22 (CHANGELOG 2026-06-22, duas entradas). Respostas
> empurradas ao `inbound/` do adotante; sinais movidos para `inbox/_processed/` do core.

### 🟡 Decisão de apetite

5. ✅ **ENTREGUE — Diretriz canônica de "decision snapshot" (retenção + payload mínimo).** Sinal de campo: o
   adotante inflou o banco gravando o **pool inteiro de candidatos** por decisão, sem retenção. Veredito:
   **DIVIDIR** — impl é local (autorizado), e a **diretriz é lacuna real do framework** (a doutrina
   spec-as-code / rastreabilidade atômica nunca especificou retenção nem teto de payload). A diretriz
   nasceu como KB concept: [`concepts/decision-snapshot-retention.md`](../knowledge-base/concepts/decision-snapshot-retention.md)
   (3 regras: payload mínimo · retenção declarada · frio→arquiva; + fronteira diretriz×impl). Quadrante MET.
   **Resíduo:** v2 quando o adotante devolver um formato de "snapshot mínimo" que generalize (insumo de campo).

### 🔴 Gap de processo (reconfirmado em campo)

6. ✅ **ENTREGUE — Anúncio flow A vira passo de ritual.** Era gap de **processo**, não de capacidade
   (`inbound/` + relatório auto-emitido + you-have-mail já existiam, #116): a federação não *exercia* o
   anúncio ao shipar — dependia de o humano lembrar. **Fix:** comando produtor [`/meta:co-announce`](../../.claude/commands/meta/co-announce.md)
   (gera o `inbound/` pronto na staging `federation/outbox/<id>/` a partir de uma entrada do CHANGELOG,
   resolvendo `alvo:` via `members.yaml`) + ritual documentado no `CONTRIBUTING.md` (passo pós-merge,
   granularidade de **merge** — não release, pois o adotante vendoriza por commit). Human-in-the-loop
   preservado (core gera/endereça; maestro transporta). **Eixo corrigido pela diligência:** o lar do
   anúncio leve é o **doc-bridge** (`inbound/`), não o `/meta:federation-publish` (ledger de contratos,
   federação formal) como a redação original sugeria. **Dogfood pegou** o parsing de `alvo:` com anotação
   entre parênteses (`nenhum (informativo...)`) que o happy-path escondia. Move o blip #1 de `assess` → `trial`.
   **Resíduo:** transporte segue manual por design (regra um-escritor-por-repo) — automação cross-repo não existe.

## Dívida técnica transversal

- **`/meta:adopt --update` sem teste ponta-a-ponta automatizado.** O `kind=merge` cobre o *merge isolado*
  do `settings.json`; o fluxo completo do `adopt` roda dentro do Claude Code (não é CLI) → não há harness
  determinístico para o `--update` inteiro. Validação fica manual (repo descartável). Limite conhecido.

## Mapa de dependências

```
#100 (arquivar #2) ── independente, mecânico
#3-c (warm-up)     ── independente, trivial → fecha o sinal #3
#1 (branch config) ── DEPENDE de → lint do schema .onion-version (dívida)
RFC-0002           ── estratégico, sem dependência técnica; destrava o veredito do rhilo
```
