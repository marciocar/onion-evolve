# 🚗 Doutrina do degrau AUTOMATE do `/meta:drive` — as paradas duras como predicado

Fragmento canônico do degrau **AUTOMATE** do [`/meta:drive`](../../meta/drive.md). A escada inteira
(nível 0, AUDIT, AUTOMATE, MOAT), o laço P0-P6 e a tabela de selagem moram na KB
[`onion-drive-doctrine.md`](../../../../docs/knowledge-base/concepts/onion-drive-doctrine.md); este
fragmento é o **contrato do degrau novo**, e o executor dele é `.claude/validation/drive-automate.sh`.

**De onde vem.** A decisão `D_AUTO_DRIVE_DEGRAU_AUTOMATE`
(`docs/evolution/research/auto-drive-2026-10/`), selada pelo maestro em 2026-10-12 por `/meta:decide`,
foi **«Forjar com as objeções»**: o degrau nasce com as quatro arestas `CONSTRAINS` do grafo como
requisito e com **`--merge` DESLIGADO por padrão**. A proposta original pedia merge por padrão; a
pergunta selada o inverteu, e a segunda opinião do adotante que evolui o KG-SSOT pediu o mesmo até a
primeira cadeia provada.

## 1. O que o degrau É

O AUTOMATE conduz **1..n raízes e a cadeia inteira** (filhos por `x_drive_parent`, predecessores por
`DEPENDS_ON`) item a item até **PR verde**, e, **só com `--merge` explícito**, até o merge pelo caminho
verificado, com o carimbo lido do forge. O LLM é **veto-only**: a sessão executa, o predicado decide
`SEGUE`/`PARA`, e nada do que a sessão escreve abre uma parada.

| subcomando | o que decide | rc |
|---|---|---|
| `plan` | a cadeia em ordem topológica + as paradas da expansão | 0 PRONTO · 1 PARA |
| `begin` | abre a passada no grafo (teto de nós, budget, merge ligado/desligado) ou a RETOMA | 0 · 1 |
| `next` | o item em voo a retomar, ou o próximo pronto, dentro do teto | 0 · 1 |
| `track` / `charge` | vincula PR ao nó; declara o gasto | 0 · 1 |
| `gate` | o predicado do merge | 0 MERGE-OK · 1 PARA · 3 AUDIT |
| `merge` | `gate` + `ops/merge-serial.sh` (core-only) + `stamp` | 0 · 1 · 3 |
| `stamp` | fecha o nó com o que LEU do forge | 0 · 1 |
| `end` | fecha a passada e escreve o checkpoint pelo `kg-drive-project.sh --close-lot` | 0 |

## 2. As quatro objeções viram predicado

| objeção (nó `CONSTRAINS`) | predicado | parada |
|---|---|---|
| **1** `E_OPINIAO_EXPANSAO_AINDA_NAO_CONFIAVEL` — o grafo é a SSOT da ordem | expansão pelo grafo, ordem topológica, conferência nó↔item no task manager por `tm.sh` | `CICLO` · `ITEM-SEM-NO` · `NO-SEM-ITEM` · `PAI-FILHO-DIVERGENTE` · `TM-ILEGIVEL`; e em todo passo, não só no `next`: `PREDECESSOR-ABERTO` · `PAI-COM-FILHO-ABERTO` |
| **2** `E_OPINIAO_CARIMBO_PELO_QUE_FOI_LIDO` — carimbo pelo que foi lido | `stamp` só com `state MERGED` + `mergedAt` + SHA do merge + run de CI SUCCESS de cada check exigido; `verified_at` = data do `mergedAt` | `PR-NAO-MERGEADO` · `CI-SEM-RUN` · `ITEM-E-DECISION` · `PAI-COM-FILHO-ABERTO` · `PR-MEXE-EM-DECISAO` (o diff não fecha decisão em outro grafo) · `POS-MERGE-FORA-DA-POLITICA` |
| **3** `E_OPINIAO_RISCOS_QUE_FALTAVAM` | checks do ruleset **presentes** e verdes; resíduo da REGRA 56 com `elenxo: sim` **e** `elenxo_isolado: sim`; passada e PR por item no grafo; insumo STALE de impacto ≥ 4; status do provedor nunca fecha nó; merge desligado por padrão e nunca para `decision` | `CI-VAZIO` · `CI-SEM-CHECK-EXIGIDO` · `CI-VERMELHO` · `ELENXO-UMA-VOZ` · `ELENXO-REPROVADO` · `INSUMO-VENCIDO` · `AUDIT` |
| **4** `E_DOGFOOD_POR_COMANDO_REAL` — usa a maquinaria | task manager só pelo `tm.sh`; merge só pelo `ops/merge-serial.sh` (core-only); checkpoint só pelo `--close-lot`; frescor e integridade pelo `kg-radar.sh` | o script não invoca outra coisa (a bancada lista as invocações) |

## 3. Invariantes (não se negociam, e cada um tem caso e mutante)

1. **Merge desligado por padrão.** Liga só com `--merge` na **abertura** da passada **e** na chamada do
   `merge`. Nenhuma variável de ambiente, default ou campo de grafo o liga; retomada não o liga. A passada
   é **selada**: o `begin` cria um segredo fora da árvore versionada (no diretório do repositório) e toda
   escrita do executor re-sela; editar `x_drive_pass` à mão, ou escrevê-la sem `begin`, é
   `PASSADA-ADULTERADA`.
