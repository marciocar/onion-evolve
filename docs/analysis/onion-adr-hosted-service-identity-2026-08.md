---
title: 'ADR — O Onion como framework + SERVIÇO HOSPEDADO: medir para limitar, não para cobrar por unidade'
date: 2026-08-01
type: adr
status: accepted (identidade + medição) — COBRANÇA por unidade explicitamente NÃO adotada
decision-scope: identity / commercial model / metering (toca a SSOT de identidade e a escada D5)
supersedes: none
extends: docs/knowledge-base/meta/onion-framework-identity.md (SSOT de posicionamento — este ADR estende, não recopia)
origin-signal: >
  Maestro, 2026-08-01, em momento declarado de CONSOLIDAÇÃO do Onion Evolve: "precisamos saber dos custos e
  eficiência da IA de cada participante", "vamos precisar de um lugar para gerenciar a federação e para que os
  federados gerenciem seus recursos", "além do custo de IA temos que pensar como vamos cobrar por recursos como
  armazenamento, número de arquivos, usuários e até o uso de ferramentas do core da VPS". Mais: "os federados
  ainda não usam o Logto, eles serão migrados, e deve ser o padrão (ainda não exclusivo) de novos adotantes".
deciders: maestro
related:
  - docs/onion/graph/d5-pricing-2026-07.kg.yaml (escada de preço ratificada 2026-07-29; a diretriz premium-sobre-pipoca)
  - docs/business-context/02-product/metrics.md (o KPI "valor medido por adotante" = `[a instrumentar]`, o pivô)
  - docs/onion/graph/m2-bridge-logto-2026-07.kg.yaml (Logto vivo; members.yaml = SSOT, Logto = projeção)
  - docs/evolution/research/stack-harmonia-2026-08/ (a REGRA DOS 5 PORTÕES e o anti-catálogo)
---

# ADR — O Onion como framework + serviço hospedado

## Contexto

A identidade canônica (2026-05-18, `onion-framework-identity.md`) afirma: *"framework template em `.claude/` que
instala num repositório o ciclo completo… **não é produto npm, não é distribuído publicamente, não tem CLI
standalone**"*. Essa frase descreve **como o framework é entregue** — e nunca precisou dizer nada sobre **serviços
hospedados**, porque não havia nenhum.

Hoje há. A VPS do core opera Logto (identidade), o bridge (Agent SDK, com **BYOK e workspace isolado por token já
no código**), Caddy, e um canal de email verificado. Os federados **serão migrados para o Logto**, que passa a ser
o **padrão — não exclusivo** — de novos adotantes. Ou seja: o core deixou de ser só um template que se copia e
passou a **atender** outros no runtime.

Isso é uma mudança de identidade. No Onion, identidade muda por **decisão declarada, não por deriva** — daí este ADR.

## Decisão

### 1. O Onion é framework **E** serviço hospedado — duas naturezas, uma identidade

O framework template continua sendo o produto principal e **não muda**: instala em `.claude/`, não é npm, não tem
CLI standalone. O que se acrescenta é uma **segunda natureza**: o core **hospeda recursos** que membros da
federação consomem (identidade, ponte de agente, canais de saída).

**Invariante que separa as duas:** o framework é **copiado** (vendorizado, soberano no repo do adotante); o serviço
é **consumido** (roda na VPS do core). Um adotante pode usar o framework **sem nunca tocar** o serviço — e essa
continua sendo a configuração default. O serviço é **acréscimo opcional**, jamais pré-requisito.

### 2. Medir para **LIMITAR**, não para cobrar por unidade

A diretriz D5 ratificada (2026-07-29) crava *"ticket premium ($129+) > pipoca ($5-10)"* e *"vender selo/curadoria,
não o texto"*. Cobrança por unidade de armazenamento/arquivo/usuário é **estruturalmente o modelo pipoca** — e
contradiria uma decisão de 3 dias atrás.

**Decisão:** a medição existe para **dimensionar tier, aplicar cota e evitar subsídio cruzado** — *"seu plano inclui
X"* — **não** para faturar por unidade (*"R$/GB"*). Se um dia a cobrança por unidade for desejada, é **outro ADR**,
e ele terá de reconciliar com a diretriz D5 explicitamente.

