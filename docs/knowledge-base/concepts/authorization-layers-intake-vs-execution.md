---
title: "Camadas de liberação — a linha entre intake (autônomo) e execução (gated)"
category: concepts
tags: [seguranca, gate, a2a, co-evolucao, trust, fail-safe, intake, execucao, autorizacao]
status: candidato
date: 2026-07-11
---

# Camadas de liberação — intake (autônomo) × execução (gated)

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Toda ingestão de sinal/mensagem de um contato (a2a, co-evolução, MCP, adoção) |
| **Origem** | Pergunta do maestro (2026-07-11) + dogfood do handshake a2a no mesmo dia |
| **Consolida** | RFC-0004 §4 · `a2a-verify.sh` · `entrega-sem-commit` (I3) · `apply_mode:propose-only` · roadmap de federação §gate |

> **Por que este estudo existe.** A doutrina de "quando um sinal externo pode virar ação" estava **espalhada**
> por RFC, headers de script, invariantes e pesquisa — nunca **nomeada como um modelo**. Este KB consolida as
> camadas e crava a **linha** que o maestro articulou: *ler, analisar e **guardar** uma mensagem de um contato
> permitido é intake — pode ser autônomo. **Executar** (aplicar, ter efeito de saída) é que exige o gate.*

## 1. A tese (a linha)

Nem toda operação sobre um sinal externo é igual. Há uma **fronteira**:

> **INTAKE** (receber · verificar · guardar) — de um contato **permitido**, é **seguro e autônomo**.
> **EXECUÇÃO** (aceitar · aplicar · efeito de saída) — exige **gate humano**.

O erro clássico é gatear no lugar errado: ou **paranoia** (pedir permissão pra *ler/guardar*, o que trava o
fluxo sem ganho de segurança) ou **negligência** (deixar um sinal virar ação *sem* gate — o antipadrão
"IA-fala-IA autônoma"). A linha resolve os dois: **guardar é livre; agir é gated.**

## 2. As camadas (mapeadas ao vivo — dogfood a2a 2026-07-11)

Um handshake a2a real (um adotante → core) expôs a escada inteira:

| # | Camada | Pergunta | Falha → | Evidência (dogfood 11/07) |
|---|---|---|---|---|
| **0** | **Transporte/acesso** | tem token/credencial pra *chegar* no endpoint? | 401, nem entra | POST vivo → `401: requer token a2a dedicado` |
| **1** | parse | envelope é bem-formado? | veto malformed | — |
| **2** | **trust** | o remetente é **contato permitido**? (`members.yaml` policy-as-data) | veto trust-denied | trust `um adotante→core` OK |
| **3** | replay | `jti` já visto? | veto replay | — |
| **4** | timestamp | relógio confiável + dentro da janela? | veto clock-untrusted/expired | `expired` vetado em teste |
| **5** | SSRF | URL de webhook é segura? | veto ssrf | loopback/metadata negados |
| **6** | **JWS** | assinatura RS256 do `kid` **pinado** confere? | veto bad-signature/unknown-kid | credencial real → `verified:true` |
| **—** | **guarda gated** | — | — | **🟢 A LINHA** · `input_required` · `committed:false` |
| **7** | **accept** | um **humano** promove pra triagem? | fica na fila | `a2a-accept.sh` (não rodado) |
| **8** | apply | agir (regulado = `propose-only`) | — | 🔴 execução |

**Tudo até a guarda gated (0-6) é INTAKE** — determinístico, sem efeito de saída, `committed:false`. **A partir
do accept (7-8) é EXECUÇÃO** — precisa do gate humano. O sinal *verificado* fica **guardado** (`input_required`)
esperando a decisão — que é exatamente "guardar mensagem de contato permitido não é problema".

## 3. A filosofia fail-safe — veto, nunca skip

Um **gate de segurança degrada para VETO, nunca para SKIP** (RFC-0004 §4: *"sem output válido = veto; ausência
nunca é aprovação"*). É o oposto dos **geradores de artefato**, que degradam gracioso (skip: "não gerou, sem
dano"). Skip num gate = *fail-open*, o antipadrão. Toda camada não-avaliável (ferramenta ausente, relógio não
confiável, SSOT faltando) → **veto**, não passa adiante. A ingestão remota é **supply-chain não-confiável até
verificada** (corroborado pela onda de MCP tool-poisoning de 2025 — ~5,5% dos servidores com poisoning, ~2.000
sem auth).

## 4. Não é só a2a — é padrão transversal do Onion

A mesma linha intake↔execução aparece em **todos** os canais de ingestão:

| Canal | Intake (autônomo) | A linha | Execução (gated) |
|---|---|---|---|
| **a2a-live** | verify (0-6) | `input_required` | `a2a-accept` → apply |
| **co-evolução (doc-bridge)** | `co-deliver` escreve **untracked** no `inbound/` (I3) | arquivo untracked | a sessão do adotante lê, **commita**, processa |
| **adoção (`/meta:adopt`)** | detecta + propõe merge (never-clobber) | conflito git | o maestro resolve + commita |
| **escopo (RFC-0005)** | compõe camadas em runtime (leitura) | — | promover a SSOT (gated + confirmed) |

O invariante compartilhado é **`entrega-sem-commit` (I3)**: o produtor **nunca** commita no destino — entrega,
e o **dono** do destino decide. Guardar ≠ aceitar ≠ aplicar.

## 5. O que isto prescreve (para agentes E humanos)

**Um agente PODE, sozinho** (intake, de fonte permitida): receber, verificar, parsear, **guardar** (untracked/
input_required/staging), analisar, resumir, propor. Nada disso tem efeito de saída irreversível.

**Um agente DEVE gatear** (execução): aceitar (`accept`), **commitar no repo de outro**, aplicar mudança,
enviar pra fora (publicar, transportar), emitir credencial/token, qualquer efeito outward. Aqui vale
"ausência de permissão = veto".

> Corolário para o operador: se você se pegou pedindo permissão pra *ler/guardar* de um contato permitido,
> gateou cedo demais. Se você aplicou algo *sem* accept, gateou tarde demais. A linha é entre **guardar** e **agir**.

## 6. Doutrina consolidada (as fontes que este KB unifica)
- **RFC-0004 §4** — modelo de aceitação (policy-as-data, veto fail-safe, untrusted-até-verificado).
- **`a2a-verify.sh`** — as camadas 1-6 (verificação-antes-de-agir); `verified:true` porém `committed:false`.
- **`entrega-sem-commit` (I3)** — o produtor não commita no destino (a2a, co-deliver, adopt).
- **`apply_mode:propose-only`** — para membros regulados, nem o accept aplica direto (só propõe).
- **Roadmap de federação** — estados de gate `input_required`/`auth_required`; `never-live-pull`.

## 7. Lacunas honestas (o que este estudo NÃO resolve)
- **A linha não é enforçada uniformemente** por um só helper — cada canal a implementa (a2a-verify, co-deliver,
  adopt). Um lint transversal "nenhum produtor commita no destino" seria o próximo passo — **gated por gatilho**.
- **A camada 0 (transporte)** é por-endpoint (o token a2a dedicado vive na VPS) — fora do core versionado.
- **Reputação condicionando o gate** (elevar/rebaixar urgência por evidência) é futuro, gated atrás de dogfood.
