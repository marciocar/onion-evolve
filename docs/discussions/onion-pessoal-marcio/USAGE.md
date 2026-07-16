# 🧅 Como usar o Onion pessoal no dia a dia — USANDO Dogfood KG-SSOT SDAAL

> Nota **pé-no-chão**: o baseline de uso, **hoje**. A interface rica (telemetria, captura automática) é
> pesquisa *gated* (`interface-state-of-art` + `behavior-mapping-kg`). Aqui é o que **já funciona** — e é o
> que responde "como eu uso isso no meu notebook?".

## A ideia em uma frase

Usar o Onion pessoal = **abrir uma sessão Claude Code no repo e conversar** — exatamente como você conversa com
o Onion do framework. A diferença é o **repo**: sua **vida** em `~/onion-pessoal`; o **framework** em `~/onion-evolve`.

## O gesto básico

```bash
cd ~/onion-pessoal && claude
```

Aí você fala, em texto solto: *"adiciona à vertical Trabalho: declarei X, mas faço Y, atrito Z"*. A sessão:

1. **estrutura** no `.kg.yaml` — o declarado vira camada `DEV`, o vivido vira `PROD`;
2. procura **contradição** (`REFUTES`) e **reconciliação** (`SUPERSEDES` = Aufhebung: nega + conserva, o nó não some);
3. roda o `kg-radar` e devolve o **veredito honesto**: *achou atrito real e acionável, ou grafo bonito e vazio?*

## Ver o estado sem abrir sessão (a lente)

```bash
bash ~/onion-evolve/.claude/validation/kg-radar.sh ~/onion-pessoal/marcio-trabalho-f0.kg.yaml
```

Mostra **ATENÇÃO** (o que pesa) · **RECONCILIAÇÃO** (os `REFUTES`/`SUPERSEDES`) · **INTEGRIDADE**. `exit 1`
com um `REFUTES` restante é **honesto** (uma tensão viva não fechada de propósito), não um erro.

## Dois repos, dois assuntos — a mesma conversa

| Comando | Assunto | Natureza |
|---|---|---|
| `cd ~/onion-pessoal && claude` | sua **vida** (KG pessoal) | privado, soberano |
| `cd ~/onion-evolve && claude` | o **framework** (o Onion em si) | público |

Mesma conversa de sempre — **repo diferente = assunto diferente**.

## O que é o KG SDAAL aqui (o dogfood)

Cada vertical da sua vida (Trabalho · Relações · Saúde · Sentido) vira um **grafo de domínio** (`.kg.yaml`):
entidades/estados/eventos/regras, com a camada **audit** (claim/evidence/decision) confrontando o que você
**DECLARA** (DEV) × o que você **VIVE** (PROD). O `kg-radar` é o espelho determinístico. **Usar o Onion pessoal
é, literalmente, dogfoodar o KG-SSOT SDAAL na sua própria vida** — o método que reconcilia negócio/técnica/
compliance de uma org, aplicado a um indivíduo N=1.

## O que NÃO existe ainda (honestidade — hoje é F0, Wizard-of-Oz)

- **App / superfície dedicada** → *gated* (`onion-mobile-app`, `interface-state-of-art`).
- **Captura automática do comportamento** (o *sensor*) → *gated* (`behavior-mapping-kg`).
- Hoje é **100% conversacional e manual**: você traz o dump cru, a sessão estrutura. É **validação (F0)**, não
  produto (**F0 ≠ onboarding** — desenhar onboarding a partir do N=1 do criador re-dispararia o caveat intra-órbita).

## Privacidade (a P4 no passo um)

O KG bruto vive no repo **privado** `~/onion-pessoal` — **nunca** commitado no `onion-evolve` público. `private`
por design; só destilado sairia, gated. *(Caveat consciente registrado: GitHub-privado satisfaz "privado" mas
≠ local-first estrito — troca durabilidade/backup × local-puro.)*

## Ligações

Doutrina completa (P1–P5): [`README.md`](README.md). Repo do dado real: `~/onion-pessoal` (privado, soberano).
