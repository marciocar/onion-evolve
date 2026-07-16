---
tipo: sinal-upstream
origem: rhilo-metagamify (adotante)
destino: onion-evolve (core)
data: 2026-07-16
assunto: "Dogfood intenso do KG SDAAL — o ouro (reconciliação de SSOT do WRR/Modo Equilíbrio)"
fluxo: feedback (adotante → core)
relacionado:
  - .claude/commands/meta/kg.md
  - .claude/validation/kg-radar.sh
  - docs/knowledge-base/concepts/knowledge-graph-sdaal.md
---

# 🥇 O ouro do dogfood KG SDAAL — reconciliação do SSOT do WRR/Modo Equilíbrio

> **Para o core.** Este foi o uso mais intenso do KG SDAAL até agora num adotante: pegamos um KG
> existente (`docs/rhilo/graph/wrr-audit.kg.yaml`) e o usamos como **SSOT viva** para reconciliar
> **produção × local × alvo** do "Modo Equilíbrio pleno" da RHILO. Migramos schema, modelamos alavancas,
> **decidimos a arquitetura pelo grafo**, estendemos o domínio, rebaixamos 126 docs a evidência, validamos
> de-saturação **ao vivo** e implementamos+testamos o pacing. Abaixo, o ouro sem filtro — o que funcionou,
> o que doeu, onde me perdi, e **7 propostas concretas** para a técnica melhorar.

## 1. O que foi feito (o dogfood, em fases)

| Fase | O quê | Saída |
|---|---|---|
| **F0** | Migração de schema (a ferramenta antiga `scripts/kg/` estava morta; o KG não passava no radar canônico) | KG canônico, radar exit 0 |
| **F1** | Veredito das alavancas — cada uma como nó `audit` com `plane: DEV` × `plane: PROD` (snapshot vivo) | tabela "alavanca × PROD × DEV × veredito" machine-readable |
| **F2** | Decisão da arquitetura **pelo grafo** (flat+déficit+pacing vs stratified) | nó `decision D_PLENO_VERDICT` |
| **F3/F4** | Camada de domínio trace-completa (regras ancoradas via `TRACES_TO`) + radar limpo | 11 avisos RULE-sem-trace zerados |
| **F5** | Ledger de **126 docs** rebaixados a evidência com status (canonical/superseded/historical/redundant) | `_LEDGER-vs-kg.md` + nó `A_DOC_LEDGER` |
| **+** | Validação de-saturação **A/B ao vivo** (`/next-participant` OFF vs ON) + pacing implementado + testado | PRs #79/#80/#81 |

**Resultado:** o KG saiu de **ilegível por qualquer ferramenta** para **canônico + motor de trabalho concreto**
(decidiu arquitetura, gerou código, guiou validação).

## 2. Sucessos — a técnica provou valor

- **`plane: DEV vs PROD` é o coração.** Reconciliou "o que a doc afirma" × "o que roda em prod" de forma
  machine-readable. Foi o que expôs que produção migrou para `flat+déficit` enquanto a doc-mãe ainda
  descrevia `stratified` — divergência de **arquitetura**, não de valor.
- **`SUPERSEDES`/`REFUTES` reconciliam sem apagar.** Contradições viraram arestas explícitas (doseMax drift,
  tabela legada, bug "já corrigido"), não deleções. A história ficou auditável.
- **O radar-de-domínio ganhou o pão:** o **SLOT-limbo emergiu como estado-absorvente** — bug estrutural que
  o *modelo* denuncia, não a prosa. Exatamente o caso de uso prometido, confirmado em campo de novo.
- **O radar de integridade pegou erros reais:** órfãos, id duplicado (`E_DOSE` 2×), e uma **contradição
  REFUTES-em-nó-confirmed** que forçou uma reconciliação honesta (`C_MG_PROD_CONFRONTED` → superseded).
- **O ledger desarmou 126 docs concorrentes.** De "12 teorias competindo" para "evidência com status +
  nó-KG governante". Padrão fortíssimo e reusável.
- **O KG virou driver de ação:** decidiu a arquitetura (2-camadas), gerou **código real** (pacing, ~30 LOC,
  testado 5/5 unit + 3/3 dump) e guiou **validação ao vivo** (de-sat A/B).

