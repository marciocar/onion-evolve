---
name: co-deliver
description: 'Carteiro-LOCAL do doc-bridge (downstream) — entrega um anúncio da staging do core (federation/outbox/<id>/) direto no inbound/ de um adotante que vive na MESMA máquina, para o hook "you have mail" sinalizar 📥 sem o maestro copiar à mão. ENTREGA-SEM-COMMIT (o core nunca commita no repo alheio — invariante I3); o commit + processamento é da sessão do adotante. É o "Carteiro-local mínimo" NÃO-gated do ADR onion-adr-ledger-format-location. Par producer = /meta:co-announce (gera o rascunho).'
category: meta
tags: [co-evolution, downstream, transport, carteiro, inbound, delivery, bridge]
version: "1.0.0"
updated: "2026-06-24"
allowed-tools: Read Bash(bash .claude/utils/co-evolution/co-deliver.sh*) Bash(ls docs/evolution/*) Bash(bash .claude/validation/onion-version.sh)
argument-hint: "<member-id> [<outbox-file>] --target <path-local-do-adotante> [--dry-run]"
---

# 📬 /meta:co-deliver — Carteiro-local (downstream, entrega doc-bridge)

Transporta um anúncio downstream do `federation/outbox/<id>/` (staging do core) para o `inbound/` de um
adotante **na mesma máquina** — automatizando o `cp` que o maestro fazia à mão. Materializa o **Carteiro-local
mínimo** liberado (NÃO-gated) pelo [ADR de formato/localização do ledger](../../../docs/knowledge-base/decisions/onion-adr-ledger-format-location-2026-06.md)
(Decisão 3).

> **O que este comando NÃO é.** Não gera o anúncio — isso é o [`/meta:co-announce`](co-announce.md) (producer,
> escreve no outbox). Este é o **carteiro**: pega o rascunho pronto e o **entrega**. E não é o transporte
> distribuído (CI broadcast / repo-neutro) — esse é **gated** pelo gatilho de graduação; o Carteiro-local
> resolve o caso 1-máquina **sem** esperar a Federação plena.

## Invariante (por que entrega SEM commit)

A sessão do core **nunca** commita/pusha no repo alheio (**I3 — um escritor por repo**). O carteiro escreve
o arquivo como **untracked** no `inbound/` do alvo. Funciona porque o hook `co-evolution-inbox-check.sh`
**conta arquivos do diretório** (não exige commit) — então o 📥 dispara na próxima sessão do adotante. O
**commit + processamento** (ler, mover blip no radar, `git mv` para `inbound/_processed/`) é da **sessão do
adotante**, com o contexto de lá. Untracked **persiste entre checkouts de branch** → a entrega é
branch-agnóstica (o canal tracked costuma viver em `develop`, mas o aviso dispara em qualquer branch do mesmo
worktree).

## Passo 1 — Guarda de papel (só CORE)

Detectar o papel **como em `/meta:co-evolve`**: ler o **stamp `.claude/.onion-version`** (campo `role:`)
primeiro; só se ausente, cair para `bash .claude/validation/onion-version.sh`. **Não** confie só no script —
ele hardcoda `role: source` (é a identidade da FONTE) e, vendorizado num adotante, mentiria 'source'.
- `role: source` (ou stamp ausente neste core) → **CORE** → segue.
- `role: adopted` → **CONSUMIDOR** → **parar**: adotante não entrega downstream (ele sinaliza upstream via
  `inbox/` + [`/meta:co-relay`](co-relay.md)).

## Passo 2 — Resolver alvo e rascunho(s)

`$ARGUMENTS` = `<member-id> [<outbox-file>] --target <path> [--dry-run]`.
- `<member-id>` deve existir em `members.yaml` com **role: hub ou standalone** (T1/T3, adotam o core direto — RFC-0003 §2.1; o helper valida). role=consumer (T2, via-hub) fica fora deste carteiro-local.
- `<outbox-file>` opcional: basename ou path de UM rascunho. Omitido = **todos** os `.md` de 1º nível de
  `outbox/<member-id>/` (cuidado: pode reentregar rascunhos antigos não-arquivados).
- `--target <path>` é o **path local do repo adotante** — obrigatório quando o `members.yaml` não traz um
  `path:` resolvível (caso de adotante standalone com remote, sem path local).

**Sempre rode com `--dry-run` primeiro** para conferir alvo + lista de arquivos antes de escrever.

## Passo 3 — Entregar

```bash
bash .claude/utils/co-evolution/co-deliver.sh <member-id> [<outbox-file>] --target <path> [--dry-run]
```

O helper: valida (member/role/outbox/alvo-git), avisa se o alvo não tem `docs/evolution/` na árvore
atual, e copia never-clobber (arquivo já presente no `inbound/` = no-op idempotente).

## Passo 4 — Marcar transportado + checkpoint do maestro

Após a entrega bem-sucedida, marque o rascunho como transportado **no core** (`git mv` para
`outbox/<id>/_processed/`) e commite no core (a auditoria de "o que foi anunciado" continua no
`CHANGELOG.md`; a outbox é só staging). **Não** assuma o lado do adotante — o maestro/adotante commita +
processa lá. Saída sugerida:

```
📬 Carteiro-local — entregue a <member-id> (<N> arquivo(s)) em <target>/docs/evolution/inbound/
   ◆ entrega-sem-commit (I3 respeitado) — o adotante commita + processa na sessão dele
   ▶ no core: git mv outbox/<id>/<arquivo> outbox/<id>/_processed/ (marcar transportado)
   ▶ no adotante: abrir sessão → 📥 you-have-mail → /meta:co-evolve
```

## ⚠️ Notas

- **Human-in-the-loop preservado:** entrega + notificação são automáticas (atos 1-2); commit/execução no
  repo alheio = **gate humano** (a sessão do adotante).
- **Untracked é entrega, não durabilidade.** O registro durável é o `outbox/` + `CHANGELOG` do core. Um
  `git clean -fd` no adotante apagaria o arquivo entregue **antes** de processado — por isso o adotante
  deve ler/processar logo (mover p/ `_processed/` torna durável lá).
- **Verbo solto em `meta/`**; não funde nem dispara workflows faseados.

## 🔗 Referências

- Producer do rascunho: [`/meta:co-announce`](co-announce.md)
- Orientação/gestão: [`/meta:co-evolve`](co-evolve.md) · Protocolo: [docs/evolution/README.md](../../../docs/evolution/README.md)
- Decisão que o libera (não-gated): [ADR ledger formato/localização](../../../docs/knowledge-base/decisions/onion-adr-ledger-format-location-2026-06.md)
- Hook: `.claude/hooks/co-evolution-inbox-check.sh` · Registro: [members.yaml](../../../docs/evolution/federation/members.yaml)
