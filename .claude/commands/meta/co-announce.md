---
name: co-announce
description: Gera um anúncio downstream pronto-para-transportar a partir de uma entrada do CHANGELOG de co-evolução, endereçado ao(s) adotante(s) do campo `alvo:` (resolvidos via members.yaml), escrevendo na staging do core (federation/outbox/<id>/). É o lado producer do doc-bridge leve (≠ /meta:federation-publish, que é o ledger de contratos). Human-in-the-loop — o maestro revisa e transporta para o inbound/ do adotante (a sessão do core nunca pusha repo alheio).
category: meta
tags: [co-evolution, downstream, announce, inbound, outbox, bridge, federation]
version: "1.1.0"
updated: "2026-07-18"
allowed-tools: Read Write Edit Grep Glob Bash(ls docs/evolution/*) Bash(git mv docs/evolution/*) Bash(bash .claude/validation/onion-version.sh) Bash(bash .claude/utils/co-evolution/reconcile-inputs.sh*) Bash(bash .claude/utils/co-evolution/resolve-target.sh*) Bash(git -C * log*)
argument-hint: "[--reconcile | <data-ou-slug-da-entrada>]  (sem arg = última entrada com alvo: ≠ nenhum · --reconcile = concilia todo o backlog)"
---

# 📣 /meta:co-announce — Anunciar mudança aos adotantes (downstream, doc-bridge)

Transforma uma entrada do `docs/evolution/federation/CHANGELOG.md` num **anúncio pronto-para-transportar**
no `inbound/` do adotante. Fecha o gap do backlog #6 (`onion-coevolution-backlog-2026-06-18`, core-only):
a capacidade de downstream existe, mas o anúncio **nunca era exercido** ao shipar — dependia de o humano lembrar.

> **O que este comando NÃO é.** Não é o relatório auto-emitido de `/meta:adopt --update` (esse é
> **adotante-puxa**, vem com o delta vendorizado). É o **core-empurra**: anuncia uma mudança/decisão
> relevante **sem esperar** o adotante rodar `--update`. E não é `/meta:federation-publish` (esse escreve
> no **ledger de contratos** — Federação formal; este é o **doc-bridge leve**, canal `inbound/`).

> **Invariante (um escritor por repo).** A sessão do core **nunca** escreve/pusha no repo do adotante.
> Este comando só escreve na **staging do core** (`federation/outbox/<id>/`). O **maestro** é o transporte:
> revisa e copia para o `inbound/` do adotante. O hook "you have mail" do adotante o capta na sessão dele.

## Modo `--reconcile` — conciliar TODO o backlog (não só o topo)

> **O gap que fecha.** O fluxo padrão (abaixo) pesca **uma** entrada — a do argumento, ou a mais recente.
> Uma entrada `alvo: todos` cujo anúncio **nunca foi** (ou foi só **parcialmente**) transportado fica
> **aberta e invisível** — a conciliação dependia de memória humana. `--reconcile` cruza o CHANGELOG
> inteiro contra a outbox e revela o **open-set**. (Nascido do dogfood 2026-07-18: a conciliação de
> backlog foi feita à mão; este modo a torna repetível — irmão do que `--only`/`co-relay` fizeram.)

Se `$ARGUMENTS` começa com `--reconcile`, siga **esta** seção (não os Passos 1-5 padrão):

1. **Guarda de papel** — idêntica ao Passo 1 (só CORE; adotante → parar).
2. **`git fetch`** (o main pode ter avançado — entradas novas surgem de outras sessões).
3. **Levantar os insumos determinísticos** (não reimplemente à mão):
   `bash .claude/utils/co-evolution/reconcile-inputs.sh` — emite duas seções TSV:
   - `[ENTRIES]`: `<date>\t<recipients-csv>\t<alvo>\t<subject>` — toda entrada com `alvo:` acionável
     (nenhum/futuros já omitidos), com os destinatários **já resolvidos** (via `resolve-target.sh`).
   - `[OUTBOX]`: `<id>\t<staging|processed>\t<filename>` — o inventário de anúncios já produzidos.
4. **Cruzar (juízo — é a parte que o script NÃO decide):** para cada `entry × recipient`, decidir a
   cobertura casando um arquivo da outbox à entrada. Heurística de match: **mesma data** + o slug do
   arquivo compartilha um **token distintivo** do assunto (ex.: `a2a-live`, `marketplace`, `kg`,
   `rfc5`, `worktree`, `assinatura`). Estados:
   - **`processed`** casando → **coberto e transportado** (fechado).
   - **`staging`** casando → **gerado, mas NÃO transportado** (semi-aberto — falta o transporte).
   - **nada** casando → **ABERTO** (nunca anunciado a esse destinatário).
5. **Aplicar as guardas** (senão a conciliação vira ruído):
   - **Superseded:** entrada que uma posterior declara substituir (`substitui`/`supersedes`) → **descartar**
     (anunciar a substituída seria contraditório).
   - **Pós-adoção (`declarado≠verificado`):** destinatário cuja adoção/último `--update` é **posterior**
     à entrada já tem a mudança vendorizada → marcar `⊘ pós-adoção`, **não** aberto. Verificar pelo
     `inbound/_processed` do adotante (se montado) ou pelo pin; **sem verificação em 1ª mão, dizer isso**
     (não afirmar cobertura que não confirmou).
   - **Ambíguo:** match incerto (data bate, token não) → **listar como candidato**, nunca decidir em
     silêncio (a heurística de data+token é grosseira por construção — o juízo é seu, não do script).
6. **Responder-gated (W6): propor, não executar.** Apresentar a **tabela de conciliação** (entrada ×
   destinatário × estado) destacando os **ABERTOS** e os **semi-abertos (staging)**, e **parar**. Só após
   o maestro confirmar: para cada gap ABERTO, gerar o rascunho reusando o **Passo 4** (mesmo envelope);
   os semi-abertos (staging) não precisam de novo rascunho — precisam de **transporte** (orientar o maestro).

Saída do `--reconcile` (exemplo):
```
🔎 conciliação de backlog — N entradas com alvo: acionável × M adotantes
   ABERTO (nunca anunciado):   <date> · <assunto> → <id>, <id>
   STAGING (falta transporte): <date> · <assunto> → <id>
   ⊘ pós-adoção / superseded:  <date> · <assunto> (motivo)
   ▶ propor gerar rascunho p/ os ABERTOS? (Passo 4) — os STAGING é só transportar.
```

## Passo 1 — Guarda de papel (só CORE)

Detectar o papel (igual a `/meta:co-evolve`): ler o **stamp `.claude/.onion-version`** (campo `role:`)
primeiro; só se ausente, cair para `bash .claude/validation/onion-version.sh`. **Não** confie só no script —
ele hardcoda `role: source` (identidade da FONTE) e, vendorizado num adotante, mentiria 'source'.
- `role: source` (ou stamp ausente neste core) → **CORE** → segue.
- `role: adopted` → **CONSUMIDOR** → **parar**: adotante não anuncia (ele sinaliza upstream via `inbox/` +
  [`/meta:co-relay`](co-relay.md)). Orientar a usar `/meta:co-evolve`.

## Passo 2 — Selecionar a entrada do CHANGELOG

`git fetch` antes (outra instância pode ter mexido — lição stale-branch). Então:
- Com `$ARGUMENTS` (data `AAAA-MM-DD` ou slug do assunto) → localizar a entrada `## <data> · <assunto> · …`
  correspondente no `docs/evolution/federation/CHANGELOG.md`.
- Sem argumento → pegar a **entrada mais recente** cujo `alvo:` **não** seja `nenhum`.
- Extrair o **bloco** da entrada (do seu `## ` até o próximo `## ` ou fim do arquivo) e o cabeçalho
  (assunto · `COMPATÍVEL`/`BREAKING` · `alvo:`).

## Passo 3 — Resolver os destinatários (`alvo:` → members.yaml)

Ler o campo `alvo:` do cabeçalho da entrada e resolver contra `docs/evolution/federation/members.yaml`.

> ⚠️ **Normalizar primeiro:** o `alvo:` real costuma ter uma **anotação entre parênteses** (ex.:
> `alvo: um adotante multi-linhagem (informativo p/ demais)`, `alvo: nenhum (informativo, sem ação)`). Parsear o(s)
> **token(s) antes do primeiro `(`** e descartar a anotação. Não casar a string inteira.

- `nenhum` → **parar**: entrada informativa, sem destinatário. Nada a anunciar.
- `futuros adotantes` → **parar**: aplica-se a adoções futuras (chega via `/meta:adopt`), não a um adotante atual.
- `adotantes` / `todos` → **todos** os `role: hub` ou `role: standalone` do `members.yaml` (T1/T3, adotam o core direto — RFC-0003 §2.1).
- `<id>` (ex.: `um adotante multi-linhagem`) → esse membro (role `hub` ou `standalone`).
- **Seletor fino (F1.2 — mata o ruído):** `<key>:<value>[,<key>:<value>]` (AND) sobre atributos do
  `members.yaml` — `key ∈ {mode|tier|specialization}`. Ex.: `alvo: mode:regulated` (só regulados),
  `alvo: specialization:nx-monorepo`, `alvo: mode:regulated,tier:standalone`. Assim um anúncio só chega a
  **quem tem contexto p/ agir** — um fix de `presentation-orchestrator` não vira ruído p/ um adotante fintech.

> **Resolução determinística:** delegue a `bash .claude/utils/co-evolution/resolve-target.sh "<alvo>"`
> (reusa `graph.sh --triples` que ingere o `members.yaml` — F1.1). Retorna os IDs que casam (um por linha;
> vazio = ninguém). `nenhum`/`futuros` → vazio; `todos`/`adotantes` e `<id>` → retrocompat; `key:value` → seletor.
> Chave desconhecida → exit 3; id inexistente → aviso. Não reimplemente o parsing à mão.

Para cada `id` resolvido, ler do `members.yaml`: `name`, `remote` (e `path` se montado localmente).
Ignorar as linhas de **template comentado** (`#  - id: <slug-do-projeto>`). Se o `id` do `alvo:` não
existir no `members.yaml` → **avisar** (registro ausente) e seguir só com os que resolvem.

## Passo 4 — Escrever o rascunho na staging (outbox do core)

Para cada destinatário, escrever `docs/evolution/federation/outbox/<id>/<data-da-entrada>-<slug>.md`
(`mkdir -p` do dir + `_processed/`). Envelope **simétrico** ao `inbound/` que o adotante já entende
(ver `/meta:adopt` § Procedimento de Relatório Downstream):

```markdown
---
title: '<assunto da entrada>'
date: <data da entrada>
from: onion-evolve (core / maestro principal)
to: <id> (<name> — consumidor)
re: CHANGELOG de co-evolução, entrada <data> (downstream)
type: downstream-announce
classe: <COMPATÍVEL | BREAKING>
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — <assunto>

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

<corpo da entrada do CHANGELOG, colado verbatim — já é o conteúdo do anúncio>

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Se a classe for **BREAKING** ou pedir update: rodar `/meta:adopt --update` no momento oportuno.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/<id>/<arquivo> <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
```

## Passo 5 — Checkpoint do maestro + saída

Apresentar o que foi gerado e **não** assumir o transporte. Saída:

```
📣 anúncio gerado (downstream) — entrada <data> · <assunto> [<COMPATÍVEL|BREAKING>]
   ◆ destinatários (de members.yaml): <id>, <id>
   ◆ rascunhos na staging:
       docs/evolution/federation/outbox/<id>/<arquivo>.md
   ▶ próximo (maestro): revisar e transportar para o inbound/ de cada adotante (comando no rodapé de cada rascunho)
```
ou, sem destinatário:
```
ℹ️ nada a anunciar: entrada <data> tem alvo: <nenhum|futuros adotantes> (sem adotante atual endereçado).
```

> **Lido/transportado git-visível:** depois que o maestro transportar, mover o rascunho para
> `outbox/_processed/` (`git mv`). O CHANGELOG continua sendo a auditoria canônica do que foi anunciado;
> a outbox é só staging de transporte.

## ⚠️ Notas

- **Human-in-the-loop:** gera e endereça; **não** transporta nem pusha repo alheio. O maestro decide e copia.
- **Doc-bridge leve, não ledger:** para anúncio de contrato formal (com bump semver validado), use
  `/meta:federation-publish`. Este comando é o produtor do canal `inbound/` (sinal/decisão/delta sem contrato).
- **Verbo solto em `meta/`**; não funde nem dispara workflows faseados.

## 🔗 Referências

- Consumidor/orientação: [`/meta:co-evolve`](co-evolve.md) (lê inbox/inbound, gerencia)
- Envelope irmão: [`/meta:adopt`](adopt.md) § Procedimento de Relatório Downstream
- Protocolo dos 3 fluxos: [docs/evolution/README.md](../../../docs/evolution/README.md)
- Registro de adotantes: [members.yaml](../../../docs/evolution/federation/members.yaml) · Anúncios: [CHANGELOG.md](../../../docs/evolution/federation/CHANGELOG.md)
- Ledger de contratos (federação formal): [`/meta:federation-publish`](federation-publish.md)
- Origem: backlog de co-evolução item #6 (`onion-coevolution-backlog-2026-06-18`, core-only)
