---
title: "F2 — Harmonia da stack VPS × necessidades do Onion e da federação (síntese REPROVADA, inventário aproveitado)"
category: research
date: 2026-08-01
status: sintese-reprovada-inventario-ratificavel
method: "Dois Elenxos orquestrados: F2 (4 pesquisas → síntese → crítico adversarial, 6 workers) + F2-b (3 pesquisas → veredito, 4 workers). Verificação independente dos pontos decisivos pelo maestro-agente."
run_id: "wf_cef413f1-a3f + wf_0f8b847a-34a"
kg: docs/evolution/research/stack-harmonia-2026-08/stack-harmonia-2026-08.kg.yaml
---

# Harmonia da stack — o que sobreviveu

> **Projeção do grafo.** SSOT: [`stack-harmonia-2026-08.kg.yaml`](./stack-harmonia-2026-08.kg.yaml).

## ⚠️ Resultado principal: a síntese foi **REPROVADA pelo crítico** — e a verificação confirmou

O crítico adversarial derrubou a arquitetura proposta mostrando que ela era **catedral erguida sobre dois
erros verificáveis**. Eu re-medi os pontos decisivos **de forma independente** e **confirmei o crítico**:

| Alegação da síntese | Verificação independente |
|---|---|
| "9 membros" → "canal partido para **44%**" | ❌ `grep -c '^  - id:'` = **12 entradas**. O percentual era **fabricado** |
| "4 membros sem canal — o que mais dói hoje" | ❌ **0 pendentes** nos 8 outboxes (tudo em `_processed/`). Ausência de diretório = ausência de **emissão**, não canal partido — e os 4 foram registrados **depois** do último anúncio |
| "deriva de projeção: o org-map não é auditável" | ❌ `federation-orgs.json` entrou no repo em **07-28**; o checkout de produção está em **07-27** — um dia **antes** de o arquivo existir. É **`git pull` pendente**, não deriva |

**Consequência:** as 4 "Leis", a doutrina candidata e a costura-estrela (`_receipts.tsv` + guarda inversa da
REGRA 46) **caem junto** — e caem justamente os itens rotulados `[GATILHO JÁ DISPAROU]`, ou seja, **o gatilho
é que foi fabricado**.

> **Não promover a doutrina candidata a KB.** *"Git é o barramento"* confunde **volume** com **provisionamento**
> (o a2a-live tem 2 exercícios porque só 2 membros têm bloco `a2a:` — é o denominador), e git é o **ledger**, não
> o transporte (o downstream real é `/meta:co-deliver`, cópia de arquivo **manual** na mesma máquina).
> `fix-must-become-mechanism` exige que a lição venha do **uso real** — aqui o "fix" veio de um `ls` lido ao contrário.

## ✅ O que sobrevive (inventário medido, sem arquitetura nova)

**Nenhum item abaixo precisa de nenhuma "Lei" para se justificar.**

1. **🔴 Desligar o WAHA** — o melhor item da lista. Container Up 15h, **zero** referências a `waha`/`3999`/`whatsapp` no `src/` do bridge, **zero** agendador, `WAHA_API_KEY` e `WAHA_DASHBOARD_PASSWORD` legíveis via `docker inspect`, e 3 mensagens aceitas que nunca chegaram. **Risco removido alto, esforço `docker stop`, reversível.**
2. **Atualizar o checkout de produção** (`git pull` + restart) — como **hábito**, não como contrato `/health {sha,dirty}` + 409 (que derrubaria a federação hoje por condição cosmética, para N=1 operador). A constatação estrutural que **de fato** vale: *o artefato que roda (07-27) não é o do repo (07-31)* → **toda conclusão sobre "o que o bridge faz" tirada do main pode estar errada**.
3. **`PERMISSION_MODE=bypassPermissions` atrás de porta pública** — real, explícito no `.env` de produção. A contenção certa é de **processo** (usuário dedicado, sem socket do Docker, sem credencial de outro tenant no ambiente), não flag do SDK.
4. **Verificar o firewall com UM comando** antes de tocar em 8+ bindings `0.0.0.0` dos stacks de adotante. A superfície é **fato**; o risco líquido **não foi medido** — ordenar a edição antes de medir repetiria `verify-access-before-specifying`.
5. **`NTFY_URL` obrigatório** (remover o default público `ntfy.sh`) + **declarar o wake como PULL** — corrige promessa maior que o mecanismo, sem construir agendador.
6. **O downstream não está partido — está PARADO.** 0 pendentes, último anúncio há dias. Se algo merece ação no eixo de entrega, é **publicar (ou decidir conscientemente não publicar)** — não instrumentar um canal que ninguém usou porque ninguém emitiu.