2. **Um caminho de merge.** `ops/merge-serial.sh` → `ops/pr-merge-verified.sh` (core-only). Sem eles no
   projeto, o merge é recusado (`SEM-CAMINHO-VERIFICADO`) e o degrau para em PR verde.
3. **MOAT.** Diff fora da allowlist do ADR (`docs/analysis`, `docs/evolution`, `docs/discussions`,
   `docs/onion`, e a projeção `docs/backlog.md`) é `PATH-VENDORIZADO`: o que viaja, publica ou serve é
   AUDIT para sempre. PR de outro repositório é `REPO-ALHEIO` (I3). PR que toca o próprio grafo de
   controle é `PR-DO-CONTROLE` (o lote é selo do maestro), e grafo de controle fora do projeto é recusado.
   O registro da federação (`docs/evolution/federation/`) sai da allowlist por nome. A política do PR é
   **relida depois do merge**, no estado final: head que mudou durante a espera do CI e saiu da política é
   `POS-MERGE-FORA-DA-POLITICA`, sem carimbo. Nó marcado `x_drive_moat`, ou com
   vocabulário de deploy, publicação ou relógio no label, é `NO-MOAT`. O script não agenda, não dorme
   e não faz laço: cada chamada decide e termina, e o `/meta:drive` só roda quando o maestro o invoca.
4. **Teto por passada.** `--max-nodes` itens iniciados e `--budget` tokens; estourou, `TETO-DE-NOS` ou
   `BUDGET-ESGOTADO`. Sem passada aberta, `SEM-PASSADA`: sem teto não há laço. Só se julga, mergeia e
   carimba o item vinculado NESTA passada (`ITEM-FORA-DA-PASSADA`): `x_drive_pr` escrito à mão ou herdado
   não fura o teto. A escrita do grafo é sob trava e atômica (gasto concorrente não se perde).
5. **O controle mora no grafo.** `meta.x_drive_pass` (a passada) e `meta.x_drive_checkpoint` (o lote)
   viajam no diff. Checkpoint pendente para tudo; uma sessão que caiu retoma do grafo (`RETOMADA`,
   `RETOMAR`), sem zerar o gasto nem o teto.
6. **Abort-on-anomaly.** Toda parada é rc 1 nomeada; a sessão **para e reporta**, nunca contorna a jusante.
   Quem decide se houve merge é o forge, nunca o rc do `merge-serial` (um estouro pode ter mergeado); o
   merge fica registrado na passada ANTES do carimbo, e o `end` relê o forge para o lote não mentir.

## 4. O que esta doutrina NÃO promete

- **Quem digitou `--merge`.** O hook vê a string do modelo, não o autor da ordem. A ordem do maestro é a
  invocação do `/meta:drive`; o que é mecânico é o merge não ligar por omissão e a passada que o ligou
  ficar no grafo e na nota do checkpoint.
- **O selo da passada não é criptografia contra quem fabrica.** Quem lê o segredo no diretório do
  repositório e recalcula o hash forja a passada: é fabricação deliberada, não engano, e o hook não a vê.
  O selo pega a edição à mão e a passada escrita sem `begin`.
- **A janela entre o gate e o merge.** O `merge-serial` recebe o número do PR e pode mergear um head
  rebaseado. O executor relê a política no estado final e PARA sem carimbo, mas o merge já aconteceu: o
  que fecha a janela de vez é amarrar o head (`--match-head-commit`) dentro do caminho verificado, e isso
  não foi feito aqui.
- **A parada `NO-MOAT` por vocabulário é rede secundária.** Ela pega o que a lista de palavras pega; a
  defesa do merge é a allowlist de caminho, e a das ações é o hook do MOAT.
- **A pré-condição 1 do ADR (enabler git-nativo)** é, nesta casa, o ruleset do main com os checks exigidos
  e bypass só em PR, mais o hook que veta o merge por fora do caminho verificado. Não há branch `auto/*`.
- **`reviewed_diff_sha256` só é exigido não-pendente aqui.** Quem confere o hash contra o diff é a REGRA 56
  no `lint-onion-artifacts`, que é check exigido: verde dele é a prova.
- **O budget em tokens é DECLARADO** pela sessão com `charge`. O teto de itens é contado pelo script.
- **`elenxo_isolado: sim` é auto-atestado.** O script exige a declaração; não sabe se o agente separado
  de fato reabriu os artefatos.
- **O que a sessão faz fora do script** (deploy, push, publicação por wrapper) segue o
  `pretooluse-moat-gate.sh` e o `pretooluse-merge-gate.sh`. `ops/publish-door.sh --push` (core-only) é wrapper
  versionado e passa no hook; é por isso que a parada `NO-MOAT` existe na expansão.
- **Ele não usa os comandos `/engineer:*` por você.** O predicado prova que o script lê o task manager
  e mergeia pela maquinaria; usar o `/engineer:start → work → pr` por item é regra da sessão (o laço
  do `/meta:drive`), e o resíduo da REGRA 56 exigido pelo `gate` é o rastro que ela deixa.

## 🔗 Referências

- Executor: `.claude/validation/drive-automate.sh` · bancada: `run_drive_automate_selftests`
- KB da escada e do laço: [`onion-drive-doctrine.md`](../../../../docs/knowledge-base/concepts/onion-drive-doctrine.md)
- Grafo da decisão: `docs/evolution/research/auto-drive-2026-10/auto-drive-2026-10.kg.yaml`
- Precedente da escada (core-only): ADR `onion-adr-autonomous-thread-runtime-2026-07`