**Corolário:** a medição **não** é bloqueada por essa decisão — ela é **pré-requisito de ambos os caminhos**, e já
está autorizada (`metrics.md:14,21`: *"é o número que vira prova de venda e base de preço"*; D5: *"INSTRUMENTAÇÃO
autorizada"*). Instrumentar **não** é pré-cozinhar cobrança.

### 3. **"Medido ≠ cobrável"** — a medição nasce auditável

Primo do `aceite ≠ entrega` (que custou 3 mensagens fantasma nesta mesma sessão). Medição para **observabilidade**
tolera aproximação; medição que sustenta **cota ou fatura** é **registro**, e um adotante dizendo *"seu número está
errado"* é conversa de outra natureza.

**Decisão:** o medidor nasce **append-only, com carimbo de tempo e reconciliável**, mesmo enquanto serve só a
observabilidade. Reformar medidor depois que ele virou base de cota é caro; nascer auditável é barato.

### 4. A unidade de conta é a **Organization do Logto**, projetada de `members.yaml`

O `members.yaml` permanece **SSOT**; o Logto é **projeção** (`logto-provision.sh`, invariante já estabelecida em
`m2-bridge-logto`). A Organization é a fronteira natural de tenant, e **já existe o gerador**.

**Decisão:** toda linha de medição referencia `org` (tenant) **e** `sub` (ator humano/serviço). Isso dá as duas
agregações que importam — por membro (cota/tier) e por pessoa (eficiência) — sem uma segunda estrutura.

### 5. Escopo do dado medido: **só metadado numérico**

**Nunca** prompt, completion, conteúdo de arquivo ou payload. Esta é a mesma lição, agora mecanizada, do incidente
desta sessão em que assinar o evento `message` (para medir `ack`) fez mensagem pessoal trafegar por um receptor.

**Decisão:** o esquema da linha é fechado — `ts · org · sub · recurso · quantidade · unidade` (+ `modelo` quando
IA). Acrescentar campo de **conteúdo** exige ADR.

### 6. O "lugar para gerenciar" **não é decidido aqui** — e o gatilho mudou

A plataforma de administração foi formalmente **refutada** (`m3-federation-admin`, `status: refuted`) sob um
gatilho **técnico** (0 membros T2, `contracts/` inexistente, operador único). O maestro traz agora um gatilho
**de negócio** (consolidação + serviço + cota), que é de outra natureza.

**Decisão:** a refutação **não é ressuscitada nem reafirmada** — ela é **re-derivada fresca** quando o gate abrir
(`gated-work-derives-fresh`: trabalho gated não se pré-cozinha). **O gate desta vez é factual e barato de checar:**
*existe ao menos 1 federado migrado para o Logto consumindo recurso hospedado?* Hoje há **1 usuário** no Logto, e é
o maestro. Enquanto for 1, não há multi-tenant a administrar — há um operador com `psql` e `git`.

**E há uma ordem que a evidência impõe:** medição **antes** de painel. Não se administra o que não se mede, e o
painel sem dado é a "visão agregada" que o F0 proibiu pré-autorizar.

## O que este ADR NÃO é

- **Não** autoriza cobrança por unidade (explicitamente adiada; ver Decisão 2).
- **Não** ressuscita a plataforma de administração (ver Decisão 6).
- **Não** torna o serviço hospedado pré-requisito do framework (Decisão 1) — adoção soberana sem tocar a VPS
  continua sendo o default.
- **Não** altera a escada D5 nem seus números (ratificados 2026-07-29) — apenas nomeia a tensão pipoca-vs-premium
  e a resolve pelo lado do limite.
- **Não** promove nenhuma doutrina a KB a partir da síntese F2 (que foi **reprovada** pelo crítico; ver
  `stack-harmonia-2026-08`).

## Invariantes

- **Framework copiado × serviço consumido** — o adotante pode usar tudo do framework sem tocar a VPS.
- **`members.yaml` é SSOT; Logto é projeção** — nunca o inverso.
- **Medição é append-only e só carrega metadado numérico** — conteúdo exige novo ADR.
- **Medir ≠ cobrar ≠ limitar** — três decisões distintas; este ADR autoriza a primeira, escolhe a terceira como
  destino e adia a segunda.
- **A REGRA DOS 5 PORTÕES governa qualquer peça nova** que este caminho sugerir (pull datado · não-reuso provado ·
  dado novo · o volume força · dono nomeado).

## Materialização (gated, por etapa)

| Etapa | Gatilho nomeado | Estado |
|---|---|---|
| **Medidor de IA** (linha append-only por chamada no bridge) | nenhum — **autorizado**; o dado não existe hoje em lugar nenhum (portão 3) | **liberado** |
| Medidor de storage/arquivos/usuários | 1º recurso hospedado de terceiro efetivamente consumido | gated |
| Cota/limite por tier | 1º consumo que ameace subsídio cruzado (medido, não estimado) | gated |
| Painel/administração da federação | ≥1 federado migrado ao Logto consumindo recurso hospedado (hoje: 0) | gated |
| Cobrança por unidade | **outro ADR** — precisa reconciliar com a diretriz D5 | não adotado |

## Nota de honestidade

Este ADR nasce de uma **direção declarada pelo maestro**, não de demanda de adotante exercida — e isso está
registrado de propósito. A parte **liberada** (medir IA) se sustenta sozinha pelos 5 portões, independentemente do
destino comercial. As demais permanecem **gated com gatilho factual e barato de verificar**, exatamente para que a
consolidação não vire acúmulo: *consolidar é tornar coerente o que existe, não somar peças*.