## 🚫 O anti-catálogo (herdado da evidência, sobreviveu inteiro)

**Não construir:** admin platform / painel agregado (já `status: refuted` no KG) · **SDAAL para email e para WhatsApp**
(falham o Teste do Eixo com evidência) · OTel/Prometheus/Grafana **agora** · Langfuse **agora** (v3 = 6 contêineres;
Helicone em *maintenance mode*) · gateway de webhook dedicado (Svix/Outpost são para **enviar**; Hookdeck é SaaS-only;
n8n nem é OSI) · multi-tenancy de adotante no Logto do **core** (o isolamento por container já é limpo) · **tunneling**
(Caddy+Logto já são a porta única; `ssh -L` resolve o caso real) · F1.2/F2.1/F2.3 · decompor o bridge em serviços ·
**e a `POST /hooks/:provider`** — que com o WAHA desligado tem **N=0** produtores.

## 🚪 A REGRA DOS 5 PORTÕES (do F2-b — candidata a doutrina, esta **sobrevive**)

Internalizar só se passar em **todos**: **(1) pull datado** (dor com data, não categoria) · **(2) não-reuso provado**
(tentar com o que já é pago, antes de decidir) · **(3) dado novo** (se já está num log e falta uma query, é dead-layer)
· **(4) o volume força** (punhado/dia: arquivo + `jq` vence) · **(5) dono nomeado** — *o portão que ninguém aplica, e
é o que fabrica catedral*.

**Teste de catedral** (qualquer um ⇒ não internalize): traz 2º banco · só dá valor via dashboard · o valor é "visão
agregada" · é confortável só porque o volume é zero.

**A assimetria que sustenta:** com 31GB, **RAM é o custo barato** — e é o único que todos calculam. Superfície,
atualização e dono **não escalam com a fatura, escalam com a contagem de peças**. A pergunta certa nunca é *"cabe?"*,
é **"quantas peças a mais passam a ter dono?"**

**Corolário que corrige a própria regra:** os 5 portões otimizam *menos peças*; **segurança às vezes quer uma peça a
mais que só compra isolamento** — e aí o portão de segurança vence os 5.

## 🔒 O dissent de segurança do F2-b (incorporado)

> No mesmo processo do bridge estão **`/chat` com credenciais Anthropic** e **`/admin` que cunha convites**. Pôr ali
> um parser de HMAC processando bytes hostis significa que **um bug no parser alcança a cunhagem de convites**.

**Concessão adotada:** *se* a rota de webhook for construída um dia, que rode como **segundo processo do mesmo
código** — mesmo repo, mesmo dono, porta própria, ambiente **sem** `AUTH_TOKEN`, **sem** chave Anthropic, **sem**
`/admin`. Isolamento de raio de explosão sem peça de terceiro nem dono novo.

## Tensões que se contornam (não se resolvem)

- **SSOT em git × estado que só existe em DB** (Logto, sessão do WAHA) → projeção **unidirecional** + gerador determinístico, nunca sincronização bidirecional. *Se não existe comando que reconstrua o estado a partir do git, aquele estado é dívida com prazo.*
- **Regulado × entrega automática** → separação dura **depositar ≠ aplicar** (o transporte escreve no `inbound/`; o `apply` é ato da sessão do adotante — o que a Camada 6 do `a2a-verify.sh` já enforça).
- **Uma VPS com core + adotantes + um negócio não-Onion** → isolamento por container **não é** isolamento por host (kernel, disco e `docker inspect` compartilhados). Não se resolve sem migrar; contorna-se com loopback, inventário de portas e nenhum segredo de tenant no ambiente de outro processo.
- **`spec-now/build-gated` × `gated-work-derives-fresh`** → registrar **só o gatilho e a necessidade exercida**, nunca o desenho. *O que sobrevive ao tempo é "quando X acontecer, isto vai doer assim"; o "como" apodrece.*
