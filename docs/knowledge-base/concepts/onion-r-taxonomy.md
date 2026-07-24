---
title: "Taxonomia ONION-R — catálogo de referência dos guardrails do core (14 categorias)"
category: concepts
tags: [seguranca, guardrails, taxonomia, gate, owasp-llm, a2a, trust, fail-safe, anti-drift]
status: candidato
date: 2026-07-19
companion_of: onion-guardrails.md
---

# Taxonomia ONION-R — catálogo de referência

> **KB companheira de [`onion-guardrails`](onion-guardrails.md).** Este é o catálogo detalhado das 14 categorias
> `ONION-R1..R14` (+ R15 proposta) destiladas dos **vetos reais** que os gates do core já emitem. A KB-conceito
> nomeia e enquadra a camada; este catálogo é a **evidência indexada**.
>
> ### 🛡️ Nota anti-drift (a camada obedece o próprio ONION-R1)
> Um catálogo de `arquivo:linha` **perpétuo** no core violaria **ONION-R1** (integridade de SSOT) — a própria
> categoria que ele define: um refactor moveria `:635`→`:650` e o número ficaria stale sem alarme. Por isso, na
> promoção ao core, **os números de linha foram deliberadamente removidos**. Cada veto é ancorado por **(a)** o
> **arquivo** (read-path a nível de arquivo — estável a refactor de linha) e **(b)** a **string de veto real
> emitida** (identificador greppável e estável). Para revalidar read-paths/contagens contra o código vivo, rode
> **`/meta:kb-freshness`** com foco nesta KB (re-grep dirigido das strings nos arquivos citados). Leia toda
> contagem (`148`, `R1 22/0`…) e todo read-path como **snapshot a REVALIDAR**, nunca verdade perpétua.
> Registro de design com os line-anchors datados (2026-07-12): `taxonomy-onion-r.md` (interno do core) — o
> fio #1 da discussão, onde a taxonomia foi minerada por fan-out (8 mineradores, um por gate, 148 vetos) com
> cada veto ancorado em `arquivo:linha` verbatim antes de o catálogo promovido rebaixá-los a read-path por-arquivo.

