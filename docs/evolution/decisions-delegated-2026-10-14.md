---
title: Decisões delegadas pelo maestro — período noturno de 2026-10-14
date: 2026-10-14
type: decision-log
---

# Decisões delegadas — 2026-10-14 (período noturno, ~5 h)

**Autorização do maestro (verbatim, 2026-10-14):** "autorizo voce neste periodo a publicar portas, deploy, selar
decisões novas, o sandbox do B1 (os seus 2 comandos), sempre que tiver que selar uma decisão use o decide e escolha as
recomendações e mantenha o historico para me apresentar".

**Como a sessão aplica:**
- Toda decisão nova passa pelo `/meta:decide`; a opção escolhida é a **recomendada** (a primeira, marcada
  "Recomendado"), e o selo leva no `verified_against` a marca "decisão delegada pelo maestro (autorização noturna de
  2026-10-14), escolhida a recomendação".
- Deploy só pelos wrappers de `ops/` (o veto do MOAT segue valendo); publicação de porta pelo `/meta:publish` com o
  número que o motor propõe.
- Nada fora do escopo autorizado: sem rotação de chaves, sem escrita em repo de adotante fora do `/meta:adopt`, sem
  apagar repositório.

## Histórico

| Hora (UTC) | Decisão / ato | Opção escolhida | Alternativas | Onde ficou |
|---|---|---|---|---|
| 03:23 | Sandbox do B1: tornar `marciocar/onion-ruleset-sandbox` PÚBLICO | público (recomendado pelo agente: réplica fiel do core, que é público) | GitHub Pro / privado | `gh repo edit --visibility public` |
| 03:23 | Desvio declarado: a branch padrão do sandbox é `trunk`, não `main` | `trunk` — a guarda de main do core veta `main` em qualquer repo de dentro da sessão, e a sessão NÃO desliga a guarda; o ruleset vale para `~DEFAULT_BRANCH`, então o teste é equivalente | desligar a guarda (recusado) | commit 0f576b0 no sandbox |
| 03:23 | Seed + ruleset (cópia do 25001643, id 25048413) + **T1 medido** | push direto do admin sem checks **RECUSADO** (rc 1, "2 of 2 required status checks are expected") | — | /tmp/claude-1000/sbx/t1-push.txt |
| 03:41 | Dogfood B1 T2–T6 medidos no sandbox | — (medição) | — | grafo postmerge-projection-writer, nós E_DOGFOOD_B1_* |
| 03:41 | **Decisão delegada: o B1 depois do dogfood** (a premissa "check por workflow_dispatch conta" foi REFUTADA; a variante "escritor publica os check runs" funciona, mas enfraquece a garantia e paga a bancada por ciclo) | **B1 GATED, variante check run registrada** (recomendada: a Fase 0 já cura a causa; gatilho = main quebrar por combinação OU commits de projeção acima de 25% em 2 semanas) | executar a variante já · testar a variante "o próprio workflow selftest publica" | D_B1_GATED_VARIANTE_CHECKRUN_REGISTRADA (PR do passo B) |
| 03:45 | Merge do selo do canal (#1102, a3cb0749) e aviso à curadoria | — (execução do selo do maestro) | — | canal-vivo-sessoes-2026-10 |
| 04:11 | Achados de segurança no gate A2A de produção: replay concorrente (8/8 verificados) + jti fail-open (curados no #1103); corpo FORA da assinatura + exp opcional (cura em andamento) | curar + servir pelo `ops/update-bridge.sh` assim que mergear (deploy autorizado) | esperar o maestro | PR #1103 + PR fix/a2a-body-signed-and-exp-required |
| 04:11 | **Decisão delegada: emenda à RFC-0004** (D_RFC0004_CONVERSA_POR_THREAD) | **B — conversa por thread com expiração, escopo suggest, 5 invariantes**; só VALE depois do corpo assinado + exp no gate E do spike vivo passar | A manter a RFC · C = B + escopo act | grafo a2a-cross-user-spike-2026-10 |
| 04:12 | PR do passo B (#1104) com os selos (Fase 0, dogfood, B1 gated delegado) na fila | — | — | #1104 |
| 04:14 | Refutação do SPIKE-PROTOCOL pela curadoria (9 achados, 1 bloqueante: o A8 media o maestro, não o modelo) | aceitar as 9 emendas (recomendado pela refutadora) | rodar como está | PR spike/a2a-protocol-amendments |
| 04:57 | Merge do passo B (#1104); limpeza das cópias não rastreadas já processadas (cmp feito); triagem do sinal da Tessl (correção de fato medido, derivável) | — | — | PR docs/triage-tessl-landscape |
| 05:17 | **Deploy autorizado**: `ops/update-bridge.sh` serve a cura do replay concorrente + jti fail-closed (#1103) | rc 0, clone e2222a79, health 200 local+público, auth enforce | esperar o maestro | bridge onion-vps-bridge |
| 05:22 | Triagem do sinal da Tessl (#1106): o 'único spec-as-source' foi REFUTADO (nó B5_17 → refuted, por REFUTES); o '10k+' não se confirma hoje (piso de 1.274); o pivô entrou como indício; o veredito B5_17_veredito_trajetoria_campo perdeu uma premissa (Q aberta, não mexida) | correção de fato medido (derivável) | — | #1106 |
| 05:23 | Tessl (estudo C) — PARQUEAR **NÃO selado**: a curadoria pediu para esperar; o veredito D_TESSL_STUDY_C ainda está open lá e é do maestro, e a autorização noturna cobre decisões do core, não vereditos que a curadoria não propôs | respeitado — fica para o maestro, na sessão da curadoria | selar já | pendência do maestro |
| 05:53 | Degrau AUTOMATE do /meta:drive (#1107): as 4 objeções viraram predicado; --merge desligado por padrão; o Elenxo reprovou a 1ª versão (15 achados, 2 bloqueadores), 11 curados; a KB dizia 'merge POR PADRÃO', contrário ao selo, e foi corrigida | executar a decisão selada em 2026-10-12 | — | #1107 |
| 05:56 | #1106 reprovou no CI (dívida SHOULD +1, label de 538 chars); a sessão principal encurtou o label (233) e re-finalizou. Achado: o pr-finalize não roda o kg_gate do CI | curar o label (fato) | — | #1106 |
| 06:16 | Cura do corpo fora da assinatura no gate A2A (#1108): body_sha256 + exp/iat obrigatórios (teto 3600 s), chave duplicada vetada. **QUEBRA** os remetentes de julho (metagamify, granaai) até eles acrescentarem o claim | merge + deploy (furo de integridade em endpoint público; A2A sem tráfego desde julho) | esperar coordenar os remetentes | #1108 |
| 06:16 | Selo da emenda à RFC-0004 (B, conversa por thread) gravado no #1108 | B, com a emenda PENDENTE no texto normativo até o spike | — | D_RFC0004_CONVERSA_POR_THREAD |
| 06:16 | **PENDENTE para o maestro**: avisar metagamify e granaai de que o envio A2A precisa do claim body_sha256 (uma linha no payload de .onion-a2a/send-signal.sh) — aviso downstream é ato do maestro | — | — | — |
| 06:18 | Merge do AUTOMATE (#1107) | — | — | main ab7797d3 |
| 06:20 | Emendas do protocolo do spike (#1109): as 9 aplicadas no §12, com hook de registro, juiz, allowlists e canários testados offline (78/78, 12/12, 12/12). Achados: regra deny esconde a tentativa do hook; toda sessão receptora tem de rodar em sandbox (o settings do core libera Read/Grep/Glob sem escopo) | merge (passos vivos seguem com o maestro) | — | #1109 |
| 07:11 | Carimbador de pin das portas lê o remoto (#1105); refutador independente: sem caminho para carimbar pin não publicado; 3 achados baixos curados | merge | — | #1105 |
| 07:12 | Merges do #1106 (Tessl) e do #1109 (emendas do protocolo); o #1108 conflitou com o #1109 no ATC, e o agente foi mandado rebasear | — | — | — |
| 08:34 | Merge do #1108 (rebaseado sobre o #1109, CI verde) pelo `ops/merge-serial.sh` | — (execução da decisão das 06:16) | — | main a84eb724 |
| 08:40 | **Deploy**: `ops/update-bridge.sh` serve o gate com `body_sha256` + `exp`/`iat` obrigatórios | rc 0, clone a84eb724, health 200 local+público, auth enforce; bancada `a2a_verify` verde rodada NO clone servido | esperar o maestro | bridge |

## O que fica para o maestro

1. **Avisar metagamify e granaai**: o envio A2A deles para de passar no gate até acrescentarem o claim
   `body_sha256` (e `exp`/`iat`) no payload do `.onion-a2a/send-signal.sh`. Aviso downstream é ato seu.
2. **Spike A2A vivo** (P2, aceitação, A7/B0, A8/A8g): segue com você; a curadoria faz a 2ª passada do
   protocolo emendado (#1109).
3. **Sandbox do B1** (`marciocar/onion-ruleset-sandbox`, público): apagar ou manter. A sessão não apaga.
4. **`D_TESSL_STUDY_C`**: veredito seu, na sessão da curadoria (não selado aqui, a pedido dela).
5. **Emenda à RFC-0004** (`D_RFC0004_CONVERSA_POR_THREAD`, B): selada por delegação, mas o texto
   normativo só muda depois do spike vivo passar.
6. **B1** ficou GATED por delegação (`D_B1_GATED_VARIANTE_CHECKRUN_REGISTRADA`); pode reverter no próximo `/meta:decide`.
