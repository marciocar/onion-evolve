---
description: Forja as peças que o comando novo pede (das 7 do conjunto), medindo antes o que já existe. Core-only.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, TodoWrite
---

# 🔨 /meta:forge — forjar um comando-com-framework

Forja as peças de um comando-com-framework — o conjunto de 7 é a régua, e esta versão **gera três
delas** (2, 3 e 7), **especifica** duas (5 e 6) e deixa duas de fora (1 e 4, que têm molde próprio).
A distinção importa e a 2ª passada adversarial a cobrou: *exigir* uma peça e *gerar* a peça são
coisas diferentes. A doutrina inteira (as 7 peças, as 4 cláusulas, o que ela não promete) vive em
[`common:prompts:forge-doctrine`](../common/prompts/forge-doctrine.md); **referencie, não copie**.

O nome é cunhagem do maestro (2026-09-28), porque a composição inteira não tem nome de mercado
confirmado — achado ancorado em `docs/evolution/research/agent-command-composition-2026-09/`.

## Degrau e limites

- **Core-only** (Camada 1 = autoria do framework). A face que viaja é **gated**: gatilho nomeado na
  cláusula 4 da doutrina.
- **Maestro-invocado.** Não auto-inicia.
- **Entrevista, não assume.** A topologia do comando novo é perguntada; só a peça 5 é invariante.
  Assumir é petrificar a forma da 1ª instância — a objeção `N=1`, que sobreviveu a refutação real.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

```bash
# FORGE_CENSUS_TOP alto DE PROPOSITO: a peca 3 existe para dar o CONJUNTO medido, e o default 12
# da projecao cortava 47 de 59 — era o caminho de producao do dano que o PR #909 curou. A licao
# tinha ido para a migalha e NAO para ca, e um aviso em prosa pedindo que a sessao rode `--tsv`
# e exatamente o "leitor nao e mecanismo" que esta casa persegue (achado do Elenxo, 2026-10-03).
FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown
```

Rode-o **primeiro**, sempre. Ele responde por medição o que o modelo responderia de memória: quais
comandos-com-framework já existem e **quais peças cada um cita**. A saída é a régua do que falta.

⚠️ **Leia o censo como ele se declara**: ele mede **presença e REFERÊNCIA**, nunca qualidade. Peça
que existe mas o artefato não cita conta como ausente — de propósito, porque a sessão que lê a
superfície também não a acharia. Na primeira medição (2026-09-28) a própria instância de referência
tinha lente e bancada e **não citava nenhuma das duas**.

## Procedimento

1. **MEDIR** — rode o censo acima. Sem ele, o resto é palpite. Se ele sair `3`, ele está declarando
   que **não pôde medir** (sem índice git, ou zero candidatos rastreados): conserte o ambiente, nunca
   siga com censo vazio.
2. **ENTREVISTAR a topologia** — qual o gênero do comando (varredura? decisão? auditoria? migração?),
   quais fases, qual o KIND do que se produz, qual a cadência de revisita. As respostas decidem a FORMA das peças
   2, 3, 6 e 7; e a **peça 5 é exigida de todo comando-com-framework** — o que esta versão da forja
   não faz é GERÁ-LA por você.
3. **EMITIR**, na ordem em que uma peça habilita a seguinte:
   - **2 doutrina** → `.claude/commands/common/prompts/<n>-doctrine.md`, com as cláusulas e o que ela
     NÃO promete (fronteira declarada é parte da doutrina, não apêndice);
   - **3 contexto injetado** → um **medidor determinístico** + o bloco que o invoca na superfície.
     O medidor **descobre por referência**; construir o nome da peça a partir do nome do candidato
     é a classe proibida pela cláusula 1, com três ocorrências medidas;
   - **7 bancada** → família `run_<n>_selftests`, e **todo caso tem de reprovar contra a versão
     defeituosa**. Caso que passa nos dois é decorativo;
   - **5 destino** (ESPECIFICAR, não gerar nesta versão) → a fase final, com `write(KG)` + radar exit 0 **e o contrato de custo**
     (`run_id` · `tokens` · `agents` · `duration_min`). A cláusula 2 da doutrina mede que o destino
     replica bem nesta casa e o **contrato** não (4,8% dos runs) — logo é o contrato que a forja
     precisa emitir, não o `kg-radar`;
   - **6 lente** (ESPECIFICAR, não gerar nesta versão) → `.claude/rules/<n>-lens.md`, e **a guarda dela JÁ EXISTE**: a REGRA 53 (Regra
     path-scoped declara `paths:` que casa algo real), HARD. Não crie regra nova sem antes medir —
     foi exatamente o erro de 2026-09-28, documentado na cláusula 3 da doutrina.
4. **LIGAR** — a superfície nova cita **todas** as suas peças por caminho. Se o censo não subir depois
   de emitir, a peça foi escrita e não foi ligada, e o censo está certo em não contá-la.
5. **DOGFOOD** — rode o artefato de verdade, e o **modo-de-falha** também. `bash -n` e lint verde não
   são dogfood: são pré-condição.
6. **GATE** — `lint-artifacts.sh` 0 HARD · a família nova verde · e o **mutante** de cada caso
   provado. Resíduo da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) no PR.

## O que este comando NÃO faz

- Não emite as peças 1 e 4 do zero — elas têm molde claro (`/meta:create-command`, o molde de fases
  do `onion-orchestration`) e a decisão de 2026-09-28 as deixou fora desta onda.
- **Nesta primeira versão, emite as peças 2, 3 e 7**; as peças 5 e 6 estão especificadas no passo 3
  (com a guarda e o contrato que cada uma exige) mas a emissão automática delas é GATED. Gatilho: a
  2ª instância de comando-com-framework pedir uma das duas — aí a forma delas se deriva de dois
  casos em vez de um, que é a objeção `N=1`.
- Não julga qualidade. O censo mede presença e ligação; `bom` é sua chamada.
- Não escreve em repo alheio, não faz deploy, não agenda (MOAT).

## 🔗 Referências

- Doutrina (fragmento canônico): [`common:prompts:forge-doctrine`](../common/prompts/forge-doctrine.md)
- Medidor da peça 3: `.claude/validation/forge-census.sh` · bancada: `run_forge_selftests`
- Guarda da peça 6: REGRA 53 (Regra path-scoped declara `paths:` que casa algo real), em `lint-artifacts.sh`
- Instância de referência: [`/onion-research`](../../skills/onion-research/SKILL.md) · grafo da
  decisão (core-only): `docs/onion/graph/forge-comando-framework-2026-09.kg.yaml`
