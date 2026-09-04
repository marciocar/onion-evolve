# STATE — {{TITLE}} (diagnóstico de engajamento, KG SDAAL)

## Objective
Transformar o material de descoberta (transcrições + docs em `sources/`) num mapa de conhecimento
KG SDAAL de 2 camadas (`domain` = o negócio do cliente; `audit` = as hipóteses da consultoria), de
forma **iterativa: construir → pausar → perguntar → responder**. O radar diagnostica (atenção =
foco; estado-absorvente = gargalo; reconciliação = hipótese refutada); o humano sela.

## Constraints
- **Soberania:** material de cliente fica LOCAL; nós confidenciais marcados; nada de engajamento vai
  ao core. Antes de qualquer projeção cruzar fronteira, gate `projection-safety.sh --terms`.
- Schema estrito do `.kg.yaml` (uma chave por linha; enums válidos; **todo nó ≥1 aresta**).
- Checkpoint durável = o `.kg.yaml` commitado por LOTE + este STATE.md (ponteiro NEXT) + notes.md.
- A PAUSA é gate humano DURO: nenhuma reconciliação/decisão se materializa sem o selo humano.

## Map (onde está o quê)
- `sources/`       — material bruto (transcrições, docs; binário pesado → proxy textual .md)
- `extracts/`      — EXTRACT por fonte (`/product:extract-meeting`)
- `consolidated/`  — fusão multi-fonte (`/product:consolidate-meetings`; Convergências/Divergências)
- `graph/{{SLUG}}.kg.yaml` — o mapa (construído em lotes)
- `notes.md`       — registro append-only (as PAUSAs e as respostas carimbadas)

## NEXT
- phase: F0
- phase_title: Inventário — varrer sources/, classificar textual vs binário, levantar pendências
- status: ACTIVE
- next_action: "Rodar o inventário do material em sources/; classificar (textual vs binário→proxy); listar as pendências; PARAR na 1ª PAUSA para o humano confirmar o escopo antes de extrair."
- blocked_by: —
- last_checkpoint: scaffold