## 3. Problemas / desvantagens — o que doeu

- **🔴 O KG-SSOT não era lido por FERRAMENTA NENHUMA.** Estava no schema da ferramenta antiga local
  (`scripts/kg/radar.js`, `type:`/flow-maps) — que quebrou (MODULE_NOT_FOUND) — e dava **287 violações** no
  radar canônico do core (`kg-radar.sh`, `node_type:`/bloco). A SSOT e o radar **driftaram** e ninguém
  percebeu. **Uma "fonte da verdade" que nenhuma ferramenta valida não é fonte da verdade.**
- **🔴 A "SSOT" tinha APODRECIDO.** Vários nós `plane: PROD` estavam **stale**:
  - `doseMaxByLevel` = 2/4/8/8/8 (real vivo = 2/4/12/15/20);
  - a tabela `WRRJourneyConfig` (legada) tratada como fonte viva — o motor lê `Journey.config.wrr`;
  - "Bloqueador #1 (bug de escopo de flag)" marcado aberto — **já corrigido** no código há tempos;
  - `fairActiveCases` "implementado localmente, aguardando push/PR" — **já deployado e gravando** em prod.
  Ninguém **re-rodou** as claims PROD contra o estado vivo → **o grafo mentia com cara de verdade**.
- **🟠 Radar frágil (parser awk por keyword-substring).** Ele faz grep de `plane:`/`status:`/`impact:` em
  **cada linha** do nó → um `label:` cujo texto contém "plane:" ou "status:" **corrompe** o campo real.
  Tive de emitir os campos livres (label/traces) **antes** dos escalares para a última ocorrência (o
  escalar real) vencer. Regra crítica, **não documentada** — footgun garantido para o próximo.
- **🟠 Footgun YAML 1.1:** a chave `on:` (usada em `TRANSITIONS ... on: EVENTO`) vira **booleano `True`** no
  parser YAML → **perdi todos os 9 gatilhos de transição de domínio** na primeira migração (só reapareceram
  quando tratei `e.get(True)`). Um estado-absorvente falso apareceu por causa disso.
- **🟠 A migração foi grande e delicada** (161KB, **3 formatos de nó** coexistindo: flow-map multiline,
  flow-map inline, bloco) — e **não há ferramenta de migração** nem **versão de schema** no `.kg.yaml`. O
  drift ficou invisível até quebrar.

## 4. Descobertas — a lição-mestra

> **Um KG-SSOT que não é RE-EXECUTADO contra o estado vivo apodrece silenciosamente.**

O valor do KG **não** é ser escrito uma vez — é ser **re-verificável**. Toda a dor da seção 3 vem de uma
única falta: **nenhuma disciplina de frescor nas claims `plane: PROD`**. Um nó `PROD` é uma foto; sem
carimbo de "verificado quando/contra o quê", ele envelhece e o leitor (humano **ou IA**) confia no stale.

O que me salvou foi **cruzar 4 fontes**: KG + memória + código (trace `arquivo:linha`) + **dump fresco**.
O KG sozinho (stale) me **enganou**. As migalhas `trace` do SDAAL são ótimas — mas apontam *onde*, não
*quando foi verificado por último*.

## 5. Comunicação — onde me perdi e como reencontrei

- **Erro que reportei ao usuário:** afirmei "dose inócua / doseControl ausente" — porque consultei a
  **tabela errada** (`WRRJourneyConfig` legada, seguindo uma nota de memória imprecisa). Reencontrei
  cruzando o nó `C_MG_PROD_CONFRONTED` (que dizia doseControl presente) + a memória de valores + o **trace
  de código** (`wrr-distribution.service.ts:2852-2873`, o motor lê `Journey.config.wrr`) → dose estava
  **VIVA**. Corrigi com o usuário e **gravei a armadilha na memória** para não repetir.
- **doseMax drift** (8/8/8 vs 12/15/20): me perdi (o KG e o dump discordavam), reencontrei pela correção
  registrada na memória (07-14). Fechei como nó `Q_DOSEMAX_DRIFT` resolvido, com `SUPERSEDES`.
