---
date: 2026-07-19
instance: onion-evolve
type: learning
classification: collective
tags: [adopt, g1, onion-pessoal, kg, roles, work-tools, dogfood, spike, privacy, local-first]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "FORK FECHADO (ver ## Resolução): NÃO construir /meta:adopt --mode kg agora — seria mecanismo SEM consumidor. O único adotante-KG real (marcio-pessoal) já roteia AO REDOR do adopt por 2 caminhos vivos: (1) método-por-referência (kg-radar do source contra ~/onion-pessoal/, onion_version:n/a no members.yaml) + (2) o APP com motor PRÓPRIO em JS (kgRadar.ts/kgStore.ts/deid.ts, zero-knowledge provado). O role `personal`+`kg_minimal` fica DESENHADO+TESTADO na prateleira (este diário), gated num 2º adotante-KG real que queira vendor-em-vez-de-app. Modernization Doctrine veta construir p/ adotante hipotético (C_ORBIT_CAVEAT). O que DESTRAVA valor não é adopt-para-KG — é a F2 do core (SSOT 6-camadas de inferência), que o app toca por cima (de-id v1) mas não substitui."
review_after: 2026-10-19
conflict_class: static
---

## Signal
Rodei o **spike F1 (gap G1)**: `/meta:adopt --mode regulated` contra um repo-KG-de-vida sintético
descartável, por dogfood (leitura completa do mecanismo + sonda determinística), para ver **onde as
premissas de "repo de código" quebram** quando o alvo é um KG de vida (domínio não-software). O aprendizado
durável: **a quebra é CATEGÓRICA, não incidental** — e o eixo de maior alavancagem (o role `kg`) **encaixa
limpo na maquinaria que já existe**. O spike fez o que um spike deve: descobriu *onde desenhar* antes de
gastar na F2.

## Evidence
- **Adopt é code-shaped em 3 eixos independentes** (não consertáveis por flag): (1) instrumento — a detecção
  de MODO e a Fase 1 reverse-eng assumem stack/`package.json`; confirmado: o alvo só tem `.md`+`.yaml`, o
  `@docs-reverse-engineer` retorna "generic" vazio. (2) bundle — a Fase 2 vendoriza o PRODUTO inteiro (98
  cmds/51 agentes/Jira/ClickUp); o KG de vida precisa só do MÉTODO. (3) durabilidade — `durable-commit.sh`
  assume "durável = objeto git + push/PR", que **contradiz** o `~/onion-pessoal/` local-first *fora de
  qualquer repo git*. Este 3º é a fronteira P4/privacidade encontrando o mecanismo.
- **O eixo do role `kg` já tem seam pronto:** `kg` NÃO é um role — é um **work_tool** dentro do set `full`
  (roles.yaml), que já materializa `kg.md`+`kg-radar.sh`+`kg-console.sh`. O que falta é um *role* método-only.
- **Testado (drive-to-verify, não de prior):** injetei `role: personal` (base `[]` = ZERO vertical de
  software) + `work_tool_sets.kg_minimal: [kg, diary, constellation]` num `roles.yaml` de scratch e rodei o
  resolver REAL → emitiu kg/diary/constellation; os três resolvem a comandos reais → **drift-guard REGRA 22
  passa**. O precedente `distilled` (base `[]`, não-vendoriza) prova que a maquinaria tolera a forma.
- **O fork que fica é do maestro:** vendorizar-durável (role `personal` + `kg_minimal`) vs referenciar-local
  (mode/marker `vendor:false`, alinhado ao `onion_version: n/a` que o onion-pessoal já escolheu). Os 3 🔴 do
  spike colapsam nessa única decisão.

## Resolução do fork (mesma sessão, drive-to-verify)
Ao re-derivar fresco contra o vivo, o fork vendor-vs-referência **se dissolveu** — a referência já venceu
NA PRÁTICA, e o adopt-para-KG **não tem consumidor**:
- **members.yaml `marcio-pessoal`:** `role: standalone` + `onion_version: n/a` — "adota o MÉTODO (kg-radar +
  /meta:kg + SDAAL destilado), NÃO vendoriza `.claude/`"; trust soberano (nem o core lê o diário). O
  no-vendor **já está carimbado no ledger de federação.**
- **O app é um cliente KG-de-vida purpose-built** (`~/onion-pessoal-app/`): motor PRÓPRIO em JS
  (`kgRadar.ts`, `kgStore.ts`, `kgSync.ts`, `deid.ts`), sync zero-knowledge provado ("remote entregou só
  ciphertext / server cannot read ✅"). **Não toca `/meta:adopt`.**
- ⇒ Construir `/meta:adopt --mode kg` seria mecanismo **sem consumidor**: o único KG-adotante real usa
  método-por-referência OU o app. **Modernization Doctrine veta** (o mesmo veto que matou C_D1_WEIGHT/C_ITEM6
  no spike /meta:evolve 07-18). O role `personal`/`kg_minimal` fica na prateleira (desenhado+testado), gated
  num 2º adotante-KG real que prefira vendor a app.
- **O spike fez seu trabalho:** um spike PODE concluir "não construa isto ainda". O valor destravado está na
  F2 do core (SSOT de inferência), não no adopt.

## Método (o que replicar)
Spike de gap = **construir o alvo mínimo real + rodar a camada determinística do mecanismo contra ele**, não
teorizar da leitura. E ao propor a extensão, **testar a extensão contra o resolver/guard reais** antes de
afirmar "encaixa". Régua Aristóteles aplicada: transfere o motor de KG/stamp/federação-pesquisa; desenha
fresh o instrumento/bundle/durabilidade.