**Método.** Esta taxonomia **não foi projetada, foi minerada** — e é uma **lente/índice sobre gates que já rodam**, não um sistema paralelo: **11 das 14 categorias herdam por read-path** de `a2a-verify`/`trust`/`metaspec-gate-keeper`/`.claude/validation/*` (reconciliação vs `authorization-layers`/`a2a-verify`/`trust` em `reconciliation-authorization-layers.md`, interno do core — a checagem #1 do core que classificou cada categoria HERDA/ESTENDE/NOVO e achou zero contradição com as 3 âncoras). Ela emergiu de **148 vetos categorizados** (a soma das 14 linhas da tabela-índice) — destilados de ~165 sinais brutos extraídos de **8 fontes de gate** do Sistema Onion (a diferença 165→148 é dedup entre fontes; nenhuma categoria perde lastro) (a2a-verify + camadas a2a, lint-artifacts, trust-topology + pin-integrity, federation-contract-validate, lint-design-tokens + inventory-drift, metaspec-gate-keeper + onion-validation, never-clobber/I3, lint-selftest). Cada veto veio com evidência `arquivo:linha` e a string real emitida. O agrupamento seguiu uma única regra dura: **uma categoria só existe se ≥1 veto real com read-path *confirmado* a sustenta** — nada de categoria bonita sem lastro. As categorias abaixo estão ordenadas por **robustez de evidência** (mais vetos confirmados primeiro), e cada tabela distingue rigorosamente `confirmado` (linha do `echo`/`violation()`/instrução lida verbatim) de `hipótese` (comportamento exigido pelo selftest, mas com a string de emissão do helper ainda não localizada). O eixo transversal é **modo**: `determinístico` (bash puro, exit code, sem LLM) vs `gated` (constituição textual que um LLM-agente obedece). Onde a família de mercado (OWASP LLM Top 10 2025 / Llama Guard S1–S14) tem análogo, ele é nomeado; onde o veto é nativo do Onion (federação a2a, never-clobber, drift de SSOT), registra-se **"sem equivalente público"** — isso é sinal, não lacuna.

---

## As categorias ONION-Rn

### ONION-R1 — Integridade de SSOT / meta-integridade de artefato gerado
**Definição:** garante que todo artefato derivado (inventário, grafo, mapa/console de federação, agent-card, plugin, manifesto de vertical) permaneça em sincronia com sua fonte-de-verdade no filesystem; bloqueia drift entre o que o repo *afirma* e o que ele *é*.
**Placement:** meta (com braços em output e federação). **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| inventory.sh ausente | `VIOLATION: ${rel_file}: inventory.sh ausente (SSOT do inventário não pode ser computada)` | lint-artifacts.sh | conf. |
| inventory.md ausente | `... docs/onion/inventory.md ausente — rode 'bash .claude/validation/inventory.sh --markdown ...'` | lint-artifacts.sh | conf. |
| inventory.md stale vs filesystem | `... inventário desatualizado vs filesystem — regenere com '/meta:inventory' ...` | lint-artifacts.sh | conf. |
| CLAUDE.md conta comandos ≠ real | `... CLAUDE.md afirma ${cmd_claim} comandos, filesystem tem ${cmd_truth} — alinhe à SSOT` | lint-artifacts.sh | conf. |
| CLAUDE.md conta agentes ≠ real | `... afirma ${agent_claim} agentes, filesystem tem ${agent_truth} ...` | lint-artifacts.sh | conf. |
| CLAUDE.md conta skills ≠ real | `... afirma ${skill_claim} skills, filesystem tem ${skill_truth} ...` | lint-artifacts.sh | conf. |
| graph.md ausente / stale | `... grafo ausente/desatualizado vs spec-as-code — regenere com '/meta:graph'` | lint-artifacts.sh | conf. |
| federation-map.md ausente / stale | `... mapa da federação desatualizado vs members.yaml ...` | lint-artifacts.sh | conf. |
| federation-console.html ausente / stale | `... console desatualizado vs SSOT — regenere ...` | lint-artifacts.sh | conf. |
| agent-card.json ausente / stale | `... agent card desatualizado vs SSOT — regenere ...` | lint-artifacts.sh | conf. |
| plugin ausente / fora de sync / tree_sha divergente | `VIOLATION: plugins/${name}: ... regenere com 'assemble-plugin.sh'` | lint-artifacts.sh | conf. |
| capability reivindicada ≠ cumprida | `... capability: reivindica '${claimed}' mas só cumpre '${met}' ...` | lint-artifacts.sh | conf. |
| vertical em roles.yaml sem manifesto / fora do marketplace.json | `... papel referencia vertical '${v}' sem manifesto ...` | lint-artifacts.sh | conf. |
| agent-card: membro core ausente | `a2a-agent-card: membro core (onion-evolve/source) ausente no members.yaml (exit 3).` | a2a-agent-card.sh | conf. |
| grafo .kg.yaml inválido (kg-radar --integrity) | `  ✗ nó órfão (grau 0): ${id}` · `  ✗ ${id}: node_type inválido` · `  ✗ CONTRADIÇÃO: ${id} recebe REFUTES mas segue status=…` (exit 1 se `problems>0`) | kg-radar.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público** — é integridade de spec-as-code / consistência doc↔filesystem, nativa do Onion. (Adjacência fraca com OWASP **LLM03 Supply Chain** no sentido de integridade de componentes.)

---

### ONION-R2 — Autenticidade criptográfica de sinal federado (A2A)
**Definição:** verifica o envelope + JWS de um sinal recebido na federação — estrutura, `alg`, `kid`, posse de chave, assinatura RS256, e coerência `iss`/`aud`/`to` — para fechar impersonação e adulteração.
**Placement:** input (superfície de ingresso federada); braço em execução (tooling). **Mode:** determinístico, com 2 vetos gated (posse/topologia).

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| envelope inexistente / não-JSON / campos ausentes | `envelope-absent` · `malformed-envelope` · `envelope-missing-fields` | a2a-verify.sh | conf. |
| JWS malformado / payload não-JSON | `malformed-jws` · `malformed-jws-payload` | a2a-verify.sh | conf. |
| `alg` ≠ RS256 | `unsupported-alg:${ALG:-none}` | a2a-verify.sh | conf. |
| `kid` ausente / com path-traversal / desconhecido | `jws-missing-kid` · `bad-kid` · `unknown-kid:${KID}` | a2a-verify.sh | conf. |
| `kid` não pertence ao `from` em members.yaml | `kid-not-owned-by-from:${KID}` | a2a-verify.sh | conf. (gated) |
| assinatura RS256 inválida | `bad-signature` | a2a-verify.sh | conf. |
| `iss`/`aud`/`to` divergem do declarado | `claim-iss-mismatch` · `claim-aud-mismatch` · `signal-to-mismatch` | a2a-verify.sh | conf. |
| tooling ausente (jq / openssl / python-yaml) | `tooling-absent:jq` · `tooling-absent:openssl` · `tooling-absent:python-yaml` | a2a-verify.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público** — autenticação message-layer agente-a-agente (federação a2a). OWASP LLM e Llama Guard não cobrem identidade/assinatura de agente.

---

### ONION-R3 — Conformância de spec-as-code (artefato como contexto do LLM)
**Definição:** valida agentes/comandos/templates que **configuram** o LLM — frontmatter completo, `model`/`category` presentes, dialeto de tools nativo (não-Cursor), formato MCP correto, limites de linha, links resolvíveis, sem vaporware.
**Placement:** input. **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| frontmatter de agente incompleto (name/description/tools) | `... frontmatter de agente incompleto — campos ausentes:${missing}` | lint-artifacts.sh | conf. |
| comando sem `description:` / sem `model:` | `... frontmatter de comando sem description:` · `... sem model: ...` | lint-artifacts.sh | conf. |
| agente sem `category:` | `... frontmatter de agente sem category: ...` | lint-artifacts.sh | conf. |
| `model:` contém gpt-4 | `... campo model: contém gpt-4 (linha(s): ${lines})` | lint-artifacts.sh | conf. |
| referência a vaporware `mcp_onion-orchestrator` | `... referência a 'mcp_onion-orchestrator' (componente vaporware)` | lint-artifacts.sh | conf. |
| agente >1500 / comando >800 linhas | `... agente com ${lines} linhas (limite: 1500)` · `... comando ... (limite: 800)` | lint-artifacts.sh | conf. |
| tool dialeto-Cursor / MCP inválido (agente, template, spec) | `... tool name estilo-Cursor: '${tool}' ...` · `... MCP em formato Cursor ...` | lint-artifacts.sh | conf. |
| escalar YAML com `': '` não-aspado | `... valor escalar com ': ' não-aspado (quebra o YAML ...)` | lint-artifacts.sh | conf. |
| doc sob `.claude/docs/` (proibido) | `... documentação sob .claude/docs/ — proibido ...` | lint-artifacts.sh | conf. |
| link relativo quebrado | `... link relativo quebrado (linha ${lineno}): '${target}' não resolve ...` | lint-artifacts.sh | conf. |

**Mapeamento de mercado:** OWASP **LLM03 Supply Chain** (integridade dos artefatos que compõem o prompt/agente). Sem análogo em Llama Guard.

---

### ONION-R4 — SSRF / controle de egress
**Definição:** antes de qualquer webhook (`pushNotificationConfig.url`), nega esquemas não-http, alvos privados/loopback/metadata-de-nuvem, e exige allow-list positiva a partir de `members.yaml`.
**Placement:** input (source1) / federação (selftest). **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| esquema não-http / host vazio | `deny scheme:non-http` · `deny empty-host` | a2a-ssrf-check.sh | conf. |
| IPv6 loopback / link-local / ULA | `deny ipv6-loopback` · `deny ipv6-link-local` · `deny ipv6-ula` | a2a-ssrf-check.sh | conf. |
| localhost / loopback-v4 | `deny localhost` · `deny loopback` | a2a-ssrf-check.sh | conf. |
| RFC-1918 (10/172/192) | `deny rfc1918-10` · `deny rfc1918-172` · `deny rfc1918-192` | a2a-ssrf-check.sh | conf. |
| 169.254.0.0/16 (metadata de nuvem) | `deny link-local-metadata` | a2a-ssrf-check.sh | conf. |
| members.yaml ausente / python-yaml ausente | `deny members-absent` · `deny tooling-absent:python-yaml` | a2a-ssrf-check.sh | conf. |
| host fora da allow-list | `deny not-in-allowlist:${host}` | a2a-ssrf-check.sh | conf. |
| script SSRF ausente / URL bloqueada (na verify) | `ssrf-check-absent` · `ssrf` | a2a-verify.sh | conf. |

**Mapeamento de mercado:** OWASP **LLM06 Excessive Agency** (egress de tool/plugin) — mais próximo. Llama Guard **S14 Code Interpreter Abuse** como análogo frouxo (abuso de sandbox/egress). SSRF em si não tem entrada dedicada no OWASP LLM.

---

### ONION-R5 — Never-clobber / segurança de adoção (I3 entrega-sem-commit)
**Definição:** ao instalar/atualizar o framework num repo alheio, nunca sobrescreve customização local nem varre produto uncommitted; degrada para sidecar/no-op ou aborta em árvore suja/conflito; guarda de papel impede a sessão errada de operar.
**Placement:** execução (merge/hook) + input (guarda de papel) + output (no-op de entrega). **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| working tree suja antes do merge | `ERRO: working tree de $T ($IB) suja — commite/stash antes do --update ...` | vendor-branch.sh | conf. |
| conflito de merge vendor | `Onion: CONFLITO no merge de $VENDOR — customização local vs framework novo ...` | vendor-branch.sh | conf. |
| já durável (idempotente) | `Onion: nada novo a commitar (instalação já durável em ${BR}).` | durable-commit.sh | conf. |
| pre-commit próprio / hooksPath custom | `Onion: .githooks/pre-commit já existe — Onion gravado como pre-commit.onion ...` | install-onion-githook.sh | conf. |
| prettierignore já protegido | `Onion: .prettierignore já protegido em ${DEST} (no-op).` | merge-prettierignore.sh | conf. |
| guarda de papel (co-deliver: só core) | `ERRO: '${MEMBER}' tem role='${ROLE}' — carteiro-local só entrega a hub/standalone ...` | co-deliver.sh | conf. |
| guarda de papel (co-relay: só adotante / stamp ausente) | `ERRO: role='${ROLE:-vazio}' no stamp — co-relay é só para ADOTANTE ...` | co-relay.sh | conf. |
| já entregue / relayado / duplicata processada | `Onion: já entregue (no-op): ${base}` · `... já relayado (no-op) ...` · `... conteúdo idêntico ...` | co-deliver.sh; co-relay.sh | conf. |
| co-deliver rodado em consumidor | (guarda real emitida em co-deliver.sh já confirmada acima; co-deliver.md é só a doutrina do papel) | co-deliver.sh | conf. |
| merge de hooks perderia hook próprio | **never-clobber POR CONSTRUÇÃO** — merge-onion-hooks.sh faz **união** (preserva hooks do alvo + adiciona os do Onion); não há string de veto porque não pode falhar em voz alta; o selftest existe para guardar esse silêncio | merge-onion-hooks.sh (verif. lint-selftest.sh) | conf.\* |
| durable-commit varreria produto | **never-clobber POR CONSTRUÇÃO** — staja SÓ o whitelist `ONION_PATHS` (`add=(); for p in "${ONION_PATHS[@]}"…`), produto uncommitted fica de fora; sem string de veto | durable-commit.sh (verif. lint-selftest.sh) | conf.\* |

**Mapeamento de mercado:** **sem equivalente público** — segurança de filesystem/coabitação na adoção. Adjacência frouxa com OWASP **LLM06** (limitar escopo de escrita do agente).

---

### ONION-R6 — Topologia de confiança / autorização de relay
**Definição:** policy-as-data em `members.yaml` decide se `from→to [action]` é permitido, com **deny-by-default**; codifica os papéis (source/hub/consumer/standalone) e o broker-obrigatório-do-core entre peers.
**Placement:** federação. **Mode:** determinístico (com braço gated via a2a-verify `trust-denied`).

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| relay negado (na verify) / trust-check ausente | `trust-denied` · `trust-check-absent` | a2a-verify.sh | conf. |
| correct→core não autorizado | `🚫 BLOQUEADO: ... can_correct_to de '$FROM_ID' não inclui 'onion-evolve' ...` | trust-topology-check.sh | conf. |
| hub→consumer fora de exposes_downstream | `🚫 BLOQUEADO: ... $TO_ID não está em exposes_downstream ...` | trust-topology-check.sh | conf. |
| hub↔hub trust não-bidirecional | `🚫 BLOQUEADO: ... Trust bidirecional incompleto: $MISSING` | trust-topology-check.sh | conf. |
| hub→hub correct exige broker core | `🚫 BLOQUEADO: ... Correção entre peers T1 exige intermediação do core ...` | trust-topology-check.sh | conf. |
| standalone→não-core (sem canal lateral) | `🚫 BLOQUEADO: ... standalone não tem canal lateral ...` | trust-topology-check.sh | conf. |
| combinação sem regra (deny-by-default) | `🚫 BLOQUEADO: ... Combinação ... não tem regra explícita — bloqueado por segurança.` | trust-topology-check.sh | conf. |
| membro / members.yaml ausente | `ERROR: membro '$ID' não encontrado ...` · `ERROR: members.yaml não encontrado ...` | trust-topology-check.sh | conf. |
| hub-correct-vazio / broker T1 / standalone→não-core | `🚫 BLOQUEADO: $FROM_ID → $TO_ID [correct]` + `exit 1` (mesmas strings das linhas confirmadas acima — o ref do minerador ao lint-selftest.sh/236/245 estava **errado**; o emit real vive no próprio trust-topology) | trust-topology-check.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público** — autorização de topologia federada agente-a-agente. Nativo.

---

### ONION-R7 — Higiene de entrada de config/CLI
**Definição:** valida argumentos e valores enumerados de ferramentas do framework (transporte, role/form de escopo, papel de bundle, classe de conflito de diário) antes de qualquer efeito.
**Placement:** input / execução. **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| FEDERATION_TRANSPORT inválido | `ERRO: FEDERATION_TRANSPORT inválido: '${KIND}' (use git-async|local|a2a-live|auto).` | detect-transport.sh | conf. |
| settings.json malformado (compose) | `ERRO: JSON inválido: $f` | compose-settings.sh | conf. |
| --role / --form inválido | `ERRO: --role inválido ...` · `ERRO: --form inválido ...` | compose-settings.sh | conf. |
| --json sem --show-scope | `ERRO: --json requer --show-scope.` | compose-settings.sh | conf. |
| papel de bundle desconhecido | `ERRO: papel desconhecido: %s (validos: %s)` | resolve-role-bundle.sh | conf. |
| conflict_class de diário inválida | `ERRO: ... conflict_class '$CCLASS' inválida (dynamic|static|conditional)` | diary-index.sh | conf. |
| $DEST inválido (prettierignore) | `ERRO: dest não é diretório: ${DEST}` (exit 2) | merge-prettierignore.sh | conf. |
| $DEST inválido / não-repo (githook) | `ERRO: dest não é diretório: ${DEST}` · `ERRO: dest não é repo git: ${DEST}` (exit 2) | install-onion-githook.sh | conf. |
| manifesto inválido (assemble-plugin) | `ERRO: manifesto inválido: '${MANIFEST}'` (exit 2) | assemble-plugin.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público direto** — validação genérica de argumento. (Sem correspondência limpa em OWASP LLM/Llama Guard.)

---

### ONION-R8 — Validação de contrato de federação
**Definição:** o gate de registro de contrato spec-as-code exige campos, semver, seções obrigatórias e — crucialmente — **≥1 teste e ≥1 fixture com payload** (contrato comportamental, não só sintático).
**Placement:** input (conteúdo) + meta (uso da CLI). **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| campo obrigatório ausente | `campo obrigatório ausente: **${field}:**` | federation-contract-validate.sh | conf. |
| version não-semver | `version não é semver válido (MAJOR.MINOR.PATCH): '${version_val}'` | federation-contract-validate.sh | conf. |
| seção obrigatória ausente | `seção obrigatória ausente: ## ${section}` | federation-contract-validate.sh | conf. |
| ## tests vazio (sem teste = blocker) | `## tests não lista nenhum path (≥1 obrigatório — sem teste = blocker)` | federation-contract-validate.sh | conf. |
| ## fixtures sem payload | `## fixtures não tem nenhum payload em bloco de código ...` | federation-contract-validate.sh | conf. |
| flag desconhecida / path ausente | `uso: $0 <path-do-contrato> [--json]` | federation-contract-validate.sh | conf. |
| contrato não encontrado | `erro: contrato não encontrado: $CONTRACT` | federation-contract-validate.sh | conf. |
| contrato malformado (via selftest) | corrobora as strings já confirmadas acima (campo/versão/seção/tests/fixtures) — mesmo validador único, exit 1 | federation-contract-validate.sh (verif. lint-selftest.sh) | conf. |

**Mapeamento de mercado:** **sem equivalente público** (contrato spec-as-code). Adjacência com OWASP **LLM03 Supply Chain**.

---

### ONION-R9 — Aterramento em evidência / anti-alucinação (epistemics do gate-keeper)
**Definição:** o `metaspec-gate-keeper` só emite veredito sobre o que **leu de fato** nesta sessão; falha de leitura ⇒ INCONCLUSIVO (nunca REJEITADO); sem meta-spec ⇒ abster; inferência exige âncora textual citada. É o guardrail contra o próprio LLM inventar conformidade.
**Placement:** meta / input. **Mode:** gated (constituição textual).

| Condição | String real (verbatim da constituição) | arquivo:linha | Ev. |
|---|---|---|---|
| veredito sem ter lido o arquivo | `Você só emite veredito a partir de arquivos que leu de fato ... proibido afirmar ... sem ... Read/Grep/Bash ...` | metaspec-gate-keeper.md | conf. |
| falha de leitura vira rejeição | `⛔ INCONCLUSIVO (BLOQUEADO) ... proibido emitir REJEITADO por falha de leitura: "não consegui ler" ≠ "viola".` | metaspec-gate-keeper.md | conf. |
| nenhuma meta-spec encontrada | `Se a descoberta não achar nenhuma metaspec → reportar e abster-se (não inventar régua).` | metaspec-gate-keeper.md | conf. |
| inferência sem âncora textual | `Inferir princípios implícitos apenas quando ancorados em texto explícito ... citar a regra-fonte (meta-spec:linha) ...` | metaspec-gate-keeper.md | conf. |
| git status para descobrir o que validar | `NUNCA usar git status/diff/branch para descobrir o que validar ...` | metaspec-gate-keeper.md | conf. |
| concluir "não existe" sem tentar Read | `NUNCA concluir que um artefato "não existe" sem ter tentado Read no caminho exato.` | metaspec-gate-keeper.md | conf. |

**Mapeamento de mercado:** OWASP **LLM09 Misinformation** (mitigação de alucinação/overreliance) — mapeamento forte. Llama Guard **S6 Specialized Advice** como análogo frouxo (conselho não-aterrado). É a categoria de veto **gated** mais bem-evidenciada do Onion.

---

### ONION-R10 — Integridade de proveniência / pin (supply chain)
**Definição:** valida que a instalação vendorizada aponta para um commit *real* na história do source e que o conteúdo pinado *de fato corresponde* (canário) — fecha o vetor de pin mentiroso; e recusa promover registro federado não-verificado.
**Placement:** input / execução. **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| stamp de pin ausente | `pin-untrusted stamp-ausente` | pin-integrity-check.sh | conf. |
| pin vazio/`unknown` | `pin-untrusted unknown` | pin-integrity-check.sh | conf. |
| SHA não existe na história | `pin-untrusted inexistente-na-historia ($PIN)` | pin-integrity-check.sh | conf. |
| canário diverge do commit pinado | `pin-untrusted canario-divergente ($PIN vs $CANARY)` | pin-integrity-check.sh | conf. |
| registro não-verificado (accept) | `RECUSADO: registro não-verificado (verdict.verified != true) — não aceito.` | a2a-accept.sh | conf. |
| registro não-JSON (accept) | `ERRO: registro não é JSON válido.` | a2a-accept.sh | conf. |

**Mapeamento de mercado:** OWASP **LLM03 Supply Chain** + **LLM04 Data & Model Poisoning** (o canário é detecção de adulteração). Mapeamento forte com LLM03.

---

### ONION-R11 — Anti-replay e frescor temporal
**Definição:** garante que cada sinal federado seja processado **uma vez** (jti/nonce) e dentro da **janela de validade** (`exp`/`iat`), com recusa dura quando o relógio não é comprovadamente sincronizado.
**Placement:** input (jti/exp/iat) + execução (clock). **Mode:** determinístico (com braço gated na verify).

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| `jti` ausente (necessário p/ anti-replay) | `jws-missing-jti` | a2a-verify.sh | conf. |
| jti já visto (replay) | `replay` | a2a-verify.sh | conf. |
| relógio não-atestado | `clock-untrusted` | a2a-verify.sh | conf. |
| `exp` < agora (expirado) | `expired` | a2a-verify.sh | conf. |
| `iat` > agora + skew (futuro) | `future` | a2a-verify.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público** — proteção message-layer (nonce/janela). Nem OWASP LLM nem Llama Guard endereçam replay/frescor de mensagem de agente.

---

### ONION-R12 — Acessibilidade / integridade de design tokens (WCAG)
**Definição:** gate determinístico sobre a SSOT de design tokens — contraste WCAG mínimo por par, tokens resolvíveis (sem alias órfão/ciclo), DTCG JSON válido.
**Placement:** output. **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| contraste abaixo do mínimo | `contraste ${ratio}:1 < ${min}:1 — ${fg} sobre ${bg} (${note})` | lint-design-tokens.sh | conf. |
| par com token ausente/não-hex | `par de contraste com token ausente/não-hex: ${fg} / ${bg}` | lint-design-tokens.sh | conf. |
| DTCG JSON inválido | `JSON inválido: ${f#${PROJECT}/}` | lint-design-tokens.sh | conf. |
| alias órfão / ciclo | `alias órfão: ${path} → ${raw}` · `ciclo de referência em: ${path} → ${raw}` | lint-design-tokens.sh | conf. |

**Mapeamento de mercado:** **sem equivalente público** — é gate de **acessibilidade**, fora do escopo de segurança de OWASP LLM / Llama Guard. Vale listar para honestidade (é um guardrail determinístico real), sinalizando que **não é um risco de segurança**.

---

### ONION-R13 — Invariantes de orquestração (arquitetura)
**Definição:** orquestração de subagentes vive em skill/comando (nunca em agente); fan-out é opt-in; a paralelização nunca funde workflows faseados canônicos. Existe em **dois modos**: gated (constituição do gate-keeper/skill) e determinístico (lint do nome reservado).
**Placement:** execução. **Mode:** gated + determinístico (o eixo em ação na mesma categoria).

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| orquestração dentro de agente | `Orquestração de subagentes vive em skill/comando, nunca em agente ...` | metaspec-gate-keeper.md | conf. (gated) |
| fusão de workflow faseado | `Invariante preservada: a orquestração paraleliza dentro de uma fase; não funde workflows faseados canônicos (§3)` | metaspec-gate-keeper.md | conf. (gated) |
| fan-out como default | `Fan-out é opt-in, nunca comportamento default (§10.2 regra 1)` | onion-validation/SKILL.md | conf. (gated) |
| agente `name: worker-orchestrator` | `... agente com name: 'worker-orchestrator' viola §4.2 da arquitetura` | lint-artifacts.sh | conf. (determ.) |

**Mapeamento de mercado:** OWASP **LLM06 Excessive Agency** (controle de autonomia/escopo de orquestração). Sem análogo em Llama Guard.

---

### ONION-R14 — Fronteira de abstração (SDAAL) / agência de tool
**Definição:** nenhum comando/agente chama SDK/MCP de provider (jira/clickup/github…) diretamente — tudo passa pela abstração agnóstica (`taskManager.*`/`forge.*`); métodos fora da interface são vetados.
**Placement:** execução / input (frontmatter). **Mode:** determinístico.

| Condição | String real | arquivo:linha | Ev. |
|---|---|---|---|
| chamada direta a provider (bypass adapter) | `... chamada direta a provider (use taskManager.* via adapter — SDAAL §9). ...` | lint-artifacts.sh | conf. |
| método fora da interface de abstração | `... método de abstração inexistente na interface: '${m}()' ...` | lint-artifacts.sh | conf. |
| tool MCP de provider direto no frontmatter | `... tool MCP de provider direto no frontmatter: '${tool}' — ... via adapter SDAAL ...` | lint-artifacts.sh | conf. |

**Mapeamento de mercado:** OWASP **LLM06 Excessive Agency** (restrição da superfície de tool/API que o agente pode invocar) — mapeamento forte; historicamente também *Insecure Plugin Design* (OWASP LLM 2023). Sem análogo em Llama Guard.

---

## Tabela-índice

| ONION-Rn | Nome | Placement | Vetos (conf./hip.) | Análogo de mercado |
|---|---|---|---|---|
| R1 | Integridade de SSOT / meta-integridade | meta | 22 / 0 | sem equiv. público (~LLM03) |
| R2 | Autenticidade criptográfica A2A | input/exec | 18 / 0 | sem equiv. público |
| R3 | Conformância de spec-as-code | input | 17 / 0 | OWASP LLM03 |
| R4 | SSRF / controle de egress | input/fed | 16 / 0 | OWASP LLM06; L.Guard S14 (frouxo) |
| R5 | Never-clobber / adoção (I3) | exec/input/output | 15 / 0 † | sem equiv. público (~LLM06) |
| R6 | Topologia de confiança / relay | federação | 13 / 0 | sem equiv. público |
| R7 | Higiene de entrada CLI/config | input/exec | 10 / 0 | sem equiv. público |
| R8 | Validação de contrato de federação | input/meta | 8 / 0 | sem equiv. público (~LLM03) |
| R9 | Aterramento em evidência / anti-alucinação | meta/input | 6 / 0 | **OWASP LLM09**; L.Guard S6 (frouxo) |
| R10 | Proveniência / pin (supply chain) | input/exec | 6 / 0 | **OWASP LLM03 + LLM04** |
| R11 | Anti-replay / frescor temporal | input/exec | 5 / 0 | sem equiv. público |
| R12 | Acessibilidade / design tokens (WCAG) | output | 5 / 0 | sem equiv. (não-segurança) |
| R13 | Invariantes de orquestração | execução | 4 / 0 | OWASP LLM06 |
| R14 | Fronteira SDAAL / agência de tool | exec/input | 3 / 0 | OWASP LLM06 |

Totais: **148 vetos categorizados** (soma exata das 14 linhas), **todos confirmados** por read-path — destilados de ~165 sinais brutos minerados (dedup entre fontes; as 11 hipóteses foram fechadas na verificação inline de 2026-07-12). *(Nem todos são guardrails de **segurança** — inclui gates de qualidade genéricos: R1 drift de SSOT, R7 higiene de CLI, R12 WCAG. Ver a coluna "análogo de mercado".)*

> ⚠️ **Auto-drift (concessão da checagem #2 do core — `refutation-survival.md` A2, interno do core: a
> refutação adversarial onde o ataque "catálogo sem gate anti-drift viola o próprio ONION-R1" PEGOU e forçou esta nota).**
> As citações `arquivo:linha` e as contagens (`148`, `R1 22/0`…) são **snapshot de 2026-07-12** — NÃO há gate
> que as revalide contra o código (um refactor movendo `:635`→`:650` deixaria isto stale sem alarme). É o
> pecado que **ONION-R1 pune** — o catálogo anti-drift ainda não tem guardrail anti-drift **de si mesmo**. Até
> a promoção amarrar esse gate (plano §Fase 1), **leia as citações como read-path a REVALIDAR**, não verdade
> perpétua. *A camada de guardrails tem que passar nos próprios guardrails.* **† R5** inclui 2 vetos `conf.*` = **never-clobber por construção** (staging por whitelist em durable-commit.sh; merge por união em merge-onion-hooks.sh): guardas reais que **não emitem string** porque previnem o clobber estruturalmente — o `lint-selftest.sh` existe para guardar esse silêncio. É um 3º modo, ao lado de `determinístico` e `gated`: **estrutural/silencioso**.

---

## Cobertura por placement

Contando os vetos confirmados pela superfície tagueada na mineração (**aproximado e com dupla-contagem deliberada** — categorias com braço em >1 placement, ex. R2/R4, aparecem em ambos; por isso a soma desta tabela **excede** o total categorizado de 148 e não deve ser lida como contagem-fechada, e sim como *presença por superfície*):

| Placement | Categorias com braço aqui | Vetos confirmados (aprox.) |
|---|---|---|
| **input** | R2, R3, R4, R5, R7, R8, R9, R10, R11, R14 | **~70** |
| **meta** | R1, R8, R9 | **~28** |
| **execução** | R2, R5, R7, R10, R11, R13, R14 | **~22** |
| **federação** | R4, R6 (+ braços fed. de R1) | **~20** |
| **output** | R1 (graph/plugin), R5 (no-op), R12 | **~13** |

**Isto refuta parcialmente — e refina — a leitura anterior.** A pesquisa anterior dizia "INPUT é a lacuna, federação/execução são fortes". Os números mostram o oposto na contagem bruta: **input é a superfície *mais* coberta** (~70 vetos), e federação/execução, embora sólidas, têm menos vetos. **Mas** a leitura anterior sobrevive quando se qualifica o que "input" significa: **todo o input coberto é input *estruturado*** — envelopes JSON, frontmatter YAML, campos de contrato markdown, URLs de webhook, SHAs de pin. **Não há um único veto sobre input *semântico / linguagem natural não-confiável*** — nada de detecção de prompt-injection, jailbreak, ou conteúdo tóxico entrando no raciocínio do LLM. Ou seja: **input-como-artefato é a superfície mais forte; input-como-prompt-não-confiável é um vazio total.** Federação e execução continuam fortes e são, de fato, onde vive a densidade *nativa* (R2/R4/R6/R11 não têm análogo público). A conclusão correta não é "input é fraco", e sim "**a robustez de input é toda sintática/estrutural; a camada semântica de guardrail de LLM não existe**".

---

## Buracos e hipóteses a fechar

**(a) Hipóteses — FECHADAS (verificação inline por grep dirigido, 2026-07-12).** As 11 hipóteses foram todas verificadas contra o helper real e **todas confirmaram**. Achados da verificação:

- **9 tinham read-path emitido**, apenas não localizado na 1ª mineração: `kg-radar.sh` (`✗ nó órfão`/`✗ node_type inválido`/`✗ CONTRADIÇÃO` → `exit (problems>0?1:0)`); `merge-prettierignore.sh`, `install-onion-githook.sh`, `assemble-plugin.sh` (todos `ERRO: … ` + `exit 2`); `federation-contract-validate.sh` (corrobora strings já confirmadas).
- **2 refs do minerador estavam ERRADOS** — apontavam pro `lint-selftest.sh` em vez do emit: `co-deliver-role-guard-consumer` na verdade é `co-deliver.sh` (já confirmada; o `.md` era só doutrina) e os 3 casos R6 (hub-correct/broker/standalone) já estavam confirmados em `trust-topology-check.sh` (o selftest:180/236/245 é código não-relacionado). *Lição: correlacionar por conteúdo, não por número de linha de outro arquivo — exatamente o gotcha "correlação por chave estável, nunca por path" da skill de orquestração.*
- **2 revelaram um 3º modo de guardrail** (não previsto na taxonomia inicial): `durable-commit.sh` e `merge-onion-hooks.sh` são **never-clobber por construção** — não emitem veto, previnem o clobber estruturalmente (whitelist / união). O `lint-selftest.sh` (:318, :470) é o que os torna verificáveis. Isso enriquece o eixo `determinístico × gated` com um terceiro: **estrutural/silencioso** (a guarda mais segura, porque não depende de a condição de erro ser detectada — ela é impossível por design).

Resultado: **taxonomia 100% aterrada em read-path confirmado.** Nenhuma categoria repousa em hipótese.

**(b) Categorias que o mercado nomeia e NENHUM veto Onion cobre — lacunas reais de guardrail, não só de nome:**

- **OWASP LLM01 Prompt Injection** — **zero vetos.** Não há sanitização/detecção de instrução adversária em input de linguagem natural. Lacuna de guardrail genuína (a mais crítica pela moldura de mercado).
- **OWASP LLM02 Sensitive Information Disclosure** — **zero vetos.** Sem redação de PII/segredos em output do LLM. (O `.env` é lido por convenção, mas não há guardrail de vazamento.)
- **OWASP LLM07 System Prompt Leakage** — **zero vetos.** Nada impede exfiltração do conteúdo de agentes/comandos.
- **OWASP LLM10 Unbounded Consumption** — **sem veto direto.** `fanout-not-default` (R13) limita autonomia de forma tangencial, mas não há gate de custo/rate/loop.
- **OWASP LLM08 Vector/Embedding Weaknesses** — **N/A por arquitetura** (Onion não tem RAG/vector store) — lacuna de *nome*, não de risco.
- **Llama Guard S1–S14 (conteúdo: violência, CSAM, ódio, self-harm, etc.)** — **cobertura zero.** Nenhum guardrail de moderação de conteúdo. **Provável out-of-scope-by-design** (o Onion é framework de dev, não chatbot de usuário final) — mas isso precisa de **decisão arquitetural explícita**, não de suposição, antes que a KB reivindique "cobertura".

Coberto pela moldura de mercado: **LLM03** (R3/R8/R10), **LLM04** (R10 canário), **LLM06** (R4/R13/R14 + braços de R5), **LLM09** (R9). Quatro das dez entradas do OWASP têm lastro Onion sólido; **três (LLM01/LLM02/LLM07) são vazios reais** e uma (LLM10) é quase-vazio.

---