- **Lição de comunicação:** o KG precisa dizer **qual fonte** e **quando foi verificada** — senão o
  consumidor confia no stale e *propaga o erro* (eu propaguei, ao usuário, por uma leitura só). O
  cruzamento de fontes não pode ser opcional; deveria ser um passo prescrito da técnica.

## 6. O que a técnica deveria incorporar — 7 propostas ao core

1. **Versão de schema no `.kg.yaml` + gate no radar.** Um `schema_version:` no `meta:`; o radar detecta
   divergência e **recusa ou migra**. Teria pego o fork `scripts/kg`↔`kg-radar.sh` no dia 1.
2. **⭐ Disciplina de frescor PROD (o maior buraco).** Campo `verified_at:` (e opcional `verified_against:`
   = baseline/dump) por nó `plane: PROD`, + checagem no radar: **"nó PROD mais antigo que a baseline/dump
   atual → ⚠ STALE"**. Sem isso, o apodrecimento da SSOT é **inevitável**, não acidental.
3. **Robustez do parser.** Ou uma **regra documentada** ("campos livres antes dos escalares"; keyword em
   texto livre nunca depois de um escalar) **+ um linter** que reprova `label:`/`trace:` contendo substring
   de keyword; ou — melhor — um **parser YAML real** no gate (mantendo o determinismo). O awk-grep-substring
   é uma bomba-relógio.
4. **`kg migrate` de 1ª classe.** `type→node_type`, flow-map→bloco, correção de planes, `on:`-bool. O schema
   evolui; a migração precisa existir como ferramenta, não como script ad-hoc de 130 linhas (o que escrevi).
5. **Doc de footguns YAML** no KB do SDAAL: `on:`→bool (YAML 1.1), colisão de keyword-substring, vírgulas
   finais em flow-maps. Pequeno, salva horas.
6. **Promover o padrão "ledger docs-as-evidência"** como método do modo `map`. O índice que classifica docs
   concorrentes (canonical/superseded/historical/redundant) → cada um mapeado ao nó-KG governante. Desarmou
   126 docs aqui; é reusável em qualquer adotante afogado em docs.
7. **Nomear a técnica "drive-to-verify" (verificar o nó dirigindo o sistema vivo).** Fiz um **A/B no
   `/next-participant`** (flag OFF vs ON) que **provou a de-saturação end-to-end** (carga que o motor
   rankeia de-inflou 4,6-9,5× ao vivo). Isso é mais forte que SQL/leitura — deveria ser um **passo canônico**
   do ciclo do KG ("uma claim PROD de alto impacto merece ser dirigida no sistema vivo, não só lida").

## 7. O que NÃO foi testado mas poderia/deveria

- **`kg-console.sh`** (render HTML) — gerado e enviado, mas não validado a fundo (layout/escala visual).
- **Modo `map` F4** (adaptador `SourceTag` no stack do consumidor) — não implementado; parei no contrato.
- **Domínio cross-repo** — a 2ª fatia (command-center do rhilo-app, que já referencia o KG) não foi mapeada.
- **Fase-2 semântica** (embeddings/cosseno para flag de redundância entre nós) — não exercitada; o ledger
  de docs foi feito à mão (por agente), não pela similaridade automática que a doutrina promete.
- **Escala do radar** — só ~165 nós/288 arestas. Comportamento (tempo, ruído do radar de atenção) em grafo
  de milhares de nós é **desconhecido**.

## 8. Veredito honesto

A técnica **entregou**: reconciliação real dos 3 estados, uma **decisão de arquitetura** defensável tirada
do grafo, **código** (pacing) e **validação ao vivo** (de-sat A/B). O KG deixou de ser prosa e virou motor.

Mas o dogfood revelou que **o elo fraco é o frescor**: um KG-SSOT sem re-verificação vira **um belo
documento que mente** — e pior, um consumidor confiante (IA inclusive) propaga a mentira. As propostas #2
(`verified_at` + gate de stale) e #3 (robustez do parser) são o ouro de maior alavanca para o core promover.

> Se o SDAAL incorporar só **uma** coisa desta rodada: **frescor como cidadão de primeira classe** —
> `verified_at` por nó PROD + um radar que grita quando a verdade envelheceu.

— sinal do adotante `rhilo-metagamify`, sessão de 2026-07-15/16.
