<!-- adapter-auxiliar: clickup -->
# 🔵 ClickUp — o executável `clickup.py` (2026-11-06)

> **Irmão de [`clickup.md`](clickup.md) por *progressive disclosure* ([`sdaal.md` §14.5](../../../../docs/sdaal/sdaal.md)).**
> O adapter guarda o contrato; este arquivo guarda o que o **executável** faz, como ele foi provado e o que
> **ninguém mediu ainda**. O executável é [`clickup.py`](clickup.py); a declaração,
> [`clickup.capabilities.tsv`](clickup.capabilities.tsv); a bancada é a família `run_task_manager_clickup_selftests` (só no core: não viaja para as portas sem lint).

## Por que nasceu

Em 2026-11-06 o maestro perguntou se havia uma task no ClickUp sobre uma integração, e a sessão não conseguiu
buscar: o projeto que usa ClickUp roda `tm.sh`, e o dispatcher saía com *"falta adapters/clickup.py"*. Havia só
a prosa e a declaração. O maestro decidiu, no mesmo dia, que o executável é pilar do Lego. Este é o 2º
executável de provider, no molde do [`linear.py`](linear.py): stdlib pura, mesmo contrato com o `tm.sh`, mesma
regra de segredo.

## Como usar

```bash
bash .claude/utils/task-manager/tm.sh --capabilities
bash .claude/utils/task-manager/tm.sh search.query "integração"            # busca por nome e descrição
bash .claude/utils/task-manager/tm.sh item.read 86abc1234                  # leitura COMPLETA; --lean = só a task
bash .claude/utils/task-manager/tm.sh comment.add 86abc1234 --visual "Progresso" --body-file corpo.txt
bash .claude/utils/task-manager/tm.sh status.transition 86abc1234 review   # resolvido contra a List
bash .claude/utils/task-manager/tm.sh item.create --title "T" --list <id> --description "**md**" \
  --priority high --due 2026-11-10T15:00:00-03:00 --tags fe,be
```

Verbos: `item.create`, `item.read`, `item.update`, `hierarchy.subtask_create`, `hierarchy.subtask_list`,
`hierarchy.context`, `status.transition`, `priority.set`, `estimate.time`, `label.set`, `comment.add`,
`comment.list`, `attachment.list`, `search.query`, `project.list`, `project.read`, `id.validate`. A lista
autoritativa é `tm.sh --capabilities`; a REGRA 104 (Executável do adapter e declaração de capacidades listam
os mesmos verbos) a mantém igual ao tsv.

Configuração: `CLICKUP_API_TOKEN` vem do ambiente; na falta, do `.env` apontado por `TM_ENV_FILE`, lido como
dado e nunca executado (a mesma regra do `linear.py`). `CLICKUP_WORKSPACE_ID` e `CLICKUP_DEFAULT_LIST_ID` são
opcionais: sem o workspace, o executável usa o único `/team` visível ao token e, com mais de um, pede
`--team`. Sem List, o `item.create` pede `--list` (veja `tm.sh project.list`).

## As armadilhas medidas, viradas código

Cada uma foi medida ao vivo por um adotante em 2026-10-02 (clickup.md, Notas Operacionais). No executável:

| armadilha | o que o executável faz |
|---|---|
| `markdown_description` é o campo da RESPOSTA | o pedido manda `markdown_content` (create e update) |
| data em ISO é aceita e não aplicada; sem a flag cai às 07:00 do dia anterior | ms inteiro + `due_date_time`/`start_date_time: true`; a data é **relida**, e se não voltou igual é rc 1 |
| `priority` string devolve `400 Priority invalid` | só inteiro 1–4 (ou urgent/high/normal/low, traduzidos); o resto morre **antes da rede**, rc 2 |
| tags no corpo do PUT devolvem 200 sem efeito | tags só por `POST`/`DELETE /task/{id}/tag/{nome}`, depois relidas; `item.update --tags` é recusado e aponta o `label.set` |
| o legado `subtasks=true` no GET da task devolve sem o campo | `include_subtasks=true` |
| status é da LIST (`400 Status not found`) | resolvido contra `GET /list/{id}`: nome exato, depois o sinônimo canônico; sem equivalente, rc 1 com os disponíveis e **sem** PUT; o status é relido |

