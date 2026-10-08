---
title: "O ciclo do engineer não muda status no Zoho sozinho: o adapter procura um 'In Progress' que o layout padrão não tem, e outros 3 achados de campo"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# A maquinaria tem de mudar o status sozinha, e hoje não consegue

O maestro, ao ver o ciclo `/engineer:start` → `/engineer:work` parar e pedir que ELE mudasse o status
de uma task na tela do Zoho: **"tem que fazer isso automaticamente na maquinaria"**.

O pedido é para o core **decidir pela lente do Onion**: medir antes de curar, registrar a decisão como
nó, passar pelo Elenxo, preferir mecanismo a conselho e declarar o teto. Este sinal traz quatro achados,
todos medidos contra o portal real e o core vivo (`8e244df4`). A escolha é do core.

## 1. `updateStatus` não tem caminho para `in_progress` nem para o terminal (severidade média)

**O que o adapter diz** (`.claude/utils/task-manager/adapters/zoho.md`, linhas 250-260 e 327-335): os ids
de status "vêm de dentro de uma task", o adapter "descobre o mapa lendo uma task do projeto", e
`in_progress` resolve por nome para `In Progress`.

**O que foi medido em 2026-10-07** (projeto novo, layout padrão do portal):

| Passo | Resultado |
|---|---|
| Todas as tasks do portal | só o status `Open` aparece; nenhuma outra task carrega outro status, então "ler uma task" nunca acha o resto do mapa |
| `PATCH {"status":{"name":"In Progress"}}` | 400 `status id is invalid or missing` |
| Varredura de 30 ids vizinhos de `Open` com `PATCH {"status":{"id":…}}`, numa task descartável | só dois aceitos: `Open` (`is_closed_type: false`) e `Closed` (`is_closed_type: true`). **O layout padrão não tem `In Progress`.** |
| `PATCH {"completion_percentage":100}` | 200, e a task passa a `Closed` com o id do status no corpo. **É o caminho para o terminal que não depende de saber o id.** |
| `PATCH {"completion_percentage":10}` | 200, o status fica `Open`, com 10% gravados |
| `GET /settings/layouts?module=tasks` e `GET /settings/layouts/{id}?module=tasks` | 200 com o escopo **`ZohoProjects.custom_fields.READ`** (sem ele: 401 `INVALID_OAUTHSCOPE`). Cada projeto ganha um layout privado próprio; o campo `status` é picklist com `options_type: status`, mas as opções não vêm no corpo |
| `GET /settings/status?module=tasks&layout_id={id}` | 200, mas devolve só o status **padrão** (`Open`), com qualquer filtro |
| `GET /projects/{id}/fields?module=tasks&page=1` | **501 NOT_IMPLEMENTED** (a rota que um MCP comunitário usa) |
| `ZohoProjects.settings.READ`, `ZohoProjects.layouts.READ` | o accounts.zoho não emite token com esses escopos |

**Mecanismo candidato (para o core medir e decidir):**
- `in_progress` → manter `Open` e gravar `completion_percentage` proporcional ao progresso das fases do
  `plan.md` (é o que o layout padrão tem para "em andamento"); usar `In Progress` só se o mapa tiver um
  status com esse nome.
- `done` → `completion_percentage: 100` e ler o id de `Closed` do corpo da resposta, que passa a compor
  o mapa. O `is_closed_type` continua sendo a fonte do "terminal".
- O `/engineer:work` chama isso a cada fase, sem pedir nada ao humano.

## 2. O adapter pede um token por chamada e esbarra no limite de emissão (severidade média)

O `client_credentials` devolve um token de 3600 s. Um cliente que pede token novo a cada chamada recebeu,
depois de umas 30 emissões em poucos minutos, `{"error":"Access Denied","error_description":"You have
made too many requests continuously. Please try again after some time."}`, e **ficou ~5 minutos sem
conseguir operar**. O adapter não fala de reuso do token. Cura medida aqui: cache por escopo, com
expiração, num arquivo de permissão 600. Qualquer `/engineer:work` que atualize várias tasks numa fase
reproduz o bloqueio sem isso.

## 3. Milestone só aceita data `MM-DD-AAAA` (severidade baixa)

`POST /projects/{id}/milestones`: `2026-10-07T00:00:00Z`, `…000Z`, `…+00:00` e `…-03:00` dão 400
`PATTERN_NOT_MATCHED`; `2026-10-07` dá 400 `INVALID_PARAMETER_VALUE`; **`10-07-2026` dá 201**. O formato
segue o formato de data do portal. O adapter não documenta a criação de milestone, e a KB mostra só o
ISO-8601 da task.

## 4. `pr-merge-verified.sh` transforma HTTP 500 da API em "zero check-runs" (severidade baixa)

Em 2026-10-07, merge do PR #9 do onion-kg-ssot: a API de check-runs do GitHub devolveu **HTTP 500 para
qualquer commit** por ~7 minutos. O script disse `✗ ZERO check-runs registrados … provável janela
pós-push; espere os checks nascerem`. A causa está em `ops/pr-merge-verified.sh:122-123`: o `gh api …
2>/dev/null` engole o erro, e a saída vazia cai no ramo de zero runs. **O comportamento (não mergear)
estava certo; o diagnóstico mandava esperar a coisa errada** e sugeria o escape `--ci-inoperante`, que
seria o erro aqui. Cura candidata: capturar o rc do `gh api` em separado e dizer "API de checks
indisponível (HTTP 500)".

## Teto declarado

- Os achados 1 a 3 foram medidos **num portal só**, de teste, e no layout padrão. Um portal pago com
  status customizados pode ter `In Progress`; o mecanismo proposto o usa quando existe.
- O número de ~30 emissões até o bloqueio é estimativa pela contagem das chamadas, não limite medido.
- A sonda de escrita usou tasks descartáveis, apagadas com `DELETE` (204) e conferidas com `GET` (404).
