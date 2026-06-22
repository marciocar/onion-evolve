# 📤 Outbox — staging de anúncios flow A (core → adotante)

Staging **do core** para anúncios de fluxo A **aguardando transporte humano** ao `inbound/` de cada
adotante. Gerada por [`/meta:co-announce`](../../../../.claude/commands/meta/co-announce.md) a partir de
uma entrada do [`CHANGELOG.md`](../CHANGELOG.md).

## Por que existe

A sessão do core **nunca escreve/pusha no repo do adotante** (invariante "um escritor por repo"). E o
adotante é **cego** ao core — só vê o que é commitado no **próprio** `inbound/`. A outbox resolve a ponte:
o core rascunha aqui (no seu próprio repo), o **maestro** revisa e copia para o `inbound/` do adotante,
onde o hook "you have mail" o capta na próxima sessão dele.

## Estrutura

```
outbox/
├── <id-do-adotante>/        # um dir por adotante (id de members.yaml)
│   ├── <data>-<slug>.md     # rascunho a transportar
│   └── _processed/          # já transportado (git-visível "enviado")
└── README.md
```

## Fluxo

1. `/meta:co-announce [<data|slug>]` gera `outbox/<id>/<data>-<slug>.md` (com rodapé de transporte).
2. Maestro revisa e copia para `<repo-do-adotante>/docs/evolution/inbound/`, commitando **no repo do adotante**.
3. Maestro move o rascunho para `outbox/<id>/_processed/` (`git mv`) — marca "enviado".

> A **auditoria canônica** do que foi anunciado é o [`CHANGELOG.md`](../CHANGELOG.md) (append-only). A
> outbox é só **staging de transporte** — efêmera por design.