Duas decisões de desenho, com a razão:

- **Busca local.** `GET /team/{id}/task` não tem parâmetro de texto documentado. Mandar um e confiar no
  servidor é a armadilha medida no Zoho (filtro aceito e ignorado devolve a lista inteira como "achado").
  O `search.query` percorre as páginas e filtra por nome e descrição do lado de cá. Tem teto de 20 páginas
  (2000 tasks, `TM_CLICKUP_SEARCH_MAX_PAGES`), declarado em `truncated`. Para workspace grande, estreite com
  `--list`/`--space`. O `subtasks=true` desse endpoint é o filtro de busca, não o legado do GET da task.
- **Data sem hora vira 12:00 UTC.** Assim ela cai no mesmo dia do calendário em qualquer fuso de UTC-11 a
  UTC+11. Data com hora exige fuso (`Z` ou `±HH:MM`); sem fuso, é erro de uso, não um palpite.

Comentários: `comment_text` é **texto**, não markdown. O `--visual "<título>"` monta o formato Unicode da casa
(`clickup-patterns` §Task Comments): `▶ título`, separador `━`, corpo e `🕐` com o timestamp UTC.

## Leitura completa

`tm.sh item.read <ID>` devolve a task, a descrição em markdown, os comentários de todas as páginas em ordem
cronológica e as respostas de cada um. Traz também a hierarquia (mãe completa e irmãs, ou subtasks recursivas
com teto de 5 níveis e 200 nós), os anexos listados, `counts`, `truncated` e o marcador `untrusted`. Conteúdo
lido é dado não confiável (R15.2). O que fica de fora vem declarado em `not_read`: o histórico (a API v2 não tem
endpoint de histórico ancorado) e o conteúdo dos anexos, que são listados mas não baixados.

## A bancada: o que prova e o que não prova

A bancada do core, pela família `run_task_manager_clickup_selftests`, roda o `tm.sh` de verdade
contra um **ClickUp falso em loopback**. A costura é `TM_CLICKUP_ENDPOINT`, que o executável só aceita em
`127.0.0.1`. O falso reproduz as armadilhas da tabela. São 27 casos (um por verbo, mais as armadilhas e os
erros: HTTP 500, `err` num 200, token ausente, verbo fora). A árvore copiada roda primeiro os casos-alvo, e
tem de ficar verde nesse arranjo antes de qualquer mutante contar. Depois vêm 22 mutantes, cada um revertendo
uma cura na cópia: todos mordem, cada um pelo motivo da sua cura.

**O que ela NÃO prova:** que o ClickUp real se comporta como o falso. O falso é a medição de 2026-10-02 posta
em código. Por isso todo verbo novo está `unverified` no tsv. Os `implemented` herdados (create, read, subtasks,
priority, estimate) apoiam-se na medição do comportamento do provedor, não do executável.

## Não medido ao vivo — para a sessão do projeto que usa ClickUp, ou o maestro

Nenhuma chamada real foi feita: a conta e o token são do projeto que usa. Roteiro para quem tiver o token,
numa task de teste:

1. `tm.sh search.query "<palavra de uma task conhecida>"`: acha a task? Quantas páginas, e o `last_page` veio?
2. `tm.sh item.read <ID>` numa task com mais de 25 comentários: vieram todos (paginação por `start`/`start_id`)?
   As subtasks de 2 níveis vieram achatadas ou só as diretas?
3. `tm.sh item.create --title teste --list <id> --due <amanhã>T15:00:00-03:00 --priority 2 --tags <tag>`:
   a data, a prioridade e a tag voltam iguais? A tag precisa existir no Space?
4. `tm.sh status.transition <ID> review` numa List sem `review`: escolheu o sinônimo certo?
5. `tm.sh comment.add <ID> --visual teste "corpo"`: o Unicode renderiza na UI?

Cada resposta medida vira `MEDIDO AO VIVO <data> <verbo>:` aqui, e o verbo pode subir a `implemented` no tsv
com a fonte `adapter:clickup-executavel.md§MEDIDO AO VIVO <data> <verbo>:`.
